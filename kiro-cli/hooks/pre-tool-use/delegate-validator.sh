#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["PAYLOAD"])
tool_input = payload.get("tool_input", {}) or {}

if not isinstance(tool_input, dict):
    sys.exit(0)

agent_name = tool_input.get("agent_name") or ""
if not agent_name.strip():
    sys.stderr.write(
        "agent_name is missing or empty. "
        "Run ListAgents first, then specify a valid agent_name.\n"
    )
    sys.exit(2)

description = tool_input.get("description") or tool_input.get("query") or tool_input.get("task") or ""
if len(description.strip()) < 10:
    sys.stderr.write(
        "Subagent description is too short (< 10 chars). "
        "Provide a clear, specific task description for the subagent.\n"
    )
    sys.exit(2)

sys.exit(0)
PY
