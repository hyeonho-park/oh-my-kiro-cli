#!/usr/bin/env bash
# post-tool-use: empty-subagent-response-detector
#
# Counter semantics (per session_key × agent_name):
#   count=0  → no empty responses yet
#   count=1  → 1st empty: exit 1 (allow retry), count becomes 1
#   count=2  → 2nd empty: exit 1 (allow retry), count becomes 2
#   count>=2 on entry → 3rd+ empty: exit 0 (advisory, surface to user)
#
# In other words: the first TWO empty responses trigger a retry (exit 1).
# The third and beyond are capped (exit 0 advisory).
# A non-empty response resets the counter to 0.
#
# PF1 = STDERR  PF3 = session_id absent → pgid fallback

set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import sys
import tempfile

payload = json.loads(os.environ["PAYLOAD"])
tool_name = payload.get("tool_name", "")

if tool_name not in {"use_subagent", "subagent"}:
    sys.exit(0)

# --- resolve agent name ---
tool_input = payload.get("tool_input") or {}
if isinstance(tool_input, str):
    try:
        tool_input = json.loads(tool_input)
    except Exception:
        tool_input = {}
agent_name = tool_input.get("agent_name") or tool_input.get("name") or "unknown"

# --- resolve session key (session_id or pgid fallback) ---
session_id = payload.get("session_id") or ""
if session_id:
    session_key = session_id
else:
    try:
        session_key = str(os.getpgid(os.getppid()))
    except Exception:
        session_key = str(os.getpid())

# --- state file ---
state_dir = os.path.expanduser(
    "~/.kiro/state/oh-my-kiro-cli/empty-subagent-response-detector"
)
os.makedirs(state_dir, exist_ok=True)
state_file = os.path.join(state_dir, f"{session_key}.json")

def load_state():
    try:
        with open(state_file) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}

def save_state(state):
    tmp = state_file + ".tmp"
    with open(tmp, "w") as f:
        json.dump(state, f)
    os.replace(tmp, state_file)

# --- check emptiness ---
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

state = load_state()

if not response_text:
    count = state.get(agent_name, 0)
    if count >= 2:
        # cap reached — surface to user instead of retrying
        sys.stderr.write(
            f"Retry cap reached for {agent_name} (2 empty responses in this session). "
            "Surfacing to user instead of auto-retry.\n"
        )
        sys.exit(0)
    else:
        state[agent_name] = count + 1
        save_state(state)
        sys.stderr.write(
            f"Empty subagent response from {agent_name}. "
            "Retry with a clearer prompt or a different agent.\n"
        )
        sys.exit(1)
else:
    if state.get(agent_name, 0) != 0:
        state[agent_name] = 0
        save_state(state)
    sys.exit(0)
PY
