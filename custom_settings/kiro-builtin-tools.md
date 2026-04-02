# Kiro CLI Built-in Tools Reference

oh-my-openagent에는 없고 Kiro CLI에서 제공하는 빌트인 도구들의 레퍼런스.
에이전트 JSON의 `tools`, `allowedTools`, `toolsSettings`에서 사용.

> 출처: https://kiro.dev/docs/cli/reference/built-in-tools/

---

## 도구 목록

### 기본 도구 (파일/검색/실행)

| 도구명 | Canonical | 설명 |
|--------|-----------|------|
| `read` | `fs_read` | 파일/폴더/이미지 읽기 |
| `write` | `fs_write` | 파일 생성/편집 |
| `glob` | `glob` | 글로브 패턴 파일 탐색 (.gitignore 존중) |
| `grep` | `grep` | 정규식 콘텐츠 검색 (.gitignore 존중) |
| `shell` | `execute_bash` | Bash 명령 실행 |
| `aws` | `use_aws` | AWS CLI 호출 |

### 웹 도구

| 도구명 | 설명 |
|--------|------|
| `web_search` | 웹 검색 |
| `web_fetch` | URL 콘텐츠 가져오기 (selective/truncated/full 모드) |

### 에이전트 도구

| 도구명 | Canonical | 설명 |
|--------|-----------|------|
| `subagent` | `use_subagent` | 서브에이전트를 병렬 스폰 (최대 4개 동시) |
| `delegate` | `delegate` | 백그라운드 에이전트에 태스크 위임 |

### 추론/분석 도구 (experimental)

| 도구명 | 설명 |
|--------|------|
| `thinking` | 복잡한 태스크를 atomic action으로 분해하는 내부 추론 |
| `introspect` | Kiro CLI 자체 기능/문서에 대한 질의 |
| `todo` | 멀티스텝 태스크 추적용 Todo 리스트 |
| `knowledge` | 세션 간 지식 저장/검색 (시맨틱 검색) |

### 기타

| 도구명 | 설명 |
|--------|------|
| `code` | 코드 인텔리전스 (심볼 검색, LSP, AST-Grep) |
| `report` | GitHub 이슈/피처 리퀘스트 생성 |
| `session` | 현재 세션 설정 임시 오버라이드 |

---

## Subagent (use_subagent) 상세

서브에이전트는 다른 커스텀 에이전트를 병렬로 스폰하는 핵심 도구.

### 기능
- 최대 4개 서브에이전트 동시 실행
- 각 서브에이전트는 독립 컨텍스트 (메인 컨텍스트 오염 없음)
- 다른 에이전트 설정(모델/도구/권한)을 상속
- 실행 상태 실시간 표시
- 완료 시 도구 사용량/시간 요약

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

| 설정 | 타입 | 설명 |
|------|------|------|
| `availableAgents` | `string[]` | 서브에이전트로 스폰 가능한 에이전트 제한. 글로브 패턴 지원 (`docs-*`) |
| `trustedAgents` | `string[]` | 권한 확인 없이 바로 실행 가능한 에이전트. 글로브 패턴 지원 |

---

## Thinking 상세

복잡한 태스크를 수행할 때 내부적으로 단계를 분해해서 추론하는 도구.

- Experimental 기능
- 별도 설정 없음
- `tools`와 `allowedTools`에 `"thinking"` 추가하면 활성화

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

| 설정 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `allowedCommands` | `string[]` | `[]` | 확인 없이 실행 가능한 명령 (regex) |
| `deniedCommands` | `string[]` | `[]` | 차단할 명령 (regex). allow보다 우선 |
| `autoAllowReadonly` | `boolean` | `false` | 읽기 전용 명령 자동 허용 |
| `denyByDefault` | `boolean` | `false` | allowedCommands 외 모든 명령 거부 |

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

| 설정 | 타입 | 설명 |
|------|------|------|
| `trusted` | `string[]` (regex) | 확인 없이 접근 가능한 URL 패턴 |
| `blocked` | `string[]` (regex) | 차단할 URL 패턴 (trusted보다 우선) |

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

## 에이전트별 권장 도구 구성

| 에이전트 역할 | tools | allowedTools 추가 | toolsSettings |
|-------------|-------|-------------------|---------------|
| 오케스트레이터 (`sisyphus`, `atlas`) | `subagent`, `thinking`, `todo` | 없음 | `subagent.availableAgents`, `trustedAgents` 설정 |
| 계획 (`prometheus`) | `read`, `glob`, `grep`, `shell` | `subagent`, `thinking`, `use_subagent` | READ-ONLY shell 정책 + subagent post hooks |
| 실행 (`executor`, `designer`, `qa-tester`, `build-error-resolver`, `writer`) | `["*"]` | 역할별 추가 도구만 최소화 | `write.allowedPaths`, `shell.autoAllowReadonly`, `deniedCommands` |
| Deep Worker (`hephaestus`) | `["*"]` | `@sequential-thinking`, `@memory`, `@context7`, `@builtin` | 실행자와 동일한 write/shell 정책 |
| READ-ONLY (`oracle`, `analyst`, `code-reviewer`, `explore`, `metis`, `momus`, `multimodal-looker`) | `read`, `glob`, `grep`, `shell` | 필요 시 memory/context7 계열만 | destructive shell pre-hook |
| Specialist READ-ONLY (`librarian`) | `read`, `glob`, `grep`, `shell`, `web_search`, `web_fetch` | `@sequential-thinking`, `@memory`, `@context7` | destructive shell pre-hook |

현재 repo는 broad tool expansion보다 역할 경계 보존을 우선한다. 특히 오케스트레이터에 `read`/`write`/`shell`을 다시 추가하지 않는다.
