# Oh-My-Kiro-CLI

Kiro CLI multi-agent orchestration system.
Inspired by [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent).

## Installation / Removal

```bash
./install.sh    # installs to ~/.kiro/ and adds the omk alias
./uninstall.sh  # removes managed files (does not auto-remove the omk alias)
```

After installation, run `omk` to start. The sisyphus orchestrator launches as the default agent.

If `~/.kiro/settings/mcp.json` already exists, install preserves that file and uninstall leaves the existing file untouched.

## Current Status

- 17 agents / 25 prompt assets / 12 hook scripts
- All 16 agents other than `sisyphus` use `prompts/agents/*.md`
- Only `librarian` is in the specialist pilot state using `web_search` and `web_fetch`
- The `omk` alias is install-only and is not automatically removed on uninstall

## Verification

```bash
./scripts/validate.sh
./tests/smoke-install.sh
```

- `scripts/validate.sh`: verifies prompt refs, hook matrix, specialist tool exclusivity, and lifecycle invariants
- `tests/smoke-install.sh`: verifies install/uninstall with a temp `KIRO_HOME`, hook behavior, `settings/mcp.json` ownership, and alias install-only policy

## Usage

sisyphus only has `subagent`, `thinking`, and `todo`. All work is delegated to subagents.

```
omk                                    # start as sisyphus
ultrawork implement the auth module    # activate a skill via magic keyword
plan the refactor of the auth module @planner    # append the prompt after the content
Ctrl+V / Ctrl+B / Ctrl+N               # toggle sisyphus / prometheus / executor
/agent swap oracle                      # manual agent switch
```

> If `@prompt` is placed at the front, the content after it is ignored. **You must write the content first and append `@prompt` afterward** so that both the prompt and the content are delivered together.

## Agent Categories

| Category       | Tools                       | Agents                                                                                         |
| -------------- | -------------------------- | ----------------------------------------------------------------------------------------------- |
| Orchestrator   | subagent, thinking, todo   | sisyphus, atlas                                                                                 |
| Executor       | full (includes write, rm blocked) | executor, hephaestus, designer, qa-tester, build-error-resolver, writer                         |
| READ-ONLY      | read, glob, grep, shell (`librarian` additionally uses web_search/web_fetch) | oracle, prometheus, metis, momus, analyst, code-reviewer, librarian, explore, multimodal-looker |

## References

- [Architecture](docs/Architecture.md) — structure, path conventions, and hook assignment details
- [Migration](docs/Migration.md) — guide for applying oh-my-openagent updates
- [Kiro Builtin Tools](custom_settings/kiro-builtin-tools.md) — reference for subagent, thinking, and other tools
