---
name: kb-create
description: >
  Activated ONLY via explicit @kb-create invocation.
  Ingests new knowledge sources into the team knowledge base.
  Validates classification and frontmatter before saving.
  Do NOT activate on keyword matching.
---

# kb-create

## Purpose
Add new source documents to the team knowledge base following the Karpathy LLM Wiki pattern. Every source must be fully preserved in wiki pages — no information loss.

## Step 0: Read Pattern Documents (MANDATORY)

Before ANY operation, read these files from the wiki project root:

1. `schema/llm-wiki.md` — wiki pattern, quality standards, project context
2. `schema/rules.md` — frontmatter specs, lint rules

**Do NOT skip. Do NOT rely on cached knowledge. Read fresh every time.**
If either file does not exist, STOP and report the error to the user.

## Full-Read Mandate

- Read the **entire** input source end-to-end before writing any wiki content.
- Partial reads or title-only summaries are **FORBIDDEN**.
- Every piece of concrete information in the source MUST appear in the wiki: commands, error messages, config values, stack traces, timelines, CIDRs, ports, environment variables.
- "자세한 내용은 원본 참조" style source-links are NOT acceptable substitutes for actual content.

## 1소스 1위키 원칙 (MANDATORY)

- **각 소스 파일(support-ticket, confluence page, incident-report 등)은 독립된 위키 페이지로 변환한다.** 여러 소스를 하나의 위키로 통합하지 않는다.
- 예외: 동일 사건의 연속 문서(예: "코드분석편" + "테스트편")만 합본 허용.
- "같은 주제"라는 이유로 다른 사건/티켓을 합치면 안 된다. (예: IRSA 설정 티켓 22건 → 22개 위키 페이지)
- 통합 가이드(예: "IRSA 설정 가이드")는 개별 위키 변환 완료 후 별도 domain=onboarding 또는 domain=processes 문서로 작성할 수 있으나, 개별 위키를 대체하면 안 된다.

## Dynamic Classification

LLM decides all classification based on source content. Nothing is hardcoded.

- **Source type**: Read `schema/templates/` for available templates. If none fits, LLM determines the appropriate format.
- **Domain**: Read `schema/ontology.md` for existing domains. If a new domain is needed, propose it.
- **Page structure**: Content determines structure. LLM selects the optimal heading layout for the material. No forced section templates.
- **Tags**: Reference `schema/ontology.md` tag vocabulary. Add new tags when existing ones are insufficient.

## Ingest Workflow

1. **Read pattern docs** — Step 0 above. Non-negotiable.
2. **Read entire source** — Full-Read Mandate. Extract every concrete detail.
3. **Explain plan to user** — Describe what source type you identified, which domain it belongs to, what wiki pages you plan to create/update, and what structure you'll use. Wait for user confirmation before proceeding.
4. **Resolve uncertainty** — If any information in the source is unclear or ambiguous, ask the user or use @kb-query to search existing wiki. Do NOT guess or assume.
5. **Classify dynamically** — Determine type, domain, tags from content.
6. **Select or create template** — Check `schema/templates/`. Use best fit or create appropriate structure.
7. **Create source file** — Save to `sources/{category}/{YYYY-MM}/` with full frontmatter per `schema/rules.md`. Must include mandatory `date: YYYY-MM-DD`.
8. **Create wiki page(s)** — Preserve ALL source information. Structure decided by content. Delegate to kb-curator for wiki page create/update.
9. **Self-verify** — Compare wiki output against source topics. List every major section/topic from the source and confirm each is reflected with concrete details. If anything is missing or reduced to a bullet point, revise before saving.
10. **Update cross-references** — Add `[[wiki-link]]` references in 3–5 related wiki pages (best-effort).
11. **If single-document ingest (not batch)**: Update `wiki/{domain}/_index.md`, `schema/manifest.json`, append to `wiki/log.md` (`## [YYYY-MM-DD] ingest | {title}`), and run `python3 scripts/update_wiki_graph.py` as normal.
12. **If part of a batch ingest**: Write ONLY the wiki `.md` file and append to `wiki/log.md`. Skip `manifest.json`, `_index.md`, and graphify — these will be rebuilt in Phase 3 (see Batch Delegation Rules).
13. **Check graphify report** — Review `graphify-out/WIKI_GRAPH_REPORT.md` for orphans/broken links. Fix in next iteration.

For batch operations (20+ pages), run graphify once at the end instead of per-page.

## Batch Delegation Rules

When processing multiple sources (batch ingest):

### Phase 1: Pre-Classification (orchestrator does this BEFORE delegating)
- Read all sources. **각 소스는 개별 위키 페이지로 변환한다 (통합 금지).**
- canonical_id는 소스별로 1개씩 할당한다.
- 동일 사건의 연속 문서만 예외적으로 합본 허용.
- domain은 소스 내용에 따라 결정한다.
- This phase is read-only and parallelizable.

### Phase 2: Wiki Creation (parallel OK if each curator gets a clear spec)
Each kb-curator receives:
- Pre-assigned `canonical_id` (MUST use this exact ID, do NOT invent a different one)
- Pre-assigned `domain`
- Explicit list of source files to include (ONLY these, no others)
- The curator creates the wiki .md file ONLY — does NOT touch manifest.json or _index.md

### Phase 3: Cascade Rebuild (single curator, after ALL pages are created)
One curator runs manifest/index rebuild:
1. `glob wiki/**/*.md` to find all wiki pages (exclude _index.md, log.md)
2. Read each page's frontmatter (canonical_id, title, domain)
3. Rebuild `schema/manifest.json` from scratch
4. Rebuild each `wiki/{domain}/_index.md` from scratch
5. Run `python3 scripts/update_wiki_graph.py`

This eliminates manifest.json last-write-wins race condition.

### Why This Matters
If multiple curators each update manifest.json independently, the last writer wins and other entries are lost. Deferred rebuild from disk state is the only safe approach for parallel execution.

## Quality Gate: Source Coverage Verification

After writing the wiki page, perform this self-check before saving:

1. List all major topics/sections from the source.
2. For each topic, verify it appears in the wiki with concrete details — not just a mention.
3. If the source has N incidents/cases, the wiki must have N detailed sections.
4. If the source has commands, configs, errors, or stack traces, the wiki must have them **verbatim**.
5. If any topic is missing or reduced to a summary bullet → **revise before saving**.
6. 다음 구체적 정보가 본문에 반드시 포함되어야 한다:
   - 발생 일시 (날짜, 가능하면 시간)
   - 환경 정보 (계정명, 클러스터명, 인스턴스 ID, 네임스페이스 등)
   - 에러 메시지 (verbatim, 축약 금지)
   - JIRA/Slack/AWS Support Case 번호 (있는 경우)
7. **자체 완결성 테스트**: "source 파일을 읽지 않고 이 위키만 읽어도 이 사례를 완전히 이해하고 재현/해결할 수 있는가?" — No이면 미완성.

**Verification test**: "이 위키 페이지만 읽고 이 이슈를 진단·해결할 수 있는가?" — if no, the page is incomplete.

This replaces character-count minimums. The standard is **source coverage**, not length.

## Source Format Requirements

- `source_id`: mandatory unique identifier, format `{type}-{YYYY-MM-DD}-{NNN}`
- `date`: mandatory (`YYYY-MM-DD`, when the event/content occurred)
- `classification`: mandatory (no default value)
- `aliases`: recommended for search/graph
- One file = one topic
- Body must start with `## 요약` section
- Body must end with `## 관련 엔티티` section with `[[...]]` links

## Wiki Page Requirements

- `last_reviewed`: set to today on creation (`YYYY-MM-DD`)
- `sources`: array linking back to source_id(s)
- Internal links use `[[canonical_id]]` format
- ATX headings only: `#` `##` `###`
- No generic headings ("상세", "기타", "메모")

## Constraints

- Source filenames: `{YYYY-MM-DD}-{NNN}.md` only
- Wiki filenames: English kebab-case only
- Korean titles in frontmatter `title` field only
- `classification` field is mandatory — reject if missing
- Restricted sources go to `sources/restricted/`
- Restricted source → wiki synthesis requires PII removal
