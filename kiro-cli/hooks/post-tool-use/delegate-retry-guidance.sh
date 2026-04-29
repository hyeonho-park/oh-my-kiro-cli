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

def extract_text(val):
    if isinstance(val, str):
        return val
    if isinstance(val, list):
        return " ".join(str(v) for v in val)
    if isinstance(val, dict):
        inner = val.get("result") or val.get("output") or ""
        return extract_text(inner)
    return str(val) if val else ""

output = extract_text(tool_response)

if not output:
    sys.exit(0)

ERROR_PATTERNS = [
    {
        "pattern": "not available to be used as SubAgent",
        "error_type": "unavailable_agent",
        "fix": "Run ListAgents first (classic) or check availableAgents (TUI), then specify a valid agent. Never use kiro_default.",
    },
    {
        "pattern": "Unknown agent",
        "error_type": "unknown_agent",
        "fix": "The agent name is wrong. Run ListAgents to see valid names.",
    },
    {
        "pattern": "Agent name cannot be empty",
        "error_type": "empty_agent",
        "fix": "Provide a non-empty agent_name (classic) or stages[].name (TUI).",
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
            f"Action: Retry the subagent call NOW with corrected parameters.\n"
        )
        sys.exit(1)

sys.exit(0)
PY
