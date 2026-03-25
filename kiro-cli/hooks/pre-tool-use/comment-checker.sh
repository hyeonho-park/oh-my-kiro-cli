#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["PAYLOAD"])
tool_input = payload.get("tool_input", {}) or {}

path = ""
content = ""
if isinstance(tool_input, dict):
    ops = tool_input.get("operations")
    if isinstance(ops, list) and ops:
        path = ops[0].get("path", "")
        content = ops[0].get("content", "")
    if not path:
        path = tool_input.get("path") or tool_input.get("file_path") or ""
    if not content:
        content = tool_input.get("content") or tool_input.get("data") or ""

if not path:
    sys.exit(0)

code_extensions = {
    ".ts", ".tsx", ".js", ".jsx", ".py", ".go", ".rs",
    ".java", ".kt", ".swift", ".c", ".cpp", ".h",
}
ext = ""
dot_idx = path.rfind(".")
if dot_idx >= 0:
    ext = path[dot_idx:]

if ext not in code_extensions:
    sys.exit(0)

if not content:
    sys.exit(0)

lines = content.split("\n")
total = len(lines)
if total == 0:
    sys.exit(0)

comment_count = 0
for line in lines:
    stripped = line.lstrip()
    if stripped.startswith("//") or stripped.startswith("#") or stripped.startswith("/*") or stripped.startswith("*") or stripped.startswith("<!--"):
        comment_count += 1

ratio = comment_count * 100 // total
if ratio > 30:
    sys.stderr.write(
        f"Comment ratio is {ratio}% ({comment_count}/{total} lines). "
        "Code should speak for itself. Comments should explain WHY, not WHAT.\n"
    )

sys.exit(0)
PY
