---
name: deepsearch
description: Thorough multi-strategy codebase search. Use when the user says "search", "find", "locate", or needs exhaustive codebase exploration.
---

# DeepSearch Skill

## Deep Codebase Search Mode

Perform exhaustive, multi-strategy search across the entire codebase.

### Search Strategy

Execute ALL of these in parallel:

1. **Grep Search**: Text patterns, strings, comments
2. **Glob Search**: File name patterns, extensions
3. **Structural Search**: Function shapes, class structures, import patterns
4. **Git Search**: History, blame, changes
5. **External Search**: OSS implementations via `librarian`

### Output Format

```markdown
## Search Results: [Query]

### Files Found
| File | Relevance | Content |
|------|-----------|---------|
| `/absolute/path/file.ts` | HIGH | [Brief description] |

### Code Locations
1. `/path/file.ts:123` - [What's here]

### Patterns Identified
- [Pattern 1]: Found in N files

### Recommendations
- [What to do with this information]
```

### Quality Standards

- ALL paths must be ABSOLUTE
- Cross-validate findings across tools
- Report uncertainty when results are unclear

### Stop Conditions

STOP searching when:
- Enough context to proceed confidently
- Same information appearing across multiple sources
- 2 search iterations yielded no new useful data
- Direct answer found

DO NOT over-search. Time is precious.
