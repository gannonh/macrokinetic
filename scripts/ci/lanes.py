"""Classify JabTrackerTests sources and emit the CI test manifest."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from types import SimpleNamespace
from typing import Any, Iterable


UNIT_TARGET = "JabTrackerUnitTests"
INTEGRATION_TARGET = "JabTrackerIntegrationTests"
SUITE_DIR = "JabTrackerTests"

STRUCT_RE = re.compile(r"\b(?:struct|class)\s+(\w+)")
FUNC_RE = re.compile(r"\bfunc\s+(\w+)\s*\(")
TEST_ATTR_RE = re.compile(r"@Test\b")


def repo_root_from_here() -> Path:
    return Path(__file__).resolve().parents[1]


def load_lane_config(root: Path) -> dict[str, Any]:
    path = root / "scripts" / "ci" / "test-lanes.json"
    config = json.loads(path.read_text())
    config["integration_skip_testing"] = list(
        dict.fromkeys(
            [*config["storekit_only_testing"], *config["performance_only_testing"]]
        )
    )
    return config


def discover_current_suite_sources(root: Path) -> set[str]:
    tests_root = root / SUITE_DIR
    discovered: set[str] = set()
    for path in tests_root.rglob("*.swift"):
        relative = path.relative_to(root).as_posix()
        if "/Onboarding/Legacy/" in f"/{path.relative_to(tests_root).as_posix()}/":
            continue
        discovered.add(relative)
    return discovered


def _suite_relative(source_file: str) -> str:
    prefix = f"{SUITE_DIR}/"
    if source_file.startswith(prefix):
        return source_file[len(prefix) :]
    return source_file


def assign_sources(root: Path) -> list[dict[str, str]]:
    config = load_lane_config(root)
    integration = set(config["integration_sources"])
    assignments: list[dict[str, str]] = []
    for source_file in sorted(discover_current_suite_sources(root)):
        relative = _suite_relative(source_file)
        if relative in integration:
            target = INTEGRATION_TARGET
            lane = "integration"
        else:
            target = UNIT_TARGET
            lane = "unit"
        assignments.append(
            {
                "source_file": source_file,
                "target": target,
                "lane": lane,
            }
        )
    return assignments


def scan_swift_tests(path: Path) -> list[tuple[str, str]]:
    current_type = path.stem
    found: list[tuple[str, str]] = []
    pending_test = False
    seen: set[tuple[str, str]] = set()
    for line in path.read_text().splitlines():
        struct_match = STRUCT_RE.search(line)
        if struct_match:
            current_type = struct_match.group(1)
        if TEST_ATTR_RE.search(line):
            pending_test = True
        func_match = FUNC_RE.search(line)
        if not func_match:
            continue
        name = func_match.group(1)
        is_test = pending_test or name.startswith("test")
        pending_test = False
        if not is_test:
            continue
        key = (current_type, name)
        if key in seen:
            continue
        seen.add(key)
        found.append(key)
    return found


def _lane_for_identifier(identifier: str, config: dict[str, Any], file_lane: str) -> str:
    if file_lane == "unit":
        return "unit"
    for prefix in config["storekit_only_testing"]:
        if identifier == prefix or identifier.startswith(f"{prefix}/"):
            return "storekit"
    for prefix in config["performance_only_testing"]:
        if identifier == prefix or identifier.startswith(f"{prefix}/"):
            return "performance"
        # Suite-level filters also match every test in that suite.
        parts = prefix.split("/")
        if len(parts) == 2 and identifier.startswith(f"{prefix}/"):
            return "performance"
    return "integration"


def _execution_policy(lane: str) -> str:
    if lane == "unit":
        return "parallel"
    return "serial"


def build_source_manifest(root: Path) -> dict[str, Any]:
    config = load_lane_config(root)
    tests: list[dict[str, str]] = []
    for assignment in assign_sources(root):
        source_file = assignment["source_file"]
        path = root / source_file
        target = assignment["target"]
        for type_name, func_name in scan_swift_tests(path):
            identifier = f"{target}/{type_name}/{func_name}"
            suite_identifier = f"{target}/{type_name}"
            lane = _lane_for_identifier(identifier, config, assignment["lane"])
            if lane == "integration":
                lane = _lane_for_identifier(suite_identifier, config, assignment["lane"])
            tests.append(
                {
                    "bundle": target,
                    "source_file": source_file,
                    "identifier": identifier,
                    "target": target,
                    "lane": lane,
                    "execution_policy": _execution_policy(lane),
                }
            )
    tests.sort(key=lambda item: (item["lane"], item["source_file"], item["identifier"]))
    return {
        "version": 1,
        "baseline": {
            "total_tests": config["baseline_xcresult_total"],
            "bundle": config["baseline_bundle"],
            "source": "pre-split JabTrackerTests xcresult summary",
        },
        "obsolete_allowlist": list(config["obsolete_allowlist"]),
        "out_of_scope": list(config["out_of_scope"]),
        "tests": tests,
    }


def compare_to_baseline(manifest: dict[str, Any]) -> dict[str, list[str]]:
    counts: dict[str, int] = defaultdict(int)
    for item in manifest["tests"]:
        counts[item["identifier"]] += 1
    duplicated = sorted(identifier for identifier, count in counts.items() if count > 1)
    unassigned = [
        item["identifier"]
        for item in manifest["tests"]
        if not item.get("lane")
    ]
    return {
        "unassigned": unassigned,
        "duplicated": duplicated,
        "obsolete_allowlist": list(manifest.get("obsolete_allowlist", [])),
    }


def assign_executed_identifiers(
    manifest: dict[str, Any],
    lane_runs: Iterable[dict[str, Any]],
) -> dict[str, Any]:
    by_identifier = {item["identifier"]: item for item in manifest["tests"]}
    assigned: dict[str, str] = {}
    duplicated: list[str] = []
    unassigned: list[str] = []
    executed: list[dict[str, str]] = []
    for run in lane_runs:
        lane = run["lane"]
        for identifier in run["identifiers"]:
            match = _match_identifier(identifier, by_identifier)
            if match is None:
                unassigned.append(identifier)
                continue
            previous = assigned.get(match)
            if previous and previous != lane:
                duplicated.append(match)
            assigned[match] = lane
            executed.append(
                {
                    "identifier": match,
                    "lane": lane,
                    "reported_identifier": identifier,
                }
            )
    return {
        "executed": executed,
        "unassigned": unassigned,
        "duplicated": duplicated,
    }


def compare_executed_assignment(merged: dict[str, Any]) -> dict[str, list[str]]:
    return {
        "unassigned": list(merged.get("unassigned", [])),
        "duplicated": list(merged.get("duplicated", [])),
    }


def _match_identifier(reported: str, by_identifier: dict[str, dict[str, str]]) -> str | None:
    if reported in by_identifier:
        return reported
    for identifier in by_identifier:
        if identifier.endswith(f"/{reported}") or reported.endswith(f"/{identifier.split('/', 1)[-1]}"):
            return identifier
        if identifier.split("/")[-1] == reported.split("/")[-1] and identifier.split("/")[-2] in reported:
            return identifier
    return None


def xcodebuild_args_for_lane(root: Path, lane: str) -> list[str]:
    config = load_lane_config(root)
    if lane == "unit":
        return [f"-only-testing:{UNIT_TARGET}"]
    if lane == "integration":
        args = [f"-only-testing:{INTEGRATION_TARGET}"]
        for identifier in config["integration_skip_testing"]:
            args.append(f"-skip-testing:{identifier}")
        return args
    if lane == "storekit":
        return [f"-only-testing:{identifier}" for identifier in config["storekit_only_testing"]]
    if lane == "performance":
        return [f"-only-testing:{identifier}" for identifier in config["performance_only_testing"]]
    raise ValueError(f"Unknown lane: {lane}")


def write_manifest(root: Path, output: Path) -> SimpleNamespace:
    output.parent.mkdir(parents=True, exist_ok=True)
    payload = build_source_manifest(root)
    output.write_text(json.dumps(payload, indent=2) + "\n")
    return SimpleNamespace(returncode=0)


def parse_xcresult_identifiers(summary: dict[str, Any]) -> list[str]:
    identifiers: list[str] = []

    def walk(node: Any) -> None:
        if isinstance(node, dict):
            identifier = node.get("identifier") or node.get("testIdentifier") or node.get("name")
            children = node.get("children") or node.get("subtests") or node.get("tests") or []
            node_type = str(node.get("nodeType") or node.get("kind") or "")
            if identifier and not children and node_type.lower() in {"test case", "testcase", ""}:
                if isinstance(identifier, str) and "/" in identifier or (
                    isinstance(identifier, str) and identifier.startswith("JabTracker")
                ):
                    identifiers.append(str(identifier))
            for child in children:
                walk(child)
        elif isinstance(node, list):
            for child in node:
                walk(child)

    walk(summary)
    return identifiers


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=None, help="Repository root")
    parser.add_argument("--output", help="Write the source or merged manifest JSON here")
    parser.add_argument(
        "--print-xcodebuild-args",
        metavar="LANE",
        help="Print xcodebuild only-testing/skip-testing args for a lane",
    )
    parser.add_argument(
        "--validate",
        action="store_true",
        help="Validate source assignment and exit non-zero on duplicates",
    )
    args = parser.parse_args(argv)
    root = Path(args.root).resolve() if args.root else Path.cwd()
    if args.print_xcodebuild_args:
        for item in xcodebuild_args_for_lane(root, args.print_xcodebuild_args):
            print(item)
        return 0
    if args.output:
        write_manifest(root, Path(args.output))
    if args.validate or args.output:
        manifest = build_source_manifest(root)
        comparison = compare_to_baseline(manifest)
        if comparison["duplicated"] or comparison["unassigned"]:
            print(json.dumps(comparison, indent=2), file=sys.stderr)
            return 1
        print(
            json.dumps(
                {
                    "baseline_total": manifest["baseline"]["total_tests"],
                    "source_identifiers": len(manifest["tests"]),
                    "lanes": sorted({item["lane"] for item in manifest["tests"]}),
                }
            )
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
