#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

tool_name=$(printf '%s' "$payload" | sed -n 's/.*"tool_name" *: *"\([^"]*\)".*/\1/p')
case "$tool_name" in
  write|fs_write) ;;
  *) exit 0 ;;
esac

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

if not path:
    sys.exit(0)

normalized = Path(path)
if normalized.is_absolute() and cwd:
    try:
        normalized = normalized.relative_to(Path(cwd))
    except ValueError:
        normalized = Path(normalized.as_posix().lstrip("/"))

name = normalized.name.lower()
looks_like_test = any(token in name for token in (".test.", ".spec.")) or name.startswith("test_")
if not looks_like_test:
    sys.exit(0)

path_text = normalized.as_posix()
allowed = path_text.startswith("tests/") or (path_text.startswith("packages/") and "/tests/" in path_text)
if allowed:
    sys.exit(0)

sys.stderr.write("Tests must be created under tests/ or packages/*/tests/.\n")
sys.exit(2)
PY
