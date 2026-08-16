import base64
import json
import os
import re
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[2]
CLIENT = ROOT / "scripts/release/testflight.rb"


class FakeAppStoreConnect:
    def __init__(self, memberships=None, groups=None):
        self.memberships = memberships or {"dev": set(), "internal": set()}
        self.groups = groups or [
            {
                "type": "betaGroups",
                "id": "dev-id",
                "attributes": {
                    "name": "dev",
                    "isInternalGroup": True,
                    "hasAccessToAllBuilds": False,
                },
            },
            {
                "type": "betaGroups",
                "id": "internal-id",
                "attributes": {
                    "name": "internal",
                    "isInternalGroup": True,
                    "hasAccessToAllBuilds": False,
                },
            },
        ]
        self.posts = []
        owner = self

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):  # noqa: N802 - stdlib handler API
                owner.handle_get(self)

            def do_POST(self):  # noqa: N802 - stdlib handler API
                owner.handle_post(self)

            def log_message(self, *_args):
                return

        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    @property
    def base_url(self):
        return f"http://127.0.0.1:{self.server.server_port}/v1"

    def close(self):
        self.server.shutdown()
        self.thread.join(timeout=5)

    def json_response(self, handler, status, payload):
        body = json.dumps(payload).encode()
        handler.send_response(status)
        handler.send_header("Content-Type", "application/json")
        handler.send_header("Content-Length", str(len(body)))
        handler.end_headers()
        handler.wfile.write(body)

    def group_name(self, group_id):
        return next(group["attributes"]["name"] for group in self.groups if group["id"] == group_id)

    def handle_get(self, handler):
        path = urlparse(handler.path).path
        if path.endswith("/apps/6757370520/betaGroups"):
            self.json_response(handler, 200, {"data": self.groups})
            return

        match = re.search(r"/betaGroups/([^/]+)/relationships/builds$", path)
        if match:
            name = self.group_name(match.group(1))
            data = [{"type": "builds", "id": build_id} for build_id in sorted(self.memberships[name])]
            self.json_response(handler, 200, {"data": data})
            return

        self.json_response(handler, 404, {"errors": [{"detail": path}]})

    def handle_post(self, handler):
        path = urlparse(handler.path).path
        match = re.search(r"/betaGroups/([^/]+)/relationships/builds$", path)
        if not match:
            self.json_response(handler, 404, {"errors": [{"detail": path}]})
            return

        body = json.loads(handler.rfile.read(int(handler.headers["Content-Length"])))
        name = self.group_name(match.group(1))
        build_ids = [item["id"] for item in body["data"]]
        self.posts.append((name, build_ids))
        self.memberships[name].update(build_ids)
        self.json_response(handler, 200, {"data": []})


class TestFlightGroupTests(unittest.TestCase):
    def ruby_environment(self, base_url):
        key = subprocess.run(
            ["openssl", "ecparam", "-name", "prime256v1", "-genkey", "-noout"],
            check=True,
            capture_output=True,
        ).stdout
        return os.environ | {
            "ASC_API_BASE": base_url,
            "ASC_KEY_ID": "test-key",
            "ASC_ISSUER_ID": "test-issuer",
            "ASC_PRIVATE_KEY_BASE64": base64.b64encode(key).decode(),
        }

    def run_client(self, server, *args):
        return subprocess.run(
            ["ruby", str(CLIENT), *args],
            cwd=ROOT,
            env=self.ruby_environment(server.base_url),
            capture_output=True,
            text=True,
        )

    def binding_file(self, directory):
        binding = Path(directory) / "binding.json"
        binding.write_text(
            json.dumps(
                {
                    "github_run_id": "run-1",
                    "github_sha": "sha-1",
                    "build_resource_id": "build-1",
                    "selected_group": "internal",
                }
            )
        )
        return binding

    def test_assignment_targets_selected_group_and_proves_exclusion(self):
        server = FakeAppStoreConnect()
        try:
            with tempfile.TemporaryDirectory() as directory:
                result = self.run_client(
                    server,
                    "assign-group",
                    str(self.binding_file(directory)),
                    "internal",
                    "run-1",
                    "sha-1",
                )
        finally:
            server.close()

        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads(result.stdout)
        self.assertEqual(payload["selected_group"], "internal")
        self.assertEqual(payload["excluded_group"], "dev")
        self.assertEqual(server.posts, [("internal", ["build-1"])])
        self.assertEqual(server.memberships["dev"], set())

    def test_existing_non_selected_relationship_fails_without_removal(self):
        server = FakeAppStoreConnect(memberships={"dev": {"build-1"}, "internal": set()})
        try:
            with tempfile.TemporaryDirectory() as directory:
                result = self.run_client(
                    server,
                    "assign-group",
                    str(self.binding_file(directory)),
                    "internal",
                    "run-1",
                    "sha-1",
                )
        finally:
            server.close()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("non-selected group dev", result.stderr)
        self.assertEqual(server.posts, [])

    def test_group_configuration_must_be_explicit_access_for_both_groups(self):
        template = FakeAppStoreConnect()
        groups = template.groups
        template.close()
        groups[0]["attributes"]["hasAccessToAllBuilds"] = True
        server = FakeAppStoreConnect(groups=groups)
        try:
            result = self.run_client(server, "assert-groups", "internal")
        finally:
            server.close()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("dev is not an internal explicit-access group", result.stderr)


if __name__ == "__main__":
    unittest.main()
