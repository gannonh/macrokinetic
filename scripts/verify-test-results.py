#!/usr/bin/env python3
"""Retain xcresult diagnostics and reject empty, failed, or skipped local runs."""

import argparse
import json
import subprocess
from pathlib import Path

from ci.launch import load_suite


def test_cases(nodes, bundle=""):
    for node in nodes:
        if node.get("nodeType", "").lower().endswith("test bundle"):
            bundle = node["name"]
        if node.get("nodeType") == "Test Case":
            identifier = node.get("nodeIdentifier", node.get("name", ""))
            yield f"{bundle}/{identifier}".removesuffix("()"), node.get("result")
        yield from test_cases(node.get("children", []), bundle)


def verify(summary, tests, expected_test="", expected_tests=None):
    if int(summary.get("totalTestCount", 0)) < 1:
        raise ValueError("No tests were discovered.")
    executed = sum(int(summary.get(key, 0)) for key in ("passedTests", "failedTests", "expectedFailures"))
    if executed < 1:
        raise ValueError("No tests were executed.")
    if int(summary.get("skippedTests", 0)):
        raise ValueError("Mandatory tests were skipped.")
    if (int(summary.get("failedTests", 0)) or int(summary.get("expectedFailures", 0))
            or summary.get("testFailures") or summary.get("result") != "Passed"):
        raise ValueError("The xcresult reports a failed or incomplete test run.")
    cases = list(test_cases(tests.get("testNodes", [])))
    if not cases:
        raise ValueError("The xcresult test inventory has no test cases.")
    identifiers = [identifier for identifier, _ in cases]
    if expected_tests is not None:
        if not expected_tests or len(expected_tests) != len(set(expected_tests)):
            raise ValueError("Expected test methods are empty or duplicated.")
        if len(identifiers) != len(set(identifiers)):
            raise ValueError("The xcresult contains duplicate test cases.")
        for expected in expected_tests:
            matches = [status for identifier, status in cases if identifier == expected]
            if not matches:
                raise ValueError(f"Required test was not discovered: {expected}")
            if matches != ["Passed"]:
                raise ValueError(f"Required test did not pass: {expected} ({matches})")
        if set(identifiers) != set(expected_tests):
            raise ValueError("The xcresult contains tests outside the exact launch selection.")
        if int(summary["totalTestCount"]) != len(expected_tests) or int(summary.get("passedTests", 0)) != len(expected_tests):
            raise ValueError("The summary counts differ from the exact launch selection.")
        return
    expected_test = expected_test.removesuffix("()")
    if expected_test and not any(
        identifier == expected_test or identifier.startswith(expected_test + "/")
        for identifier in identifiers
    ):
        raise ValueError(f"The selected test was not discovered: {expected_test}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_directory", type=Path)
    expected = parser.add_mutually_exclusive_group()
    expected.add_argument("--expected-test", default="")
    expected.add_argument("--suite-file", type=Path)
    args = parser.parse_args()
    run_directory = args.run_directory
    bundle = run_directory / "results.xcresult"
    if not bundle.is_dir():
        print("The xcresult bundle is missing.")
        return 1

    payloads = {}
    errors = []
    for section in ("summary", "tests"):
        result = subprocess.run(
            ["xcrun", "xcresulttool", "get", "test-results", section, "--path", str(bundle), "--format", "json"],
            text=True,
            capture_output=True,
        )
        (run_directory / f"xcresult-{section}.json").write_text(result.stdout)
        (run_directory / f"xcresult-{section}-errors.txt").write_text(result.stderr)
        try:
            if result.returncode:
                raise ValueError(f"Unable to read xcresult {section} (exit {result.returncode}).")
            payloads[section] = json.loads(result.stdout)
        except (ValueError, TypeError) as error:
            errors.append(str(error))

    exported = subprocess.run(
        ["xcrun", "xcresulttool", "export", "attachments", "--path", str(bundle),
         "--output-path", str(run_directory / "attachments")],
        text=True,
        capture_output=True,
    )
    (run_directory / "attachment-export.txt").write_text(exported.stdout + exported.stderr)
    if exported.returncode:
        errors.append(f"Unable to export xcresult attachments (exit {exported.returncode}).")

    if "summary" in payloads and "tests" in payloads:
        try:
            selected = None
            if args.suite_file:
                selected = [test["selector"] for test in load_suite(args.suite_file)["tests"]]
            verify(payloads["summary"], payloads["tests"], args.expected_test, selected)
        except (ValueError, TypeError, AttributeError) as error:
            errors.append(str(error))
    if errors:
        print("\n".join(errors))
        return 1
    print(f"Validated {payloads['summary']['totalTestCount']} non-skipped tests; attachments retained.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
