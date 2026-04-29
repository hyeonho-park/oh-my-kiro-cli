#!/usr/bin/env bash
# delegate-retry-guidance.sh — postToolUse hook for use_subagent
#
# Error type labels (canonical):
#   unavailable_agent  — "not available to be used as SubAgent"
#   unknown_agent      — "Unknown agent"
#   empty_agent        — "Agent name cannot be empty"
#   denied_agent       — "denied list"
#
# Retry cap: per (session_key, error_type). Cap = 2.
#   count < 2  → increment, exit 1 (retry-now guidance to stderr)
#   count >= 2 → exit 0 (surface to user, no more forced retries)
#
# session_key: $KIRO_SESSION_KEY env var, else pgid of this process.
# State file:  ~/.kiro/state/oh-my-kiro-cli/delegate-retry-guidance/<session_key>.json
#              JSON dict: { error_type: count }
#
# PF1=STDERR  PF3=pgid fallback
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

matched = None
for ep in ERROR_PATTERNS:
    if ep["pattern"] in output:
        matched = ep
        break

if not matched:
    sys.exit(0)

error_type = matched["error_type"]

# Determine session key: env var or pgid fallback
session_key = os.environ.get("KIRO_SESSION_ID") or str(os.getpgid(os.getppid()))

state_dir = os.path.expanduser(
    "~/.kiro/state/oh-my-kiro-cli/delegate-retry-guidance"
)
os.makedirs(state_dir, exist_ok=True)
state_file = os.path.join(state_dir, f"{session_key}.json")

# Load existing counts
try:
    with open(state_file) as f:
        counts = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    counts = {}

count = counts.get(error_type, 0)

if count >= 2:
    sys.stderr.write(
        f"Retry cap reached for {error_type} (2 attempts in this session). Surfacing to user.\n"
    )
    sys.exit(0)

# Increment and persist (atomic write)
counts[error_type] = count + 1
tmp = state_file + ".tmp"
with open(tmp, "w") as f:
    json.dump(counts, f)
os.replace(tmp, state_file)

sys.stderr.write(
    f"[Subagent Delegation Failed — Retry Required]\n"
    f"Error: {error_type}\n"
    f"Fix: {matched['fix']}\n"
    f"\n"
    f"Action: Retry the subagent call NOW with corrected parameters.\n"
)
sys.exit(1)
PY
