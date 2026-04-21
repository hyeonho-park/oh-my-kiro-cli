# Kiro CLI Built-in Tools Reference

Reference for built-in tools provided by Kiro CLI that are not available in oh-my-openagent.
Used in the agent JSON fields `tools`, `allowedTools`, and `toolsSettings`.

> Source: https://kiro.dev/docs/cli/reference/built-in-tools/

---

## Tool List

### Core Tools (file/search/execution)

| Tool | Canonical | Description |
|------|-----------|-------------|
| `read` | `fs_read` | Read files/folders/images |
| `write` | `fs_write` | Create/edit files |
| `glob` | `glob` | Glob-pattern file discovery (respects .gitignore) |
| `grep` | `grep` | Regex content search (respects .gitignore) |
| `shell` | `execute_bash` | Execute bash commands |
| `aws` | `use_aws` | Call the AWS CLI |

### Web Tools

| Tool | Description |
|------|-------------|
| `web_search` | Web search |
| `web_fetch` | Fetch URL content (selective/truncated/full modes) |

### Agent Tools

| Tool | Canonical | Description |
|------|-----------|-------------|
| `subagent` | `use_subagent` | Spawn subagents in parallel (up to 4 concurrent) |
| `delegate` | `delegate` | Delegate tasks to a background agent |

### Reasoning/Analysis Tools (experimental)

| Tool | Description |
|------|-------------|
| `thinking` | Internal reasoning that decomposes complex tasks into atomic actions |
| `introspect` | Query Kiro CLI's own features/documentation |
| `todo` | Todo list for tracking multi-step tasks |
| `knowledge` | Cross-session knowledge storage/retrieval (semantic search) |

### Other

| Tool | Description |
|------|-------------|
| `code` | Code intelligence (symbol search, LSP, AST-Grep) |
| `report` | Create a GitHub issue/feature request |
| `session` | Temporarily override current session settings |

---

## Subagent (use_subagent) Details

Subagent is the core tool for spawning other custom agents in parallel.

### Capabilities
- Up to 4 subagents running concurrently
- Each subagent has an independent context (no main-context pollution)
- Inherits other agent settings (model/tools/permissions)
- Live execution status display
- Tool usage / time summary on completion

### toolsSettings

```json
{
  "toolsSettings": {
    "subagent": {
      "availableAgents": ["executor", "explore", "oracle", "qa-tester", "hephaestus"],
      "trustedAgents": ["explore", "oracle"]
    }
  }
}
```

| Setting | Type | Description |
|---------|------|-------------|
| `availableAgents` | `string[]` | Restrict which agents can be spawned as subagents. Supports glob patterns (`docs-*`) |
| `trustedAgents` | `string[]` | Agents that can run without a permission prompt. Supports glob patterns |

---

## Thinking Details

A tool that decomposes steps internally and reasons through complex tasks.

- Experimental feature
- No additional configuration
- Enabled by adding `"thinking"` to `tools` and `allowedTools`

---

## Shell toolsSettings

```json
{
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["git status", "git fetch", "npm test"],
      "deniedCommands": ["git commit .*", "git push .*", "rm -rf.*"],
      "autoAllowReadonly": true,
      "denyByDefault": false
    }
  }
}
```

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `allowedCommands` | `string[]` | `[]` | Commands that run without a prompt (regex) |
| `deniedCommands` | `string[]` | `[]` | Commands to block (regex). Takes precedence over allow |
| `autoAllowReadonly` | `boolean` | `false` | Automatically allow read-only commands |
| `denyByDefault` | `boolean` | `false` | Deny every command not in allowedCommands |

---

## Read/Write/Glob/Grep toolsSettings

```json
{
  "toolsSettings": {
    "read": {
      "allowedPaths": ["~/projects", "./src/**"],
      "deniedPaths": ["/etc", "/var"]
    },
    "write": {
      "allowedPaths": ["./src/**", "./tests/**"],
      "deniedPaths": ["./node_modules/**"]
    },
    "glob": {
      "allowedPaths": ["./src/**"],
      "allowReadOnly": true
    },
    "grep": {
      "allowedPaths": ["./src/**"],
      "allowReadOnly": true
    }
  }
}
```

---

## Web Fetch toolsSettings

```json
{
  "toolsSettings": {
    "web_fetch": {
      "trusted": [".*docs\\.aws\\.amazon\\.com.*", ".*github\\.com.*"],
      "blocked": [".*pastebin\\.com.*"]
    }
  }
}
```

| Setting | Type | Description |
|---------|------|-------------|
| `trusted` | `string[]` (regex) | URL patterns that can be accessed without a prompt |
| `blocked` | `string[]` (regex) | URL patterns to block (takes precedence over trusted) |

---

## AWS toolsSettings

```json
{
  "toolsSettings": {
    "aws": {
      "allowedServices": ["s3", "lambda", "ec2"],
      "deniedServices": ["eks", "rds"],
      "autoAllowReadonly": true
    }
  }
}
```

---

## Recommended Tool Configuration per Agent

| Agent Role | tools | Additional allowedTools | toolsSettings |
|------------|-------|-------------------------|---------------|
| Orchestrator (`sisyphus`, `atlas`) | `subagent`, `thinking`, `todo` | none | configure `subagent.availableAgents`, `trustedAgents` |
| Planning (`prometheus`) | `read`, `glob`, `grep`, `shell` | `subagent`, `thinking`, `use_subagent` | READ-ONLY shell policy + subagent post hooks |
| Execution (`executor`, `designer`, `qa-tester`, `build-error-resolver`, `writer`) | `["*"]` | keep role-specific additions minimal | `write.allowedPaths`, `shell.autoAllowReadonly`, `deniedCommands` |
| Deep Worker (`hephaestus`) | `["*"]` | `@sequential-thinking`, `@memory`, `@context7`, `@builtin` | same write/shell policy as execution agents |
| READ-ONLY (`oracle`, `analyst`, `code-reviewer`, `explore`, `metis`, `momus`, `multimodal-looker`) | `read`, `glob`, `grep`, `shell` | memory/context7 family only if needed | destructive shell pre-hook |
| Specialist READ-ONLY (`librarian`) | `read`, `glob`, `grep`, `shell`, `web_search`, `web_fetch` | `@sequential-thinking`, `@memory`, `@context7` | destructive shell pre-hook |

The current repo prioritizes preserving role boundaries over broad tool expansion. In particular, do not add `read`/`write`/`shell` back to orchestrators.
