#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import sys
from pathlib import Path

payload = json.loads(os.environ["PAYLOAD"])
cwd = payload.get("cwd", "")
tool_input = payload.get("tool_input", {}) or {}
path = ""
if isinstance(tool_input, dict):
    path = tool_input.get("path") or tool_input.get("file_path") or tool_input.get("target_file") or ""

if not path or not path.endswith(".md"):
    sys.exit(0)

normalized = Path(path)
if not normalized.is_absolute() and cwd:
    normalized = Path(cwd) / normalized

relative = normalized.as_posix()
if cwd:
    cwd_path = Path(cwd)
    try:
        relative = normalized.relative_to(cwd_path).as_posix()
    except ValueError:
        relative = normalized.as_posix().lstrip("/")

allowed_root_files = {
    "README.md",
    "CHANGELOG.md",
    "LICENSE.md",
    "CONTRIBUTING.md",
    "WORK_PLAN.md",
    "TODO.md",
}

if relative in allowed_root_files or relative.startswith("docs/") or relative.startswith("tmp/") or relative.startswith(".kiro/"):
    sys.exit(0)

sys.stderr.write("Markdown files must live in docs/, tmp/, .kiro/, or the approved root filenames.\n")
sys.exit(2)
PY
