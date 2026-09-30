#!/usr/bin/env python3
"""Validate the submission packet and import unchanged candidate screenshots."""

import argparse
import binascii
import hashlib
import json
import re
import shutil
import struct
import sys
import zlib
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse


PACKET = Path(__file__).resolve().parents[1] / "docs/app-store"
IPHONE_SIZES = {(1260, 2736), (1290, 2796), (1320, 2868)}
OWNER_IDS = {
    "public_name_and_rights", "legal_seller", "public_contact", "public_urls",
    "storage_and_retention", "privacy_label", "regions_age_medical_status",
    "pricing_and_agreements", "app_review_access", "export_and_signing",
}
DOCUMENTS = (
    "README.md", "review-notes.md", "privacy-data-flow.md",
    "age-and-medical-status.md", "launch-audit.md", "screenshots/README.md",
    "evidence/README.md", "public/README.md", "public/privacy.md",
    "public/terms.md", "public/support.md",
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def nonempty(value):
    return isinstance(value, str) and bool(value.strip())


def read_json(path):
    value = json.loads(path.read_text())
    require(isinstance(value, dict), f"{path.name}: expected a JSON object")
    return value


def packet_file(packet, name):
    require(nonempty(name), "expected a packet-relative file path")
    path = (packet / name).resolve()
    require(path.is_relative_to(packet.resolve()), f"path escapes packet: {name}")
    require(path.is_file(), f"missing file: {name}")
    return path


def timestamp(value):
    require(nonempty(value), "missing capture/evidence timestamp")
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    require(parsed.tzinfo is not None, "timestamp requires a timezone")


def png_size(path, accepted):
    data = path.read_bytes()
    require(data[:8] == b"\x89PNG\r\n\x1a\n", f"{path.name}: expected PNG")
    offset, compressed, dimensions = 8, bytearray(), None
    ended = False
    while offset < len(data):
        require(offset + 12 <= len(data), f"{path.name}: truncated PNG chunk")
        length = struct.unpack_from(">I", data, offset)[0]
        kind = data[offset + 4:offset + 8]
        end = offset + 12 + length
        require(end <= len(data), f"{path.name}: truncated PNG payload")
        payload = data[offset + 8:offset + 8 + length]
        crc = struct.unpack_from(">I", data, offset + 8 + length)[0]
        require(binascii.crc32(kind + payload) & 0xffffffff == crc,
                f"{path.name}: PNG checksum mismatch")
        if dimensions is None:
            require(kind == b"IHDR" and length == 13, "PNG must start with IHDR")
            width, height, depth, color, compression, filtering, interlace = struct.unpack(">IIBBBBB", payload)
            require((width, height) in accepted, f"{path.name}: unsupported size {width}x{height}")
            require((depth, color, compression, filtering, interlace) == (8, 2, 0, 0, 0),
                    f"{path.name}: use an opaque 8-bit RGB, noninterlaced PNG")
            dimensions = width, height
        elif kind == b"IHDR":
            raise ValueError("duplicate PNG header")
        if kind == b"tRNS":
            raise ValueError("PNG transparency is not allowed")
        if kind == b"IDAT":
            compressed.extend(payload)
        if kind == b"IEND":
            require(length == 0 and end == len(data), "invalid PNG ending")
            ended = True
            break
        offset = end
    require(ended and compressed and dimensions, "incomplete PNG")
    width, height = dimensions
    expected = (width * 3 + 1) * height
    decoder = zlib.decompressobj()
    pixels = decoder.decompress(compressed, expected + 1)
    require(decoder.eof and not decoder.unused_data and len(pixels) == expected,
            "PNG pixel data does not match dimensions")
    require(all(pixels[row * (width * 3 + 1)] <= 4 for row in range(height)),
            "invalid PNG scanline filter")
    return dimensions


def checksum(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def evidence(packet, name, sha, blockers, label, claim=None):
    if not name:
        blockers.append(f"{label}: evidence missing")
        return
    value = read_json(packet_file(packet, name))
    require(value.get("candidate_sha") == sha and sha, f"{label}: evidence candidate mismatch")
    require(value.get("result") == "PASS", f"{label}: evidence result is not PASS")
    require(nonempty(value.get("method")) and nonempty(value.get("reviewed_by")),
            f"{label}: evidence requires method and reviewer")
    timestamp(value.get("recorded_at"))
    if claim:
        require(claim in value.get("claims", []), f"{label}: evidence does not cover {claim}")


def validate(packet):
    blockers = []
    for name in DOCUMENTS:
        packet_file(packet, name)
    metadata = read_json(packet / "metadata.json")
    assets = read_json(packet / "assets.json")
    owners = read_json(packet / "owner-inputs.json")
    for label, value in (("metadata", metadata), ("assets", assets), ("owner inputs", owners)):
        require(value.get("state") in {"draft", "ready"}, f"{label}: invalid state")
        if value["state"] != "ready":
            blockers.append(f"{label}: still draft")
    for field, limit in {"name": 30, "subtitle": 30, "promotional_text": 170,
                         "description": 4000, "whats_new": 4000}.items():
        text = metadata.get(field)
        require(nonempty(text) and len(text) <= limit, f"{field}: required, maximum {limit} characters")
    keywords = metadata.get("keywords")
    require(nonempty(keywords) and len(keywords.encode("utf-8")) <= 100,
            "keywords: required, maximum 100 UTF-8 bytes")
    require(all(len(word.strip()) > 2 for word in keywords.split(",")), "keywords: each term requires more than two characters")
    require(metadata.get("locale") == "en-US", "packet supports en-US only")
    for field in ("support_url", "privacy_url", "terms_url"):
        value = metadata.get(field)
        if not value:
            blockers.append(f"{field}: owner-confirmed URL missing")
            continue
        url = urlparse(value)
        host = url.hostname or ""
        require(url.scheme == "https" and host and not url.username and not url.password,
                f"{field}: requires a public HTTPS URL")
        require(host != "localhost" and not host.endswith((".test", ".invalid", ".example"))
                and host not in {"example.com", "example.org", "example.net"}, f"{field}: placeholder host")
    if not nonempty(metadata.get("copyright")):
        blockers.append("copyright: legal owner unresolved")
    candidate = assets.get("candidate", {})
    sha = candidate.get("sha")
    if not sha:
        blockers.append("candidate SHA missing")
    else:
        require(isinstance(sha, str) and re.fullmatch(r"[0-9a-f]{40}", sha), "candidate SHA requires 40 lowercase hex characters")
    for field in ("version", "build"):
        if not candidate.get(field):
            blockers.append(f"candidate {field} missing")
    if candidate.get("version"):
        require(re.fullmatch(r"[0-9]+\.[0-9]+(?:\.[0-9]+)?", candidate["version"]), "invalid candidate version")
        require(candidate["version"] == metadata.get("proposed_version"), "metadata/candidate version mismatch")
    if candidate.get("build"):
        require(re.fullmatch(r"[1-9][0-9]*", str(candidate["build"])), "invalid candidate build")
    require(nonempty(candidate.get("scope_note")) and candidate.get("excluded_features"), "release scope inventory missing")
    if re.search(r"pending|unverified|unresolved", candidate["scope_note"], re.IGNORECASE):
        blockers.append("release scope: candidate exclusions still unverified")
    evidence(packet, candidate.get("release_scope_evidence"), sha, blockers, "release scope", "release_scope")
    claims = metadata.get("claims", [])
    require(isinstance(claims, list) and claims and all(isinstance(claim, dict) for claim in claims), "claim inventory is empty or malformed")
    claim_ids = [claim.get("id") for claim in claims]
    require(all(nonempty(value) for value in claim_ids) and len(set(claim_ids)) == len(claim_ids), "claim IDs must be nonempty and unique")
    for claim in claims:
        evidence(packet, claim.get("evidence"), sha, blockers, claim["id"], claim["id"])
    screenshots = assets.get("screenshots", [])
    require(isinstance(screenshots, list) and 1 <= len(screenshots) <= 10
            and all(isinstance(slot, dict) for slot in screenshots), "require 1 to 10 screenshot slots")
    ids = [slot.get("id") for slot in screenshots]
    require(all(isinstance(value, str) and re.fullmatch(r"[a-z][a-z0-9-]*", value) for value in ids)
            and len(set(ids)) == len(ids), "screenshot IDs must be unique lowercase names")
    sizes, paths = set(), set()
    for slot in screenshots:
        require(nonempty(slot.get("caption")) and slot.get("claim") in claim_ids, f"{slot['id']}: caption/claim missing")
        if not slot.get("path"):
            require(slot.get("state") == "pending", f"{slot['id']}: uncaptured screenshot must be pending")
            blockers.append(f"{slot['id']}: authentic screenshot missing")
            continue
        path = packet_file(packet, slot["path"])
        require(path not in paths, "screenshot file reused across slots")
        paths.add(path)
        sizes.add(png_size(path, IPHONE_SIZES))
        require(slot.get("sha256") == checksum(path), f"{slot['id']}: image checksum mismatch")
        require(slot.get("candidate_sha") == sha and sha, f"{slot['id']}: candidate mismatch")
        require(str(slot.get("version")) == candidate.get("version") and str(slot.get("build")) == str(candidate.get("build")), f"{slot['id']}: version/build mismatch")
        for field in ("device", "os_version", "scenario"):
            require(nonempty(slot.get(field)), f"{slot['id']}: missing {field}")
        timestamp(slot.get("captured_at"))
        require(slot.get("fictional_data") is True, f"{slot['id']}: fictional-data attestation missing")
        require(slot.get("state") in {"captured_unreviewed", "reviewed"}, f"{slot['id']}: invalid capture state")
        if slot["state"] != "reviewed" or not nonempty(slot.get("reviewed_by")):
            blockers.append(f"{slot['id']}: human content review missing")
        evidence(packet, slot.get("evidence"), sha, blockers, slot["id"], slot["claim"])
    require(len(sizes) <= 1, "use one screenshot size for this locale/set")
    icon = assets.get("icon", {})
    repo = packet.parents[1]
    source = (repo / icon.get("source", "")).resolve()
    require(source.is_relative_to(repo.resolve()) and (source / "icon.json").is_file(), "Icon Composer source missing")
    composition = read_json(source / "icon.json")
    require(composition.get("groups"), "Icon Composer has no groups")
    for group in composition["groups"]:
        for layer in group.get("layers", []):
            if layer.get("image-name"):
                image = (source / "Assets" / layer["image-name"]).resolve()
                require(image.is_relative_to(source) and image.is_file(), "Icon Composer layer image missing")
    if not icon.get("path"):
        blockers.append("compiled App Store icon missing")
    else:
        path = packet_file(packet, icon["path"])
        png_size(path, {(1024, 1024)})
        require(icon.get("sha256") == checksum(path), "icon checksum mismatch")
        require(icon.get("candidate_sha") == sha and sha, "icon candidate mismatch")
        if not nonempty(icon.get("reviewed_by")):
            blockers.append("compiled icon review missing")
        evidence(packet, icon.get("evidence"), sha, blockers, "compiled icon", "compiled_icon")
    inputs = owners.get("inputs", [])
    require(isinstance(inputs, list) and all(isinstance(item, dict) for item in inputs)
            and {item.get("id") for item in inputs} == OWNER_IDS
            and len(inputs) == len(OWNER_IDS), "owner input inventory changed or duplicated")
    for item in inputs:
        require(item.get("status") in {"unresolved", "resolved"}, "invalid owner input status")
        if item["status"] != "resolved" or not nonempty(item.get("value")):
            blockers.append(f"owner input unresolved: {item['id']}")
        else:
            evidence(packet, item.get("evidence"), sha, blockers, item["id"])
    for name in ("review-notes.md", "public/privacy.md", "public/terms.md", "public/support.md"):
        if re.search(r"\b(DRAFT|UNRESOLVED|UNVERIFIED|NOT RUN)\b", packet_file(packet, name).read_text()):
            blockers.append(f"{name}: unresolved draft content")
    return blockers


def import_screenshot(args):
    packet = args.packet.resolve()
    assets = read_json(packet / "assets.json")
    matches = [slot for slot in assets["screenshots"] if slot["id"] == args.slot]
    require(len(matches) == 1, "unknown screenshot slot")
    require(re.fullmatch(r"[0-9a-f]{40}", args.candidate_sha), "candidate SHA requires 40 lowercase hex characters")
    require(re.fullmatch(r"[0-9]+\.[0-9]+(?:\.[0-9]+)?", args.version), "invalid version")
    require(re.fullmatch(r"[1-9][0-9]*", args.build), "invalid build")
    timestamp(args.captured_at)
    for value in (args.device, args.os_version, args.scenario):
        require(nonempty(value), "capture facts must be nonempty")
    png_size(args.source, IPHONE_SIZES)
    candidate = assets["candidate"]
    for field, value in {"sha": args.candidate_sha, "version": args.version, "build": args.build}.items():
        require(candidate.get(field) in (None, value), f"candidate {field} conflicts with packet")
        candidate[field] = value
    require(not matches[0].get("path"), "slot already has a capture; review/remove the old entry before replacement")
    destination = packet / "screenshots" / f"{args.slot}.png"
    require(not destination.exists(), "destination exists; refusing to overwrite a capture")
    shutil.copyfile(args.source, destination)
    matches[0].update({
        "state": "captured_unreviewed", "path": f"screenshots/{args.slot}.png",
        "sha256": checksum(destination), "candidate_sha": args.candidate_sha,
        "version": args.version, "build": args.build, "device": args.device,
        "os_version": args.os_version, "captured_at": args.captured_at,
        "scenario": args.scenario, "fictional_data": args.fictional_data,
        "reviewed_by": None, "evidence": None,
    })
    (packet / "assets.json").write_text(json.dumps(assets, indent=2) + "\n")
    print(f"Imported unchanged capture: {destination}. Human content review is pending.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--packet", type=Path, default=PACKET)
    commands = parser.add_subparsers(dest="command", required=True)
    check = commands.add_parser("validate")
    check.add_argument("--ready", action="store_true")
    capture = commands.add_parser("import-screenshot")
    capture.add_argument("slot")
    capture.add_argument("source", type=Path)
    for field in ("candidate-sha", "version", "build", "device", "os-version", "captured-at", "scenario"):
        capture.add_argument(f"--{field}", required=True)
    capture.add_argument("--fictional-data", action="store_true", required=True)
    args = parser.parse_args()
    try:
        if args.command == "import-screenshot":
            import_screenshot(args)
            return 0
        blockers = validate(args.packet.resolve())
        print("Packet format checks passed.")
        if blockers:
            print("Submission readiness BLOCKED:")
            for blocker in blockers:
                print(f"- {blocker}")
            return 2 if args.ready else 0
        print("Packet consistency checks passed. Human review and signed-candidate acceptance remain required.")
        return 0
    except (ValueError, TypeError, KeyError, OSError, zlib.error) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
