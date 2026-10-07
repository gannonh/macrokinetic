import json
import os
import plistlib
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
from contextlib import closing

from scripts.ci.launch import declared_methods, gate, source_flags, write_evidence


ROOT = Path(__file__).resolve().parents[2]


class LaunchEvidenceTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.run = self.root / "run"
        self.run.mkdir()
        self.app = self.root / "JabTracker.app"
        self.app.mkdir()
        controls = self.root / "scripts/release/build-controls.py"
        controls.parent.mkdir(parents=True)
        shutil.copy2(ROOT / "scripts/release/build-controls.py", controls)
        self.policy = self.root / "JabTracker/App/ReleasePolicy.swift"
        self.policy.parent.mkdir(parents=True)
        self.policy.write_text("""
enum ReleaseFeature: CaseIterable {
    case first
    case second
}
enum ReleasePolicy {
    static func isEnabled(_ feature: ReleaseFeature) -> Bool {
        switch feature {
        case .first, .second:
            return false
        }
    }
}
""")
        self.inputs = {
            "configuration": "Release", "bundle_identifier": "com.gannonhall.JabTracker",
            "platform_name": "iphonesimulator", "swift_active_compilation_conditions": "",
            "other_swift_flags": "", "toolchain_dir": "",
            "compiler_overrides": {"SWIFT_EXEC": "", "SWIFT_FRONTEND_EXEC": "", "SWIFT_DRIVER_SWIFT_FRONTEND_EXEC": ""},
        }
        self.write_app()
        database = self.root / "JabTracker/Resources/usda_foods.sqlite"
        database.parent.mkdir(parents=True)
        with closing(sqlite3.connect(database)) as connection, connection:
            connection.execute("CREATE TABLE foods(id INTEGER)")
            connection.executemany("INSERT INTO foods VALUES (?)", [(index,) for index in range(22)])
        shutil.copy2(database, self.app / "usda_foods.sqlite")
        (self.run / "context.json").write_text(json.dumps({"configuration": "Release", "fixture": "ci-foods-22"}))
        (self.run / "build-settings.json").write_text(json.dumps([
            {"target": "JabTracker", "buildSettings": {"CONFIGURATION": "Release", "SDK_VERSION": "fixture"}},
        ]))
        (self.run / "xcode-version.txt").write_text("Synthetic Xcode fixture\n")
        (self.run / "raw_output.txt").write_text("builtin-SwiftDriver -- /fixture/swiftc -module-name JabTracker -O\n")

    def write_app(self):
        (self.app / "JabTrackerBuildManifest.json").write_text(json.dumps({"schema_version": 1, "inputs": self.inputs}))
        with (self.app / "Info.plist").open("wb") as output:
            plistlib.dump({"CFBundleIdentifier": self.inputs["bundle_identifier"],
                          "CFBundleShortVersionString": "0.10.1", "CFBundleVersion": "16",
                          "CFBundleExecutable": "JabTracker"}, output)
        (self.app / "JabTracker").write_bytes(b"synthetic executable fixture")

    def collect(self, configuration="Release"):
        def command(arguments, **_):
            return SimpleNamespace(stdout="a" * 40 if "rev-parse" in arguments else "")
        with patch("scripts.ci.launch.subprocess.run", side_effect=command):
            return write_evidence(self.run, self.app, configuration, self.root)

    def test_candidate_evidence_preserves_literal_artifact_and_dynamic_flags(self):
        self.assertEqual(self.collect(), [])
        result = json.loads((self.run / "candidate-evidence.json").read_text())
        self.assertEqual(result["candidate_sha"], "a" * 40)
        self.assertEqual(result["artifact"]["bundle_identifier"], "com.gannonhall.JabTracker")
        self.assertEqual((result["artifact"]["version"], result["artifact"]["build"]), ("0.10.1", "16"))
        self.assertEqual(result["database"]["record_count"], 22)
        self.assertFalse(result["database"]["production_database_acceptance"])
        self.assertEqual(result["release_flags"]["values"], {"first": False, "second": False})
        self.assertEqual((self.run / "ReleasePolicy.swift").read_text(), self.policy.read_text())
        self.assertTrue((self.run / "built-Info.plist").is_file())
        self.assertTrue((self.run / "JabTrackerBuildManifest.json").is_file())
        self.assertIn("-module-name JabTracker -O", (self.run / "compiler-commands.txt").read_text())

    def test_missing_flag_registry_fails_but_retains_other_candidate_identity(self):
        self.policy.unlink()
        errors = self.collect()
        self.assertTrue(any(error.startswith("release_flags:") for error in errors))
        result = json.loads((self.run / "candidate-evidence.json").read_text())
        self.assertEqual(result["status"], "Failed")
        self.assertEqual(result["candidate_sha"], "a" * 40)
        self.assertEqual(result["artifact"]["build"], "16")

    def test_harness_artifact_cannot_satisfy_ordinary_release_check(self):
        self.inputs.update(configuration="ReleaseTestHarness", bundle_identifier="com.gannonhall.JabTrackerTestHarness",
                           swift_active_compilation_conditions="JABTRACKER_TEST_HARNESS")
        self.write_app()
        self.assertTrue(any("only ordinary Release" in error for error in self.collect()))

    def test_harness_evidence_preserves_its_distinct_identity_and_runtime(self):
        self.inputs.update(configuration="ReleaseTestHarness", bundle_identifier="com.gannonhall.JabTrackerTestHarness",
                           swift_active_compilation_conditions="JABTRACKER_TEST_HARNESS")
        self.write_app()
        runtime = {"runtime_identifier": "synthetic.runtime", "device": {"udid": "synthetic-device"},
                   "configuration": "ReleaseTestHarness", "fixture": "ci-foods-22"}
        (self.run / "context.json").write_text(json.dumps(runtime))
        (self.run / "build-settings.json").write_text(json.dumps([
            {"target": "JabTracker", "buildSettings": {"CONFIGURATION": "ReleaseTestHarness"}},
        ]))
        tests = self.run / "test-run"
        tests.mkdir()
        (tests / "raw_output.txt").write_text("builtin-SwiftDriver -- /fixture/swiftc -module-name JabTracker -O\n")
        self.assertEqual(self.collect("ReleaseTestHarness"), [])
        result = json.loads((self.run / "candidate-evidence.json").read_text())
        self.assertEqual(result["artifact"]["bundle_identifier"], "com.gannonhall.JabTrackerTestHarness")
        self.assertEqual(result["run_context"], runtime)
        self.assertEqual(result["release_flags"]["values"], {"first": False, "second": False})

    def test_database_difference_and_missing_actual_compiler_commands_fail(self):
        with closing(sqlite3.connect(self.app / "usda_foods.sqlite")) as connection, connection:
            connection.execute("DELETE FROM foods WHERE id=0")
        (self.run / "raw_output.txt").write_text("BUILD SUCCEEDED\n")
        errors = self.collect()
        self.assertTrue(any(error.startswith("database:") for error in errors))
        self.assertTrue(any(error.startswith("compiler_commands:") for error in errors))

    def test_policy_true_values_are_recorded_and_nonliteral_decisions_reject(self):
        self.policy.write_text(self.policy.read_text().replace("return false", "return true"))
        self.assertEqual(source_flags(self.policy)["values"], {"first": True, "second": True})
        self.policy.write_text(self.policy.read_text().replace("return true", "return feature == .first"))
        with self.assertRaisesRegex(ValueError, "nonliteral"):
            source_flags(self.policy)

    def test_declared_method_must_belong_to_its_class_and_not_a_comment_or_nested_helper(self):
        self.assertEqual(declared_methods("""
class FirstTests: XCTestCase {
    // func testComment() {}
    let text = "func testString() {}"
    func testFirst() { func testNested() {} }
}
class SecondTests: XCTestCase { func testSecond() {} }
"""), {("FirstTests", "testFirst"), ("SecondTests", "testSecond")})

    def test_missing_journeys_still_fail_when_known_control_test_passes(self):
        tests = self.run / "test-run"
        tests.mkdir()
        for name in ("results.xcresult", "raw_output.txt", "xcresult-summary.json", "xcresult-tests.json",
                     "attachment-export.txt", "launch-suite.json"):
            (tests / name).write_text("fixture")
        (tests / "runner-status.txt").write_text("0\n")
        (self.run / "candidate-evidence.json").write_text(json.dumps({"status": "Passed", "errors": []}))
        quarantine = self.root / "scripts/ci/launch-quarantine.json"
        quarantine.parent.mkdir(parents=True)
        quarantine.write_text(json.dumps({"schema_version": 1, "entries": [{
            "selector": "JabTrackerUITests/DormantTests", "reason": "Capability off",
            "issue": "https://linear.app/kata-sh/issue/KAT-3581",
        }]}))
        suite = {"critical_journeys": ["nutrition"], "missing_critical_journeys": [],
                 "tests": [{"selector": "JabTrackerUITests/ControlTests/testRetry", "journeys": ["controls"]}],
                 "quarantine_file": "scripts/ci/launch-quarantine.json"}
        (tests / "launch-suite.json").write_text(json.dumps(suite))
        self.assertEqual(gate(suite, self.run, self.root), ["No verified selected test covers required journey: nutrition"])
        suite["tests"][0]["journeys"] = ["nutrition"]
        (tests / "launch-suite.json").write_text(json.dumps(suite))
        self.assertEqual(gate(suite, self.run, self.root), [])
        (self.run / "candidate-evidence.json").write_text(json.dumps({"status": "Failed", "errors": []}))
        self.assertIn("Candidate evidence did not pass.", gate(suite, self.run, self.root))
        (self.run / "candidate-evidence.json").write_text(json.dumps({"status": "Passed", "errors": []}))
        (tests / "launch-suite.json").write_text(json.dumps(suite | {"critical_journeys": ["different"]}))
        self.assertIn("The retained runner suite differs from the readiness selection.", gate(suite, self.run, self.root))
        (tests / "launch-suite.json").write_text(json.dumps(suite))
        (tests / "xcresult-tests.json").unlink()
        self.assertIn("Required launch artifact is missing: xcresult-tests.json", gate(suite, self.run, self.root))


class LaunchCommandTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.directory = Path(directory.name)
        self.bin = self.directory / "bin"
        self.bin.mkdir()
        command = self.bin / "xcodebuild"
        command.write_text(f"#!{sys.executable}\n" + """
import json, os, sys
from pathlib import Path
Path(os.environ['FAKE_CALLED']).touch()
if '-version' in sys.argv:
    print('Synthetic Xcode fixture')
elif '-showBuildSettings' in sys.argv:
    print(json.dumps([{'target': 'JabTracker', 'buildSettings': {'CONFIGURATION': 'Release'}}]))
else:
    print('error: synthetic compilation failure', file=sys.stderr)
    sys.exit(65)
""")
        command.chmod(0o755)
        self.evidence = self.directory / "evidence"
        self.called = self.directory / "called"

    def run_command(self, mode):
        return subprocess.run(
            ["bash", str(ROOT / "scripts/ci/run-launch-validation.sh"), mode],
            env=os.environ | {"PATH": f"{self.bin}:{os.environ['PATH']}", "RUNNER_TEMP": str(self.directory),
                              "JABTRACKER_LAUNCH_EVIDENCE_DIR": str(self.evidence),
                              "FAKE_CALLED": str(self.called)},
            text=True, capture_output=True,
        )

    def test_release_compile_failure_remains_65_after_metadata_failure(self):
        result = self.run_command("release")
        self.assertEqual(result.returncode, 65, result.stdout + result.stderr)
        self.assertEqual((self.evidence / "xcodebuild-status.txt").read_text(), "65\n")
        self.assertIn("synthetic compilation failure", (self.evidence / "raw_output.txt").read_text())
        payload = json.loads((self.evidence / "candidate-evidence.json").read_text())
        self.assertEqual(payload["status"], "Failed")
        self.assertTrue(any(error.startswith("artifact:") for error in payload["errors"]))

    def test_unknown_mode_is_rejected_before_any_compiler_command(self):
        self.assertEqual(self.run_command("debug").returncode, 2)
        self.assertFalse(self.called.exists())

    def test_existing_evidence_directory_cannot_be_overwritten(self):
        self.evidence.mkdir()
        marker = self.evidence / "previous.txt"
        marker.write_text("preserve")
        self.assertEqual(self.run_command("release").returncode, 2)
        self.assertEqual(marker.read_text(), "preserve")
        self.assertFalse(self.called.exists())


if __name__ == "__main__":
    unittest.main()
