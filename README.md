# Oh-My-Kiro-CLI

Kiro CLI 멀티 에이전트 오케스트레이션 시스템.
[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent)에서 영감.

## 설치 / 제거

```bash
./install.sh    # ~/.kiro/에 설치 + omk alias 추가
./uninstall.sh  # 관리 대상 파일 제거 (omk alias는 자동 제거하지 않음)
```

설치 후 `omk`로 실행. sisyphus 오케스트레이터가 기본 에이전트로 시작.

기존 `~/.kiro/settings/mcp.json`가 있으면 install은 그 파일을 보존하고, uninstall도 그 기존 파일을 건드리지 않는다.

## 현재 상태

- 17 agents / 25 prompt assets / 12 hook scripts
- `sisyphus`를 제외한 16개 에이전트는 모두 `prompts/agents/*.md`를 사용
- `librarian`만 `web_search`, `web_fetch`를 사용하는 specialist pilot 상태
- `omk` alias는 install-only 정책이며 uninstall에서 자동 제거하지 않음

## 검증

```bash
./scripts/validate.sh
./tests/smoke-install.sh
```

- `scripts/validate.sh`: prompt refs, hook matrix, specialist tool exclusivity, lifecycle invariants 검증
- `tests/smoke-install.sh`: temp `KIRO_HOME` install/uninstall, hook behavior, `settings/mcp.json` ownership, alias install-only 정책 검증

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

| 분류           | 도구                       | 에이전트                                                                                        |
| -------------- | -------------------------- | ----------------------------------------------------------------------------------------------- |
| 오케스트레이터 | subagent, thinking, todo   | sisyphus, atlas                                                                                 |
| 실행자         | 전체 (write 포함, rm 차단) | executor, hephaestus, designer, qa-tester, build-error-resolver, writer                         |
| READ-ONLY      | read, glob, grep, shell (`librarian` additionally uses web_search/web_fetch) | oracle, prometheus, metis, momus, analyst, code-reviewer, librarian, explore, multimodal-looker |

## 참고

- [Architecture](docs/Architecture.md) — 구조, 경로 규칙, 훅 할당 상세
- [Migration](docs/Migration.md) — oh-my-openagent 업데이트 반영 가이드
- [Kiro Builtin Tools](custom_settings/kiro-builtin-tools.md) — subagent, thinking 등 도구 레퍼런스
