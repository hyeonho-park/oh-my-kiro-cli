---
name: kb-query
description: >
  Activated ONLY via explicit @kb-query invocation.
  Queries the team knowledge base for answers with citations.
  Do NOT activate on keyword matching.
---

# kb-query

## Purpose
Search the knowledge base and synthesize answers with citations following the Karpathy LLM Wiki pattern.

## Step 0: Read Karpathy Pattern (MANDATORY)

Before every query, read these files fresh:
1. `schema/llm-wiki.md` — 3-layer architecture, operations, Graphify integration
2. `schema/rules.md` — frontmatter fields, lint rules, document structure

Never skip this step. Never rely on cached knowledge of these files.

## Full-Read Mandate

Searcher MUST read full wiki pages end-to-end, not just titles or frontmatter. Every relevant page must be read completely before synthesizing an answer. Partial reads are forbidden.

## Query Workflow

### 1. Parse User Question
Extract the core topic, entities, and intent from the user's question.

### 2. Multi-Strategy Search (priority order)

#### a. Graphify (primary — token-efficient)
1. Read `graphify-out/wiki-graph.json` (162 pages, 428 links)
2. Find seed nodes matching the query topic (by title, tags, or canonical_id)
3. Traverse 1–2 hops from seed nodes to discover related pages
4. Collect candidate page paths from graph traversal

This avoids reading all wiki pages. Only read pages the graph identifies as relevant.

> Note: `graphify-out/graph.json` is the CODE graph. Do NOT use it for wiki search.

#### b. Manifest
If graph doesn't cover the topic: search `schema/manifest.json` for matching entries by title, domain, tags, or canonical_id.

#### c. Index
Scan relevant `wiki/{domain}/_index.md` files for page listings in the target domain.

#### d. Grep (fallback)
Direct search in `wiki/` directory as last resort when structured search fails.

### 3. Read Relevant Wiki Pages
- Read up to 10 wiki pages identified by search (each read FULLY)
- Apply Thin Page Detection (see below)
- Flag stale content: if `last_reviewed` is older than 90 days, note "⚠️ last reviewed YYYY-MM-DD — may be outdated"

### 4. Synthesize Answer with Citations
- Every claim must cite its source wiki page using `[[canonical_id]]` format
- If information comes from multiple pages, cite all: `[[page-a]]`, `[[page-b]]`
- If no wiki page covers the topic, say so explicitly
- Prioritize recent sources over older ones
- When sources from different dates disagree, highlight the contradiction with both dates

### 5. Suggest Knowledge Creation
If the answer produces new insight worth preserving (cross-cutting synthesis, gap identification), suggest: "이 내용을 위키에 보존하려면 @kb-create 를 사용하세요."

### 6. Append to Log
Append to `wiki/log.md`:
```
## [YYYY-MM-DD] query | {question summary}
```

## Thin Page Detection

When reading wiki pages during query:
- If a page body is **thin** (lacks concrete details, just bullet lists, no commands/configs/errors/timelines), flag it: `⚠️ thin page — may lack detail`
- After answering, suggest `@kb-update` to enrich flagged thin pages
- Verification test: "이 위키 페이지만 읽고 이 이슈를 진단·해결할 수 있는가?" → 아니면 thin

## Citation Format

Every claim in the answer must cite its source:
```
[[canonical_id]]
```
- `canonical_id`: the wiki page's canonical_id frontmatter field
- Multiple sources: `[[page-a]]`, `[[page-b]]`
- No wiki coverage: state explicitly "위키에 해당 내용이 없습니다"

## Date Awareness
- Include dates when presenting information (source `date` and wiki `last_reviewed`)
- Flag stale content: `last_reviewed` older than 90 days → "⚠️ last reviewed YYYY-MM-DD — may be outdated"
- Contradicting sources from different dates → highlight with both dates
- Prioritize recent over old

## Substantive Answers
- No link-only or shallow summary responses
- Every answer must contain concrete details extracted from the wiki pages
- Never say "see [page]" without including the actual relevant content
- Synthesize information from multiple pages into a coherent answer

## Constraints
- Max 10 wiki pages per query
- Every claim must have `[[canonical_id]]` citation
- Report stale pages (`last_reviewed` > 90 days)
- Report conflict pages (`status: conflict`)
- Graphify first → manifest → index → grep fallback
