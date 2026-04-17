#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import hashlib
import json
import os
import sys

payload = json.loads(os.environ["PAYLOAD"])
tool_name = payload.get("tool_name", "")

if not tool_name:
    sys.exit(0)

tool_input = payload.get("tool_input", "")
signature = hashlib.md5(json.dumps({"n": tool_name, "i": tool_input}, sort_keys=True).encode()).hexdigest()

state_dir = os.path.expanduser("~/.kiro")
state_file = os.path.join(state_dir, ".infra-circuit-breaker-state")

os.makedirs(state_dir, exist_ok=True)

prev_sig = ""
count = 0
try:
    with open(state_file) as f:
        state = json.load(f)
        prev_sig = state.get("sig", "")
        count = state.get("count", 0)
except (FileNotFoundError, json.JSONDecodeError, KeyError):
    pass

if signature == prev_sig:
    count += 1
else:
    count = 1

with open(state_file, "w") as f:
    json.dump({"sig": signature, "count": count}, f)

if count >= 8:
    sys.stderr.write(
        f"[BLOCKED — Infinite Loop Detected]\n"
        f"Tool '{tool_name}' called {count} times with identical arguments.\n"
        f"This operation is BLOCKED. You MUST stop this approach entirely.\n"
        f"Revert if needed and try a fundamentally different strategy.\n"
    )
    sys.exit(1)

if count >= 5:
    sys.stderr.write(
        f"[WARNING — Possible Infinite Loop]\n"
        f"Tool '{tool_name}' called {count} times consecutively with identical arguments.\n"
        f"STOP and try a different approach. Do not repeat the same call.\n"
    )
    sys.exit(1)

sys.exit(0)
PY