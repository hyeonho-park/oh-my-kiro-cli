Create a comprehensive context summary for continuing work in a new session.

## What Gets Captured

1. **Current state** — What was done, what's in progress
2. **Key decisions** — Important choices made and why
3. **Remaining work** — What still needs to be done
4. **File changes** — Files modified, created, deleted
5. **Blockers** — Any issues that need resolution
6. **Context** — Important patterns, dependencies, constraints

## Output

Creates a `HANDOFF.md` file in `tmp/` with:

```markdown
# Session Handoff

## Goal
[What we're working on]

## Completed
- [Done items]

## In Progress
- [Current work]

## Remaining
- [Todo items]

## Key Decisions
- [Decision 1]: [Reasoning]

## Files Changed
- [File list with descriptions]

## Important Context
- [Patterns, constraints, gotchas]

## Next Steps
1. [First thing to do in new session]
```

## Usage

```
@handoff "Authentication migration to OAuth2"
```
