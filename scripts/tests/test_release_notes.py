import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
GENERATOR = ROOT / ".agents/skills/testflight-release-notes/scripts/generate_release_notes.py"


class ReleaseNotesTests(unittest.TestCase):
    def git(self, repository: Path, *args: str) -> None:
        subprocess.run(["git", "-C", str(repository), *args], check=True, capture_output=True, text=True)

    def commit(self, repository: Path, filename: str, contents: str, subject: str) -> None:
        (repository / filename).write_text(contents, encoding="utf-8")
        self.git(repository, "add", filename)
        self.git(repository, "commit", "-m", subject)

    def test_generates_testflight_text_from_release_range(self):
        with tempfile.TemporaryDirectory() as directory:
            repository = Path(directory)
            self.git(repository, "init", "-q")
            self.git(repository, "config", "user.email", "test@example.com")
            self.git(repository, "config", "user.name", "Release Notes Test")
            self.commit(repository, "README", "baseline\n", "chore: baseline")
            self.git(repository, "tag", "v0.10.0")
            self.commit(repository, "feature", "food\n", "feat(food): add custom food")
            self.commit(repository, "search", "fast\n", "fix(search): make food search responsive")
            self.commit(repository, "docs", "docs\n", "docs: update release instructions")

            result = subprocess.run(
                [
                    "python3",
                    str(GENERATOR),
                    "--repo",
                    str(repository),
                    "--version",
                    "0.10.1",
                    "--build",
                    "5",
                    "--from-ref",
                    "v0.10.0",
                    "--to-ref",
                    "HEAD",
                    "--focus",
                    "Verify Food Library search",
                ],
                check=True,
                capture_output=True,
                text=True,
            )

        self.assertIn("JabTracker 0.10.1 (5)", result.stdout)
        self.assertIn("- Verify Food Library search", result.stdout)
        self.assertIn("- Add custom food", result.stdout)
        self.assertIn("- Make food search responsive", result.stdout)
        self.assertNotIn("update release instructions", result.stdout)

    def test_output_is_bounded(self):
        result = subprocess.run(
            [
                "python3",
                str(GENERATOR),
                "--version",
                "0.10.1",
                "--build",
                "5",
                "--focus",
                "A" * 200,
                "--max-chars",
                "80",
            ],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertLessEqual(len(result.stdout), 80)


if __name__ == "__main__":
    unittest.main()
