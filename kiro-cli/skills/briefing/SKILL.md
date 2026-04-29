---
name: briefing
description: Slack, Jira, Confluence를 병렬로 조회해 하루 업무 브리핑 리포트를 생성하고, Slack DM으로 전송합니다. 어제 참여한 스레드에서 결정사항/백로그/정리 대상을 분류하여 Jira/Wiki 액션 후보로 제안합니다. Triggered by "브리핑", "briefing", "오늘 업무", "어제 뭐했지", "daily report", "일일 보고".
---

# Daily Briefing Skill

## Configuration

```
SLACK_USER_ID     = U075FBWB2N7
JIRA_ACCOUNT_ID   = 60481f77ad0d2e006844afcd
JIRA_CIE_PROJECT  = CIE
JIRA_SVCINFRA_PROJECT = SVCINFRA
JIRA_AI_LABEL     = AI-DRIVEN-AGENT
DEFAULT_SPACE_KEY  = CLOUDINFRA
ATLASSIAN_CLI      = ~/.kiro/scripts/atlassian_cli.py
```

환경변수 필요: `ATLASSIAN_EMAIL`, `ATLASSIAN_API_TOKEN`
agent-slack 인증 필요: `agent-slack auth test`로 확인

## Instructions

You are a personal work briefing assistant. When this skill is invoked, collect data from all sources in parallel and render a structured daily briefing report.

### Step 1: Calculate Dates

Compute the following dates in KST (Asia/Seoul, UTC+9):

- **today**: current date in `YYYY-MM-DD` format
- **yesterday**: previous *business* day
  - If today is Monday → yesterday = last Friday
  - If today is Tuesday–Friday → yesterday = previous day
  - If today is Saturday/Sunday → yesterday = previous Friday

### Step 2: Fire All Queries in Parallel

Execute ALL of the following simultaneously via `shell` tool.

#### A. Slack — 어제 내 활동
```
shell: agent-slack search messages "from:@me" --after {yesterday} --before {today} --limit 20
```

#### B. Slack — 저장한 항목
```
shell: agent-slack later list --state in_progress --limit 20
```

#### C. Jira — CIE 프로젝트 오픈 티켓
```
shell: python3 {ATLASSIAN_CLI} jira search \
  --jql 'project = {JIRA_CIE_PROJECT} AND assignee = "{JIRA_ACCOUNT_ID}" AND statusCategory != Done ORDER BY updated DESC' \
  --max-results 20
```

#### D. Jira — SVCINFRA AI-DRIVEN-AGENT 티켓
```
shell: python3 {ATLASSIAN_CLI} jira search \
  --jql 'project = {JIRA_SVCINFRA_PROJECT} AND labels = "{JIRA_AI_LABEL}" AND statusCategory != Done ORDER BY updated DESC' \
  --max-results 20
```

#### E. Confluence — 최근 7일 내 @멘션
```
shell: python3 {ATLASSIAN_CLI} confluence search \
  --cql 'mention = "{JIRA_ACCOUNT_ID}" AND lastModified >= startOfDay("-7d") ORDER BY lastModified DESC' \
  --limit 10
```

#### F. Slack — 어제 내가 멘션된 스레드
```
shell: agent-slack search messages "<@{SLACK_USER_ID}>" --after {yesterday} --before {today} --limit 20
```

### Step 2.5: Thread Digest — 스레드 수집 & 분류

Step 2의 A(내가 쓴 메시지)와 F(내가 멘션된 메시지) 결과를 합산하여 어제 참여한 스레드를 식별합니다.

#### 스레드 식별 & 중복 제거
- 각 검색 결과에서 스레드 URL을 추출
- 동일한 스레드는 하나로 병합
- 스레드가 아닌 단독 메시지는 제외

#### 스레드 전문 읽기
중복 제거된 스레드 목록에 대해 전문을 읽습니다:
```
shell: agent-slack message list {thread_url}
```

스레드가 10개 이상이면 최근 10개만 읽습니다 (비용 절감).

#### 분류
각 스레드를 읽고 다음 카테고리로 분류합니다. 하나의 스레드가 여러 카테고리에 해당할 수 있습니다.

| 카테고리 | 판단 기준 | 예시 |
|---------|----------|------|
| `decision` | 결정사항, 합의, 승인이 명시됨 | "이걸로 가겠습니다", "승인합니다" |
| `backlog` | TODO, 할 일, 후속 작업이 도출됨 | "다음에 해야 할 것", "백로그에 추가" |
| `knowledge` | 기술 논의, 트러블슈팅, 가이드 성격 | 설정 방법, 에러 해결, 아키텍처 논의 |
| `skip` | 단순 잡담, 인사, 리액션만 있음 | "감사합니다", 이모지만 |

분류는 키워드 매칭이 아니라 대화의 맥락과 결론을 기반으로 판단합니다.
`skip`으로 분류된 스레드는 리포트에서 제외합니다.

### Step 3: Synthesize & Render the Briefing Report

**핵심 원칙: 데이터를 나열하지 말고, "무슨 일이 있었는지"를 이해해서 요약하라.**

수집한 데이터 전체를 먼저 읽고, 다음 기준으로 해석한다:
- 여러 채널에 걸친 같은 맥락의 메시지는 하나의 작업으로 묶는다
- Slack 메시지 ↔ Jira 티켓이 같은 주제면 연결해서 표현한다
- 단순 잡담이나 반응(이모지, "감사합니다")은 생략한다

아래 포맷으로 렌더링한다:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📋 DAILY BRIEFING — {오늘 날짜 한국어 형식}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ✅ 어제 한 일  [{yesterday}]
- [작업 주제] 한 줄 요약  (#채널명 / 관련 티켓: CIE-XXXXX)
...
(없으면: "어제 기록된 활동이 없습니다.")

## 🔖 저장해둔 미처리 스레드
- [핵심 요청/이슈] — #채널명  (저장 추정일)
...
(없으면: "저장된 미처리 스레드가 없습니다.")

## 🎫 내 Jira 담당 티켓  [CIE: N개]
- [CIE-XXXXX]  티켓 제목  →  상태: OOO  (최종 수정: MM-DD)
...
(없으면: "담당 티켓이 없습니다.")

## 🤖 AI-DRIVEN-AGENT 진행 현황  [SVCINFRA: N개]
- [SVCINFRA-XXX]  티켓 제목  →  상태: OOO  [담당: 이름]
...
(없으면: "해당 티켓이 없습니다.")

## 📝 위키 멘션  [최근 7일]
- [페이지 제목]  (스페이스명)  — MM-DD
...
(없으면: "최근 멘션된 페이지가 없습니다.")

## 🚀 액션 후보 — 어제 스레드 다이제스트

### 🔴 결정사항 (Decision)
- [결정 내용 한 줄 요약] — #채널명
  → {thread_url}

### 🟡 백로그 / TODO (Backlog)
- [할 일 한 줄 요약] — #채널명
  → {thread_url}
  💡 `slack-to-jira {thread_url} --epic {관련_epic}` 으로 Jira 티켓 생성 가능

### 🔵 정리 대상 (Knowledge)
- [주제 한 줄 요약] — #채널명
  → {thread_url}
  💡 `slack-to-wiki {thread_url}` 로 Wiki 페이지 생성 가능

(해당 카테고리에 항목이 없으면 해당 서브섹션을 생략한다.)
(전체적으로 액션 후보가 없으면: "어제 스레드에서 별도 액션이 필요한 항목이 없습니다.")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
소스: Slack · Jira · Confluence
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Output Rules

- **나열 금지**: 원본 메시지를 그대로 복사하지 않는다. 반드시 의미 단위로 묶어 요약한다.
- **맥락 연결**: 같은 이슈를 다룬 Slack + Jira + Confluence 내용은 하나의 항목으로 묶는다.
- **잡담 제외**: 이모지 반응, "감사합니다" 등 단독으로 의미 없는 메시지는 생략한다.
- **빈 섹션 유지**: 결과가 없어도 섹션 자체는 항상 표시한다 (액션 후보 제외).
- **오류 처리**: 소스 응답 실패 시 `[⚠️ 소스명 응답 실패]`로 표시하고 나머지 섹션은 계속 렌더링한다.
- **Jira 키 병기**: 작업 요약에 관련 티켓이 있으면 반드시 키를 함께 표시한다.
- **보고서 외 텍스트 금지**: 보고서 앞뒤로 설명, 인사, 부연 설명을 붙이지 않는다.
- **액션 후보 섹션**: 스레드 링크는 반드시 클릭 가능한 전체 URL로 표시한다.

### Step 4: Slack DM 전송

리포트 렌더링이 완료되면 본인 Slack DM으로 **전체 리포트를 생략 없이** 전송합니다.

`agent-slack`은 `@me`로 본인에게 DM을 보낼 수 있습니다. 리포트가 길면 여러 메시지로 분할하여 순서대로 전송합니다.

```
shell: agent-slack message send @me "{렌더링된 브리핑 리포트 파트 1}"
shell: agent-slack message send @me "{렌더링된 브리핑 리포트 파트 2}"
```

DM 전송 실패 시 리포트는 대화에 그대로 출력합니다. 전송 실패가 전체 브리핑을 막아서는 안 됩니다.
