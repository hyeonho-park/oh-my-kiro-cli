# Migration Guide

oh-my-openagent (또는 oh-my-settings Claude Code 버전) 업데이트 사항을 oh-my-kiro-cli에 반영하기 위한 가이드.

이 문서는 LLM 에이전트가 마이그레이션 작업을 자동으로 수행할 수 있도록 작성되었다.

---

## 소스와 타겟

| 항목 | 경로 |
|------|------|
| **소스 (Claude Code)** | `~/workspace/claude-code-settings/oh-my-settings/claude-<version>/` |
| **타겟 (Kiro CLI)** | `~/workspace/oh-my-kiro-cli/kiro-cli/` |
| **소스 GitHub** | https://github.com/code-yeongyu/oh-my-openagent |

---

## 에이전트 아키텍처 (Kiro 고유)

Kiro CLI에서는 에이전트를 3가지 분류로 나눈다. Claude Code에는 이 구분이 없다.

### 오케스트레이터 (sisyphus, atlas)

직접 도구가 없다. `use_subagent`로만 작업한다.

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

- `availableAgents`: 서브에이전트로 스폰 가능한 목록. `kiro_default` 제외.
- `trustedAgents`: 확인 없이 바로 스폰. 보통 availableAgents 전체.
- `read`, `write`, `shell`, `glob`, `grep` 없음 — 직접 작업 불가.

### 실행자 (executor, hephaestus, designer, qa-tester, build-error-resolver, writer)

모든 도구 접근 가능. 작업 디렉토리 쓰기 허용, `rm` 차단.

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

읽기 도구만. 쓰기 불가.

```json
{
  "tools": ["read", "glob", "grep", "shell"],
  "allowedTools": ["read", "glob", "grep", "shell"]
}
```

prometheus는 추가로 `subagent`, `thinking` 보유 (metis/momus 호출용).

---

## 컴포넌트 매핑 테이블

### Agents: `agents/*.md` → `agents/*.json`

| Claude Source | Kiro Target | 분류 |
|---------------|-------------|------|
| _(CLAUDE.md에서 추출)_ | `agents/sisyphus.json` | 오케스트레이터 |
| `agents/atlas.md` | `agents/atlas.json` | 오케스트레이터 |
| `agents/executor.md` | `agents/executor.json` | 실행자 |
| `agents/hephaestus.md` | `agents/hephaestus.json` | 실행자 |
| `agents/designer.md` | `agents/designer.json` | 실행자 |
| `agents/qa-tester.md` | `agents/qa-tester.json` | 실행자 |
| `agents/build-error-resolver.md` | `agents/build-error-resolver.json` | 실행자 |
| `agents/writer.md` | `agents/writer.json` | 실행자 |
| `agents/oracle.md` | `agents/oracle.json` | READ-ONLY |
| `agents/prometheus.md` | `agents/prometheus.json` | READ-ONLY (+subagent) |
| `agents/metis.md` | `agents/metis.json` | READ-ONLY |
| `agents/momus.md` | `agents/momus.json` | READ-ONLY |
| `agents/analyst.md` | `agents/analyst.json` | READ-ONLY |
| `agents/code-reviewer.md` | `agents/code-reviewer.json` | READ-ONLY |
| `agents/librarian.md` | `agents/librarian.json` | READ-ONLY |
| `agents/multimodal-looker.md` | `agents/multimodal-looker.json` | READ-ONLY |
| `agents/explore.md` | `agents/explore.json` | READ-ONLY |

### 변환 규칙: Agent MD → Agent JSON

**모델명 매핑:**

| Claude | Kiro CLI |
|--------|----------|
| `opus` | `claude-opus-4.6` |
| `sonnet` | `claude-sonnet-4.6` |
| `haiku` | `claude-haiku-4.5` |

**도구명 매핑:**

| Claude Tool | Kiro Tool | Notes |
|-------------|-----------|-------|
| `Read` | `read` | |
| `Grep` | `grep` | |
| `Glob` | `glob` | |
| `Edit`/`Write` | `write` | |
| `Bash` | `shell` | |
| `TodoWrite` | `todo` | Kiro 빌트인 |
| `WebSearch`/`WebFetch` | _(MCP)_ | MCP 서버로 처리 |
| `Task` (subagent) | `subagent` | `use_subagent` 도구 |

**분류별 변환:**

오케스트레이터로 변환할 때:
1. `tools`/`allowedTools`를 `["subagent", "thinking", "todo"]`로 설정
2. `toolsSettings.subagent`에 `availableAgents`/`trustedAgents` 설정
3. `read`, `write`, `shell` 등 직접 도구 제거

실행자로 변환할 때:
1. `tools`를 `["*"]`로 설정
2. `allowedTools`에 `read`, `glob`, `grep`, `shell`, `write` 포함
3. `toolsSettings.write.allowedPaths = ["./**"]`
4. `toolsSettings.shell`: `autoAllowReadonly=true`, `deniedCommands=["rm .*"]`, `allowedCommands=["trash .*"]`

READ-ONLY로 변환할 때:
1. `tools`/`allowedTools`를 `["read", "glob", "grep", "shell"]`로 동일하게 설정
2. `write` 도구 제외

**공통 필드:**

| 필드 | 값 | Notes |
|------|-----|-------|
| `resources` | `["__OH_MY_KIRO_STEERING_GLOB__", "file://.kiro/steering/**/*.md"]` | 글로벌+워크스페이스 steering |
| `includeMcpJson` | `true` (explore만 `false`) | |

### Hook Assignment

총 10개 훅 스크립트. 매처(matcher)가 있는 훅은 해당 도구 호출 후에만 발동한다.

| 에이전트 분류 | preToolUse (fs_write) | postToolUse | stop |
|-------------|-----------|-------------|------|
| 오케스트레이터 (sisyphus, atlas) | _(없음)_ | context-window-reminder, empty-subagent-response-detector (use_subagent), delegate-retry-guidance (use_subagent) | todo-continuation |
| 실행자 (executor, hephaestus, build-error-resolver) | comment-checker, doc-blocker, test-location-validator | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| 실행자 (designer, writer) | comment-checker, doc-blocker | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| 실행자 (qa-tester) | comment-checker, test-location-validator | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | todo-continuation, cleanup-prompt |
| READ-ONLY (8개) | _(없음)_ | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read) | _(없음)_ |
| prometheus (READ-ONLY + subagent) | _(없음)_ | context-window-reminder, agent-usage-reminder (glob/grep), read-image-resizer (read), empty-subagent-response-detector (use_subagent), delegate-retry-guidance (use_subagent) | _(없음)_ |

---

### Skills: `skills/*/SKILL.md` → `skills/*/SKILL.md`

형식 거의 동일. 변환:

1. `user-invocable` 필드 제거
2. `description`에 트리거 키워드 추가 ("Use when the user says ...")
3. 본문에서 `Task(agent=...)` → `use_subagent`로 서브에이전트 호출
4. `SubAgent` 참조 → `use_subagent` 도구 호출
5. Claude 도구명 → Kiro 도구명

### Commands: `commands/*.md` → `prompts/*.md`

| Claude Source | Kiro Target | 호출 방법 |
|---------------|-------------|-----------|
| `commands/ralph-loop.md` | `prompts/ralph-loop.md` | `@ralph-loop` |
| `commands/ulw-loop.md` | `prompts/ulw-loop.md` | `@ulw-loop` |
| `commands/refactor.md` | `prompts/refactor.md` | `@refactor` |
| `commands/start-work.md` | `prompts/start-work.md` | `@start-work` |
| `commands/handoff.md` | `prompts/handoff.md` | `@handoff` |
| `commands/code-review.md` | `prompts/code-review.md` | `@code-review` |
| `commands/build-fix.md` | `prompts/build-fix.md` | `@build-fix` |
| `commands/checkpoint.md` | _(미포팅)_ | Kiro 빌트인 `/checkpoint` |

변환: YAML frontmatter 제거, `/command` → `@prompt-name`, `Task(agent=...)` → `use_subagent` 호출.

### Hooks: `hooks/**/*.sh` → `hooks/**/*.sh`

총 10개 훅 스크립트:

| 훅 | 라이프사이클 | 매처 | 출처 |
|---|---|---|---|
| comment-checker | preToolUse | fs_write | Claude Code hooks |
| doc-blocker | preToolUse | fs_write | Claude Code hooks |
| test-location-validator | preToolUse | fs_write | Claude Code hooks |
| context-window-reminder | postToolUse | _(전체)_ | Claude Code hooks |
| agent-usage-reminder | postToolUse | glob/grep | Claude Code hooks |
| read-image-resizer | postToolUse | read | Claude Code hooks |
| empty-subagent-response-detector | postToolUse | use_subagent | oh-my-openagent empty-task-response-detector |
| delegate-retry-guidance | postToolUse | use_subagent | oh-my-openagent delegate-task-retry |
| todo-continuation | stop | _(전체)_ | Claude Code hooks |
| cleanup-prompt | stop | _(전체)_ | Claude Code hooks |

훅은 Kiro stdin JSON 형식으로 변환. Claude는 환경변수/인자, Kiro는 JSON stdin.

```bash
#!/usr/bin/env bash
set -euo pipefail
payload="$(cat)"
PAYLOAD="$payload" python3 - <<'PY'
import json, os, sys
payload = json.loads(os.environ["PAYLOAD"])
tool_input = payload.get("tool_input", {}) or {}
# ... 로직 ...
PY
```

Exit code: `0`=허용, `2`=차단(preToolUse만), 기타=경고.

### Rules: `rules/*.md` → `steering/*.md`

YAML frontmatter 제거, plain markdown으로.

### CLAUDE.md → 분할

| CLAUDE.md 섹션 | Kiro Target |
|---------------|-------------|
| Identity, Core Competencies | `prompts/sisyphus-system.md` |
| Phase-Based Workflow, Operating Modes, Magic Keywords, Todo Management | `steering/workflow.md` |
| Available Agents, Category-Based Delegation | `steering/AGENTS.md` |
| Delegation Rules, Oracle Protocol | `steering/delegation.md` |
| Code Changes, Constraints, File Rules, Communication Style | `steering/constraints.md` |
| Hooks | _(제거 — 에이전트 JSON에 직접 설정)_ |

### settings.json → 분산

| 필드 | Kiro Target |
|------|-------------|
| `model` | `settings/cli.json` → `chat.defaultModel` |
| `permissions.allow` | 각 agent JSON의 `allowedTools` + `toolsSettings` |
| `hooks` | 각 agent JSON의 `hooks` 필드 |
| `mcpServers` | `settings/mcp.json` |

---

## 업데이트 반영 절차

### Step 1: 변경 사항 파악

```bash
diff -rq claude-<old-version>/ claude-<new-version>/ | grep -v '.DS_Store'
```

### Step 2: 카테고리별 변환

#### 새 에이전트 추가

1. 분류 결정 (오케스트레이터 / 실행자 / READ-ONLY)
2. 분류별 변환 규칙에 따라 JSON 생성
3. `install.sh`의 `AGENTS` 배열에 추가
4. `uninstall.sh`도 동일
5. 오케스트레이터의 `availableAgents`/`trustedAgents`에 추가

#### 새 스킬/커맨드/훅 추가

1. 위 변환 규칙에 따라 변환
2. `install.sh`의 해당 배열에 추가

#### CLAUDE.md 변경

분할 매핑 테이블에 따라 해당 steering/prompt 파일에 반영.

### Step 3: install.sh 배열 업데이트

```bash
AGENTS=(sisyphus oracle prometheus ...)
STEERING_FILES=(AGENTS.md workflow.md ...)
PROMPT_FILES=(sisyphus-system.md planner.md ...)
SKILLS=(orchestrate ultrawork ralph ...)
```

### Step 4: 테스트

```bash
./uninstall.sh && ./install.sh
for f in ~/.kiro/agents/*.json; do python3 -c "import json; json.loads(open('$f').read()); print('OK: $f')"; done
omk  # sisyphus로 시작되는지 확인
```

---

## 경로 시스템

### 플레이스홀더 (install.sh가 치환)

| 플레이스홀더 | 치환 값 |
|-------------|---------|
| `__OH_MY_KIRO_STEERING_GLOB__` | `file://$KIRO_HOME/steering/**/*.md` |
| `__OH_MY_KIRO_HOOK_ROOT__` | `$KIRO_HOME/hooks/oh-my-kiro-cli` |

### 상대 경로 (런타임 해석, `~/.kiro/agents/` 기준)

| 경로 패턴 | 실제 경로 |
|-----------|----------|
| `file://../prompts/X.md` | `~/.kiro/prompts/X.md` |
| `skill://../skills/**/SKILL.md` | `~/.kiro/skills/**/SKILL.md` |
| `file://.kiro/steering/**/*.md` | `<workspace>/.kiro/steering/*.md` |

### 기존 설정과의 공존

`~/.kiro/`는 Kiro IDE와 CLI가 공유. oh-my-kiro-cli는 자기가 관리하는 파일명만 덮어쓰고 나머지 보존. `settings/cli.json`은 deep merge.

---

## Kiro CLI 고유 사항

| 파일 | 용도 |
|------|------|
| `agents/sisyphus.json` | 오케스트레이터. 도구 3개만 (subagent, thinking, todo). CLAUDE.md 역할. |
| `prompts/sisyphus-system.md` | sisyphus 시스템 프롬프트. use_subagent 필수 절차 포함. |
| `custom_settings/kiro-builtin-tools.md` | Kiro CLI 빌트인 도구 레퍼런스 (subagent, thinking, todo, delegate 등) |
| `settings/cli.json` | `chat.defaultAgent: "sisyphus"` |
| alias `omk` | `kiro-cli --agent sisyphus` (install.sh가 자동 추가) |

---

## 버전 히스토리

| 날짜 | 기반 버전 | 변경 사항 |
|------|----------|-----------|
| 2026-03-25 | oh-my-settings v3.10.0 | 초기 Full 마이그레이션: 17 에이전트, 12 스킬, 9 프롬프트, 8 훅, 9 steering |
| 2026-03-25 | _(Kiro 적응)_ | 오케스트레이터 도구 제한 (subagent+thinking+todo), toolsSettings 추가 (rm deny, write allowedPaths), subagent trustedAgents 전체 확장 |
| 2026-03-26 | oh-my-openagent v3.13.1 | 훅 전면 정비: 신규 2개 (empty-subagent-response-detector, delegate-retry-guidance), 전 에이전트 훅 할당 완성 (17/17), 훅 총 8→10개 |

---

## LLM Quick Reference

```
1. Claude 소스 읽기
2. 에이전트 분류 결정 (오케스트레이터 / 실행자 / READ-ONLY)
3. 분류별 변환 규칙에 따라 JSON 생성
4. toolsSettings 설정 (write.allowedPaths, shell.deniedCommands, subagent.availableAgents)
5. install.sh 배열 업데이트
6. JSON 유효성 검증
7. docs 동기화
```
