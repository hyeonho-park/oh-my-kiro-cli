#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

PAYLOAD="$payload" python3 - <<'PY'
import json
import os
import re
import sys

payload = json.loads(os.environ["PAYLOAD"])
tool_input = payload.get("tool_input", {}) or {}

secret_patterns = [
    r"-----BEGIN (?:RSA|OPENSSH|EC|DSA|PGP) PRIVATE KEY-----",
    r"AKIA[0-9A-Z]{16}",
    r"ASIA[0-9A-Z]{16}",
    r"ghp_[A-Za-z0-9]{36}",
    r"github_pat_[A-Za-z0-9_]{20,}",
    r"xox[baprs]-[A-Za-z0-9-]{10,}",
    r"AIza[0-9A-Za-z\-_]{35}",
    r"(?i)(?:api[_-]?key|secret[_-]?key|access[_-]?key|auth[_-]?token|token|password)\s*[:=]\s*[\"']?[A-Za-z0-9_\-/+=]{16,}[\"']?",
]


def gather_contents(value):
    contents = []
    if isinstance(value, dict):
        ops = value.get("operations")
        if isinstance(ops, list):
            for op in ops:
                if isinstance(op, dict):
                    text = op.get("content") or op.get("data")
                    if isinstance(text, str) and text:
                        contents.append(text)
        for key in ("content", "data"):
            text = value.get(key)
            if isinstance(text, str) and text:
                contents.append(text)
    elif isinstance(value, str) and value:
        contents.append(value)
    return contents


contents = gather_contents(tool_input)
if not contents:
    sys.exit(0)

for content in contents:
    for pattern in secret_patterns:
        if re.search(pattern, content):
            sys.stderr.write(
                "Potential secret detected in write content. Remove credentials, keys, or tokens before writing files.\n"
            )
            sys.exit(2)

sys.exit(0)
PY
