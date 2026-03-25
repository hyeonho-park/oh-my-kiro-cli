# Delegation

## Agent Routing

| Task Type | Subagent |
|-----------|----------|
| Architecture questions | `oracle` |
| UI/Frontend work | `designer` |
| Codebase search / file reading | `explore` |
| External docs / OSS | `librarian` |
| Documentation | `writer` |
| Plan review | `momus` |
| Testing | `qa-tester` |
| Build errors | `build-error-resolver` |
| Code review | `code-reviewer` |
| Visual analysis | `multimodal-looker` |
| Complex autonomous work | `hephaestus` |
| Plan execution | `atlas` |
| Code implementation | `executor` |

## Subagent Delegation

오케스트레이터(sisyphus, atlas)는 `use_subagent` 도구로만 작업한다. 직접 도구 사용 불가.

### 필수 절차 (위반 시 차단됨)

1. **ListAgents 먼저** — 세션 첫 서브에이전트 호출 전, 반드시 ListAgents로 사용 가능한 에이전트 목록 확인.
2. **agent_name 명시** — ListAgents 결과에 있는 이름만 사용. 절대 생략하지 않는다.
3. **kiro_default 금지** — 기본 에이전트로 폴백하면 차단된다.

### 위임 패턴

- 파일 읽기/검색 → `explore` 서브에이전트 호출
- 외부 문서 조사 → `librarian` 서브에이전트 호출
- 구현 위임 → `executor` 또는 `hephaestus` 서브에이전트 호출
- 독립 작업이 여러 개 → 여러 서브에이전트를 병렬 호출 (최대 4개)

## Delegation Rules

- Prefer one good subagent over many unnecessary ones.
- Parallelize only when tasks are independent.
- Keep instructions concrete: task, expected outcome, constraints, and verification.

## Delegation Format

Every delegation MUST include:

```
1. TASK: Atomic, specific goal
2. EXPECTED OUTCOME: Concrete deliverables
3. MUST DO: Exhaustive requirements
4. MUST NOT DO: Forbidden actions
5. CONTEXT: File paths, patterns, constraints
```

## Deep Parallel Delegation

When a task decomposes into multiple independent work units:

1. **Decompose** into independent work units
2. **Spawn** one `hephaestus` subagent per unit — all run simultaneously
3. **Give each a clear GOAL** with success criteria, not step-by-step instructions
4. **Collect** all results, integrate, and verify coherence

## Plan Agent Dependency

For multi-step tasks (2+ steps, unclear scope, architecture decisions):

- ALWAYS spawn `prometheus` subagent first before implementation
- Single-file fix or trivial change → delegate directly to `executor`
- If ANY part is ambiguous → spawn `prometheus` before guessing

## Oracle Usage Protocol

Spawn `oracle` subagent for:
- Architecture decisions
- Self-review before completing important tasks
- Hard debugging after 3+ failed attempts
- Unfamiliar patterns or frameworks
- Security and performance concerns

Do NOT spawn oracle for:
- Simple lookups (use explore)
- Trivial decisions (naming, formatting)
