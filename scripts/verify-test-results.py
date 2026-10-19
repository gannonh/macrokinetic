#!/usr/bin/env python3
"""Retain xcresult diagnostics and reject empty, failed, or skipped local runs."""

import argparse
import json
import subprocess
from pathlib import Path


def test_cases(nodes, bundle=""):
    for node in nodes:
        if node.get("nodeType", "").lower().endswith("test bundle"):
            bundle = node["name"]
        if node.get("nodeType") == "Test Case":
            identifier = node.get("nodeIdentifier", node.get("name", ""))
            yield f"{bundle}/{identifier}".removesuffix("()")
        yield from test_cases(node.get("children", []), bundle)


def verify(summary, tests, expected_test):
    if int(summary.get("totalTestCount", 0)) < 1:
        raise ValueError("No tests were discovered.")
    executed = sum(int(summary.get(key, 0)) for key in ("passedTests", "failedTests", "expectedFailures"))
    if executed < 1:
        raise ValueError("No tests were executed.")
    if int(summary.get("skippedTests", 0)):
        raise ValueError("Mandatory tests were skipped.")
    if int(summary.get("failedTests", 0)) or summary.get("testFailures") or summary.get("result") != "Passed":
        raise ValueError("The xcresult reports a failed or incomplete test run.")
    identifiers = list(test_cases(tests.get("testNodes", [])))
    if not identifiers:
        raise ValueError("The xcresult test inventory has no test cases.")
    expected_test = expected_test.removesuffix("()")
    if expected_test and not any(
        identifier == expected_test or identifier.startswith(expected_test + "/")
        for identifier in identifiers
    ):
        raise ValueError(f"The selected test was not discovered: {expected_test}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("run_directory", type=Path)
    parser.add_argument("--expected-test", default="")
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
            verify(payloads["summary"], payloads["tests"], args.expected_test)
        except (ValueError, TypeError, AttributeError) as error:
            errors.append(str(error))
    if errors:
        print("\n".join(errors))
        return 1
    print(f"Validated {payloads['summary']['totalTestCount']} non-skipped tests; attachments retained.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
