#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["PAYLOAD"])
tool_name = payload.get("tool_name", "")

if tool_name not in {"use_subagent", "subagent"}:
    sys.exit(0)

tool_response = payload.get("tool_response")
response_text = ""

if isinstance(tool_response, str):
    response_text = tool_response.strip()
elif isinstance(tool_response, dict):
    response_text = (tool_response.get("result") or tool_response.get("output") or "").strip()

if not response_text:
    sys.stderr.write(
        "[Subagent Empty Response Warning]\n"
        "Subagent returned no response. The agent may have:\n"
        "- Failed to execute properly\n"
        "- Not terminated correctly\n"
        "- Returned an empty result\n"
        "\n"
        "The call has already completed. Retry with a clearer prompt "
        "or delegate to a different agent.\n"
    )
    sys.exit(1)

sys.exit(0)
PY
