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

def extract_text(val):
    if isinstance(val, str):
        return val.strip()
    if isinstance(val, list):
        return " ".join(str(v) for v in val).strip()
    if isinstance(val, dict):
        inner = val.get("result") or val.get("output") or ""
        return extract_text(inner)
    return str(val).strip() if val else ""

response_text = extract_text(tool_response)

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
