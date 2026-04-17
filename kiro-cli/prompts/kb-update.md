# kb-update

## Purpose
Modify existing wiki pages following the Karpathy LLM Wiki pattern. Sources are immutable and cannot be updated. When a thin page is touched, enrich it from original sources — this is the primary mechanism for upgrading legacy wiki pages.

## Step 0: Read Pattern Documents (MANDATORY)

Before ANY operation, read these files from the wiki project root:

1. `schema/llm-wiki.md` — wiki pattern, quality standards, project context
2. `schema/rules.md` — frontmatter specs, lint rules

**Do NOT skip. Do NOT rely on cached knowledge. Read fresh every time.**
If either file does not exist, STOP and report the error to the user.

## Full-Read Mandate

- Read the **entire** target wiki page before editing. Never edit based on partial reads.
- Read **ALL** source documents referenced in the page's frontmatter `sources[]` array.
- Understand the full context — both the wiki page and its original sources — before making any changes.
- Every piece of concrete information in the sources MUST be reflected in the wiki: commands, error messages, config values, stack traces, timelines, CIDRs, ports, environment variables.

## Update Workflow

1. **Read pattern docs** — Step 0 above. Non-negotiable.
2. **Read target wiki page** — Full page, end-to-end.
3. **Read all referenced sources** — Every source listed in frontmatter `sources[]`. Extract all concrete details.
4. **Explain plan to user** — Describe what changes you'll make, whether the page needs enrichment, and what the result will look like. Wait for user confirmation before proceeding.
5. **Resolve uncertainty** — If any information is unclear or ambiguous, ask the user or use @kb-query to search existing wiki. Do NOT guess or assume.
6. **Apply requested changes** — Make the modifications the user asked for.
7. **Enrichment check** — Is this page thin? (See Enrichment on Update below.) If yes, rewrite the entire page, not just the requested change.
8. **Self-verify source coverage** — Quality Gate below. Compare wiki output against all source topics.
9. **Update `last_reviewed`** — Set to today's date (YYYY-MM-DD).
10. **Update cross-references** — Find other pages that reference this page via `[[canonical_id]]`. If the update changes meaning, title, or structure, update those pages too (best-effort). Log cascade failures.
11. **Update `_index.md`** — If title, summary, or domain changed, update `wiki/{domain}/_index.md`.
12. **Update `manifest.json`** — If title, aliases, or metadata changed, update `schema/manifest.json`.
13. **Append to log** — Add to `wiki/log.md`: `## [YYYY-MM-DD] update | {title}`
14. **Run graphify** — `python3 scripts/update_wiki_graph.py`
15. **Check graphify report** — Review `graphify-out/WIKI_GRAPH_REPORT.md` for orphans/broken links introduced by this update. Fix if found.

For batch operations (20+ pages), run graphify once at the end instead of per-page.

## Enrichment on Update

This is the **PRIMARY mechanism** for upgrading legacy thin pages. There are 162+ existing wiki pages, many of which are thin. Every `@kb-update` invocation is an opportunity to enrich them.

**A page is thin if it**:
- Lacks concrete details (commands, configs, error messages, stack traces)
- Consists mostly of bullet-point summaries without depth
- Uses "자세한 내용은 원본 참조" style source-links instead of actual content
- Cannot pass the verification test: "이 위키 페이지만 읽고 이 이슈를 진단·해결할 수 있는가?"

**When updating a thin page**:
1. Read **ALL** source documents referenced in frontmatter `sources[]`.
2. Extract every concrete detail: commands, errors, configs, timelines, stack traces, CIDRs, ports, environment variables.
3. **Rewrite the entire page** — don't just apply the requested change. Restructure and expand to meet quality standards.
4. The result must pass the same Source Coverage Verification as kb-create.
5. Delegate the full rewrite to kb-curator.

This means: every time someone touches a thin page via `@kb-update`, it gets fully enriched. This is the gradual improvement path for the existing wiki.

## Quality Gate: Source Coverage Verification

After writing the wiki page, perform this self-check before saving:

1. List all major topics/sections from every referenced source.
2. For each topic, verify it appears in the wiki with concrete details — not just a mention.
3. If a source has N incidents/cases, the wiki must have N detailed sections.
4. If a source has commands, configs, errors, or stack traces, the wiki must have them **verbatim**.
5. If any topic is missing or reduced to a summary bullet → **revise before saving**.

**Verification test**: "이 위키 페이지만 읽고 이 이슈를 진단·해결할 수 있는가?" — if no, the page is incomplete.

This replaces character-count minimums. The standard is **source coverage**, not length.

## Entry Point
User invokes with: {modification request} @kb-update

## Agents
- kb-curator: sole writer for wiki pages

## Constraints

- Only wiki pages can be updated (sources are immutable)
- All wiki writes go through kb-curator (sole writer)
- Source versions must be recalculated after update
- `classification` field is mandatory — reject if missing
- Restricted sources → wiki synthesis requires PII removal
- ATX headings only: `#` `##` `###`
- Internal links use `[[canonical_id]]` format
- No generic headings ("상세", "기타", "메모")
