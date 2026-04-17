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

operations = tool_input.get("operations", [])
if not isinstance(operations, list):
    operations = []

path_field = tool_input.get("path", "")
all_paths = [path_field] if path_field else []

for op in operations:
    if isinstance(op, dict):
        p = op.get("path", "")
        if p:
            all_paths.append(p)

ALLOWED_WIKI_PREFIX = os.path.join(os.path.expanduser("~"), ".kiro", "wikis") + os.sep

for p in all_paths:
    if ".." in p.split(os.sep):
        sys.stderr.write(
            f"BLOCKED: Path traversal detected ({p}).\n"
            f"Paths containing '..' are not allowed.\n"
        )
        sys.exit(2)

    if "wiki" in p or "schema/manifest.json" in p:
        expanded = os.path.realpath(os.path.expanduser(p)) if not p.startswith("/") else p
        normalized = os.path.normpath(os.path.expanduser(p))
        if not (normalized + os.sep).startswith(ALLOWED_WIKI_PREFIX) and not normalized.startswith(ALLOWED_WIKI_PREFIX.rstrip(os.sep)):
            sys.stderr.write(
                f"BLOCKED: Direct wiki access detected ({p}).\n"
                f"Wiki access is only allowed under {ALLOWED_WIKI_PREFIX}.\n"
                f"Delegate to kb-searcher agent instead.\n"
            )
            sys.exit(2)

sys.exit(0)
PY