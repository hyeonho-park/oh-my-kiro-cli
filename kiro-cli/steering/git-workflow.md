# Git Workflow

## Commits
- Never commit unless user explicitly requests it
- Use conventional commit format: `type(scope): description`
- Each commit should be one logical change (atomic)
- Never commit secrets, credentials, or API keys
- Run tests before committing

## Branches
- Never force push to shared branches (main, develop)
- Always pull before push
- Use feature branches for new work

## Code Review
- Review your own changes before committing (`git diff --staged`)
- Check for unintended file changes
- Verify no debug code left behind (console.log, debugger)

## Bugfix Rule
- Fix minimally — NEVER refactor while fixing bugs
- One fix per commit
- Include reproduction steps in commit message body
