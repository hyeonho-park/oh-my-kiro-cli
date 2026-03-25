#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["PAYLOAD"])
tool_name = payload.get("tool_name", "")
response = payload.get("tool_response")

if tool_name not in {"grep", "glob", "read"}:
    sys.exit(0)

count = 0
if isinstance(response, list):
    count = len(response)
elif isinstance(response, dict):
    items = response.get("items")
    if isinstance(items, list):
        count = len(items)

if count >= 20:
    sys.stderr.write("Large search result set detected. Consider switching to a dedicated explore agent before continuing.\n")
    sys.exit(1)

sys.exit(0)
PY
