# Architecture

## Overview

`oh-my-kiro-cli` is a Kiro CLI adaptation of the `oh-my-settings` multi-agent workflow. It replaces the Claude Code-centric `CLAUDE.md + settings.json + skills + commands` structure with Kiro CLI-native building blocks:

- Custom agent JSON files in `~/.kiro/agents/`
- Shared steering files in `~/.kiro/steering/`
- Skills in `~/.kiro/skills/`
- Reusable prompt assets in `~/.kiro/prompts/`
- Hook scripts referenced from agent JSON files
- CLI and MCP settings in `~/.kiro/settings/`

## Repository Layout

```text
.
├── README.md
├── install.sh
├── uninstall.sh
├── docs/
│   ├── Architecture.md
│   └── Migration.md
├── custom_settings/
│   └── kiro-builtin-tools.md    # Kiro CLI builtin tool reference
└── kiro-cli/
    ├── agents/       # 17 agent JSON templates
    ├── steering/     # 9 steering files
    ├── skills/       # 12 skills (SKILL.md each)
    ├── prompts/      # 25 prompt assets
    ├── hooks/        # 12 shell hook scripts
    └── settings/     # CLI + MCP settings
```

## Installed Runtime Layout

`~/.kiro/` is shared between Kiro IDE and CLI, and other agent configurations may already exist there. oh-my-kiro-cli only installs the files it manages and does not touch existing files.

```text
~/.kiro/
├── agents/                          # 17 oh-my-kiro-cli files + existing files preserved
│   ├── sisyphus.json
│   ├── oracle.json
│   └── ...
├── steering/                        # created by oh-my-kiro-cli (9 files)
│   ├── AGENTS.md
│   ├── workflow.md
│   └── ...
├── skills/                          # 12 oh-my-kiro-cli files + existing files preserved
│   ├── orchestrate/SKILL.md
│   ├── ultrawork/SKILL.md
│   └── ...
├── prompts/                         # created by oh-my-kiro-cli (25 files)
│   ├── sisyphus-system.md
│   ├── planner.md
│   ├── ...
│   └── agents/
│       ├── oracle.md
│       ├── analyst.md
│       └── ...
├── hooks/
│   └── oh-my-kiro-cli/              # dedicated oh-my-kiro-cli namespace
│       ├── pre-tool-use/
│       ├── post-tool-use/
│       └── stop/
├── settings/
│   ├── cli.json                     # deep merge (existing keys preserved)
│   └── mcp.json                     # created only when the file does not exist
└── backups/                         # backups taken at install time
```

### Conflict-Avoidance Principles

- `agents/`, `skills/`: only the names managed by oh-my-kiro-cli are overwritten; the rest are preserved
- `settings/cli.json`: existing settings preserved via deep merge
- `settings/mcp.json`: not installed if the file already exists
- uninstall only removes `settings/mcp.json` when oh-my-kiro-cli installed it directly; existing user files are preserved
- `hooks/oh-my-kiro-cli/`: uses a dedicated namespace, so there is no conflict with other hooks directories

### Path Conventions

Agent JSON files are installed to `~/.kiro/agents/`. Relative paths are resolved from this location:

| Path Pattern | Resolves To | Used For |
|-------------|-------------|----------|
| `file://../prompts/X.md` | `~/.kiro/prompts/X.md` | agent `prompt` field |
| `file://../prompts/agents/X.md` | `~/.kiro/prompts/agents/X.md` | agent prompt assets |
| `skill://../skills/**/SKILL.md` | `~/.kiro/skills/**/SKILL.md` | global skill auto-discovery |
| `file://.kiro/steering/**/*.md` | `<workspace>/.kiro/steering/*.md` | workspace steering |
| `skill://.kiro/skills/**/SKILL.md` | `<workspace>/.kiro/skills/*.md` | workspace skills |

`__OH_MY_KIRO_STEERING_GLOB__` is replaced with an absolute path by install.sh.

## Agent Architecture

### Current rollout status

- `sisyphus` continues to use `file://../prompts/sisyphus-system.md`
- All non-`sisyphus` agents now use prompt files under `prompts/agents/`
- `sisyphus` continues to use `prompts/sisyphus-system.md` as its dedicated orchestrator system prompt
- Secret detection now runs as an execution-agent `fs_write` pre-hook
- `librarian` now pilots `web_search` and `web_fetch` as specialist-only external research tools
- `settings/mcp.json` is preserved when it pre-exists and removed on uninstall only when oh-my-kiro-cli installed it
- `omk` alias creation is install-only in the current lifecycle policy and is not automatically reverted on uninstall

### Intentional boundaries

- prompt externalization is whole-file only; prompt fragment composition is not part of the runtime model
- READ-ONLY shell policy remains hook-first; broad `denyByDefault` rollout is still not the live baseline
- `librarian` is the only built-in external research pilot; `code` and `knowledge` are not broadly enabled

### Agent Categories

| Category | Tools | Agents |
|------|------|----------|
| **Orchestrator** | `subagent`, `thinking`, `todo` | sisyphus, atlas |
| **Executor** | `["*"]` with `write` in `allowedTools` | executor, hephaestus, designer, qa-tester, build-error-resolver, writer |
| **READ-ONLY** | `read`, `glob`, `grep`, `shell` (+ `web_search`, `web_fetch` for `librarian`) | oracle, analyst, code-reviewer, explore, librarian, metis, momus, multimodal-looker, prometheus |

Orchestrators cannot read or write files directly. They only work through `use_subagent`.

### Model Allocation

| Agent | Model |
|-------|-------|
| sisyphus | claude-opus-4.7 |
| oracle | claude-opus-4.7 |
| prometheus | claude-opus-4.7 |
| analyst | claude-opus-4.7 |
| hephaestus | claude-opus-4.7 |
| metis | claude-sonnet-4.6 |
| momus | claude-sonnet-4.6 |
| atlas | claude-sonnet-4.6 |
| executor | claude-sonnet-4.6 |
| designer | claude-sonnet-4.6 |
| qa-tester | claude-sonnet-4.6 |
| build-error-resolver | claude-sonnet-4.6 |
| code-reviewer | claude-sonnet-4.6 |
| librarian | claude-sonnet-4.6 |
| multimodal-looker | claude-sonnet-4.6 |
| explore | claude-haiku-4.5 |
| writer | claude-haiku-4.5 |

### toolsSettings

Common settings applied to execution agents:

```json
{
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

Settings applied to orchestrators (sisyphus, atlas):

```json
{
  "toolsSettings": {
    "subagent": {
      "availableAgents": ["oracle", "executor", "explore", ...],
      "trustedAgents": ["oracle", "executor", "explore", ...]
    }
  }
}
```

### Hook Assignment

A total of 12 hook scripts are assigned per agent category.

#### Orchestrators

| Agent | preToolUse | postToolUse | stop |
|-------|-----------|-------------|------|
| sisyphus | _(none)_ | context-window-reminder, empty-subagent-response-detector (use_subagent), delegate-retry-guidance (use_subagent) | todo-continuation |
| atlas | _(none)_ | context-window-reminder, empty-subagent-response-detector (use_subagent), delegate-retry-guidance (use_subagent) | todo-continuation |

#### Executors

| Agent | preToolUse | postToolUse | stop |
|-------|-----------|-------------|------|
| executor | comment-checker, doc-blocker, test-location-validator, secret-leak-detector | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| hephaestus | comment-checker, doc-blocker, test-location-validator, secret-leak-detector | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| designer | comment-checker, doc-blocker, secret-leak-detector | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| qa-tester | comment-checker, test-location-validator, secret-leak-detector | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| build-error-resolver | comment-checker, doc-blocker, test-location-validator, secret-leak-detector | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| writer | comment-checker, doc-blocker, secret-leak-detector | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |

#### READ-ONLY

| Agent | preToolUse | postToolUse | stop |
|-------|-----------|-------------|------|
| oracle | destructive-command-blocker (shell) | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(none)_ |
| analyst | destructive-command-blocker (shell) | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(none)_ |
| code-reviewer | destructive-command-blocker (shell) | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(none)_ |
| explore | destructive-command-blocker (shell) | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(none)_ |
| librarian | destructive-command-blocker (shell) | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(none)_ |
| metis | destructive-command-blocker (shell) | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(none)_ |
| momus | destructive-command-blocker (shell) | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(none)_ |
| multimodal-looker | destructive-command-blocker (shell) | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(none)_ |
| prometheus | destructive-command-blocker (shell) | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read), empty-subagent-response-detector (use_subagent), delegate-retry-guidance (use_subagent) | _(none)_ |

## Installer Architecture

### Template Rendering

`install.sh` replaces two placeholders in agent JSON:
- `__OH_MY_KIRO_STEERING_GLOB__` → `file://$KIRO_HOME/steering/**/*.md` (absolute)
- `__OH_MY_KIRO_HOOK_ROOT__` → `$KIRO_HOME/hooks/oh-my-kiro-cli` (absolute)

Agent `prompt` and `resources` fields use relative paths that resolve from `~/.kiro/agents/` at runtime. These do NOT need rendering.

### Install Behavior
- Agent JSON: only placeholders are rendered to absolute paths; relative paths are left as-is
- Steering, prompts, skills: copied as-is
- CLI settings: deep merge (existing keys preserved)
- MCP settings: installed only when the file does not exist
- Hooks: copied, then made executable (currently 12 files)
- Backup: conflicting files are backed up with a timestamp before being overwritten
- Files not under management are never touched
- `alias omk="kiro-cli --agent sisyphus"` is automatically added to zshrc/bashrc
- The alias follows the current install-only policy and is not automatically removed on uninstall

### Validation helpers

- `scripts/validate.sh`: checks externalized prompt refs, hook existence, READ-ONLY/executor hook-matrix integrity, prompt inventory symmetry, orchestrator/executor/READ-ONLY tool boundaries, `librarian` specialist-tool exclusivity, and `mcp_managed` ownership metadata
- `tests/smoke-install.sh`: runs install/uninstall smoke tests with a temp `KIRO_HOME`, verifies hook behavior, confirms externalized prompt cleanup, confirms removal of installer-managed `settings/mcp.json`, confirms install/uninstall preservation of an existing `settings/mcp.json`, and verifies the alias install-only policy
