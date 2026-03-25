#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import sys
from pathlib import Path

payload = json.loads(os.environ["PAYLOAD"])
cwd = payload.get("cwd")
if not cwd:
    sys.exit(0)

root = Path(cwd)
messages = []

tmp_dir = root / "tmp"
if tmp_dir.exists():
    temp_files = [path for path in tmp_dir.rglob("*") if path.is_file()]
    if temp_files:
        messages.append(f"tmp/ contains {len(temp_files)} file(s); clean up temporary artifacts before stopping if they are no longer needed.")

if messages:
    sys.stderr.write("\n".join(messages) + "\n")
    sys.exit(1)

sys.exit(0)
PY
