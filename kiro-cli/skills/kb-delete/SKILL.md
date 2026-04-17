---
name: kb-delete
description: >
  Activated ONLY via explicit @kb-delete invocation.
  Deletes or retires sources and wiki pages from the team knowledge base.
  Do NOT activate on keyword matching.
---

# kb-delete

## Purpose
Remove or retire source files and wiki pages from the knowledge base. Always perform impact analysis and offer retirement before deletion.

## Step 0: Read Pattern Documents (MANDATORY)

Before ANY operation, read these files from the wiki project root:

1. `schema/llm-wiki.md` — wiki pattern, quality standards, project context
2. `schema/rules.md` — frontmatter specs, lint rules

**Do NOT skip. Do NOT rely on cached knowledge. Read fresh every time.**
If either file does not exist, STOP and report the error to the user.

## Delete Workflow

### 1. Identify Target

Determine what the user wants to remove:
- **Source file** — file in `sources/`
- **Wiki page** — file in `wiki/`
- **Both** — source + all wiki pages that were created from it

### 2. Impact Analysis (MANDATORY)

Before any deletion, analyze the blast radius:

1. Grep all wiki pages for `[[canonical_id]]` references to the target.
2. Check `graphify-out/wiki-graph.json` for inbound/outbound links.
3. Check `schema/manifest.json` for the target entry.
4. Check `wiki/{domain}/_index.md` for the target listing.

### 3. Present Impact to User

Show the user:
- Target file(s) to be removed
- List of all pages referencing the target via `[[wiki-link]]`
- Whether deletion would create orphan pages (pages with no remaining inbound links)

### 4. Offer Retire Option

**Always present retirement as an alternative before deletion.**

> "이 페이지를 삭제하는 대신 `status: retired`로 변경할 수 있습니다. 은퇴 처리하면 기존 링크가 유지되고 히스토리가 보존됩니다. 삭제하시겠습니까, 은퇴 처리하시겠습니까?"

### 5. Wait for Explicit Confirmation

**NEVER proceed without the user's explicit choice: delete or retire.**

### 6. Execute: Delete Path

If the user confirms deletion:

1. **Remove source file** — `trash {file}` or `mv {file} ~/.Trash/` (NEVER `rm`)
2. **Remove wiki page(s)** — `trash {file}` or `mv {file} ~/.Trash/`
3. **Clean broken links** — Find all pages containing `[[canonical_id]]` of the deleted target and remove or replace those links
4. **Update _index.md** — Remove the entry from `wiki/{domain}/_index.md`
5. **Update manifest.json** — Remove the entry from `schema/manifest.json`
6. **Append to log** — Add to `wiki/log.md`:
   ```markdown
   ## [YYYY-MM-DD] delete | {title}

   - source_id: {source_id} (if source deletion)
   - wiki: {canonical_id} (if wiki deletion)
   - orphans_found: [list of pages that referenced deleted content]
   - orphans_cleaned: [list of pages where references were removed]
   ```
7. **Run graphify** — `python3 scripts/update_wiki_graph.py`
8. **Check graphify report** — Review `graphify-out/WIKI_GRAPH_REPORT.md` for new orphans or broken links. Fix if introduced.

### 7. Execute: Retire Path

If the user chooses retirement:

1. **Set status** — Add `status: retired` to the page's YAML frontmatter
2. **Add retirement note** — Insert at the top of the page body:
   ```markdown
   > ⚠️ **이 페이지는 은퇴 처리되었습니다** (YYYY-MM-DD). 내용이 더 이상 최신이 아닐 수 있습니다.
   ```
3. **Update manifest.json** — Set status to `retired` in `schema/manifest.json`
4. **Append to log** — Add to `wiki/log.md`:
   ```markdown
   ## [YYYY-MM-DD] retire | {title}

   - wiki: {canonical_id}
   - reason: {user-provided reason or "user request"}
   ```

## Safety Rules

- **NEVER delete without explicit user confirmation**
- **ALWAYS show impact analysis first**
- **ALWAYS offer retire as alternative to deletion**
- **NEVER use `rm`** — use `trash` or `mv {file} ~/.Trash/`
- **Warn on orphan creation** — if deletion would leave pages with zero inbound links, flag them
- **Git history preserves deleted files** — remind user that tracked files are recoverable via git

## Constraints

- Tracked files: `trash` (recoverable via git history)
- Restricted files: `trash` (not tracked by git, confirm with user that loss is acceptable)
- All wiki content updates go through kb-curator for re-synthesis when needed
