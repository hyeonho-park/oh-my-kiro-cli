# kb-lint

## Purpose
Comprehensive wiki health check. Runs 9 checks against the knowledge base and produces a severity-grouped report. Read-only — never modifies files (except log.md append).

## Step 0: Read Pattern Documents (MANDATORY)

Before ANY operation, read these files from the wiki project root:

1. `schema/llm-wiki.md` — wiki pattern, quality standards, project context
2. `schema/rules.md` — frontmatter specs, lint rules
3. `schema/ontology.md` — domain taxonomy, tag vocabulary

**Do NOT skip. Do NOT rely on cached knowledge. Read fresh every time.**
If any file does not exist, STOP and report the error to the user.

## Input Modes

- **Single page**: `eks-node-notready-oom @kb-lint` — lint one wiki page
- **Domain scan**: `troubleshooting @kb-lint` — lint all pages in a domain
- **Full scan**: `@kb-lint` — lint entire wiki

## Lint Workflow

1. **Read pattern docs** — Step 0 above. Non-negotiable.
2. **Read `schema/manifest.json`** — Full wiki inventory.
3. **Read `graphify-out/wiki-graph.json`** — Link structure for graph-based checks.
4. **Determine scope** — Single page, domain, or full scan from user input.
5. **Run all 9 checks** against target pages.
6. **Generate severity-grouped report** — 🔴 Critical → 🟡 Warning → 🟢 Info.
7. **Append to `wiki/log.md`**: `## [YYYY-MM-DD] lint | {summary}`

## Check 1: Frontmatter Validation 🔴

Verify every wiki page has complete, valid frontmatter.

1. Required fields per `schema/rules.md`: `title`, `canonical_id`, `domain`, `tags`, `status`, `last_reviewed`, `sources`.
2. `canonical_id` must match the filename (without `.md` extension).
3. `domain` must be valid per `schema/ontology.md`.
4. `status` must be one of: `current`, `conflict`, `retired`.

## Check 2: Orphan Pages 🟡

Detect pages with no inbound links.

1. Use `graphify-out/wiki-graph.json` to build inbound link map.
2. Flag any page that has zero inbound `[[wiki-links]]` from other pages.
3. Exclude `_index.md` files from orphan detection.

## Check 3: Broken Links 🔴

Detect `[[wiki-links]]` pointing to non-existent pages.

1. Extract all `[[...]]` patterns from each wiki page body.
2. Cross-reference `graphify-out/wiki-graph.json` with actual files in `wiki/`.
3. Report each broken link with the source page and the missing target.
4. Suggest closest matches when possible.

## Check 4: Thin Pages 🟡

Detect pages lacking concrete, actionable content.

1. Flag pages that are just bullet lists with no commands, configs, or error messages.
2. Flag pages that read as summaries rather than full technical content.
3. Include `source_id` in the finding so they can be enriched via `@kb-update`.
4. Domain-specific: troubleshooting pages require code blocks; processes/onboarding may not.

## Check 5: Stale Pages 🟡

Detect pages that may be outdated.

1. Flag pages where `last_reviewed` is older than 6 months from today.
2. Flag pages with `status: current` that have not been reviewed recently.
3. Suggest `@kb-update` to refresh content and bump `last_reviewed`.

## Check 6: Source Coverage 🔴/🟡

Verify wiki pages adequately represent their source material.

1. For pages with `source_id` in frontmatter, verify the source file exists in `sources/`.
2. Spot-check whether the wiki page covers the source's major topics (증상, 원인, 해결, etc.).
3. 🔴 if source file is missing entirely. 🟡 if coverage appears incomplete.

## Check 7: Contradictions 🟡

Detect conflicting information across wiki pages.

1. Identify pages covering similar topics (same domain, overlapping tags).
2. Flag pages with potentially conflicting information (different commands for the same problem, conflicting thresholds, etc.).
3. Flag for human review — do not auto-resolve.

## Check 8: _index.md Consistency 🟡/🔴

Verify domain index files are in sync with actual pages.

1. Every wiki page must be listed in its domain's `wiki/{domain}/_index.md`.
2. No `_index.md` entry should point to a non-existent page.
3. 🔴 if an `_index.md` references a missing page. 🟡 if a page is missing from its `_index.md`.

## Check 9: Graphify Cross-validation 🟢

Verify the wiki graph matches filesystem state.

1. Compare `graphify-out/wiki-graph.json` against actual files in `wiki/`.
2. Flag pages in the graph that no longer exist on disk.
3. Flag pages on disk that are missing from the graph.
4. Suggest running `python3 scripts/update_wiki_graph.py` if out of sync.

## Report Format

```
# Wiki Lint Report [YYYY-MM-DD]

## Summary
- 🔴 Critical: X issues
- 🟡 Warning: Y issues
- 🟢 Info: Z items

## 🔴 Critical
### Frontmatter Validation
- wiki/{domain}/{page}.md — missing field: {field}

### Broken Links
- wiki/{domain}/{page}.md — [[target]] does not exist

### Source Coverage
- wiki/{domain}/{page}.md — source file {source_id} not found

### _index.md Consistency
- wiki/{domain}/_index.md — references non-existent {page}

## 🟡 Warning
### Orphan Pages
- wiki/{domain}/{page}.md — no inbound links

### Thin Pages
- wiki/{domain}/{page}.md — lacks concrete details (source_id: {id})

### Stale Pages
- wiki/{domain}/{page}.md — last_reviewed: {date} (N months ago)

### Source Coverage
- wiki/{domain}/{page}.md — incomplete coverage of {source_id}

### Contradictions
- wiki/{domain}/{page-a}.md vs wiki/{domain}/{page-b}.md — conflicting {topic}

### _index.md Consistency
- wiki/{domain}/{page}.md — missing from _index.md

## 🟢 Info
### Graphify Cross-validation
- wiki-graph.json has N entries not on disk
- N files on disk missing from wiki-graph.json
- Suggest: python3 scripts/update_wiki_graph.py

## Suggested Actions
- @kb-update wiki/{domain}/{page}.md — enrich from source {source_id}
- @kb-update wiki/{domain}/{page}.md — refresh stale content
- Manual review: wiki/{domain}/{page-a}.md vs {page-b}.md contradiction
```

## Constraints

- **Read-only** — do NOT modify any wiki pages, sources, or config files during lint (only `wiki/log.md` append)
- **Do NOT auto-fix** without explicit user approval
- **All 9 checks are mandatory** — never skip a check
- **Report all findings** — do not suppress minor issues
- Severity grouping: 🔴 Critical → 🟡 Warning → 🟢 Info

## Entry Point

```
Entry Point: @kb-lint
Agents: kb-curator (for user-approved fixes only)
```
