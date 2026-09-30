import hashlib
import json
import os
import plistlib
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CLI = ROOT / "scripts/release/build-controls.py"
INSPECTOR = ROOT / "scripts/release/inspect-release-bundle.sh"
MANIFEST = "JabTrackerBuildManifest.json"


class BuildControlsTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="build controls ")
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.app = self.directory / "archive/JabTracker.app"
        self.app.mkdir(parents=True)
        self.info = {
            "CFBundleIdentifier": "com.gannonhall.JabTracker",
            "CFBundleShortVersionString": "0.10.1",
            "CFBundleVersion": "16",
        }
        self.write_info()
        (self.app / "usda_foods.sqlite").write_bytes(b"fictional database fixture")
        self.environment = os.environ | {
            "CONFIGURATION": "Release",
            "PRODUCT_BUNDLE_IDENTIFIER": "com.gannonhall.JabTracker",
            "PLATFORM_NAME": "iphoneos",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "",
            "OTHER_SWIFT_FLAGS": "",
            "TOOLCHAIN_DIR": "",
            "SWIFT_EXEC": "",
            "SWIFT_FRONTEND_EXEC": "",
            "SWIFT_DRIVER_SWIFT_FRONTEND_EXEC": "",
            "RUNNER_TEMP": str(self.directory / "runner temp"),
        }
        Path(self.environment["RUNNER_TEMP"]).mkdir()

    def write_info(self):
        (self.app / "Info.plist").write_bytes(plistlib.dumps(self.info))

    def manifest(self, **updates):
        inputs = {
            "configuration": "Release",
            "bundle_identifier": "com.gannonhall.JabTracker",
            "platform_name": "iphoneos",
            "swift_active_compilation_conditions": "",
            "other_swift_flags": "",
            "toolchain_dir": "",
            "compiler_overrides": {
                "SWIFT_EXEC": "",
                "SWIFT_FRONTEND_EXEC": "",
                "SWIFT_DRIVER_SWIFT_FRONTEND_EXEC": "",
            },
        }
        inputs.update(updates)
        return {"schema_version": 1, "inputs": inputs}

    def write_manifest(self, payload):
        (self.app / MANIFEST).write_text(json.dumps(payload))

    def generate(self, **environment_updates):
        return subprocess.run(
            ["python3", str(CLI), "generate", "--info-plist", str(self.app / "Info.plist"),
             "--output", str(self.app / MANIFEST)],
            env=self.environment | environment_updates,
            text=True, capture_output=True,
        )

    def inspect(self, ipa_payload=None):
        ipa = self.directory / "JabTracker.ipa"
        with zipfile.ZipFile(ipa, "w") as archive:
            for path in self.app.iterdir():
                data = path.read_bytes()
                if path.name == MANIFEST and ipa_payload is not None:
                    data = json.dumps(ipa_payload).encode()
                archive.writestr(f"Payload/JabTracker.app/{path.name}", data)
        checksum = hashlib.sha256((self.app / "usda_foods.sqlite").read_bytes()).hexdigest()
        return subprocess.run(
            ["bash", str(INSPECTOR), str(self.app), str(ipa), "0.10.1", "16", checksum],
            env=self.environment, text=True, capture_output=True,
        )

    def test_existing_inspector_rejects_test_harness_artifact(self):
        self.info["CFBundleIdentifier"] = "com.gannonhall.JabTrackerTestHarness"
        self.write_info()
        self.write_manifest(self.manifest(
            configuration="ReleaseTestHarness",
            bundle_identifier="com.gannonhall.JabTrackerTestHarness",
            swift_active_compilation_conditions="JABTRACKER_TEST_HARNESS",
        ))
        result = self.inspect()
        self.assertNotEqual(result.returncode, 0, result.stdout)

    def test_generated_ordinary_release_passes_real_archive_and_ipa_inspector(self):
        result = self.generate()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads((self.app / MANIFEST).read_text()), self.manifest())
        result = self.inspect()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ordinary Release compiler inputs", result.stdout)

    def test_generator_records_raw_inputs_and_replaces_previous_build(self):
        self.assertEqual(self.generate().returncode, 0)
        result = self.generate(CONFIGURATION="Debug", SWIFT_ACTIVE_COMPILATION_CONDITIONS="DEBUG")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads((self.app / MANIFEST).read_text()), self.manifest(
            configuration="Debug", swift_active_compilation_conditions="DEBUG",
        ))
        self.assertNotEqual(self.inspect().returncode, 0)
        self.assertFalse((self.app / (MANIFEST + ".tmp")).exists())

    def test_resolved_standard_apple_compilers_are_recorded_and_accepted(self):
        toolchain = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"
        result = self.generate(
            TOOLCHAIN_DIR=toolchain,
            SWIFT_EXEC=f"{toolchain}/usr/bin/swiftc",
            SWIFT_FRONTEND_EXEC=f"{toolchain}/usr/bin/swift-frontend",
            SWIFT_DRIVER_SWIFT_FRONTEND_EXEC=f"{toolchain}/usr/bin/swift-frontend",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.inspect().returncode, 0)
        payload = json.loads((self.app / MANIFEST).read_text())
        self.assertEqual(payload["inputs"]["toolchain_dir"], toolchain)
        self.assertEqual(payload["inputs"]["compiler_overrides"]["SWIFT_EXEC"], f"{toolchain}/usr/bin/swiftc")

    def test_inspector_rejects_definitions_from_every_supported_compiler_input(self):
        cases = [
            {"swift_active_compilation_conditions": "DEBUG"},
            {"swift_active_compilation_conditions": "TEST"},
            {"swift_active_compilation_conditions": "JABTRACKER_TEST_HARNESS"},
            {"swift_active_compilation_conditions": "NEW_UNKNOWN_CONDITION"},
            {"other_swift_flags": "-DDEBUG"},
            {"other_swift_flags": "-D TEST"},
            {"other_swift_flags": "-Xfrontend -DJABTRACKER_TEST_HARNESS"},
            {"other_swift_flags": "-Xfrontend -D -Xfrontend DEBUG"},
        ]
        for updates in cases:
            with self.subTest(updates=updates):
                self.write_manifest(self.manifest(**updates))
                result = self.inspect()
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn("nonempty Swift definitions", result.stderr)

    def test_generator_rejects_ambiguous_inputs_and_removes_stale_output(self):
        cases = [
            {"OTHER_SWIFT_FLAGS": "-D"},
            {"OTHER_SWIFT_FLAGS": "-DDEBUG=1"},
            {"OTHER_SWIFT_FLAGS": "@hidden-definitions"},
            {"OTHER_SWIFT_FLAGS": "-Xfrontend @hidden-definitions"},
            {"OTHER_SWIFT_FLAGS": "-Xfrontend"},
            {"OTHER_SWIFT_FLAGS": "-Xfrontend -Xfrontend -DDEBUG"},
            {"OTHER_SWIFT_FLAGS": "-Xswiftc -DDEBUG"},
            {"OTHER_SWIFT_FLAGS": "-- -DDEBUG"},
            {"OTHER_SWIFT_FLAGS": "$(inherited)"},
            {"OTHER_SWIFT_FLAGS": "'unterminated"},
            {"SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG=1"},
            {"SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited)"},
            {"SWIFT_EXEC": "/custom/swiftc"},
            {"SWIFT_FRONTEND_EXEC": "/custom/frontend"},
            {"SWIFT_DRIVER_SWIFT_FRONTEND_EXEC": "/custom/frontend"},
            {"TOOLCHAIN_DIR": "/custom/Toolchain.xctoolchain"},
            {"TOOLCHAIN_DIR": "$(TOOLCHAIN_DIR)"},
            {
                "TOOLCHAIN_DIR": "/Applications/$(XCODE)/XcodeDefault.xctoolchain",
                "SWIFT_EXEC": "/Applications/$(XCODE)/XcodeDefault.xctoolchain/usr/bin/swiftc",
            },
            {"CONFIGURATION": "`configuration`"},
            {"CONFIGURATION": ""},
            {"PRODUCT_BUNDLE_IDENTIFIER": "$(PRODUCT_BUNDLE_IDENTIFIER)"},
            {"PLATFORM_NAME": ""},
        ]
        for updates in cases:
            with self.subTest(updates=updates):
                self.write_manifest(self.manifest())
                result = self.generate(**updates)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertFalse((self.app / MANIFEST).exists())

    def test_generator_rejects_identifier_mismatch_and_missing_info(self):
        self.info["CFBundleIdentifier"] = "com.gannonhall.JabTrackerTestHarness"
        self.write_info()
        self.assertNotEqual(self.generate().returncode, 0)
        (self.app / "Info.plist").unlink()
        self.assertNotEqual(self.generate().returncode, 0)

    def test_inspector_rejects_wrong_identity_configuration_and_compiler(self):
        cases = [
            {"configuration": "Debug"},
            {"configuration": "ReleaseTestHarness"},
            {"bundle_identifier": "com.gannonhall.JabTrackerTestHarness"},
            {"compiler_overrides": {
                "SWIFT_EXEC": "/custom/swiftc", "SWIFT_FRONTEND_EXEC": "",
                "SWIFT_DRIVER_SWIFT_FRONTEND_EXEC": "",
            }},
            {"other_swift_flags": "@definitions"},
        ]
        for updates in cases:
            with self.subTest(updates=updates):
                self.write_manifest(self.manifest(**updates))
                self.assertNotEqual(self.inspect().returncode, 0)
        self.write_manifest(self.manifest())
        self.info["CFBundleIdentifier"] = "com.gannonhall.JabTrackerTestHarness"
        self.write_info()
        self.assertNotEqual(self.inspect().returncode, 0)

    def test_inspector_rejects_missing_malformed_and_misleading_metadata(self):
        self.assertNotEqual(self.inspect().returncode, 0)
        invalid = [
            {"schema_version": 2, "inputs": self.manifest()["inputs"]},
            {"schema_version": True, "inputs": self.manifest()["inputs"]},
            {"schema_version": 1, "inputs": []},
            self.manifest(configuration=False),
            self.manifest(compiler_overrides={}),
            self.manifest() | {"test_controls_compiled": False},
            {"schema_version": 1},
        ]
        for payload in invalid:
            with self.subTest(payload=payload):
                self.write_manifest(payload)
                self.assertNotEqual(self.inspect().returncode, 0)
        for raw in ("invalid JSON", '{"schema_version":1,"schema_version":1,"inputs":{}}'):
            (self.app / MANIFEST).write_text(raw)
            self.assertNotEqual(self.inspect().returncode, 0)

    def test_inspector_recomputes_inputs_instead_of_accepting_a_disabled_boolean(self):
        payload = self.manifest(other_swift_flags="-DDEBUG")
        payload["test_controls_compiled"] = False
        self.write_manifest(payload)
        self.assertNotEqual(self.inspect().returncode, 0)

    def test_inspector_rejects_archive_ipa_disagreement_and_ipa_only_test_input(self):
        self.assertEqual(self.generate().returncode, 0)
        self.assertNotEqual(self.inspect(self.manifest(other_swift_flags="-DDEBUG")).returncode, 0)
        result = self.inspect(self.manifest(platform_name="iphonesimulator"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("archive and IPA build inputs differ", result.stderr)

    def test_existing_version_build_database_checks_remain_required(self):
        self.assertEqual(self.generate().returncode, 0)
        for key, value in [("CFBundleShortVersionString", "9.9.9"), ("CFBundleVersion", "999")]:
            with self.subTest(key=key):
                original = self.info[key]
                self.info[key] = value
                self.write_info()
                self.assertNotEqual(self.inspect().returncode, 0)
                self.info[key] = original
                self.write_info()
        ipa = self.directory / "wrong-database.ipa"
        with zipfile.ZipFile(ipa, "w") as archive:
            for path in self.app.iterdir():
                archive.writestr(f"Payload/JabTracker.app/{path.name}",
                                 b"changed database" if path.name == "usda_foods.sqlite" else path.read_bytes())
        checksum = hashlib.sha256((self.app / "usda_foods.sqlite").read_bytes()).hexdigest()
        result = subprocess.run(
            ["bash", str(INSPECTOR), str(self.app), str(ipa), "0.10.1", "16", checksum],
            env=self.environment, text=True, capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("IPA database checksum mismatch", result.stderr)


if __name__ == "__main__":
    unittest.main()
