# kb-* Vendoring & Sync

The kb-* agents, skills, and prompts are vendored from two source repos.

## Source Repos & Pinned SHAs

| Repo | Branch | SHA |
|------|--------|-----|
| infra-kiro-bundle | feature/CIE-13236 | 53125ef24894578f2b0abbf72c36e5be5a32174a |
| infra-llm-wiki (schema only) | feature/CIE-13236 | ebcbf1b687893b2e6312eddac3e0a602fbea2a32 |

## What was vendored

From infra-kiro-bundle:
- agents/kb-searcher.json, agents/kb-curator.json (path-rewritten)
- skills/kb-{create,update,delete,query,lint}/SKILL.md
- skills/references/SCHEMA_CHEATSHEET.md, WIKI_ANALYSIS_KNOWLEDGE.md
- prompts/kb-{create,update,delete,query,lint}.md
- prompts/agents/kb-{searcher,curator}.md (multi-wiki section prepended)
- hooks/post-tool-use/circuit-breaker.sh
- hooks/pre-tool-use/wiki-access-guard.sh (adapted for multi-wiki)

From infra-llm-wiki:
- schema/llm-wiki.md, rules.md, ontology.md, manifest.json → skills/references/wiki-schema/

## Re-sync procedure

1. Check out the source repos at the desired commit.
2. Re-run the copy steps from the integration plan (tmp/plans/kb-integration.md).
3. Re-apply multi-wiki adaptations to kb-curator.md, kb-searcher.md, wiki-access-guard.sh.
4. Update the SHAs in this file.
5. Run `./scripts/validate.sh` and smoke test.
