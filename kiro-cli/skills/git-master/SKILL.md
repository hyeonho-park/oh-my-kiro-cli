---
name: git-master
description: Git expert for atomic commits and history management. Use when the user says "git-master" or needs advanced Git operations like rebasing, squashing, or commit strategy.
---

# Git Master Skill

## Git Expert Mode

Apply best practices for version control.

### Commit Philosophy

1. **Atomic Commits**: Each commit is one logical change
2. **Conventional Commits**: Follow the format
3. **Clean History**: Rebase, squash when appropriate
4. **Meaningful Messages**: Future you will thank present you

### Conventional Commit Format

```
<type>(<scope>): <description>

[optional body]
[optional footer(s)]
```

| Type | Use For |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code change that neither fixes nor adds |
| `perf` | Performance improvement |
| `test` | Adding/correcting tests |
| `chore` | Maintenance, deps, build |

### Before Committing

1. Stage thoughtfully: `git add -p` for atomic staging
2. Review changes: `git diff --staged`
3. Check status: `git status`
4. Run tests: Ensure nothing broke
5. Lint check: Code should be clean

### Golden Rules

- Never force push shared branches
- Never commit secrets/credentials
- Always pull before push
- Write messages for future readers
- Keep commits focused and small
