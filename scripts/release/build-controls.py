#!/usr/bin/env python3
"""Record resolved Swift inputs and reject test-enabled shipping artifacts."""

import argparse
import json
import os
import plistlib
import re
import shlex
import sys
from pathlib import Path


MANIFEST_NAME = "JabTrackerBuildManifest.json"
PRODUCTION_IDENTIFIER = "com.gannonhall.JabTracker"
COMPILER_OVERRIDES = ("SWIFT_EXEC", "SWIFT_FRONTEND_EXEC", "SWIFT_DRIVER_SWIFT_FRONTEND_EXEC")
ENVIRONMENT_KEYS = {
    "configuration": "CONFIGURATION",
    "bundle_identifier": "PRODUCT_BUNDLE_IDENTIFIER",
    "platform_name": "PLATFORM_NAME",
    "swift_active_compilation_conditions": "SWIFT_ACTIVE_COMPILATION_CONDITIONS",
    "other_swift_flags": "OTHER_SWIFT_FLAGS",
    "toolchain_dir": "DT_TOOLCHAIN_DIR",
}
SYMBOL = re.compile(r"[A-Za-z_][A-Za-z0-9_]*\Z")
# Xcode lists the Metal toolchain first when its cryptex is installed, which makes TOOLCHAIN_DIR the Metal
# toolchain. DT_TOOLCHAIN_DIR is always the default toolchain; TOOLCHAINS shows whether anything else is selected.
APPLE_TOOLCHAINS = re.compile(r"com\.apple\.dt\.toolchain\.(XcodeDefault|Metal(\.[0-9]+)*)\Z")


def tokens(raw):
    if "$" in raw or "`" in raw:
        raise ValueError("unresolved compiler input")
    values = shlex.split(raw)
    if any("@" in value for value in values):
        raise ValueError("response files are not inspectable build inputs")
    return values


def definitions(inputs):
    if set(inputs) != set(ENVIRONMENT_KEYS) | {"compiler_overrides"}:
        raise ValueError("unknown or missing build inputs")
    for key in ENVIRONMENT_KEYS:
        if type(inputs[key]) is not str:
            raise ValueError(f"{key} must be a string")
    for key in ("configuration", "bundle_identifier", "platform_name"):
        if not inputs[key] or "$" in inputs[key] or "`" in inputs[key]:
            raise ValueError(f"{key} must be resolved")
    overrides = inputs["compiler_overrides"]
    if type(overrides) is not dict or set(overrides) != set(COMPILER_OVERRIDES):
        raise ValueError("unknown or missing compiler override inputs")
    toolchain = inputs["toolchain_dir"]
    if toolchain and ("$" in toolchain or "`" in toolchain or not os.path.isabs(toolchain)
                      or Path(toolchain).name != "XcodeDefault.xctoolchain"):
        raise ValueError("custom Swift toolchains are not inspectable")
    for key, value in overrides.items():
        if type(value) is not str:
            raise ValueError("compiler inputs must be strings")
        if value:
            compiler = "swiftc" if key == "SWIFT_EXEC" else "swift-frontend"
            expected = os.path.join(toolchain, "usr/bin", compiler)
            if "$" in value or "`" in value or not toolchain or os.path.normpath(value) != os.path.normpath(expected):
                raise ValueError("custom Swift compiler overrides are not inspectable")

    symbols = tokens(inputs["swift_active_compilation_conditions"])
    flags = tokens(inputs["other_swift_flags"])
    forwarded = []
    index = 0
    while index < len(flags):
        if flags[index] == "-Xfrontend":
            index += 1
            if index == len(flags) or flags[index] == "-Xfrontend":
                raise ValueError("missing frontend flag")
        forwarded.append(flags[index])
        index += 1
    index = 0
    while index < len(forwarded):
        flag = forwarded[index]
        if flag == "--" or flag.startswith("-Xswiftc"):
            raise ValueError("ambiguous Swift flag forwarding")
        if flag == "-D":
            index += 1
            if index == len(forwarded):
                raise ValueError("missing Swift definition")
            symbols.append(forwarded[index])
        elif flag.startswith("-D"):
            symbols.append(flag[2:])
        index += 1
    if any(not SYMBOL.fullmatch(symbol) for symbol in symbols):
        raise ValueError("invalid Swift conditional definition")
    return set(symbols)


def read_info(path):
    with path.open("rb") as source:
        info = plistlib.load(source)
    if type(info) is not dict or type(info.get("CFBundleIdentifier")) is not str:
        raise ValueError("Info.plist lacks a bundle identifier")
    return info


def selected_toolchains_are_apple():
    return all(APPLE_TOOLCHAINS.fullmatch(identifier) for identifier in os.environ.get("TOOLCHAINS", "").split())


def generate(output, info_path):
    if not selected_toolchains_are_apple():
        raise ValueError("custom Swift toolchains are not inspectable")
    inputs = {key: os.environ.get(variable, "") for key, variable in ENVIRONMENT_KEYS.items()}
    inputs["compiler_overrides"] = {key: os.environ.get(key, "") for key in COMPILER_OVERRIDES}
    definitions(inputs)
    if read_info(info_path)["CFBundleIdentifier"] != inputs["bundle_identifier"]:
        raise ValueError("resolved identifier differs from built Info.plist")
    payload = {"schema_version": 1, "inputs": inputs}
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_name(output.name + ".tmp")
    temporary.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    os.replace(temporary, output)


def unique_keys(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate manifest key: {key}")
        result[key] = value
    return result


def verify_app(app):
    with (app / MANIFEST_NAME).open() as source:
        manifest = json.load(source, object_pairs_hook=unique_keys)
    if type(manifest) is not dict or set(manifest) != {"schema_version", "inputs"}:
        raise ValueError("unknown manifest structure")
    if type(manifest["schema_version"]) is not int or manifest["schema_version"] != 1:
        raise ValueError("unsupported manifest schema")
    inputs = manifest["inputs"]
    if type(inputs) is not dict:
        raise ValueError("manifest inputs must be a dictionary")
    symbols = definitions(inputs)
    info = read_info(app / "Info.plist")
    if inputs["configuration"] != "Release":
        raise ValueError("only ordinary Release can pass shipment preflight")
    if inputs["bundle_identifier"] != PRODUCTION_IDENTIFIER or info["CFBundleIdentifier"] != PRODUCTION_IDENTIFIER:
        raise ValueError("bundle identifier is not the production application")
    if symbols:
        raise ValueError("ordinary Release has nonempty Swift definitions: " + ", ".join(sorted(symbols)))
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    actions = parser.add_subparsers(dest="action", required=True)
    writer = actions.add_parser("generate")
    writer.add_argument("--info-plist", type=Path, required=True)
    writer.add_argument("--output", type=Path, required=True)
    verifier = actions.add_parser("verify")
    verifier.add_argument("--archive-app", type=Path, required=True)
    verifier.add_argument("--ipa-app", type=Path, required=True)
    args = parser.parse_args()
    try:
        if args.action == "generate":
            generate(args.output, args.info_plist)
        else:
            archive = verify_app(args.archive_app)
            ipa = verify_app(args.ipa_app)
            if archive != ipa:
                raise ValueError("archive and IPA build inputs differ")
            print("archive and IPA have ordinary Release compiler inputs")
    except (OSError, ValueError, TypeError, plistlib.InvalidFileException) as error:
        if args.action == "generate":
            for path in (args.output, args.output.with_name(args.output.name + ".tmp")):
                path.unlink(missing_ok=True)
        print(f"build-controls: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
