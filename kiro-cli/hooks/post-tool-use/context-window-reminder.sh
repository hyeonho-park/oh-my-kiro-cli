#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["PAYLOAD"])
tool_response = payload.get("tool_response")

if not isinstance(tool_response, dict):
    sys.exit(0)

result = tool_response.get("result")
if not result:
    sys.exit(0)

size = 0
if isinstance(result, str):
    size = len(result)
elif isinstance(result, list):
    size = sum(len(str(item)) for item in result)

if size > 50000:
    sys.stderr.write(
        f"Large tool response detected (~{size // 1000}KB). "
        "Consider using /compact if context window is getting full. "
        "Use /context show to check current usage.\n"
    )
    sys.exit(1)

sys.exit(0)
PY
