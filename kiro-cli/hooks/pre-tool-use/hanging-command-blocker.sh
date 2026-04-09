#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import re
import sys

payload = json.loads(os.environ["PAYLOAD"])
if payload.get("tool_name") != "shell":
    sys.exit(0)

command = (payload.get("tool_input") or {}).get("command", "").strip()
if not command:
    sys.exit(0)

# (pattern, reason, suggestion)
checks = [
    (
        r"tail\s+.*(-f|--follow)",
        "tail -f streams indefinitely",
        "Use `head -n 50 <file>` or `tail -n 50 <file>` to read a fixed number of lines",
    ),
    (
        r"^watch\s",
        "`watch` loops indefinitely",
        "Run the command once directly instead",
    ),
    (
        r"^(top|htop)\b(?!.*\s-l\s)",
        "`top`/`htop` is an interactive monitor",
        "Use `top -l 1` (macOS) or `ps aux` for a one-shot snapshot",
    ),
    (
        r"^(less|more|man)\s",
        "interactive pager blocks the shell",
        "Pipe to `cat` instead, e.g. `man curl | cat`",
    ),
    (
        r"^(vim|vi|nano|emacs)\b",
        "interactive editor blocks the shell",
        "Use file-write tools to edit files",
    ),
    (
        r"^(python3?|node|irb|ruby|lua)\s*$",
        "bare REPL blocks waiting for input",
        "Pass a script file or `-c` flag with the code to run",
    ),
    (
        r"^cat\s*$",
        "`cat` without arguments blocks waiting for stdin",
        "Provide a filename: `cat <file>`",
    ),
    (
        r"^docker\s+attach\b",
        "`docker attach` connects interactively and blocks",
        "Use `docker logs --tail 50 <container>` to inspect output",
    ),
    (
        r"^docker\s+.*exec\s+.*-(it|ti)\b",
        "`docker exec -it` opens an interactive TTY and blocks",
        "Use `docker exec <container> <command>` without -it for non-interactive commands",
    ),
    (
        r"^ssh\s+\S+\s*$",
        "`ssh` without a remote command opens an interactive session",
        "Append the remote command: `ssh host 'command'`",
    ),
    (
        r"\bsleep\s+(\d+)",
        "sleep duration >= 100 seconds blocks the agent",
        "Use `timeout 30 <command>` or reduce sleep to under 100 seconds",
    ),
    (
        r"^(npm|yarn|pnpm)\s+(start|dev|serve)\s*$",
        "dev server runs indefinitely",
        "Use `timeout 30 <command>` if you only need to verify startup",
    ),
]

for pattern, reason, suggestion in checks:
    m = re.search(pattern, command)
    if not m:
        continue

    # Special case: allow top -l (macOS one-shot)
    if re.match(r"^(top|htop)\b", command) and re.search(r"\s-l\s", command):
        continue

    # Special case: only block sleep when duration >= 100
    if "sleep" in pattern:
        duration = int(m.group(1))
        if duration < 100:
            continue

    sys.stderr.write(f"Blocked: {reason}.\nSuggestion: {suggestion}\n")
    sys.exit(2)

sys.exit(0)
PY
