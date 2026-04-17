#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="${SCRIPT_DIR}/kiro-cli"
KIRO_HOME="${KIRO_HOME:-${HOME}/.kiro}"
INSTALL_HOOK_ROOT="${KIRO_HOME}/hooks/oh-my-kiro-cli"
BACKUP_DIR="${KIRO_HOME}/backups/oh-my-kiro-cli-$(date +%Y%m%d-%H%M%S)"
META_FILE="${KIRO_HOME}/.oh-my-kiro-cli-meta"

AGENTS=(sisyphus oracle prometheus metis momus analyst hephaestus atlas executor designer qa-tester build-error-resolver code-reviewer librarian multimodal-looker explore writer kb-searcher kb-curator)
STEERING_FILES=(AGENTS.md workflow.md delegation.md constraints.md verification.md coding-style.md git-workflow.md testing.md patterns.md)
PROMPT_FILES=(sisyphus-system.md planner.md start-work.md handoff.md code-review.md ralph-loop.md ulw-loop.md refactor.md build-fix.md agents/oracle.md agents/analyst.md agents/code-reviewer.md agents/explore.md agents/librarian.md agents/metis.md agents/momus.md agents/multimodal-looker.md agents/atlas.md agents/build-error-resolver.md agents/designer.md agents/executor.md agents/hephaestus.md agents/prometheus.md agents/qa-tester.md agents/writer.md kb-create.md kb-update.md kb-delete.md kb-query.md kb-lint.md agents/kb-searcher.md agents/kb-curator.md)
SKILLS=(orchestrate ultrawork ralph planner deepsearch git-master frontend-ui-ux playwright strategic-compact tdd-workflow verification-loop iterative-retrieval skill-creator handoff kb-create kb-update kb-delete kb-query kb-lint)

log() { echo "[oh-my-kiro-cli] $1"; }
warn() { echo "[oh-my-kiro-cli] WARNING: $1" >&2; }

backup_path() {
  local target="$1"
  local relative="$2"
  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return
  fi

  mkdir -p "$BACKUP_DIR/$(dirname "$relative")"
  if [ -L "$target" ]; then
    printf '%s\n' "$(readlink "$target")" > "$BACKUP_DIR/${relative}.symlink"
  elif [ -d "$target" ]; then
    cp -R "$target" "$BACKUP_DIR/$relative"
  else
    cp "$target" "$BACKUP_DIR/$relative"
  fi
}

install_file() {
  local source="$1"
  local target="$2"
  local relative="$3"
  backup_path "$target" "$relative"
  mkdir -p "$(dirname "$target")"
  cp "$source" "$target"
}

render_agent() {
  local source_file="$1"
  local target_file="$2"
  local relative="$3"
  backup_path "$target_file" "$relative"
  mkdir -p "$(dirname "$target_file")"
  python3 - "$source_file" "$target_file" "$KIRO_HOME/steering/**/*.md" "$INSTALL_HOOK_ROOT" "$KIRO_HOME" <<'PY'
import json
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
steering_glob = sys.argv[3]
hook_root = sys.argv[4]
kiro_home = sys.argv[5]

data = json.loads(source.read_text())
rendered = json.dumps(data)
rendered = rendered.replace("__OH_MY_KIRO_STEERING_GLOB__", f"file://{steering_glob}")
rendered = rendered.replace("__OH_MY_KIRO_HOOK_ROOT__", hook_root)
rendered = rendered.replace("~/.kiro/", f"{kiro_home}/")
target.write_text(json.dumps(json.loads(rendered), indent=2) + "\n")
PY
}

merge_cli_settings() {
  local source="$1"
  local target="$2"
  local relative="$3"
  backup_path "$target" "$relative"
  mkdir -p "$(dirname "$target")"
  python3 - "$source" "$target" <<'PY'
import json
import sys
from pathlib import Path

source_path = Path(sys.argv[1])
target_path = Path(sys.argv[2])
source = json.loads(source_path.read_text())
if target_path.exists():
    target = json.loads(target_path.read_text())
else:
    target = {}

def merge(dst, src):
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(dst.get(key), dict):
            merge(dst[key], value)
        else:
            dst[key] = value

merge(target, source)
target_path.write_text(json.dumps(target, indent=2) + "\n")
PY
}

mkdir -p "$KIRO_HOME/agents" "$KIRO_HOME/steering" "$KIRO_HOME/prompts" "$KIRO_HOME/skills" "$KIRO_HOME/settings" "$KIRO_HOME/hooks" "$KIRO_HOME/backups"
log "Backing up conflicting files to ${BACKUP_DIR}"

MCP_MANAGED=0

for agent in "${AGENTS[@]}"; do
  render_agent "$SOURCE_ROOT/agents/${agent}.json" "$KIRO_HOME/agents/${agent}.json" "agents/${agent}.json"
done
log "Installed ${#AGENTS[@]} agents"

for file in "${STEERING_FILES[@]}"; do
  install_file "$SOURCE_ROOT/steering/${file}" "$KIRO_HOME/steering/${file}" "steering/${file}"
done
log "Installed ${#STEERING_FILES[@]} steering files"

for file in "${PROMPT_FILES[@]}"; do
  install_file "$SOURCE_ROOT/prompts/${file}" "$KIRO_HOME/prompts/${file}" "prompts/${file}"
done
log "Installed ${#PROMPT_FILES[@]} prompts"

for skill in "${SKILLS[@]}"; do
  skill_source_dir="$SOURCE_ROOT/skills/${skill}"
  skill_target_dir="$KIRO_HOME/skills/${skill}"
  if [ -f "$skill_source_dir/SKILL.md" ]; then
    backup_path "$skill_target_dir" "skills/${skill}"
    mkdir -p "$skill_target_dir"
    rsync -a --exclude='__pycache__' "$skill_source_dir/" "$skill_target_dir/"
  fi
done
log "Installed ${#SKILLS[@]} skills"

# Install kb references and wiki-schema templates
if [[ -d "$SOURCE_ROOT/skills/references" ]]; then
  mkdir -p "$KIRO_HOME/skills/references/wiki-schema"
  cp "$SOURCE_ROOT/skills/references/SCHEMA_CHEATSHEET.md" "$KIRO_HOME/skills/references/"
  cp "$SOURCE_ROOT/skills/references/WIKI_ANALYSIS_KNOWLEDGE.md" "$KIRO_HOME/skills/references/"
  cp "$SOURCE_ROOT/skills/references/wiki-schema/"* "$KIRO_HOME/skills/references/wiki-schema/"
fi

# Create wikis parent directory for kb-* multi-wiki support
mkdir -p "$KIRO_HOME/wikis"

merge_cli_settings "$SOURCE_ROOT/settings/cli.json" "$KIRO_HOME/settings/cli.json" "settings/cli.json"
log "Merged CLI settings"

if [ ! -f "$KIRO_HOME/settings/mcp.json" ]; then
  install_file "$SOURCE_ROOT/settings/mcp.json" "$KIRO_HOME/settings/mcp.json" "settings/mcp.json"
  MCP_MANAGED=1
  log "Installed MCP settings"
else
  warn "Leaving existing settings/mcp.json unchanged"
fi

backup_path "$INSTALL_HOOK_ROOT" "hooks/oh-my-kiro-cli"
rm -rf "$INSTALL_HOOK_ROOT"
mkdir -p "$INSTALL_HOOK_ROOT"
cp -R "$SOURCE_ROOT/hooks/." "$INSTALL_HOOK_ROOT/"
find "$INSTALL_HOOK_ROOT" -type f -name '*.sh' -exec chmod +x {} +
log "Installed hooks"

cat > "$META_FILE" <<EOF
installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
backup_dir=${BACKUP_DIR}
install_hook_root=${INSTALL_HOOK_ROOT}
agents=${AGENTS[*]}
steering=${STEERING_FILES[*]}
prompts=${PROMPT_FILES[*]}
skills=${SKILLS[*]}
mcp_managed=${MCP_MANAGED}
references_managed=1
EOF

SHELL_RC=""
if [ -n "${ZSH_VERSION:-}" ] || [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
  if ! grep -q 'alias omk=' "$SHELL_RC" 2>/dev/null; then
    printf '\nalias omk="kiro-cli --agent sisyphus --classic"\n' >> "$SHELL_RC"
    log "Added 'omk' alias to ${SHELL_RC}"
  else
    log "Alias 'omk' already exists in ${SHELL_RC}"
  fi
fi

log ""
log "=== Installation Complete ==="
log "Installed to: ${KIRO_HOME}"
log "  Agents:   ${#AGENTS[@]}"
log "  Steering: ${#STEERING_FILES[@]}"
log "  Prompts:  ${#PROMPT_FILES[@]}"
log "  Skills:   ${#SKILLS[@]}"
log "  Hooks:    12"
log "Backup: ${BACKUP_DIR}"
log ""
log "Run 'source ${SHELL_RC:-~/.zshrc}' then type 'omk' to start."

# Graphify hint
if ! command -v graphify &>/dev/null; then
  echo "Hint: install graphify with 'pip install graphifyy' for wiki graph features."
fi
