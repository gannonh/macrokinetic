import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class TestRunnerTests(unittest.TestCase):
    def setUp(self):
        evidence_root = os.environ.get("JABTRACKER_RUNNER_TEST_EVIDENCE_DIR")
        if evidence_root:
            self.directory = Path(evidence_root) / self._testMethodName
            self.directory.mkdir(parents=True, exist_ok=False)
        else:
            temporary = tempfile.TemporaryDirectory()
            self.addCleanup(temporary.cleanup)
            self.directory = Path(temporary.name)
        self.bin = self.directory / "bin"
        self.bin.mkdir()
        self.summary = {
            "totalTestCount": 1,
            "passedTests": 1,
            "failedTests": 0,
            "skippedTests": 0,
            "expectedFailures": 0,
            "result": "Passed",
            "testFailures": [],
        }
        self.nodes = {
            "testNodes": [{
                "nodeType": "Unit test bundle",
                "name": "JabTrackerUnitTests",
                "children": [{
                    "nodeType": "Test Case",
                    "nodeIdentifier": "ExampleTests/testExample()",
                    "result": "Passed",
                }],
            }],
        }
        self.write_executable("xcodebuild", """
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
Path(os.environ['FAKE_ARGUMENTS']).write_text(json.dumps(args))
if '-resultBundlePath' in args and os.environ.get('FAKE_MISSING_RESULT') != '1':
    Path(args[args.index('-resultBundlePath') + 1]).mkdir(parents=True)
print('xcodebuild stdout')
print(os.environ.get('FAKE_STDERR', 'xcodebuild stderr'), file=sys.stderr)
sys.exit(int(os.environ.get('FAKE_XCODE_STATUS', '0')))
""")
        self.write_executable("xcbeautify", """
import os, sys
sys.stdout.write(sys.stdin.read())
sys.exit(int(os.environ.get('FAKE_FORMATTER_STATUS', '0')))
""")
        self.write_executable("xcrun", """
import os, sys
from pathlib import Path
args = sys.argv[1:]
if 'summary' in args:
    sys.stdout.write(Path(os.environ['FAKE_SUMMARY']).read_text())
elif 'tests' in args:
    sys.stdout.write(Path(os.environ['FAKE_NODES']).read_text())
elif 'export' in args:
    if os.environ.get('FAKE_EXPORT_FAILURE') == '1':
        print('attachment export failed', file=sys.stderr)
        sys.exit(1)
    output = Path(args[args.index('--output-path') + 1])
    output.mkdir(parents=True, exist_ok=True)
    (output / 'before-failure.png').write_bytes(b'fake screenshot')
    (output / 'hierarchy.txt').write_text('Application hierarchy evidence')
elif 'xccov' in args:
    print('{}')
else:
    print('unexpected xcrun call: ' + repr(args), file=sys.stderr)
    sys.exit(1)
""")

    def write_executable(self, name, source):
        path = self.bin / name
        path.write_text(f"#!{sys.executable}\n" + source)
        path.chmod(0o755)

    def write_launch_suite(self, selectors=None):
        selectors = selectors or ["JabTrackerUITests/FoodSearchV08UITests/testSearchShowsRetryableError"]
        path = self.directory / "launch-suite.json"
        path.write_text(json.dumps({
            "schema_version": 1,
            "name": "runner-regression",
            "scheme": "JabTrackerReleaseTestHarness",
            "configuration": "ReleaseTestHarness",
            "fixture": "ci-foods-22",
            "critical_journeys": ["runner-regression"],
            "tests": [{
                "selector": selector,
                "source": "JabTrackerUITests/Nutrition/FoodSearchV08UITests.swift",
                "issue": "KAT-3589",
                "purpose": "CLI fixture, not app acceptance",
                "verified_evidence": "synthetic runner fixture",
                "journeys": ["runner-regression"],
            } for selector in selectors],
            "missing_critical_journeys": [],
        }))
        self.nodes["testNodes"][0]["name"] = "JabTrackerUITests"
        self.nodes["testNodes"][0]["children"] = [{
            "nodeType": "Test Case",
            "nodeIdentifier": selector.split("/", 1)[1] + "()",
            "result": "Passed",
        } for selector in selectors]
        self.summary.update(totalTestCount=len(selectors), passedTests=len(selectors))
        return path

    def test_release_harness_suite_uses_exact_declared_methods_and_configuration(self):
        suite = self.write_launch_suite()
        result = self.run_runner(
            "ui", "--scheme", "JabTrackerReleaseTestHarness", "--configuration", "ReleaseTestHarness",
            "--suite-file", str(suite), "--log-dir", str(self.directory / "suite-evidence"),
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        arguments = json.loads((self.directory / "arguments.json").read_text())
        self.assertEqual(arguments[arguments.index("-scheme") + 1], "JabTrackerReleaseTestHarness")
        self.assertEqual(arguments[arguments.index("-configuration") + 1], "ReleaseTestHarness")
        self.assertEqual(arguments[arguments.index("-parallel-testing-enabled") + 1], "NO")
        self.assertIn("CODE_SIGNING_ALLOWED=NO", arguments)
        self.assertIn("SWIFT_ENABLE_EXPLICIT_MODULES=NO", arguments)
        self.assertEqual([arg for arg in arguments if arg.startswith("-only-testing:")], [
            "-only-testing:JabTrackerUITests/FoodSearchV08UITests/testSearchShowsRetryableError",
        ])
        self.assertFalse(any(arg.startswith("-skip-testing:") for arg in arguments))

    def run_launch_suite(self, suite, **environment):
        return self.run_runner(
            "ui", "--scheme", "JabTrackerReleaseTestHarness", "--configuration", "ReleaseTestHarness",
            "--suite-file", str(suite), "--log-dir", str(self.directory / "suite-evidence"), **environment,
        )

    def test_launch_suite_requires_every_expected_method(self):
        suite = self.write_launch_suite([
            "JabTrackerUITests/FoodSearchV08UITests/testSearchShowsRetryableError",
            "JabTrackerUITests/FoodSearchV08UITests/testCompleteAddFoodFlow",
        ])
        self.nodes["testNodes"][0]["children"].pop()
        result = self.run_launch_suite(suite)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Required test was not discovered", result.stderr)
        self.assertTrue((self.directory / "suite-evidence/attachments/hierarchy.txt").exists())

    def test_launch_case_status_cannot_be_hidden_by_passed_summary(self):
        suite = self.write_launch_suite()
        self.nodes["testNodes"][0]["children"][0]["result"] = "Skipped"
        result = self.run_launch_suite(suite)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Required test did not pass", result.stderr)

    def test_duplicate_launch_case_fails(self):
        suite = self.write_launch_suite()
        self.nodes["testNodes"][0]["children"] *= 2
        self.summary.update(totalTestCount=2, passedTests=2)
        result = self.run_launch_suite(suite)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("duplicate test cases", result.stderr)

    def test_launch_expected_failure_fails(self):
        suite = self.write_launch_suite()
        self.summary.update(expectedFailures=1)
        result = self.run_launch_suite(suite)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("failed or incomplete test run", result.stderr)

    def test_launch_attachment_export_failure_fails(self):
        suite = self.write_launch_suite()
        result = self.run_launch_suite(suite, FAKE_EXPORT_FAILURE="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unable to export xcresult attachments", result.stderr)

    def test_invalid_launch_selection_never_invokes_xcode(self):
        valid = self.write_launch_suite()
        payload = json.loads(valid.read_text())
        variants = {
            "empty": payload | {"tests": []},
            "duplicate": payload | {"tests": payload["tests"] * 2},
            "class_only": payload | {"tests": [payload["tests"][0] | {"selector": "JabTrackerUITests/FoodSearchV08UITests"}]},
            "undeclared": payload | {"tests": [payload["tests"][0] | {"selector": "JabTrackerUITests/FoodSearchV08UITests/testInventedJourney"}]},
            "outside_source": payload | {"tests": [payload["tests"][0] | {"source": "../Outside.swift"}]},
            "wrong_configuration": payload | {"configuration": "Debug"},
        }
        for name, suite in variants.items():
            with self.subTest(name=name):
                path = self.directory / f"{name}.json"
                path.write_text(json.dumps(suite))
                result = self.run_launch_suite(path)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertFalse((self.directory / "arguments.json").exists())

    def test_suite_file_cannot_mix_with_legacy_filter_or_wrong_configuration(self):
        suite = self.write_launch_suite()
        for arguments in (
            ("ui", "FoodSearchV08UITests", "--suite-file", str(suite)),
            ("unit", "--suite-file", str(suite)),
            ("ui", "--scheme", "JabTrackerReleaseTestHarness", "--configuration", "Debug"),
            ("ui", "--scheme", "JabTracker", "--configuration", "Release"),
        ):
            with self.subTest(arguments=arguments):
                result = self.run_runner(*arguments)
                self.assertEqual(result.returncode, 2)
                self.assertFalse((self.directory / "arguments.json").exists())

    def run_runner(self, *args, **environment):
        summary_path = self.directory / "summary-fixture.json"
        nodes_path = self.directory / "tests-fixture.json"
        summary_path.write_text(json.dumps(self.summary))
        nodes_path.write_text(json.dumps(self.nodes))
        env = os.environ | {
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "FAKE_ARGUMENTS": str(self.directory / "arguments.json"),
            "FAKE_SUMMARY": str(summary_path),
            "FAKE_NODES": str(nodes_path),
        } | environment
        result = subprocess.run(
            [str(ROOT / "scripts/test.sh"), *args],
            cwd=self.directory,
            env=env,
            text=True,
            capture_output=True,
        )
        (self.directory / "runner.stdout").write_text(result.stdout)
        (self.directory / "runner.stderr").write_text(result.stderr)
        return result

    def test_compilation_failure_keeps_exit_65_after_successful_formatter(self):
        result = self.run_runner("unit", FAKE_XCODE_STATUS="65", FAKE_STDERR="error: compilation failed")
        self.assertEqual(result.returncode, 65, result.stdout + result.stderr)
        self.assertNotIn("Tests passed", result.stdout)

    def test_xctest_failure_keeps_exit_65_in_log_only_mode(self):
        result = self.run_runner("unit", "--log-only", FAKE_XCODE_STATUS="65", FAKE_STDERR="XCTAssertEqual failed")
        self.assertEqual(result.returncode, 65, result.stdout + result.stderr)
        self.assertNotIn("Tests passed", result.stdout)

    def run_directory(self):
        return next((self.directory / "logs").glob("unit_*"))

    def test_success_retains_both_streams_status_summary_and_attachments(self):
        log_directory = self.directory / "evidence with spaces"
        result = self.run_runner("unit", "--log-only", "--log-dir", str(log_directory))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Tests passed", result.stdout)
        self.assertEqual((log_directory / "xcodebuild-status.txt").read_text(), "0\n")
        self.assertEqual((log_directory / "raw_output.txt").read_text(), "xcodebuild stderr\nxcodebuild stdout\n")
        self.assertEqual(json.loads((log_directory / "xcresult-summary.json").read_text()), self.summary)
        self.assertEqual(json.loads((log_directory / "xcresult-tests.json").read_text()), self.nodes)
        self.assertEqual((log_directory / "attachments/hierarchy.txt").read_text(), "Application hierarchy evidence")
        self.assertEqual((log_directory / "attachments/before-failure.png").read_bytes(), b"fake screenshot")

    def test_missing_result_bundle_fails(self):
        result = self.run_runner("unit", FAKE_MISSING_RESULT="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("xcresult bundle is missing", result.stderr)
        self.assertEqual((self.run_directory() / "xcodebuild-status.txt").read_text(), "0\n")

    def test_zero_discovered_tests_fails(self):
        self.summary.update(totalTestCount=0, passedTests=0)
        result = self.run_runner("unit")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("No tests were discovered", result.stderr)

    def test_zero_executed_tests_fails(self):
        self.summary.update(passedTests=0, skippedTests=1)
        result = self.run_runner("unit")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("No tests were executed", result.stderr)

    def test_unexpected_skip_fails(self):
        self.summary.update(totalTestCount=2, skippedTests=1)
        result = self.run_runner("unit")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Mandatory tests were skipped", result.stderr)

    def test_failed_summary_fails_even_when_xcodebuild_returns_zero(self):
        self.summary.update(result="Failed", passedTests=0, failedTests=1)
        result = self.run_runner("unit")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("failed or incomplete test run", result.stderr)

    def test_empty_inventory_fails(self):
        self.nodes = {"testNodes": []}
        result = self.run_runner("unit")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("inventory has no test cases", result.stderr)

    def test_selected_test_must_appear_in_inventory(self):
        result = self.run_runner("unit", "MissingTests/testMissing")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("selected test was not discovered", result.stderr)

    def test_selected_method_and_destination_remain_single_arguments(self):
        destination = "platform=iOS Simulator,name=iPhone 18 Pro Max,OS=27.0"
        result = self.run_runner("unit", "ExampleTests/testExample", "--destination", destination)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        arguments = json.loads((self.directory / "arguments.json").read_text())
        self.assertEqual(arguments[arguments.index("-destination") + 1], destination)
        self.assertIn("-only-testing:JabTrackerUnitTests/ExampleTests/testExample", arguments)

    def test_environment_destination_is_honored(self):
        destination = "platform=iOS Simulator,id=13D2AEC6-F13F-4318-BC06-BCBF69040A47"
        result = self.run_runner("unit", JABTRACKER_TEST_DESTINATION=destination)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        arguments = json.loads((self.directory / "arguments.json").read_text())
        self.assertEqual(arguments[arguments.index("-destination") + 1], destination)

    def test_device_id_selects_simulator_destination(self):
        device_id = "13D2AEC6-F13F-4318-BC06-BCBF69040A47"
        result = self.run_runner("unit", "--device-id", device_id)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        arguments = json.loads((self.directory / "arguments.json").read_text())
        self.assertEqual(arguments[arguments.index("-destination") + 1], "platform=iOS Simulator,id=" + device_id)

    def test_invalid_options_fail_before_xcodebuild(self):
        for arguments in (
            ("unit", "--typo"),
            ("unit", "--destination"),
            ("unit", "--destination", ""),
            ("unit", "--device-id", "wrong"),
            ("unit", "--device-id", "13D2AEC6-F13F-4318-BC06-BCBF69040A47", "--destination", "other"),
            ("unit", "--reset"),
            ("unit", "OneSuite", "TwoSuite"),
            ("all", "ExampleTests"),
            ("wrong",),
        ):
            with self.subTest(arguments=arguments):
                result = self.run_runner(*arguments)
                self.assertEqual(result.returncode, 2)
                self.assertFalse((self.directory / "arguments.json").exists())

    def test_existing_evidence_is_not_overwritten(self):
        log_directory = self.directory / "previous"
        log_directory.mkdir()
        (log_directory / "raw_output.txt").write_text("previous evidence")
        result = self.run_runner("unit", "--log-dir", str(log_directory))
        self.assertEqual(result.returncode, 2)
        self.assertFalse((self.directory / "arguments.json").exists())
        self.assertEqual((log_directory / "raw_output.txt").read_text(), "previous evidence")

    def test_attachment_export_failure_fails(self):
        result = self.run_runner("unit", FAKE_EXPORT_FAILURE="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unable to export xcresult attachments", result.stderr)
        self.assertIn("attachment export failed", (self.run_directory() / "attachment-export.txt").read_text())

    def test_formatter_failure_cannot_report_success(self):
        result = self.run_runner("unit", FAKE_FORMATTER_STATUS="7")
        self.assertEqual(result.returncode, 7)
        self.assertNotIn("Tests passed", result.stdout)

    def test_malformed_summary_fails_and_retains_inventory_and_attachments(self):
        self.summary = ["invalid summary"]
        result = self.run_runner("unit")
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue((self.run_directory() / "xcresult-summary.json").exists())
        self.assertTrue((self.run_directory() / "attachments/hierarchy.txt").exists())

    def test_coverage_is_retained(self):
        result = self.run_runner("unit", "--coverage")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(json.loads((self.run_directory() / "coverage.json").read_text()), {})


if __name__ == "__main__":
    unittest.main()
