#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

# kb-curator exemption: needs git push/commit for wiki git integration
if [[ "${KIRO_AGENT_NAME:-}" == "kb-curator" ]]; then
  exit 0
fi

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import re
import sys

payload = json.loads(os.environ["PAYLOAD"])
tool_input = payload.get("tool_input", {}) or {}


def gather_candidates(value):
    candidates = []
    if isinstance(value, dict):
        for key in ("command", "cmd", "input", "text", "script"):
            item = value.get(key)
            if isinstance(item, str) and item.strip():
                candidates.append(item)
        commands = value.get("commands")
        if isinstance(commands, list):
            for item in commands:
                if isinstance(item, str) and item.strip():
                    candidates.append(item)
    elif isinstance(value, str) and value.strip():
        candidates.append(value)
    return candidates


candidates = gather_candidates(tool_input)
if not candidates:
    sys.exit(0)

blocked_patterns = [
    r"(^|[;&|]\s*)rm\s",
    r"(^|[;&|]\s*)trash\s",
    r"(^|[;&|]\s*)mv\s",
    r"(^|[;&|]\s*)chmod\s",
    r"(^|[;&|]\s*)chown\s",
    r"(^|[;&|]\s*)sed\s+-i\b",
    r"(^|[;&|]\s*)perl\s+-i\b",
    r"git\s+commit\b",
    r"git\s+push\b",
    r"git\s+reset\b",
    r"git\s+clean\b",
    r"git\s+checkout\s+--",
    r"git\s+restore\s+--",
    r"git\s+rebase\b",
    r"git\s+cherry-pick\b",
    r"git\s+merge\b",
    r"git\s+apply\b",
]

for command in candidates:
    lowered = command.lower()
    if any(re.search(pattern, lowered) for pattern in blocked_patterns):
        sys.stderr.write(
            "READ-ONLY agents cannot run destructive shell commands. "
            "Use read/glob/grep for inspection or hand off execution to a write-capable agent.\n"
        )
        sys.exit(2)

sys.exit(0)
PY
