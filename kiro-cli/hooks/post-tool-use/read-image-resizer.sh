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
if isinstance(tool_input, dict):
    ops = tool_input.get("operations")
    if isinstance(ops, list) and ops:
        path = ops[0].get("path", "")
    if not path:
        path = tool_input.get("path") or tool_input.get("file_path") or ""

if not path:
    sys.exit(0)

image_extensions = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".svg"}
ext = ""
dot_idx = path.rfind(".")
if dot_idx >= 0:
    ext = path[dot_idx:].lower()

if ext not in image_extensions:
    sys.exit(0)

from pathlib import Path
p = Path(path)
if not p.exists():
    sys.exit(0)

size_bytes = p.stat().st_size
size_kb = size_bytes / 1024

info_parts = [f"Image: {p.name}", f"Size: {size_kb:.0f}KB"]

try:
    import struct
    with open(p, "rb") as f:
        header = f.read(32)
    if ext == ".png" and header[:8] == b'\x89PNG\r\n\x1a\n':
        w = struct.unpack(">I", header[16:20])[0]
        h = struct.unpack(">I", header[20:24])[0]
        info_parts.append(f"Dimensions: {w}x{h}")
    elif ext in {".jpg", ".jpeg"}:
        with open(p, "rb") as f:
            f.read(2)
            while True:
                marker = f.read(2)
                if len(marker) < 2:
                    break
                if marker[0] != 0xFF:
                    break
                if marker[1] in (0xC0, 0xC1, 0xC2):
                    f.read(3)
                    h = struct.unpack(">H", f.read(2))[0]
                    w = struct.unpack(">H", f.read(2))[0]
                    info_parts.append(f"Dimensions: {w}x{h}")
                    break
                else:
                    length = struct.unpack(">H", f.read(2))[0]
                    f.read(length - 2)
except Exception:
    pass

estimated_tokens = int(size_kb * 1.5)
info_parts.append(f"~{estimated_tokens} tokens")

sys.stderr.write(" | ".join(info_parts) + "\n")
sys.exit(0)
PY
