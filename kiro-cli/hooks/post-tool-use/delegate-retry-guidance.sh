#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import sys
import re

payload = json.loads(os.environ["PAYLOAD"])
tool_name = payload.get("tool_name", "")

if tool_name not in {"use_subagent", "subagent"}:
    sys.exit(0)

tool_response = payload.get("tool_response")
output = ""

if isinstance(tool_response, str):
    output = tool_response
elif isinstance(tool_response, dict):
    output = tool_response.get("result") or tool_response.get("output") or ""

if not output:
    sys.exit(0)

ERROR_PATTERNS = [
    {
        "pattern": "not available to be used as SubAgent",
        "error_type": "unavailable_agent",
        "fix": "Run ListAgents first, then use an agent_name from the available list. Never use kiro_default.",
    },
    {
        "pattern": "Unknown agent",
        "error_type": "unknown_agent",
        "fix": "The agent name is wrong. Run ListAgents to see valid names.",
    },
    {
        "pattern": "Agent name cannot be empty",
        "error_type": "empty_agent",
        "fix": "Provide a non-empty agent_name parameter.",
    },
    {
        "pattern": "denied list",
        "error_type": "denied_agent",
        "fix": "This agent is blocked. Choose a different agent from availableAgents.",
    },
]

for ep in ERROR_PATTERNS:
    if ep["pattern"] in output:
        sys.stderr.write(
            f"[Subagent Delegation Failed — Retry Required]\n"
            f"Error: {ep['error_type']}\n"
            f"Fix: {ep['fix']}\n"
            f"\n"
            f"Action: Retry use_subagent NOW with corrected parameters.\n"
        )
        sys.exit(1)

sys.exit(0)
PY
