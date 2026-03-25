# Oh-My-Kiro-CLI

Kiro CLI 멀티 에이전트 오케스트레이션 시스템.
[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)에서 영감.

## 설치 / 제거

```bash
./install.sh    # ~/.kiro/에 설치 + omk alias 추가
./uninstall.sh  # 설치한 파일만 제거
```

설치 후 `omk`로 실행. sisyphus 오케스트레이터가 기본 에이전트로 시작.

## 구조

- **17 에이전트** — 오케스트레이터(sisyphus, atlas) + 실행자(executor, hephaestus 등) + READ-ONLY(oracle, explore 등)
- **12 스킬** — ultrawork, ralph, planner, deepsearch 등 (매직 키워드로 자동 활성화)
- **9 프롬프트** — `@planner`, `@start-work`, `@ralph-loop` 등
- **9 steering** — workflow, delegation, constraints, coding-style 등
- **7 훅** — comment-checker, doc-blocker, todo-continuation 등

## 사용

sisyphus는 `subagent`, `thinking`, `todo`만 가지고 있다. 모든 작업은 서브에이전트에 위임.

```
omk                                    # sisyphus로 시작
ultrawork 인증 모듈 구현해줘              # 매직 키워드로 스킬 활성화
인증 모듈 리팩토링 계획 세워줘 @planner    # 프롬프트는 내용 뒤에 붙이기
Ctrl+V / Ctrl+B / Ctrl+N               # sisyphus / prometheus / executor 토글
/agent swap oracle                      # 수동 에이전트 전환
```

> `@prompt`는 앞에 붙이면 뒤의 내용이 무시된다. **내용을 먼저 쓰고 뒤에 `@prompt`를 붙여야** 프롬프트 + 내용이 함께 전달된다.

## 에이전트 분류

| 분류 | 도구 | 에이전트 |
|------|------|----------|
| 오케스트레이터 | subagent, thinking, todo | sisyphus, atlas |
| 실행자 | 전체 (write 포함, rm 차단) | executor, hephaestus, designer, qa-tester, build-error-resolver, writer |
| READ-ONLY | read, glob, grep, shell | oracle, prometheus, metis, momus, analyst, code-reviewer, librarian, explore, multimodal-looker |

## 참고

- [Architecture](docs/Architecture.md) — 구조, 경로 규칙, 훅 할당
- [Migration](docs/Migration.md) — oh-my-openagent 업데이트 반영 가이드
- [Kiro Builtin Tools](custom_settings/kiro-builtin-tools.md) — subagent, thinking 등 도구 레퍼런스
