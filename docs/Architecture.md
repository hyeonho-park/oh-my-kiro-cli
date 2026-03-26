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
│   └── kiro-builtin-tools.md    # Kiro CLI 빌트인 도구 레퍼런스
└── kiro-cli/
    ├── agents/       # 17 agent JSON templates
    ├── steering/     # 9 steering files
    ├── skills/       # 12 skills (SKILL.md each)
    ├── prompts/      # 9 prompt assets
    ├── hooks/        # 10 shell hook scripts
    └── settings/     # CLI + MCP settings
```

## Installed Runtime Layout

`~/.kiro/`는 Kiro IDE와 CLI가 공유하며, 다른 에이전트 설정이 이미 존재할 수 있다. oh-my-kiro-cli는 자기가 관리하는 파일만 설치하고 기존 파일은 건드리지 않는다.

```text
~/.kiro/
├── agents/                          # oh-my-kiro-cli 17개 + 기존 파일 보존
│   ├── sisyphus.json
│   ├── oracle.json
│   └── ...
├── steering/                        # oh-my-kiro-cli가 생성 (9개)
│   ├── AGENTS.md
│   ├── workflow.md
│   └── ...
├── skills/                          # oh-my-kiro-cli 12개 + 기존 파일 보존
│   ├── orchestrate/SKILL.md
│   ├── ultrawork/SKILL.md
│   └── ...
├── prompts/                         # oh-my-kiro-cli가 생성 (9개)
│   ├── sisyphus-system.md
│   └── ...
├── hooks/
│   └── oh-my-kiro-cli/              # oh-my-kiro-cli 전용 네임스페이스
│       ├── pre-tool-use/
│       ├── post-tool-use/
│       └── stop/
├── settings/
│   ├── cli.json                     # deep merge (기존 키 보존)
│   └── mcp.json                     # 파일 없을 때만 생성
└── backups/                         # 설치 시 백업
```

### 충돌 방지 원칙

- `agents/`, `skills/`: oh-my-kiro-cli가 관리하는 이름만 덮어쓰고 나머지는 보존
- `settings/cli.json`: deep merge로 기존 설정 보존
- `settings/mcp.json`: 파일이 이미 있으면 설치하지 않음
- `hooks/oh-my-kiro-cli/`: 전용 네임스페이스 사용, 다른 hooks 디렉토리와 충돌 없음

### Path Conventions

에이전트 JSON은 `~/.kiro/agents/`에 설치된다. 상대 경로는 이 위치 기준으로 해석된다:

| Path Pattern | Resolves To | Used For |
|-------------|-------------|----------|
| `file://../prompts/X.md` | `~/.kiro/prompts/X.md` | agent `prompt` field |
| `skill://../skills/**/SKILL.md` | `~/.kiro/skills/**/SKILL.md` | 글로벌 스킬 자동 발견 |
| `file://.kiro/steering/**/*.md` | `<workspace>/.kiro/steering/*.md` | 워크스페이스 steering |
| `skill://.kiro/skills/**/SKILL.md` | `<workspace>/.kiro/skills/*.md` | 워크스페이스 스킬 |

`__OH_MY_KIRO_STEERING_GLOB__`은 install.sh가 절대 경로로 치환한다.

## Agent Architecture

### 에이전트 분류

| 분류 | 도구 | 에이전트 |
|------|------|----------|
| **오케스트레이터** | `subagent`, `thinking`, `todo` | sisyphus, atlas |
| **실행자** | `["*"]` + `allowedTools`에 write 포함 | executor, hephaestus, designer, qa-tester, build-error-resolver, writer |
| **READ-ONLY** | `read`, `glob`, `grep`, `shell` | oracle, analyst, code-reviewer, explore, librarian, metis, momus, multimodal-looker, prometheus |

오케스트레이터는 직접 파일을 읽거나 쓸 수 없다. `use_subagent`로만 작업한다.

### Model Allocation

| Agent | Model |
|-------|-------|
| sisyphus | claude-opus-4.6 |
| oracle | claude-opus-4.6 |
| prometheus | claude-opus-4.6 |
| analyst | claude-opus-4.6 |
| hephaestus | claude-opus-4.6 |
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

실행 에이전트에 적용되는 공통 설정:

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

오케스트레이터(sisyphus, atlas)에 적용되는 설정:

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

총 10개 훅 스크립트를 에이전트 분류에 따라 할당한다.

#### 오케스트레이터

| Agent | preToolUse | postToolUse | stop |
|-------|-----------|-------------|------|
| sisyphus | _(없음)_ | context-window-reminder, empty-subagent-response-detector (use_subagent), delegate-retry-guidance (use_subagent) | todo-continuation |
| atlas | _(없음)_ | context-window-reminder, empty-subagent-response-detector (use_subagent), delegate-retry-guidance (use_subagent) | todo-continuation |

#### 실행자

| Agent | preToolUse | postToolUse | stop |
|-------|-----------|-------------|------|
| executor | comment-checker, doc-blocker, test-location-validator | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| hephaestus | comment-checker, doc-blocker, test-location-validator | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| designer | comment-checker, doc-blocker | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| qa-tester | comment-checker, test-location-validator | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| build-error-resolver | comment-checker, doc-blocker, test-location-validator | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| writer | comment-checker, doc-blocker | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |

#### READ-ONLY

| Agent | preToolUse | postToolUse | stop |
|-------|-----------|-------------|------|
| oracle | _(없음)_ | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(없음)_ |
| analyst | _(없음)_ | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(없음)_ |
| code-reviewer | _(없음)_ | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(없음)_ |
| explore | _(없음)_ | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(없음)_ |
| librarian | _(없음)_ | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(없음)_ |
| metis | _(없음)_ | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(없음)_ |
| momus | _(없음)_ | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(없음)_ |
| multimodal-looker | _(없음)_ | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(없음)_ |
| prometheus | _(없음)_ | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read), empty-subagent-response-detector (use_subagent), delegate-retry-guidance (use_subagent) | _(없음)_ |

## Installer Architecture

### Template Rendering

`install.sh` replaces two placeholders in agent JSON:
- `__OH_MY_KIRO_STEERING_GLOB__` → `file://$KIRO_HOME/steering/**/*.md` (absolute)
- `__OH_MY_KIRO_HOOK_ROOT__` → `$KIRO_HOME/hooks/oh-my-kiro-cli` (absolute)

Agent `prompt` and `resources` fields use relative paths that resolve from `~/.kiro/agents/` at runtime. These do NOT need rendering.

### Install Behavior
- Agent JSON: 플레이스홀더만 절대 경로로 렌더링, 상대 경로는 그대로
- Steering, prompts, skills: 그대로 복사
- CLI settings: deep merge (기존 키 보존)
- MCP settings: 파일 없을 때만 설치
- Hooks: 복사 후 실행 권한 부여
- Backup: 충돌 파일은 타임스탬프 백업 후 덮어쓰기
- 관리 대상이 아닌 파일은 절대 건드리지 않음
- `alias omk="kiro-cli --agent sisyphus"`를 zshrc/bashrc에 자동 추가
