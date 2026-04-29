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

command = tool_input.get("command") or ""

# ListAgents doesn't require validation
if command == "ListAgents":
    sys.exit(0)

# --- TUI mode: subagent tool uses {task, stages} schema ---
stages = tool_input.get("stages")
if stages is not None:
    if not isinstance(stages, list) or not stages:
        sys.stderr.write("stages must be a non-empty array.\n")
        sys.exit(2)
    for i, stage in enumerate(stages):
        name = (stage.get("name") or "").strip()
        if not name:
            sys.stderr.write(f"stages[{i}].name is missing or empty.\n")
            sys.exit(2)
    sys.exit(0)

# --- Classic mode: InvokeSubagents uses {content: {subagents}} schema ---
content = tool_input.get("content") or {}
subagents = content.get("subagents") or []

if not subagents:
    sys.stderr.write("No subagents specified in InvokeSubagents call.\n")
    sys.exit(2)

for i, sub in enumerate(subagents):
    agent_name = (sub.get("agent_name") or "").strip()
    if not agent_name:
        sys.stderr.write(
            f"agent_name is missing or empty in subagent[{i}]. "
            "Run ListAgents first, then specify a valid agent_name.\n"
        )
        sys.exit(2)

    query = (sub.get("query") or "").strip()
    if len(query) < 10:
        sys.stderr.write(
            f"Subagent[{i}] query is too short (< 10 chars). "
            "Provide a clear, specific task description.\n"
        )
        sys.exit(2)

sys.exit(0)
PY