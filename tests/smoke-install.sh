#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

readonly_agents=(oracle analyst code-reviewer explore librarian metis momus multimodal-looker prometheus)
execution_agents=(executor hephaestus designer qa-tester build-error-resolver writer)
externalized_agents=(atlas oracle analyst code-reviewer explore librarian metis momus multimodal-looker prometheus executor hephaestus designer qa-tester build-error-resolver writer)

run_clean_install_cycle() {
  local home_dir="$TMP_DIR/home-clean"
  local kiro_home="$TMP_DIR/kiro-home-clean"

  mkdir -p "$home_dir" "$kiro_home"
  : > "$home_dir/.zshrc"

  HOME="$home_dir" KIRO_HOME="$kiro_home" "$ROOT/install.sh"

  for agent in "${readonly_agents[@]}" atlas "${execution_agents[@]}"; do
    kiro-cli agent validate --path "$kiro_home/agents/${agent}.json"
  done

  python3 - <<'PY' "$kiro_home"
import json
import sys
from pathlib import Path

home = Path(sys.argv[1])
readonly_agents = ["oracle", "analyst", "code-reviewer", "explore", "librarian", "metis", "momus", "multimodal-looker", "prometheus"]
externalized_agents = ["atlas", "oracle", "analyst", "code-reviewer", "explore", "librarian", "metis", "momus", "multimodal-looker", "prometheus", "executor", "hephaestus", "designer", "qa-tester", "build-error-resolver", "writer"]
execution_agents = ["executor", "hephaestus", "designer", "qa-tester", "build-error-resolver", "writer"]

for name in externalized_agents:
    agent = json.loads((home / "agents" / f"{name}.json").read_text())
    expected = f"file://../prompts/agents/{name}.md"
    assert agent["prompt"] == expected, (name, agent["prompt"])
    assert (home / "prompts" / "agents" / f"{name}.md").exists(), name

for name in readonly_agents:
    agent = json.loads((home / "agents" / f"{name}.json").read_text())
    pre = agent.get("hooks", {}).get("preToolUse", [])
    assert any(item.get("matcher") == "shell" and "destructive-command-blocker.sh" in item.get("command", "") for item in pre), name

librarian = json.loads((home / "agents" / "librarian.json").read_text())
assert "web_search" in librarian["tools"], librarian["tools"]
assert "web_fetch" in librarian["tools"], librarian["tools"]
assert "web_search" in librarian["allowedTools"], librarian["allowedTools"]
assert "web_fetch" in librarian["allowedTools"], librarian["allowedTools"]

for agent_path in (home / "agents").glob("*.json"):
    if agent_path.stem == "librarian":
        continue
    data = json.loads(agent_path.read_text())
    assert "web_search" not in data.get("tools", []), agent_path.stem
    assert "web_fetch" not in data.get("tools", []), agent_path.stem
    assert "web_search" not in data.get("allowedTools", []), agent_path.stem
    assert "web_fetch" not in data.get("allowedTools", []), agent_path.stem

for name in execution_agents:
    agent = json.loads((home / "agents" / f"{name}.json").read_text())
    pre = agent.get("hooks", {}).get("preToolUse", [])
    assert any(item.get("matcher") == "fs_write" and "secret-leak-detector.sh" in item.get("command", "") for item in pre), name

hook = home / "hooks" / "oh-my-kiro-cli" / "pre-tool-use" / "destructive-command-blocker.sh"
assert hook.exists(), hook
secret_hook = home / "hooks" / "oh-my-kiro-cli" / "pre-tool-use" / "secret-leak-detector.sh"
assert secret_hook.exists(), secret_hook
zshrc = home.parent / "home-clean" / ".zshrc"
assert 'alias omk="kiro-cli --agent sisyphus"' in zshrc.read_text(), zshrc
print("clean-install-cycle: OK")
PY

  python3 - <<'PY' "$kiro_home"
import json
import subprocess
import sys
from pathlib import Path

home = Path(sys.argv[1])
destructive = home / "hooks" / "oh-my-kiro-cli" / "pre-tool-use" / "destructive-command-blocker.sh"
secret = home / "hooks" / "oh-my-kiro-cli" / "pre-tool-use" / "secret-leak-detector.sh"

checks = [
    (destructive, {"tool_input": {"command": "git push origin main"}}, 2),
    (destructive, {"tool_input": {"command": "git status"}}, 0),
    (secret, {"tool_input": {"content": "const token = \"ghp_abcdefghijklmnopqrstuvwxyz1234567890\";"}}, 2),
    (secret, {"tool_input": {"content": "const status = \"ok\";"}}, 0),
]

for hook, payload, expected in checks:
    proc = subprocess.run([str(hook)], input=json.dumps(payload).encode(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != expected:
        raise SystemExit(f"{hook.name} expected {expected}, got {proc.returncode}")

print("hook-behavior-check: OK")
PY

  HOME="$home_dir" KIRO_HOME="$kiro_home" "$ROOT/uninstall.sh"

  python3 - <<'PY' "$kiro_home"
from pathlib import Path
import sys

home = Path(sys.argv[1])
externalized_agents = ["atlas", "oracle", "analyst", "code-reviewer", "explore", "librarian", "metis", "momus", "multimodal-looker", "prometheus", "executor", "hephaestus", "designer", "qa-tester", "build-error-resolver", "writer"]

for name in externalized_agents:
    assert not (home / "prompts" / "agents" / f"{name}.md").exists(), name

assert not (home / "hooks" / "oh-my-kiro-cli").exists(), "hook namespace should be removed on uninstall"
assert not (home / "settings" / "mcp.json").exists(), home / "settings" / "mcp.json"
zshrc = home.parent / "home-clean" / ".zshrc"
assert 'alias omk="kiro-cli --agent sisyphus"' in zshrc.read_text(), zshrc
print("clean-uninstall-cycle: OK")
PY
}

run_existing_mcp_preserve_check() {
  local home_dir="$TMP_DIR/home-mcp"
  local kiro_home="$TMP_DIR/kiro-home-mcp"
  local mcp_file="$kiro_home/settings/mcp.json"

  mkdir -p "$home_dir" "$kiro_home/settings"
  printf '{"sentinel":true}\n' > "$mcp_file"

  HOME="$home_dir" KIRO_HOME="$kiro_home" "$ROOT/install.sh"

  python3 - <<'PY' "$mcp_file"
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())
assert data == {"sentinel": True}, data
print("mcp-preserve-check: OK")
PY

  HOME="$home_dir" KIRO_HOME="$kiro_home" "$ROOT/uninstall.sh"

  python3 - <<'PY' "$mcp_file"
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())
assert data == {"sentinel": True}, data
print("mcp-uninstall-preserve-check: OK")
PY
}

run_clean_install_cycle
run_existing_mcp_preserve_check

echo "smoke-install.sh: OK"
