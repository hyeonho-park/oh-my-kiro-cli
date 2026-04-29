#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import sys

STATE_DIR = os.path.expanduser("~/.kiro/state/oh-my-kiro-cli/context-window-reminder")
os.makedirs(STATE_DIR, exist_ok=True)

# Derive session key
session_key = os.environ.get("KIRO_SESSION_ID")
fallback_source_file = os.path.join(STATE_DIR, ".fallback-key-source")

if session_key:
    source = "KIRO_SESSION_ID"
else:
    session_key = str(os.getpgid(os.getppid()))
    source = "pgid"

if not os.path.exists(fallback_source_file):
    with open(fallback_source_file, "w") as f:
        f.write(source + "\n")

cache_file = os.path.join(STATE_DIR, f"{session_key}.cache")

count = 0
if os.path.exists(cache_file):
    try:
        count = int(open(cache_file).read().strip())
    except (ValueError, OSError):
        count = 0

count += 1

with open(cache_file, "w") as f:
    f.write(str(count) + "\n")

if count == 50:
    sys.stderr.write(
        "Context reminder: you have made 50 tool calls. "
        "Consider /compact at the next natural break point.\n"
    )
elif count > 50 and (count - 50) % 25 == 0:
    sys.stderr.write(
        f"Context reminder: you have made {count} tool calls. "
        "Consider /compact at the next natural break point.\n"
    )

sys.exit(0)
PY
