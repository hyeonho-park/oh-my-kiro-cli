# Migration Guide

Guide for applying updates from oh-my-openagent (or the Claude Code version of oh-my-settings) into oh-my-kiro-cli.

This document is written so that an LLM agent can perform the migration work automatically.

---

## Source and Target

| Item | Path |
|------|------|
| **Source (Claude Code)** | `~/workspace/claude-code-settings/oh-my-settings/claude-<version>/` |
| **Target (Kiro CLI)** | `~/workspace/oh-my-kiro-cli/kiro-cli/` |
| **Source GitHub** | https://github.com/code-yeongyu/oh-my-openagent |

---

## Agent Architecture (Kiro-specific)

Kiro CLI divides agents into 3 categories. Claude Code does not have this distinction.

### Orchestrators (sisyphus, atlas)

They have no direct tools. They only work through `use_subagent`.

```json
{
  "tools": ["subagent", "thinking", "todo"],
  "allowedTools": ["subagent", "thinking", "todo"],
  "toolsSettings": {
    "subagent": {
      "availableAgents": ["oracle", "executor", "explore", ...],
      "trustedAgents": ["oracle", "executor", "explore", ...]
    }
  }
}
```

- `availableAgents`: list of subagents that can be spawned. `kiro_default` excluded.
- `trustedAgents`: spawned immediately without confirmation. Typically the full availableAgents list.
- No `read`, `write`, `shell`, `glob`, `grep` — direct work is not possible.

### Executors (executor, hephaestus, designer, qa-tester, build-error-resolver, writer)

The executor tier consists of agents capable of `write`. They commonly use `read`, `glob`, `grep`, `shell`, and `write`, and additional allowed tools may differ by role. Working-directory write is allowed and `rm` is blocked by default.

```json
{
  "tools": ["*"],
  "allowedTools": ["read", "glob", "grep", "shell", "write"],
  "toolsSettings": {
    "write": { "allowedPaths": ["./**"] },
    "shell": {
      "autoAllowReadonly": true,
      "deniedCommands": ["rm .*", "rm -.*"],
      "allowedCommands": ["trash .*"]
    }
  }
}
```

### READ-ONLY (oracle, analyst, code-reviewer, explore, librarian, metis, momus, multimodal-looker, prometheus)

By default they only use read tools and cannot write. Currently, only `librarian` additionally uses `web_search` and `web_fetch` as a specialist pilot.

```json
{
  "tools": ["read", "glob", "grep", "shell"],
  "allowedTools": ["read", "glob", "grep", "shell"]
}
```

prometheus additionally has `subagent` and `thinking` (used to call metis/momus).

---

## Component Mapping Table

### Agents: `agents/*.md` → `agents/*.json`

| Claude Source | Kiro Target | Category |
|---------------|-------------|------|
| _(extracted from CLAUDE.md)_ | `agents/sisyphus.json` | Orchestrator |
| `agents/atlas.md` | `agents/atlas.json` | Orchestrator |
| `agents/executor.md` | `agents/executor.json` | Executor |
| `agents/hephaestus.md` | `agents/hephaestus.json` | Executor |
| `agents/designer.md` | `agents/designer.json` | Executor |
| `agents/qa-tester.md` | `agents/qa-tester.json` | Executor |
| `agents/build-error-resolver.md` | `agents/build-error-resolver.json` | Executor |
| `agents/writer.md` | `agents/writer.json` | Executor |
| `agents/oracle.md` | `agents/oracle.json` | READ-ONLY |
| `agents/prometheus.md` | `agents/prometheus.json` | READ-ONLY (+subagent) |
| `agents/metis.md` | `agents/metis.json` | READ-ONLY |
| `agents/momus.md` | `agents/momus.json` | READ-ONLY |
| `agents/analyst.md` | `agents/analyst.json` | READ-ONLY |
| `agents/code-reviewer.md` | `agents/code-reviewer.json` | READ-ONLY |
| `agents/librarian.md` | `agents/librarian.json` | READ-ONLY |
| `agents/multimodal-looker.md` | `agents/multimodal-looker.json` | READ-ONLY |
| `agents/explore.md` | `agents/explore.json` | READ-ONLY |

### Conversion Rules: Agent MD → Agent JSON

**Model name mapping:**

| Claude | Kiro CLI |
|--------|----------|
| `opus` | `claude-opus-4.7` |
| `sonnet` | `claude-sonnet-4.6` |
| `haiku` | `claude-haiku-4.5` |

**Tool name mapping:**

| Claude Tool | Kiro Tool | Notes |
|-------------|-----------|-------|
| `Read` | `read` | |
| `Grep` | `grep` | |
| `Glob` | `glob` | |
| `Edit`/`Write` | `write` | |
| `Bash` | `shell` | |
| `TodoWrite` | `todo` | Kiro builtin |
| `WebSearch`/`WebFetch` | `web_search` / `web_fetch` | Currently used only by the `librarian` pilot |
| `Task` (subagent) | `subagent` | `use_subagent` tool |

**Per-category conversion:**

When converting to an orchestrator:
1. Set `tools`/`allowedTools` to `["subagent", "thinking", "todo"]`
2. Set `availableAgents`/`trustedAgents` under `toolsSettings.subagent`
3. Remove direct tools such as `read`, `write`, `shell`

When converting to an executor:
1. Set `tools` to `["*"]`
2. Include `read`, `glob`, `grep`, `shell`, `write` in `allowedTools`
3. `toolsSettings.write.allowedPaths = ["./**"]`
4. `toolsSettings.shell`: `autoAllowReadonly=true`, `deniedCommands=["rm .*"]`, `allowedCommands=["trash .*"]`

When converting to READ-ONLY:
1. Set `tools`/`allowedTools` identically to `["read", "glob", "grep", "shell"]`
2. Exclude the `write` tool

**Common fields:**

| Field | Value | Notes |
|------|-----|-------|
| `resources` | `["__OH_MY_KIRO_STEERING_GLOB__", "file://.kiro/steering/**/*.md"]` | global + workspace steering |
| `includeMcpJson` | `true` (only `explore` uses `false`) | |

### Hook Assignment

A total of 12 hook scripts. Hooks with a matcher only fire after the corresponding tool call.

| Agent Category | preToolUse (fs_write) | postToolUse | stop |
|-------------|-----------|-------------|------|
| Orchestrators (sisyphus, atlas) | _(none)_ | context-window-reminder, empty-subagent-response-detector (use_subagent), delegate-retry-guidance (use_subagent) | todo-continuation |
| Executors (executor, hephaestus, build-error-resolver) | comment-checker, doc-blocker, test-location-validator, secret-leak-detector | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| Executors (designer, writer) | comment-checker, doc-blocker, secret-leak-detector | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| Executors (qa-tester) | comment-checker, test-location-validator, secret-leak-detector | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| READ-ONLY (8 agents) | destructive-command-blocker (shell) | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(none)_ |
| prometheus (READ-ONLY + subagent) | destructive-command-blocker (shell) | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read), empty-subagent-response-detector (use_subagent), delegate-retry-guidance (use_subagent) | _(none)_ |

---

### Skills: `skills/*/SKILL.md` → `skills/*/SKILL.md`

Almost identical format. Conversion:

1. Remove the `user-invocable` field
2. Add trigger keywords to `description` ("Use when the user says ...")
3. In the body, replace `Task(agent=...)` with a `use_subagent` subagent call
4. Replace `SubAgent` references with `use_subagent` tool calls
5. Claude tool names → Kiro tool names

### Commands: `commands/*.md` → `prompts/*.md`

| Claude Source | Kiro Target | Invocation |
|---------------|-------------|-----------|
| `commands/ralph-loop.md` | `prompts/ralph-loop.md` | `@ralph-loop` |
| `commands/ulw-loop.md` | `prompts/ulw-loop.md` | `@ulw-loop` |
| `commands/refactor.md` | `prompts/refactor.md` | `@refactor` |
| `commands/start-work.md` | `prompts/start-work.md` | `@start-work` |
| `commands/handoff.md` | `prompts/handoff.md` | `@handoff` |
| `commands/code-review.md` | `prompts/code-review.md` | `@code-review` |
| `commands/build-fix.md` | `prompts/build-fix.md` | `@build-fix` |
| `commands/checkpoint.md` | _(not ported)_ | Kiro builtin `/checkpoint` |

Conversion: remove YAML frontmatter, replace `/command` with `@prompt-name`, and replace `Task(agent=...)` with a `use_subagent` call.

### Current rollout status

- `sisyphus` continues to use `prompts/sisyphus-system.md` as before.
- All 16 agents other than `sisyphus` have been externalized to `prompts/agents/*.md`.
- `prometheus` is still a special case for `use_subagent` post-hooks, but its prompt is sourced from an external file.
- secret detection was added as an executor-tier `fs_write` pre-hook.
- `librarian` uses `web_search` and `web_fetch` as a specialist pilot.
- `settings/mcp.json` is preserved on both install and uninstall when the file pre-exists, and is only removed on uninstall when oh-my-kiro-cli installed it directly.
- The `alias omk` follows the install-only policy and is not automatically removed on uninstall.

### Hooks: `hooks/**/*.sh` → `hooks/**/*.sh`

A total of 12 hook scripts:

| Hook | Lifecycle | Matcher | Origin |
|---|---|---|---|
| comment-checker | preToolUse | fs_write | Claude Code hooks |
| doc-blocker | preToolUse | fs_write | Claude Code hooks |
| test-location-validator | preToolUse | fs_write | Claude Code hooks |
| destructive-command-blocker | preToolUse | shell | oh-my-kiro-cli Phase 1 |
| secret-leak-detector | preToolUse | fs_write | oh-my-kiro-cli Phase 1 |
| context-window-reminder | postToolUse | _(all)_ | Claude Code hooks |
| agent-usage-reminder | postToolUse | glob/grep | Claude Code hooks |
| read-image-resizer | postToolUse | read | Claude Code hooks |
| empty-subagent-response-detector | postToolUse | use_subagent | oh-my-openagent empty-task-response-detector |
| delegate-retry-guidance | postToolUse | use_subagent | oh-my-openagent delegate-task-retry |
| todo-continuation | stop | _(all)_ | Claude Code hooks |
| cleanup-prompt | stop | _(all)_ | Claude Code hooks |

Hooks are converted to the Kiro stdin JSON format. Claude uses env vars/arguments; Kiro uses JSON over stdin.

```bash
#!/usr/bin/env bash
set -euo pipefail
payload="$(cat)"
PAYLOAD="$payload" python3 - <<'PY'
import json, os, sys
payload = json.loads(os.environ["PAYLOAD"])
tool_input = payload.get("tool_input", {}) or {}
# ... logic ...
PY
```

Exit codes: `0`=allow, `2`=block (preToolUse only), others=warning.

### Rules: `rules/*.md` → `steering/*.md`

Strip YAML frontmatter, convert to plain markdown.

### CLAUDE.md → Split

| CLAUDE.md Section | Kiro Target |
|---------------|-------------|
| Identity, Core Competencies | `prompts/sisyphus-system.md` |
| Phase-Based Workflow, Operating Modes, Magic Keywords, Todo Management | `steering/workflow.md` |
| Available Agents, Category-Based Delegation | `steering/AGENTS.md` |
| Delegation Rules, Oracle Protocol | `steering/delegation.md` |
| Code Changes, Constraints, File Rules, Communication Style | `steering/constraints.md` |
| Hooks | _(removed — configured directly in agent JSON)_ |

### settings.json → Distributed

| Field | Kiro Target |
|------|-------------|
| `model` | `settings/cli.json` → `chat.defaultModel` |
| `permissions.allow` | each agent JSON's `allowedTools` + `toolsSettings` |
| `hooks` | each agent JSON's `hooks` field |
| `mcpServers` | `settings/mcp.json` |

### Lifecycle change checklist

- Did you update `install.sh` and `uninstall.sh` together?
- Did you add the necessary static checks to `scripts/validate.sh`?
- Did you add install/uninstall scenarios to `tests/smoke-install.sh`?
- Do `README.md`, `docs/Architecture.md`, and `docs/Migration.md` match the actual behavior?
- Did you explicitly state the policy (preserve, no-restore, or restore) for existing user files and shell rc modifications?

---

## Update Integration Procedure

### Step 1: Identify changes

```bash
diff -rq claude-<old-version>/ claude-<new-version>/ | grep -v '.DS_Store'
```

### Step 2: Category-based conversion

#### Adding a new agent

1. Decide the category (Orchestrator / Executor / READ-ONLY)
2. Generate JSON according to the category's conversion rules
3. Add to the `AGENTS` array in `install.sh`
4. Do the same for `uninstall.sh`
5. Add to the orchestrators' `availableAgents`/`trustedAgents`

#### Adding a new skill/command/hook

1. Convert using the rules above
2. Add to the corresponding array in `install.sh`

#### CLAUDE.md changes

Apply to the relevant steering/prompt file according to the split mapping table.

### Step 3: Update install.sh arrays

```bash
AGENTS=(sisyphus oracle prometheus ...)
STEERING_FILES=(AGENTS.md workflow.md ...)
PROMPT_FILES=(sisyphus-system.md planner.md ...)
SKILLS=(orchestrate ultrawork ralph ...)
```

In the current implementation, `PROMPT_FILES` includes `agents/oracle.md`, `agents/analyst.md`, `agents/code-reviewer.md`, `agents/explore.md`, `agents/librarian.md`, `agents/metis.md`, `agents/momus.md`, `agents/multimodal-looker.md`, `agents/atlas.md`, `agents/build-error-resolver.md`, `agents/designer.md`, `agents/executor.md`, `agents/hephaestus.md`, `agents/prometheus.md`, `agents/qa-tester.md`, and `agents/writer.md`.

### Step 4: Testing

```bash
./uninstall.sh && ./install.sh
for f in ~/.kiro/agents/*.json; do python3 -c "import json; json.loads(open('$f').read()); print('OK: $f')"; done
omk  # verify it starts as sisyphus
./scripts/validate.sh
./tests/smoke-install.sh
```

---

## Path System

### Placeholders (substituted by install.sh)

| Placeholder | Substituted Value |
|-------------|---------|
| `__OH_MY_KIRO_STEERING_GLOB__` | `file://$KIRO_HOME/steering/**/*.md` |
| `__OH_MY_KIRO_HOOK_ROOT__` | `$KIRO_HOME/hooks/oh-my-kiro-cli` |

### Relative paths (resolved at runtime, relative to `~/.kiro/agents/`)

| Path Pattern | Actual Path |
|-----------|----------|
| `file://../prompts/X.md` | `~/.kiro/prompts/X.md` |
| `file://../prompts/agents/X.md` | `~/.kiro/prompts/agents/X.md` |
| `skill://../skills/**/SKILL.md` | `~/.kiro/skills/**/SKILL.md` |
| `file://.kiro/steering/**/*.md` | `<workspace>/.kiro/steering/*.md` |

### Coexistence with existing configurations

`~/.kiro/` is shared between Kiro IDE and CLI. oh-my-kiro-cli only overwrites the filenames it manages and preserves the rest. `settings/cli.json` is deep-merged.

---

## Kiro CLI-Specific Items

| File | Purpose |
|------|------|
| `agents/sisyphus.json` | Orchestrator. Only 3 tools (subagent, thinking, todo). Plays the CLAUDE.md role. |
| `prompts/sisyphus-system.md` | sisyphus system prompt. Includes the required use_subagent procedure. |
| `custom_settings/kiro-builtin-tools.md` | Kiro CLI builtin tool reference (subagent, thinking, todo, delegate, etc.) |
| `settings/cli.json` | `chat.defaultAgent: "sisyphus"` |
| alias `omk` | `kiro-cli --agent sisyphus` (auto-added by install.sh) |

---

## Version History

| Date | Base Version | Changes |
|------|----------|-----------|
| 2026-03-25 | oh-my-settings v3.10.0 | Initial full migration: 17 agents, 12 skills, 9 prompts, 8 hooks, 9 steering |
| 2026-03-25 | _(Kiro adaptation)_ | Orchestrator tool restriction (subagent+thinking+todo), toolsSettings added (rm deny, write allowedPaths), subagent trustedAgents expanded to full list |
| 2026-03-26 | oh-my-openagent v3.13.1 | Full hook overhaul: 2 new (empty-subagent-response-detector, delegate-retry-guidance), complete hook assignment for all agents (17/17), total hooks 8→10 |
| 2026-04-02 | first-wave complete | Externalized 16 agent prompts, READ-ONLY destructive blocker, executor secret detector, librarian `web_search`/`web_fetch` pilot, 25 prompts / 12 hooks settled, MCP ownership fix |

---

## LLM Quick Reference

```
1. Read the Claude source
2. Decide the agent category (Orchestrator / Executor / READ-ONLY)
3. Generate JSON using the per-category conversion rules
4. Configure toolsSettings (write.allowedPaths, shell.deniedCommands, subagent.availableAgents)
5. Update the install.sh arrays
6. Validate the JSON
7. Sync the docs
```
