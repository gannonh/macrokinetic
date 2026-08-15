#!/usr/bin/env bash

set -euo pipefail

output="${1:?output path is required}"
: "${ASC_KEY_ID:?missing ASC_KEY_ID}"
: "${ASC_ISSUER_ID:?missing ASC_ISSUER_ID}"
: "${ASC_PRIVATE_KEY_BASE64:?missing ASC_PRIVATE_KEY_BASE64}"

python3 - "$output" "$ASC_KEY_ID" "$ASC_ISSUER_ID" <<'PY'
import base64
import json
import os
import sys

path, key_id, issuer_id = sys.argv[1:]
private_key = base64.b64decode(os.environ["ASC_PRIVATE_KEY_BASE64"]).decode()
with open(path, "x", encoding="utf-8") as output:
    json.dump({"key_id": key_id, "issuer_id": issuer_id, "key": private_key}, output)
    output.write("\n")
PY
chmod 600 "$output"
