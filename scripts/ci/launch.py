"""Validate the launch allowlist and preserve candidate evidence."""

import argparse
import hashlib
import importlib.util
import json
import re
import shutil
import sqlite3
import subprocess
import sys
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SELECTOR = re.compile(r"JabTrackerUITests/[A-Za-z_][A-Za-z0-9_]*/test[A-Za-z0-9_]+\Z")


def unique_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def declared_methods(text):
    text = re.sub(r'"""[\s\S]*?"""|"(?:\\.|[^"\\])*"|/\*[\s\S]*?\*/|//[^\n]*', "", text)
    depth = 0
    classes = []
    methods = set()
    for token in re.finditer(r"\bclass\s+(\w+)\s*:[^{]+\{|\bfunc\s+(test\w+)\s*\(\s*\)|[{}]", text):
        if token[1]:
            depth += 1
            classes.append((token[1], depth))
        elif token[2]:
            if classes and depth == classes[-1][1]:
                methods.add((classes[-1][0], token[2]))
        elif token[0] == "{":
            depth += 1
        else:
            depth -= 1
            while classes and classes[-1][1] > depth:
                classes.pop()
    return methods


def load_suite(path, root=ROOT):
    suite = json.loads(Path(path).read_text(), object_pairs_hook=unique_keys)
    required = {"schema_version", "name", "scheme", "configuration", "fixture", "tests", "missing_critical_journeys",
                "critical_journeys"}
    if not isinstance(suite, dict) or not required <= suite.keys() or suite.keys() - required - {"quarantine_file"}:
        raise ValueError("Unknown or missing launch suite fields.")
    if type(suite["schema_version"]) is not int or suite["schema_version"] != 1:
        raise ValueError("Unsupported launch suite version.")
    if suite["scheme"] != "JabTrackerReleaseTestHarness" or suite["configuration"] != "ReleaseTestHarness":
        raise ValueError("Launch journeys require the ReleaseTestHarness configuration and scheme.")
    for field in ("name", "fixture"):
        if not isinstance(suite[field], str) or not suite[field].strip():
            raise ValueError(f"Launch suite {field} must be nonempty.")
    if not isinstance(suite["tests"], list) or not suite["tests"]:
        raise ValueError("Launch suite must select at least one exact method.")
    selectors = set()
    for test in suite["tests"]:
        fields = {"selector", "source", "issue", "purpose", "verified_evidence", "journeys"}
        if not isinstance(test, dict) or set(test) != fields:
            raise ValueError("Unknown or missing selected-test fields.")
        if any(not isinstance(test[field], str) or not test[field].strip() for field in fields - {"journeys"}):
            raise ValueError("Selected-test metadata must be nonempty strings.")
        if not isinstance(test["journeys"], list) or not test["journeys"] or any(
            not isinstance(journey, str) or not journey.strip() for journey in test["journeys"]
        ):
            raise ValueError("Selected tests must name their exercised journeys.")
        selector = test["selector"]
        if not SELECTOR.fullmatch(selector):
            raise ValueError(f"Launch selector must name an exact UI test method: {selector}")
        if selector in selectors:
            raise ValueError(f"Duplicate launch selector: {selector}")
        selectors.add(selector)
        source = (root / test["source"]).resolve()
        if not source.is_relative_to((root / "JabTrackerUITests").resolve()) or source.suffix != ".swift":
            raise ValueError(f"Invalid UI test source: {test['source']}")
        _, suite_name, method = selector.split("/")
        if (suite_name, method) not in declared_methods(source.read_text()):
            raise ValueError(f"Selected test is not declared in its source: {selector}")
    missing = suite["missing_critical_journeys"]
    if (not isinstance(suite["critical_journeys"], list) or not suite["critical_journeys"] or any(
        not isinstance(journey, str) or not journey.strip() for journey in suite["critical_journeys"]
    ) or len(suite["critical_journeys"]) != len(set(suite["critical_journeys"]))):
        raise ValueError("The required critical journey inventory must be nonempty.")
    if not isinstance(missing, list) or any(
        not isinstance(entry, dict) or set(entry) != {"issue", "journey", "reason"}
        or any(not isinstance(value, str) or not value.strip() for value in entry.values())
        for entry in missing
    ):
        raise ValueError("Missing critical journeys must carry an issue, journey and reason.")
    return suite


def source_flags(path):
    source = path.read_text()
    cleaned = re.sub(r"//[^\n]*|/\*[\s\S]*?\*/", "", source)
    text = re.sub(r"\s+", "", cleaned)
    enum = re.search(r"enum\s+ReleaseFeature\s*:\s*CaseIterable\s*\{([^{}]+)\}", cleaned)
    policy = re.search(r"enumReleasePolicy\{staticfuncisEnabled\(_feature:ReleaseFeature\)->Bool\{switchfeature\{([^{}]+)\}\}\}", text)
    if not enum or not policy:
        raise ValueError("ReleasePolicy is missing or no longer a static exhaustive boolean policy.")
    features = re.findall(r"\bcase\s+([A-Za-z_]\w*)", enum[1])
    if not features or re.sub(r"\bcase\s+[A-Za-z_]\w*", "", enum[1]).strip():
        raise ValueError("ReleaseFeature declaration is not inspectable.")
    values = {}
    branches = list(re.finditer(r"case((?:\.\w+,)*\.\w+):return(true|false)", policy[1]))
    if "".join(branch[0] for branch in branches) != policy[1]:
        raise ValueError("ReleasePolicy contains nonliteral decisions.")
    for branch in branches:
        for name in branch[1].replace(".", "").split(","):
            if name in values:
                raise ValueError(f"Duplicate release policy decision: {name}")
            values[name] = branch[2] == "true"
    if len(features) != len(set(features)) or set(features) != set(values):
        raise ValueError("ReleasePolicy does not cover exactly its declared features.")
    return {"source_sha256": hashlib.sha256(source.encode()).hexdigest(), "values": values,
            "basis": "Policy source from the tested checkout; compiled values were not independently sampled"}


def file_sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_evidence(run_directory, app, configuration, root=ROOT):
    payload = {"schema_version": 1, "configuration": configuration,
               "recorded_at": datetime.now(timezone.utc).isoformat()}
    errors = []

    def collect(name, read):
        try:
            payload[name] = read()
        except (OSError, ValueError, TypeError, KeyError, sqlite3.Error, subprocess.CalledProcessError) as error:
            errors.append(f"{name}: {error}")

    collect("candidate_sha", lambda: subprocess.run(
        ["git", "-C", str(root), "rev-parse", "HEAD"], check=True, text=True, capture_output=True
    ).stdout.strip())
    collect("source_status", lambda: subprocess.run(
        ["git", "-C", str(root), "status", "--porcelain", "--untracked-files=all"],
        check=True, text=True, capture_output=True
    ).stdout.strip())
    if payload.get("source_status"):
        errors.append("Uncommitted source changes prevent association with the candidate SHA.")
    collect("run_context", lambda: json.loads((run_directory / "context.json").read_text()))
    def settings():
        rows = json.loads((run_directory / "build-settings.json").read_text())
        apps = [row["buildSettings"] for row in rows if row.get("target") == "JabTracker"]
        if len(apps) != 1 or apps[0]["CONFIGURATION"] != configuration:
            raise ValueError("Resolved app target/settings do not match the requested configuration.")
        return apps[0]

    collect("resolved_settings", settings)
    collect("xcode", lambda: (run_directory / "xcode-version.txt").read_text().strip())

    def artifact():
        spec = importlib.util.spec_from_file_location("build_controls", root / "scripts/release/build-controls.py")
        controls = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(controls)
        manifest = json.loads((app / controls.MANIFEST_NAME).read_text(), object_pairs_hook=unique_keys)
        info = controls.read_info(app / "Info.plist")
        if configuration == "Release":
            controls.verify_app(app)
        else:
            inputs = manifest["inputs"]
            if (manifest.get("schema_version") != 1 or set(manifest) != {"schema_version", "inputs"}
                    or configuration != "ReleaseTestHarness" or inputs["configuration"] != configuration
                    or inputs["bundle_identifier"] != "com.gannonhall.JabTrackerTestHarness"
                    or info["CFBundleIdentifier"] != inputs["bundle_identifier"]
                    or controls.definitions(inputs) != {"JABTRACKER_TEST_HARNESS"}):
                raise ValueError("Harness artifact identity/compiler inputs do not match its configuration.")
        for key in ("CFBundleShortVersionString", "CFBundleVersion"):
            if not isinstance(info.get(key), str) or not info[key]:
                raise ValueError(f"Built Info.plist lacks {key}.")
        shutil.copy2(app / "Info.plist", run_directory / "built-Info.plist")
        shutil.copy2(app / controls.MANIFEST_NAME, run_directory / controls.MANIFEST_NAME)
        return {"build_manifest": manifest, "bundle_identifier": info["CFBundleIdentifier"],
                "version": info["CFBundleShortVersionString"], "build": info["CFBundleVersion"],
                "info_sha256": file_sha(app / "Info.plist"),
                "executable_sha256": file_sha(app / info["CFBundleExecutable"])}

    collect("artifact", artifact)

    def database():
        path = app / "usda_foods.sqlite"
        with closing(sqlite3.connect(f"file:{path}?mode=ro", uri=True)) as connection:
            count = connection.execute("SELECT count(*) FROM foods").fetchone()[0]
        checksum = file_sha(path)
        if count != 22 or checksum != file_sha(root / "JabTracker/Resources/usda_foods.sqlite"):
            raise ValueError("Built database does not match the deterministic 22-food CI fixture.")
        return {"identity": "ci-foods-22", "record_count": count, "sha256": checksum,
                "production_database_acceptance": False}

    collect("database", database)

    def flags():
        path = root / "JabTracker/App/ReleasePolicy.swift"
        values = source_flags(path)
        shutil.copy2(path, run_directory / "ReleasePolicy.swift")
        return values

    collect("release_flags", flags)

    def compiler():
        log = run_directory / ("raw_output.txt" if configuration == "Release" else "test-run/raw_output.txt")
        lines = log.read_text().splitlines()
        commands = [line.strip() for line in lines if re.search(r"-module-name\s+JabTracker(?:\s|$)", line)
                    and ("swiftc " in line or "swift-frontend " in line or "builtin-SwiftDriver" in line)]
        if not commands:
            raise ValueError("Actual app Swift compiler commands are missing.")
        (run_directory / "compiler-commands.txt").write_text("\n".join(commands) + "\n")
        return commands

    collect("compiler_commands", compiler)
    payload["errors"] = errors
    payload["status"] = "Failed" if errors else "Passed"
    (run_directory / "candidate-evidence.json").write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    return errors


def gate(suite, run_directory, root=ROOT):
    errors = []
    covered = {journey for test in suite["tests"] for journey in test["journeys"]}
    for journey in sorted(set(suite["critical_journeys"]) - covered):
        errors.append(f"No verified selected test covers required journey: {journey}")
    for missing in suite["missing_critical_journeys"]:
        errors.append(f"Missing critical journey {missing['journey']} ({missing['issue']}): {missing['reason']}")
    evidence = json.loads((run_directory / "candidate-evidence.json").read_text())
    if evidence.get("status") != "Passed":
        errors.extend(evidence.get("errors") or ["Candidate evidence did not pass."])
    tests = run_directory / "test-run"
    for name in ("results.xcresult", "raw_output.txt", "xcresult-summary.json", "xcresult-tests.json",
                 "attachment-export.txt", "runner-status.txt", "launch-suite.json"):
        if not (tests / name).exists():
            errors.append(f"Required launch artifact is missing: {name}")
    if not (tests / "runner-status.txt").is_file() or (tests / "runner-status.txt").read_text().strip() != "0":
        errors.append("The launch runner failed.")
    if (tests / "launch-suite.json").is_file():
        retained = json.loads((tests / "launch-suite.json").read_text(), object_pairs_hook=unique_keys)
        if retained != suite:
            errors.append("The retained runner suite differs from the readiness selection.")
    if not suite.get("quarantine_file"):
        errors.append("The explicit quarantine inventory is missing.")
    else:
        path = (root / suite["quarantine_file"]).resolve()
        if not path.is_relative_to((root / "scripts/ci").resolve()) or path.suffix != ".json":
            raise ValueError("The quarantine inventory must be a versioned scripts/ci JSON file.")
        inventory = json.loads(path.read_text(), object_pairs_hook=unique_keys)
        if inventory.get("schema_version") != 1 or not isinstance(inventory.get("entries"), list) or not inventory["entries"]:
            raise ValueError("The explicit quarantine inventory is empty or unsupported.")
        shutil.copy2(path, run_directory / "launch-quarantine.json")
        for entry in inventory["entries"]:
            if not entry.get("reason") or not entry.get("issue") or not entry.get("selector"):
                errors.append("A quarantine entry lacks its selector/reason/owner.")
            if any(test["selector"] == entry["selector"] or test["selector"].startswith(entry["selector"] + "/")
                   for test in suite["tests"]):
                errors.append(f"A selected test is explicitly quarantined: {entry['selector']}")
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["selectors", "evidence", "gate"])
    parser.add_argument("--suite-file", type=Path)
    parser.add_argument("--scheme")
    parser.add_argument("--configuration", choices=["Debug", "Release", "ReleaseTestHarness"])
    parser.add_argument("--run-directory", type=Path)
    parser.add_argument("--app", type=Path)
    args = parser.parse_args()
    try:
        if args.action == "evidence":
            if not args.run_directory or not args.app or args.configuration not in {"Release", "ReleaseTestHarness"}:
                raise ValueError("Evidence requires a run directory, built app and explicit Release configuration.")
            errors = write_evidence(args.run_directory, args.app, args.configuration)
        else:
            if not args.suite_file:
                raise ValueError("A versioned suite file is required.")
            suite = load_suite(args.suite_file)
            if args.action == "selectors":
                if (args.scheme, args.configuration) != (suite["scheme"], suite["configuration"]):
                    raise ValueError("Requested scheme/configuration does not match the launch suite.")
                for test in suite["tests"]:
                    print(test["selector"])
                errors = []
            else:
                if not args.run_directory:
                    raise ValueError("The launch gate requires a run directory.")
                errors = gate(suite, args.run_directory)
        if errors:
            raise ValueError("\n".join(errors))
    except (OSError, ValueError, TypeError) as error:
        print(f"launch-suite: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
