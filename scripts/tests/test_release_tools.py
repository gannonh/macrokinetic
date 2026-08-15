import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class ReleaseToolTests(unittest.TestCase):
    def run_tool(self, path: str, *args: str, check: bool = True, env=None):
        return subprocess.run(
            [str(ROOT / path), *args],
            cwd=ROOT,
            env=env,
            check=check,
            text=True,
            capture_output=True,
        )

    def test_input_validation_rejects_invalid_values_before_dispatch(self):
        self.run_tool("scripts/release/validate-inputs.sh", "dev", "0.10.2", "17")
        result = self.run_tool(
            "scripts/release/validate-inputs.sh", "dev", "10", "0", check=False
        )
        self.assertNotEqual(result.returncode, 0)

    def test_project_version_resolution_ignores_commented_setting(self):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory) / "project.yml"
            project.write_text(
                "# MARKETING_VERSION: 9.9.9\nsettings:\n  MARKETING_VERSION: \"0.10.1\"\n"
            )
            result = self.run_tool(
                "scripts/release/resolve-project-version.sh", str(project)
            )
        self.assertEqual(result.stdout.strip(), "0.10.1")

    def test_snapshot_tags_are_sorted_and_malformed_tags_fail(self):
        releases = [
            {"tag_name": "food-db-20-aaaaaaaaaaaa"},
            {"tag_name": "food-db-30-bbbbbbbbbbbb"},
            {"tag_name": "food-db-10-cccccccccccc", "draft": True},
        ]
        result = subprocess.run(
            ["python3", "scripts/release/snapshot-tags.py"],
            cwd=ROOT,
            input=json.dumps(releases),
            text=True,
            capture_output=True,
            check=True,
        )
        self.assertEqual(result.stdout.splitlines(), ["food-db-30-bbbbbbbbbbbb", "food-db-20-aaaaaaaaaaaa"])

        malformed = subprocess.run(
            ["python3", "scripts/release/snapshot-tags.py"],
            cwd=ROOT,
            input=json.dumps([{"tag_name": "food-db-invalid"}]),
            text=True,
            capture_output=True,
        )
        self.assertNotEqual(malformed.returncode, 0)

    def test_food_database_planner_requires_full_inputs_for_stale_or_disconnected_snapshots(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            index = root / "index.txt"
            index.write_text("openfoodfacts_products_100_200.json.gz\n")
            manifest = root / "food-db-manifest.json"
            manifest.write_text(json.dumps({"created_epoch": 1_000, "off_cursor": 100}))

            delta = self.run_tool(
                "scripts/release/plan-food-database.py",
                "--off-index",
                str(index),
                "--snapshot-manifest",
                str(manifest),
                "--now-epoch",
                "1000",
            )
            self.assertEqual(delta.stdout.strip(), "delta")

            stale = self.run_tool(
                "scripts/release/plan-food-database.py",
                "--off-index",
                str(index),
                "--snapshot-manifest",
                str(manifest),
                "--now-epoch",
                str(1_000 + 30 * 24 * 60 * 60),
            )
            self.assertEqual(stale.stdout.strip(), "full")

            index.write_text("openfoodfacts_products_200_300.json.gz\n")
            gap = self.run_tool(
                "scripts/release/plan-food-database.py",
                "--off-index",
                str(index),
                "--snapshot-manifest",
                str(manifest),
                "--now-epoch",
                "1000",
            )
            self.assertEqual(gap.stdout.strip(), "full")

            no_snapshot = self.run_tool(
                "scripts/release/plan-food-database.py",
                "--off-index",
                str(index),
            )
            self.assertEqual(no_snapshot.stdout.strip(), "full")

    def test_wrapper_validates_before_invoking_gh(self):
        with tempfile.TemporaryDirectory() as directory:
            marker = Path(directory) / "called"
            fake_gh = Path(directory) / "gh"
            fake_gh.write_text(f"#!/bin/sh\ntouch '{marker}'\nexit 0\n")
            fake_gh.chmod(0o755)
            environment = os.environ | {"PATH": f"{directory}:{os.environ['PATH']}"}
            result = subprocess.run(
                [str(ROOT / "scripts/upload-testflight.sh"), "--group", "bad"],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
            )
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(marker.exists())


if __name__ == "__main__":
    unittest.main()
