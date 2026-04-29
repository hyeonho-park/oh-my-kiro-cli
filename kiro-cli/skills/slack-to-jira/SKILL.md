---
name: slack-to-jira
description: Slack 스레드 URL을 받아 내용을 구조화 요약하고, Jira Story 티켓을 생성한 뒤, 결과를 해당 스레드에 회신합니다. Triggered by "슬랙 티켓", "slack ticket", "슬랙에서 지라", "slack to jira", "스레드 티켓", "thread to jira", "지라 생성", "jira 만들어", "이 스레드 티켓으로", "슬랙 지라 연동".
---

# Slack Thread → Jira Ticket

Slack 스레드의 대화를 읽고, 핵심 내용을 구조화 요약한 Jira Story를 생성한 뒤, 생성된 티켓 링크를 해당 스레드에 회신합니다.

## Configuration

```
JIRA_BASE_URL      = https://woowahanbros.atlassian.net/browse
DEFAULT_PROJECT    = CIE
DEFAULT_LABEL      = CIE-INFRA
DEFAULT_ISSUE_TYPE = Story
ATLASSIAN_CLI      = ~/.kiro/scripts/atlassian_cli.py
```

환경변수 필요: `ATLASSIAN_EMAIL`, `ATLASSIAN_API_TOKEN`

## Input

사용자는 다음 형태로 요청합니다:

```
slack-to-jira <slack-thread-url> --epic <EPIC-KEY>
```

### 필수
- **Slack 스레드 URL**: `https://*.slack.com/archives/<channel_id>/p<timestamp>` 형식
- **Epic (상위항목)**: `--epic CIE-123` 또는 대화 중 사용자에게 질문

### 선택 (오버라이드)
- `--project <KEY>`: Jira 프로젝트 키 (기본값: CIE)
- `--label <LABEL>`: 라벨 (기본값: CIE-INFRA)
- `--type <TYPE>`: 이슈 타입 (기본값: Story)

Epic이 인자에 없으면 반드시 사용자에게 질문하세요. Epic 없이 티켓을 생성하지 마세요.

## Workflow

### Step 1: Parse Input & Validate

Slack 스레드 URL을 그대로 사용합니다. `agent-slack`은 URL을 직접 받을 수 있습니다.

Epic 키가 없으면 사용자에게 질문합니다:
> 상위항목(Epic) 키를 알려주세요. (예: CIE-123)

### Step 2: Read Slack Thread

```
shell: agent-slack message list {slack_thread_url}
```

스레드를 읽은 뒤 다음을 확인합니다:
- 스레드가 존재하는지
- 메시지가 2개 이상인지 (의미 있는 대화인지)

### Step 3: Summarize Thread

스레드 내용을 분석하여 **Jira 티켓 제목**과 **구조화된 설명**을 생성합니다.

#### 제목 (summary)
- 대화의 핵심 주제를 한 줄로 요약
- 구체적이고 행동 지향적으로 작성 (예: "S3 버킷 권한 설정 요청" ✓, "슬랙 대화" ✗)
- 50자 이내

#### 설명 (description) 템플릿

아래 섹션 중 대화에 해당하는 내용만 포함합니다. 빈 섹션은 생략합니다.

```
## 배경
{이 대화가 시작된 배경과 맥락}

## 요청사항
{구체적으로 요청된 작업이나 변경사항}

## 논의 내용
{주요 논의 포인트, 결정사항, 합의 내용}

## 조치 필요사항
{다음에 해야 할 구체적인 액션 아이템}

## 참여자
{대화에 참여한 사람들 — @mention 형태 유지}

---
> Slack 원문: {slack_thread_url}
```

**요약 원칙:**
- 기술 용어, 에러 메시지, 리소스명은 원문 그대로 보존
- 사람 이름이나 멘션은 그대로 유지
- 대화에서 나온 코드 스니펫이나 명령어는 코드 블록으로 포함
- 추측하지 않음 — 대화에 없는 내용은 작성하지 않음

### Step 4: Create Jira Ticket

설명 내용을 임시 파일에 저장한 뒤 atlassian_cli.py로 생성합니다.

```
shell: cat > /tmp/jira_desc.txt << 'JIRA_EOF'
{Step 3에서 생성한 구조화된 설명}
JIRA_EOF

shell: python3 {ATLASSIAN_CLI} jira create-issue \
  --project {project} \
  --type {type} \
  --summary "{Step 3에서 생성한 제목}" \
  --description-file /tmp/jira_desc.txt \
  --parent {epic_key} \
  --labels {label}
```

생성 결과 JSON에서 `key`와 `url`을 추출합니다.

### Step 5: Post Result to Slack Thread

생성된 티켓 정보를 원래 Slack 스레드에 회신합니다.

```
shell: agent-slack message send {slack_thread_url} \
  "Jira 티켓이 생성되었습니다.\n\n> *{issue_key}*: {summary}\n> {issue_url}\n> Project: {project} | Label: {label} | Epic: {epic_key}"
```

### Step 6: Report to User

사용자에게 최종 결과를 보고합니다:

```
Jira 티켓 생성 완료:
- 티켓: {issue_key} — {summary}
- 링크: {issue_url}
- Slack 스레드에 결과 회신 완료
```

## Error Handling

| 상황 | 대응 |
|------|------|
| Slack URL 파싱 실패 | 올바른 URL 형식을 안내하고 재입력 요청 |
| 스레드 읽기 실패 | agent-slack 인증 상태 확인 안내 |
| Jira 생성 실패 | 에러 메시지 원문 전달, ATLASSIAN 환경변수 확인 안내 |
| Epic 키가 유효하지 않음 | 에러 전달 후 올바른 Epic 키 재입력 요청 |
| Slack 회신 실패 | Jira 티켓은 이미 생성됨을 안내하고 링크 직접 제공 |
