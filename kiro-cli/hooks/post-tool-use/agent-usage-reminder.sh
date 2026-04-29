#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

tool_name=$(printf '%s' "$payload" | sed -n 's/.*"tool_name" *: *"\([^"]*\)".*/\1/p')
case "$tool_name" in
  glob|grep) ;;
  *) exit 0 ;;
esac

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["PAYLOAD"])
tool_name = payload.get("tool_name", "")
response = payload.get("tool_response")

if tool_name not in {"grep", "glob"}:
    sys.exit(0)

count = 0
if isinstance(response, list):
    count = len(response)
elif isinstance(response, dict):
    items = response.get("result") or response.get("items")
    if isinstance(items, list):
        count = len(items)

if count >= 50:
    sys.stderr.write(f"Search returned {count} results. Consider delegating to the `explore` subagent for large result sets to keep main context clean.\n")

sys.exit(0)
PY
