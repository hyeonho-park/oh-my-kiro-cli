#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

readonly_agents=(oracle analyst code-reviewer explore librarian metis momus multimodal-looker prometheus)
execution_agents=(executor hephaestus designer qa-tester build-error-resolver writer)
externalized_agents=(atlas oracle analyst code-reviewer explore librarian metis momus multimodal-looker prometheus executor hephaestus designer qa-tester build-error-resolver writer)

destructive_hook="$ROOT/kiro-cli/hooks/pre-tool-use/destructive-command-blocker.sh"
secret_hook="$ROOT/kiro-cli/hooks/pre-tool-use/secret-leak-detector.sh"

fail() {
  echo "[validate] $1" >&2
  exit 1
}

[[ -f "$destructive_hook" ]] || fail "missing destructive-command-blocker hook"
[[ -x "$destructive_hook" ]] || fail "destructive-command-blocker hook is not executable"
[[ -f "$secret_hook" ]] || fail "missing secret-leak-detector hook"
[[ -x "$secret_hook" ]] || fail "secret-leak-detector hook is not executable"

python3 - <<'PY' "$ROOT"
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
agents_dir = root / "kiro-cli" / "agents"
prompts_dir = root / "kiro-cli" / "prompts" / "agents"

sisyphus = json.loads((agents_dir / "sisyphus.json").read_text())
if sisyphus.get("prompt") != "file://../prompts/sisyphus-system.md":
    raise SystemExit(f"sisyphus prompt mismatch: {sisyphus.get('prompt')!r}")

readonly_agents = ["oracle", "analyst", "code-reviewer", "explore", "librarian", "metis", "momus", "multimodal-looker", "prometheus"]
execution_agents = ["executor", "hephaestus", "designer", "qa-tester", "build-error-resolver", "writer"]
externalized_agents = ["atlas", "oracle", "analyst", "code-reviewer", "explore", "librarian", "metis", "momus", "multimodal-looker", "prometheus", "executor", "hephaestus", "designer", "qa-tester", "build-error-resolver", "writer"]
orchestrators = ["sisyphus", "atlas"]

for name in orchestrators:
    data = json.loads((agents_dir / f"{name}.json").read_text())
    if "write" in data.get("allowedTools", []):
        raise SystemExit(f"orchestrator {name} should not allow write")
    if "shell" in data.get("allowedTools", []):
        raise SystemExit(f"orchestrator {name} should not allow shell")

for name in execution_agents:
    data = json.loads((agents_dir / f"{name}.json").read_text())
    if "write" not in data.get("allowedTools", []):
        raise SystemExit(f"execution agent {name} missing write")

for name in externalized_agents:
    data = json.loads((agents_dir / f"{name}.json").read_text())
    expected_prompt = f"file://../prompts/agents/{name}.md"
    if data.get("prompt") != expected_prompt:
        raise SystemExit(f"agent {name} prompt mismatch: {data.get('prompt')!r}")

    prompt_file = prompts_dir / f"{name}.md"
    if not prompt_file.exists():
        raise SystemExit(f"missing prompt file: {prompt_file}")

for name in readonly_agents:
    data = json.loads((agents_dir / f"{name}.json").read_text())
    if name != "librarian" and "web_search" in data.get("allowedTools", []):
        raise SystemExit(f"READ-ONLY agent {name} should not allow web_search")
    if name != "librarian" and "web_fetch" in data.get("allowedTools", []):
        raise SystemExit(f"READ-ONLY agent {name} should not allow web_fetch")
    if name != "librarian" and "write" in data.get("allowedTools", []):
        raise SystemExit(f"READ-ONLY agent {name} should not allow write")
    pre = data.get("hooks", {}).get("preToolUse", [])
    if not any(item.get("matcher") == "shell" and "destructive-command-blocker.sh" in item.get("command", "") for item in pre):
        raise SystemExit(f"agent {name} missing destructive shell pre-hook")

for name in execution_agents:
    data = json.loads((agents_dir / f"{name}.json").read_text())
    pre = data.get("hooks", {}).get("preToolUse", [])
    if not any(item.get("matcher") == "fs_write" and "secret-leak-detector.sh" in item.get("command", "") for item in pre):
        raise SystemExit(f"agent {name} missing secret leak fs_write pre-hook")

prometheus = json.loads((agents_dir / "prometheus.json").read_text())
prom_post = prometheus.get("hooks", {}).get("postToolUse", [])
if not any(item.get("matcher") == "use_subagent" and "empty-subagent-response-detector.sh" in item.get("command", "") for item in prom_post):
    raise SystemExit("prometheus missing empty-subagent-response-detector post-hook")
if not any(item.get("matcher") == "use_subagent" and "delegate-retry-guidance.sh" in item.get("command", "") for item in prom_post):
    raise SystemExit("prometheus missing delegate-retry-guidance post-hook")

librarian = json.loads((agents_dir / "librarian.json").read_text())
for tool_name in ("web_search", "web_fetch"):
    if tool_name not in librarian.get("tools", []):
        raise SystemExit(f"librarian missing tool: {tool_name}")
    if tool_name not in librarian.get("allowedTools", []):
        raise SystemExit(f"librarian missing allowed tool: {tool_name}")

for agent_file in agents_dir.glob("*.json"):
    if agent_file.stem == "librarian":
        continue
    data = json.loads(agent_file.read_text())
    for tool_name in ("web_search", "web_fetch"):
        if tool_name in data.get("tools", []) or tool_name in data.get("allowedTools", []):
            raise SystemExit(f"{agent_file.stem} should not expose specialist tool: {tool_name}")

# use_subagent must not appear in any agent's tools or allowedTools (only orchestrators invoke subagents via the runtime)
for agent_file in agents_dir.glob("*.json"):
    data = json.loads(agent_file.read_text())
    if "use_subagent" in data.get("tools", []) or "use_subagent" in data.get("allowedTools", []):
        raise SystemExit(f"{agent_file.stem} must not list use_subagent in tools/allowedTools")

install_text = (root / "install.sh").read_text()
uninstall_text = (root / "uninstall.sh").read_text()
for name in externalized_agents:
    rel = f"agents/{name}.md"
    if rel not in install_text:
        raise SystemExit(f"install.sh missing prompt inventory entry: {rel}")
    if rel not in uninstall_text:
        raise SystemExit(f"uninstall.sh missing prompt inventory entry: {rel}")

if "mcp_managed=" not in install_text:
    raise SystemExit("install.sh missing mcp_managed metadata field")
if 'MCP_MANAGED="$(grep \'^mcp_managed=' not in uninstall_text:
    raise SystemExit("uninstall.sh missing mcp_managed metadata read")
if 'if [ "$MCP_MANAGED" = "1" ]; then' not in uninstall_text:
    raise SystemExit("uninstall.sh missing conditional mcp ownership check")

print("validate.sh: OK")
PY
