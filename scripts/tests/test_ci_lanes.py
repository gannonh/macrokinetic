"""Contract tests for issue #354: split unit/integration CI lanes."""

from __future__ import annotations

import json
import re
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = ROOT / "scripts"
if str(SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SCRIPTS))

from ci import lanes  # noqa: E402


CI_YML = ROOT / ".github" / "workflows" / "ci.yml"
FULL_VALIDATION_YML = ROOT / ".github" / "workflows" / "full-validation.yml"
TESTFLIGHT_YML = ROOT / ".github" / "workflows" / "testflight-release.yml"
PROJECT_YML = ROOT / "project.yml"
LANE_CONFIG = ROOT / "scripts" / "ci" / "test-lanes.json"

REQUIRED_PR_JOBS = {
    "Fast unit tests": 10,
    "SwiftLint": 5,
    "Python tooling": 5,
}
ADVISORY_PR_JOBS = {
    "Integration tests": 20,
    "StoreKit tests": 10,
    "Performance tests": 10,
}
ALL_PR_JOBS = {**REQUIRED_PR_JOBS, **ADVISORY_PR_JOBS}


def workflow_jobs(text: str) -> dict[str, dict[str, object]]:
    jobs: dict[str, dict[str, object]] = {}
    current: str | None = None
    in_jobs = False
    for raw in text.splitlines():
        if raw.startswith("jobs:"):
            in_jobs = True
            continue
        if not in_jobs:
            continue
        if raw.startswith("  ") and not raw.startswith("    ") and raw.strip().endswith(":"):
            current = raw.strip()[:-1]
            jobs[current] = {"name": current, "timeout-minutes": None, "continue-on-error": False}
            continue
        if current is None:
            continue
        name_match = re.match(r'^    name:\s*(.+)$', raw)
        if name_match:
            jobs[current]["name"] = name_match.group(1).strip().strip("'\"")
        timeout_match = re.match(r'^    timeout-minutes:\s*(\d+)', raw)
        if timeout_match:
            jobs[current]["timeout-minutes"] = int(timeout_match.group(1))
        if re.match(r'^    continue-on-error:\s*', raw):
            jobs[current]["continue-on-error"] = "true" in raw.lower()
    return jobs


def job_display_names(text: str) -> set[str]:
    return {str(job["name"]) for job in workflow_jobs(text).values()}


class PRWorkflowContractTests(unittest.TestCase):
    def setUp(self) -> None:
        self.text = CI_YML.read_text()
        self.jobs = workflow_jobs(self.text)

    def test_workflow_name_is_ci(self) -> None:
        self.assertTrue(self.text.startswith("name: CI\n"))

    def test_exact_required_and_advisory_job_names(self) -> None:
        self.assertEqual(job_display_names(self.text), set(ALL_PR_JOBS))

    def test_lane_timeouts_match_spec(self) -> None:
        by_name = {str(job["name"]): job for job in self.jobs.values()}
        for name, timeout in ALL_PR_JOBS.items():
            self.assertEqual(by_name[name]["timeout-minutes"], timeout, name)

    def test_no_job_uses_the_old_45_minute_timeout(self) -> None:
        for job_id, job in self.jobs.items():
            self.assertNotEqual(job["timeout-minutes"], 45, job_id)

    def test_advisory_jobs_are_not_masked_by_continue_on_error(self) -> None:
        by_name = {str(job["name"]): job for job in self.jobs.values()}
        for name in ALL_PR_JOBS:
            self.assertFalse(by_name[name]["continue-on-error"], name)
        self.assertNotRegex(self.text, r"^    continue-on-error:\s*true", re.M)

    def test_unit_job_enables_four_worker_parallelism_on_ios_26_2(self) -> None:
        action = (ROOT / ".github" / "actions" / "run-xcode-tests" / "action.yml").read_text()
        self.assertIn("OS=26.2", self.text)
        self.assertIn("lane: unit", self.text)
        self.assertIn("scheme: JabTrackerUnitTests", self.text)
        self.assertIn("scheme: JabTrackerIntegrationTests", self.text)
        self.assertIn("max_workers: \"4\"", self.text)
        self.assertIn("parallel-testing-enabled YES", action)
        self.assertIn("maximum-parallel-testing-workers", action)
        self.assertIn("SWIFT_ENABLE_EXPLICIT_MODULES=NO", action)
        self.assertIn("COMPILER_INDEX_STORE_ENABLE=NO", action)
        self.assertIn("COMPRESS_PNG_FILES=NO", action)
        self.assertNotIn("macos-26-intel", self.text)
        self.assertIn("runs-on: macos-26\n", self.text)
        self.assertIn("runs-on: macos-26-xlarge\n", self.text)
        self.assertIn("actions/cache/restore", self.text)
        self.assertIn("actions/cache/save", self.text)
        self.assertEqual(
            lanes.xcodebuild_args_for_lane(ROOT, "unit"),
            ["-only-testing:JabTrackerUnitTests"],
        )

    def test_artifact_uploads_use_always(self) -> None:
        self.assertGreaterEqual(self.text.count("if: always()"), 6)
        self.assertIn("timing", self.text.lower())
        self.assertIn("manifest", self.text.lower())


class FullValidationWorkflowTests(unittest.TestCase):
    def setUp(self) -> None:
        self.text = FULL_VALIDATION_YML.read_text()
        self.jobs = workflow_jobs(self.text)

    def test_workflow_name_and_triggers(self) -> None:
        self.assertTrue(self.text.startswith("name: Full Validation\n"))
        self.assertIn("workflow_dispatch:", self.text)
        self.assertIn("workflow_call:", self.text)
        self.assertRegex(self.text, r"branches:\s*\[main\]")
        self.assertIn("schedule:", self.text)
        self.assertIn("cron:", self.text)

    def test_full_validation_jobs_match_the_lane_matrix(self) -> None:
        self.assertEqual(job_display_names(self.text), set(ALL_PR_JOBS))
        self.assertNotIn("macos-26-intel", self.text)
        by_name = {str(job["name"]): job for job in self.jobs.values()}
        for name, timeout in ALL_PR_JOBS.items():
            self.assertEqual(by_name[name]["timeout-minutes"], timeout, name)
            self.assertFalse(by_name[name]["continue-on-error"], name)

    def test_lane_failure_fails_the_workflow(self) -> None:
        self.assertNotRegex(self.text, r"^    continue-on-error:\s*true", re.M)


class TestFlightFullValidationTests(unittest.TestCase):
    def test_testflight_invokes_full_validation_before_archive(self) -> None:
        text = TESTFLIGHT_YML.read_text()
        self.assertIn("uses: ./.github/workflows/full-validation.yml", text)
        self.assertNotIn("uses: ./.github/actions/run-unit-tests", text)
        self.assertRegex(
            text,
            r"full-validation:[\s\S]*?uses: \./\.github/workflows/full-validation.yml",
        )
        build = re.search(r"  build:\n(?:.*\n)*?    needs: \[([^\]]+)\]", text)
        self.assertIsNotNone(build)
        needs = build.group(1)
        self.assertIn("full-validation", needs)


class ProjectTargetTests(unittest.TestCase):
    def setUp(self) -> None:
        self.text = PROJECT_YML.read_text()

    def test_defines_separate_unit_and_integration_targets(self) -> None:
        self.assertIn("  JabTrackerUnitTests:", self.text)
        self.assertIn("  JabTrackerIntegrationTests:", self.text)
        self.assertNotRegex(self.text, r"^  JabTrackerTests:\s*$", re.M)

    def test_scheme_lists_both_test_targets(self) -> None:
        self.assertIn("JabTrackerUnitTests: [test]", self.text)
        self.assertIn("JabTrackerIntegrationTests: [test]", self.text)
        self.assertIn("name: JabTrackerUnitTests", self.text)
        self.assertIn("name: JabTrackerIntegrationTests", self.text)
        self.assertIn("parallelizable: true", self.text)

    def test_shared_sources_include_test_mocks(self) -> None:
        config = lanes.load_lane_config(ROOT)
        mocks = {
            path.relative_to(ROOT / "JabTrackerTests").as_posix()
            for path in (ROOT / "JabTrackerTests" / "Mocks").rglob("*.swift")
        }
        self.assertTrue(mocks)
        self.assertTrue(mocks.issubset(set(config["shared_sources"])), mocks)

    def test_explicit_source_membership_matches_lane_config(self) -> None:
        config = lanes.load_lane_config(ROOT)
        for relative in config["integration_sources"]:
            self.assertIn(relative, self.text, relative)
        for relative in config["shared_sources"]:
            self.assertIn(relative, self.text, relative)


class ManifestContractTests(unittest.TestCase):
    def test_baseline_total_is_3233(self) -> None:
        config = lanes.load_lane_config(ROOT)
        self.assertEqual(config["baseline_xcresult_total"], 3233)

    def test_every_current_suite_source_is_assigned_once(self) -> None:
        assignments = lanes.assign_sources(ROOT)
        paths = [item["source_file"] for item in assignments]
        self.assertEqual(len(paths), len(set(paths)))
        discovered = lanes.discover_current_suite_sources(ROOT)
        self.assertEqual(set(paths), discovered)

    def test_manifest_records_bundle_file_identifier_target_lane_and_policy(self) -> None:
        manifest = lanes.build_source_manifest(ROOT)
        self.assertEqual(manifest["baseline"]["total_tests"], 3233)
        out_of_scope = {item["bundle"] for item in manifest["out_of_scope"]}
        self.assertEqual(
            out_of_scope,
            {"JabTrackerUITests", "JabTrackerFoodSearchBenchmarkTests"},
        )
        self.assertTrue(manifest["tests"])
        sample = manifest["tests"][0]
        for key in (
            "bundle",
            "source_file",
            "identifier",
            "target",
            "lane",
            "execution_policy",
        ):
            self.assertIn(key, sample)
        lanes_found = {item["lane"] for item in manifest["tests"]}
        self.assertEqual(lanes_found, {"unit", "integration", "storekit", "performance"})

    def test_every_baseline_identifier_maps_to_exactly_one_lane(self) -> None:
        manifest = lanes.build_source_manifest(ROOT)
        comparison = lanes.compare_to_baseline(manifest)
        self.assertEqual(comparison["unassigned"], [])
        self.assertEqual(comparison["duplicated"], [])
        self.assertEqual(comparison["obsolete_allowlist"], [])

    def test_xcresult_identifiers_are_assigned_without_overlap(self) -> None:
        manifest = lanes.build_source_manifest(ROOT)
        xcresult_ids = [
            item["identifier"] for item in manifest["tests"] if item["lane"] == "unit"
        ][:8]
        xcresult_ids.extend(
            item["identifier"]
            for item in manifest["tests"]
            if item["lane"] == "storekit"
        )
        merged = lanes.assign_executed_identifiers(
            manifest,
            [{"lane": "unit", "identifiers": xcresult_ids[:8]},
             {"lane": "storekit", "identifiers": xcresult_ids[8:]}],
        )
        comparison = lanes.compare_executed_assignment(merged)
        self.assertEqual(comparison["unassigned"], [])
        self.assertEqual(comparison["duplicated"], [])

    def test_storekit_and_performance_filters_are_explicit(self) -> None:
        config = lanes.load_lane_config(ROOT)
        self.assertTrue(config["storekit_only_testing"])
        self.assertTrue(config["performance_only_testing"])
        self.assertTrue(
            set(config["storekit_only_testing"]).issubset(
                set(config["integration_skip_testing"])
            )
        )
        self.assertTrue(
            set(config["performance_only_testing"]).issubset(
                set(config["integration_skip_testing"])
            )
        )

    def test_dashboard_performance_identifier_is_in_performance_lane(self) -> None:
        manifest = lanes.build_source_manifest(ROOT)
        matches = [
            item
            for item in manifest["tests"]
            if item["identifier"].endswith("/dashboardPerformanceWithLargeDoseHistory")
        ]
        self.assertEqual(len(matches), 1, matches)
        self.assertEqual(matches[0]["lane"], "performance")
        self.assertEqual(
            matches[0]["identifier"],
            "JabTrackerIntegrationTests/PKDashboardPerformanceTests/dashboardPerformanceWithLargeDoseHistory",
        )
        self.assertIn(
            "JabTrackerIntegrationTests/PKDashboardPerformanceTests",
            lanes.load_lane_config(ROOT)["performance_only_testing"],
        )


class StoreKitFailureSemanticsTests(unittest.TestCase):
    def test_storekit_suite_fails_when_configuration_is_missing(self) -> None:
        source = (
            ROOT
            / "JabTrackerTests"
            / "SubscriptionManagerStoreKitIntegrationTests.swift"
        ).read_text()
        self.assertNotIn("StoreKit configuration not available, skip test", source)
        self.assertNotIn("tests will be skipped", source)
        self.assertIn("configureStoreKitTestSession()", source)
        self.assertNotIn("SKTestSession?", source)


class ManifestCliTests(unittest.TestCase):
    def test_generate_test_manifest_writes_machine_readable_output(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "manifest.json"
            result = lanes.write_manifest(ROOT, output)
            self.assertEqual(result.returncode, 0)
            payload = json.loads(output.read_text())
            self.assertEqual(payload["baseline"]["total_tests"], 3233)
            self.assertIn("tests", payload)


if __name__ == "__main__":
    unittest.main()
