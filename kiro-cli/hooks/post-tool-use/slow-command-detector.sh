#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import re
import sys

payload = json.loads(os.environ["PAYLOAD"])

if payload.get("tool_name", "") != "shell":
    sys.exit(0)

response = str(payload.get("tool_response", ""))
command = payload.get("tool_input", {}).get("command", "")

exit_124 = bool(re.search(r'exit code[:\s]+124|exitCode[:\s]+124|returned 124|status 124', response))
signal_killed = bool(re.search(r'timed out|Timed out|SIGTERM|SIGKILL|signal 15|signal 9|[Kk]illed|Terminated|Command timed out', response))

if exit_124 or signal_killed:
    sys.stderr.write(
        f"[WARNING — Command Timed Out or Killed]\n"
        f"Command appears to have timed out or been killed:\n"
        f"  {command}\n"
        f"Suggestions:\n"
        f"  - Use a shorter timeout: `timeout <seconds> <command>`\n"
        f"  - Try a different approach or break into smaller steps\n"
        f"  - Wrap long-running commands with `timeout <seconds>` prefix\n"
    )
    sys.exit(1)

sys.exit(0)
PY
