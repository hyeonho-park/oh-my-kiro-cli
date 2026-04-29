#!/usr/bin/env bash
set -euo pipefail

KIRO_HOME="${KIRO_HOME:-${HOME}/.kiro}"
META_FILE="${KIRO_HOME}/.oh-my-kiro-cli-meta"
BACKUP_DIR=""
MCP_MANAGED=""
AGENTS=(sisyphus oracle prometheus metis momus analyst hephaestus atlas executor designer qa-tester build-error-resolver code-reviewer librarian multimodal-looker explore writer)
STEERING_FILES=(AGENTS.md workflow.md delegation.md constraints.md verification.md coding-style.md git-workflow.md testing.md patterns.md)
PROMPT_FILES=(sisyphus-system.md planner.md start-work.md handoff.md code-review.md ralph-loop.md ulw-loop.md refactor.md build-fix.md agents/oracle.md agents/analyst.md agents/code-reviewer.md agents/explore.md agents/librarian.md agents/metis.md agents/momus.md agents/multimodal-looker.md agents/atlas.md agents/build-error-resolver.md agents/designer.md agents/executor.md agents/hephaestus.md agents/prometheus.md agents/qa-tester.md agents/writer.md)
SKILLS=(orchestrate ultrawork ralph planner deepsearch git-master frontend-ui-ux playwright strategic-compact tdd-workflow verification-loop iterative-retrieval skill-creator handoff slack-to-jira slack-to-wiki briefing)
SCRIPTS=(atlassian_cli.py)
HOOK_ROOT="${KIRO_HOME}/hooks/oh-my-kiro-cli"

log() { echo "[oh-my-kiro-cli] $1"; }

restore_or_remove() {
  local target="$1"
  local relative="$2"
  local backup="$BACKUP_DIR/$relative"
  local symlink_backup="$BACKUP_DIR/${relative}.symlink"

  rm -rf "$target"

  if [ -n "$BACKUP_DIR" ]; then
    mkdir -p "$(dirname "$target")"
    if [ -f "$symlink_backup" ]; then
      ln -s "$(cat "$symlink_backup")" "$target"
    elif [ -e "$backup" ]; then
      if [ -d "$backup" ]; then
        cp -R "$backup" "$target"
      else
        cp "$backup" "$target"
      fi
    fi
  fi
}

if [ -f "$META_FILE" ]; then
  BACKUP_DIR="$(grep '^backup_dir=' "$META_FILE" | cut -d= -f2-)"
  MCP_MANAGED="$(grep '^mcp_managed=' "$META_FILE" | cut -d= -f2- || true)"
  hook_override="$(grep '^install_hook_root=' "$META_FILE" | cut -d= -f2- || true)"
  if [ -n "$hook_override" ]; then
    HOOK_ROOT="$hook_override"
  fi
fi

for agent in "${AGENTS[@]}"; do
  restore_or_remove "$KIRO_HOME/agents/${agent}.json" "agents/${agent}.json"
done

for file in "${STEERING_FILES[@]}"; do
  restore_or_remove "$KIRO_HOME/steering/${file}" "steering/${file}"
done

for file in "${PROMPT_FILES[@]}"; do
  restore_or_remove "$KIRO_HOME/prompts/${file}" "prompts/${file}"
done

for skill in "${SKILLS[@]}"; do
  restore_or_remove "$KIRO_HOME/skills/${skill}" "skills/${skill}"
done

CUSTOM_SKILLS_LINE="$(grep '^custom_skills=' "$META_FILE" 2>/dev/null | cut -d= -f2- || true)"
if [ -n "$CUSTOM_SKILLS_LINE" ]; then
  read -ra CUSTOM_SKILLS <<< "$CUSTOM_SKILLS_LINE"
  for skill in "${CUSTOM_SKILLS[@]}"; do
    restore_or_remove "$KIRO_HOME/skills/${skill}" "skills/${skill}"
  done
fi

for script in "${SCRIPTS[@]}"; do
  restore_or_remove "$KIRO_HOME/scripts/${script}" "scripts/${script}"
done

restore_or_remove "$HOOK_ROOT" "hooks/oh-my-kiro-cli"
restore_or_remove "$KIRO_HOME/settings/cli.json" "settings/cli.json"
if [ "$MCP_MANAGED" = "1" ]; then
  restore_or_remove "$KIRO_HOME/settings/mcp.json" "settings/mcp.json"
fi
rm -f "$META_FILE"

log "Removed oh-my-kiro-cli assets from ${KIRO_HOME}"
if [ -n "$BACKUP_DIR" ]; then
  log "Restored files from ${BACKUP_DIR} when backups were available"
fi
