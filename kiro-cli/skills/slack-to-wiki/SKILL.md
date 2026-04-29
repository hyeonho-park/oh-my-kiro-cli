---
name: slack-to-wiki
description: Slack 스레드 URL을 받아 내용을 구조화 요약한 Confluence wiki 페이지를 CLOUDINFRA 스페이스에 생성하고, 결과를 해당 스레드에 회신합니다. Triggered by "슬랙 위키", "slack wiki", "스레드 문서화", "thread to wiki", "위키 작성", "슬랙 컨플루언스", "slack confluence", "문서로 남겨", "기록 남겨", "위키에 정리".
---

# Slack Thread → Confluence Wiki Page

Slack 스레드의 대화를 읽고, 핵심 내용을 구조화한 Confluence wiki 페이지를 생성한 뒤, 생성된 페이지 링크를 해당 스레드에 회신합니다.

## Configuration

```
WIKI_BASE_URL      = https://woowahanbros.atlassian.net/wiki
DEFAULT_SPACE_KEY  = CLOUDINFRA
ATLASSIAN_CLI      = ~/.kiro/scripts/atlassian_cli.py
```

환경변수 필요: `ATLASSIAN_EMAIL`, `ATLASSIAN_API_TOKEN`

## Input

```
slack-to-wiki <slack-thread-url>
```

### 필수
- **Slack 스레드 URL**: `https://*.slack.com/archives/<channel_id>/p<timestamp>` 형식

### 선택 (오버라이드)
- `--parent <page-id>`: 부모 페이지 ID
- `--space <SPACE_KEY>`: 스페이스 키 (기본값: CLOUDINFRA)
- `--title <제목>`: 페이지 제목 직접 지정

부모 페이지가 인자에 없으면 Step 3에서 사용자에게 질문합니다.

## Workflow

### Step 1: Parse Input & Validate

Slack 스레드 URL을 확인합니다. `agent-slack`은 URL을 직접 받을 수 있습니다.

### Step 2: Read Slack Thread

```
shell: agent-slack message list {slack_thread_url}
```

스레드를 읽은 뒤 내용을 파악합니다.

### Step 3: Resolve Parent Page

CLOUDINFRA 스페이스는 정리가 완벽하지 않으므로, 사용자가 부모 페이지를 직접 지정할 수 있게 합니다.

**`--parent`가 제공된 경우:** 그대로 사용합니다.

**`--parent`가 없는 경우:**

스페이스의 최상위 페이지 목록을 조회하여 사용자에게 선택지를 제공합니다.

```
shell: python3 {ATLASSIAN_CLI} confluence list-pages --space-key {space_key} --limit 50
```

사용자에게 질문합니다:
> 아래 페이지 중 어디 아래에 문서를 생성할까요?
> 1. {page_title_1} (ID: {id})
> 2. {page_title_2} (ID: {id})
> ...
> 또는 페이지 ID를 직접 입력해주세요.

사용자가 특정 페이지의 하위를 더 보고싶어 하면:

```
shell: python3 {ATLASSIAN_CLI} confluence get-children --page-id {selected_page_id}
```

사용자가 최종 선택할 때까지 탐색을 반복합니다.

### Step 4: Summarize Thread & Draft Wiki Page

스레드 내용을 분석하여 **페이지 제목**과 **본문**을 생성합니다.

#### 제목
- `--title`이 제공되었으면 그대로 사용
- 없으면 대화의 핵심 주제를 간결하게 요약

#### 본문 구조

대화 내용에 맞게 아래 섹션 중 해당하는 것만 포함합니다. 빈 섹션은 생략합니다. HTML(Confluence storage format)로 작성합니다.

```html
<ac:structured-macro ac:name="info"><ac:rich-text-body>
<p>이 문서는 Slack 스레드 대화를 기반으로 작성되었습니다.</p>
<p>원문: <a href="{slack_thread_url}">{slack_thread_url}</a></p>
<p>작성일: {today}</p>
</ac:rich-text-body></ac:structured-macro>

<h2>배경</h2>
<p>{이 대화가 시작된 배경과 맥락}</p>

<h2>문제 / 요청사항</h2>
<p>{구체적으로 제기된 문제나 요청된 작업}</p>

<h2>논의 내용</h2>
<p>{주요 논의 포인트, 제안된 방안들}</p>

<h2>결론 / 결정사항</h2>
<p>{최종 결정, 합의된 내용}</p>

<h2>액션 아이템</h2>
<ul>
  <li>{구체적 액션}</li>
</ul>

<h2>참여자</h2>
<p>{대화에 참여한 사람들}</p>
```

**작성 원칙:**
- 기술 용어, 에러 메시지, 리소스명, 명령어는 원문 그대로 보존
- 코드 스니펫은 `<pre><code>` 블록으로 포함
- 사람 이름이나 멘션은 그대로 유지
- 추측하지 않음 — 대화에 없는 내용은 작성하지 않음

### Step 5: Create Confluence Page

본문을 임시 파일에 저장한 뒤 atlassian_cli.py로 생성합니다.

```
shell: cat > /tmp/wiki_body.html << 'WIKI_EOF'
{Step 4에서 생성한 HTML 본문}
WIKI_EOF

shell: python3 {ATLASSIAN_CLI} confluence create-page \
  --space-key {space_key} \
  --parent-id {selected_parent_page_id} \
  --title "{Step 4에서 생성한 제목}" \
  --body-file /tmp/wiki_body.html
```

생성 결과 JSON에서 `id`와 `url`을 추출합니다.

### Step 6: Post Result to Slack Thread

```
shell: agent-slack message send {slack_thread_url} \
  "Confluence 위키 페이지가 생성되었습니다.\n\n> *{page_title}*\n> {page_url}\n> Space: {space_key} | Parent: {parent_page_title}"
```

### Step 7: Report to User

```
Wiki 페이지 생성 완료:
- 제목: {page_title}
- 링크: {page_url}
- 위치: {space_key} > {parent_page_title} > {page_title}
- Slack 스레드에 결과 회신 완료
```

## Error Handling

| 상황 | 대응 |
|------|------|
| Slack URL 파싱 실패 | 올바른 URL 형식을 안내하고 재입력 요청 |
| 스레드 읽기 실패 | agent-slack 인증 상태 확인 안내 |
| 부모 페이지 ID 유효하지 않음 | 에러 전달 후 다른 페이지 선택 요청 |
| Confluence 페이지 생성 실패 | 에러 메시지 원문 전달, 환경변수 확인 안내 |
| Slack 회신 실패 | 페이지는 이미 생성됨을 안내하고 링크 직접 제공 |
