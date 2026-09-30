import binascii
import hashlib
import json
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
TOOL = ROOT / "scripts/app-store.py"
SHA = "a" * 40


def png(width=1290, height=2796, color=2, byte=0):
    def chunk(kind, payload):
        return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", binascii.crc32(kind + payload) & 0xffffffff)
    channels = 4 if color == 6 else 3
    rows = (b"\x00" + bytes([byte]) * (width * channels)) * height
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, color, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(rows)) + chunk(b"IEND", b""))


class AppStoreTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.packet = self.repo / "docs/app-store"
        shutil.copytree(ROOT / "docs/app-store", self.packet)
        shutil.copytree(ROOT / "JabTracker/AppIcon.icon", self.repo / "JabTracker/AppIcon.icon")
        self.edit("metadata.json", lambda value: value.update(
            state="draft", proposed_version="1.0.0", support_url=None, privacy_url=None,
            terms_url=None, copyright=None,
            claims=[dict(claim, evidence=None) for claim in value["claims"]]))
        def reset_assets(value):
            value["state"] = "draft"
            value["candidate"].update(sha=None, version=None, build=None, release_scope_evidence=None)
            value["icon"].update(path=None, sha256=None, candidate_sha=None, reviewed_by=None, evidence=None)
            value["screenshots"] = [
                {"id": slot["id"], "caption": slot["caption"], "claim": slot["claim"], "state": "pending", "path": None}
                for slot in value["screenshots"]]
        self.edit("assets.json", reset_assets)
        self.edit("owner-inputs.json", lambda value: value.update(
            state="draft", inputs=[dict(item, status="unresolved", value=None, evidence=None) for item in value["inputs"]]))

    def run_tool(self, *args):
        return subprocess.run([sys.executable, str(TOOL), "--packet", str(self.packet), *args],
                              text=True, capture_output=True)

    def edit(self, name, update):
        path = self.packet / name
        value = json.loads(path.read_text())
        update(value)
        path.write_text(json.dumps(value))

    def import_capture(self, *, data=None, sha=SHA):
        source = self.repo / "capture.png"
        source.write_bytes(png() if data is None else data)
        return self.run_tool("import-screenshot", "food-log", str(source), "--candidate-sha", sha,
                             "--version", "1.0.0", "--build", "17", "--device", "Test iPhone",
                             "--os-version", "27.0", "--captured-at", "2026-09-30T12:00:00-07:00",
                             "--scenario", "Verified literal meal totals", "--fictional-data")

    def test_draft_passes_format_checks_but_strict_readiness_fails(self):
        draft = self.run_tool("validate")
        self.assertEqual(draft.returncode, 0, draft.stderr)
        self.assertIn("Submission readiness BLOCKED", draft.stdout)
        ready = self.run_tool("validate", "--ready")
        self.assertEqual(ready.returncode, 2)
        self.assertIn("compiled App Store icon missing", ready.stdout)
        self.assertIn("owner input unresolved: storage_and_retention", ready.stdout)

    def test_copy_limits_count_keyword_bytes(self):
        self.edit("metadata.json", lambda value: value.update(keywords="é" * 60))
        result = self.run_tool("validate")
        self.assertEqual(result.returncode, 1)
        self.assertIn("100 UTF-8 bytes", result.stderr)

    def test_overlong_name_is_rejected(self):
        self.edit("metadata.json", lambda value: value.update(name="a" * 31))
        self.assertEqual(self.run_tool("validate").returncode, 1)

    def test_import_preserves_bytes_and_records_unreviewed_provenance(self):
        original = png()
        result = self.import_capture(data=original)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.packet / "screenshots/food-log.png").read_bytes(), original)
        manifest = json.loads((self.packet / "assets.json").read_text())
        slot = next(slot for slot in manifest["screenshots"] if slot["id"] == "food-log")
        self.assertEqual(slot["state"], "captured_unreviewed")
        self.assertEqual(slot["sha256"], hashlib.sha256(original).hexdigest())
        self.assertEqual(slot["candidate_sha"], SHA)
        self.assertEqual(self.run_tool("validate").returncode, 0)
        self.assertEqual(self.run_tool("validate", "--ready").returncode, 2)

    def test_invalid_size_alpha_and_corruption_do_not_import(self):
        for data in (png(100, 100), png(color=6), png()[:-1] + b"x"):
            with self.subTest(data_length=len(data)):
                before = (self.packet / "assets.json").read_bytes()
                self.assertEqual(self.import_capture(data=data).returncode, 1)
                self.assertEqual((self.packet / "assets.json").read_bytes(), before)
                self.assertFalse((self.packet / "screenshots/food-log.png").exists())

    def test_hash_drift_and_candidate_conflict_are_rejected(self):
        self.assertEqual(self.import_capture().returncode, 0)
        self.assertEqual(self.import_capture(sha="b" * 40).returncode, 1)
        (self.packet / "screenshots/food-log.png").write_bytes(png(byte=1))
        result = self.run_tool("validate")
        self.assertEqual(result.returncode, 1)
        self.assertIn("image checksum mismatch", result.stderr)

    def test_placeholder_url_and_escaping_evidence_are_rejected(self):
        self.edit("metadata.json", lambda value: value.update(privacy_url="https://example.com/privacy"))
        self.assertEqual(self.run_tool("validate").returncode, 1)
        self.edit("metadata.json", lambda value: value.update(privacy_url=None))
        self.edit("assets.json", lambda value: value["candidate"].update(release_scope_evidence="../../capture.png"))
        result = self.run_tool("validate")
        self.assertEqual(result.returncode, 1)
        self.assertIn("path escapes packet", result.stderr)

    def test_empty_asset_or_owner_inventory_is_rejected(self):
        self.edit("assets.json", lambda value: value.update(screenshots=[]))
        self.assertEqual(self.run_tool("validate").returncode, 1)

    def test_consistent_reviewed_packet_passes_strict_gate(self):
        metadata = json.loads((self.packet / "metadata.json").read_text())
        result = {
            "candidate_sha": SHA, "result": "PASS", "method": "Temporary CLI fixture",
            "reviewed_by": "Test reviewer", "recorded_at": "2026-09-30T12:00:00-07:00",
            "claims": [claim["id"] for claim in metadata["claims"]] + ["release_scope", "compiled_icon"],
        }
        (self.packet / "evidence/result.json").write_text(json.dumps(result))
        def ready_metadata(value):
            value.update(state="ready", support_url="https://publisher.org/support",
                         privacy_url="https://publisher.org/privacy", terms_url="https://publisher.org/terms",
                         copyright="Test fixture owner")
            for claim in value["claims"]:
                claim["evidence"] = "evidence/result.json"
        self.edit("metadata.json", ready_metadata)
        def ready_assets(value):
            value["state"] = "ready"
            value["candidate"].update(sha=SHA, version="1.0.0", build="17", release_scope_evidence="evidence/result.json",
                                      scope_note="Reviewed exclusions in the temporary CLI fixture.")
            for index, slot in enumerate(value["screenshots"]):
                image = self.packet / "screenshots" / f"{slot['id']}.png"
                image.write_bytes(png(byte=index))
                slot.update(state="reviewed", path=f"screenshots/{slot['id']}.png", sha256=hashlib.sha256(image.read_bytes()).hexdigest(),
                            candidate_sha=SHA, version="1.0.0", build="17", device="Test iPhone", os_version="27.0",
                            scenario="Temporary CLI fixture", captured_at=result["recorded_at"], fictional_data=True,
                            reviewed_by="Test reviewer", evidence="evidence/result.json")
            icon = self.packet / "screenshots/icon.png"
            icon.write_bytes(png(1024, 1024))
            value["icon"].update(path="screenshots/icon.png", sha256=hashlib.sha256(icon.read_bytes()).hexdigest(),
                                 candidate_sha=SHA, reviewed_by="Test reviewer", evidence="evidence/result.json")
        self.edit("assets.json", ready_assets)
        self.edit("owner-inputs.json", lambda value: value.update(
            state="ready", inputs=[dict(item, status="resolved", value="Temporary owner fixture", evidence="evidence/result.json")
                                   for item in value["inputs"]]))
        for name in ("review-notes.md", "public/privacy.md", "public/terms.md", "public/support.md"):
            (self.packet / name).write_text("Approved temporary CLI fixture text.")
        ready = self.run_tool("validate", "--ready")
        self.assertEqual(ready.returncode, 0, ready.stderr + ready.stdout)
        self.assertIn("Human review and signed-candidate acceptance remain required", ready.stdout)


if __name__ == "__main__":
    unittest.main()
