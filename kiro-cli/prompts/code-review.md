Trigger expert code review on recent changes using the code-reviewer agent.

## Workflow

1. **Identify changes** — `git diff` to find modified files
2. **Switch to code-reviewer** — Review each changed file
3. **Report findings** — Categorized by severity
4. **Fix critical issues** — Auto-fix if requested

## Review Scope

| Target | Usage |
|--------|-------|
| All uncommitted changes | `@code-review` |
| Specific file | `@code-review src/auth.ts` |
| Specific directory | `@code-review src/components/` |
| Last commit | `@code-review HEAD~1` |

## Output

- Critical issues (must fix)
- Suggestions (should fix)
- Nits (nice to have)
- Overall verdict (APPROVE / REQUEST CHANGES)
