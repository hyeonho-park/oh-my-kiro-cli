Perform safe refactoring with full verification at each step.

## Workflow

1. **Analyze** — Understand current code structure
2. **Plan** — Identify all files that need changes
3. **Search** — Find all references and usages
4. **Refactor** — Apply changes systematically
5. **Verify** — Run build, types, tests after EACH change
6. **Review** — Oracle review of final result

## Strategies

| Strategy | Use Case |
|----------|----------|
| rename | Rename symbols across codebase |
| extract | Extract function/component/module |
| inline | Inline function/variable |
| move | Move code between files/modules |

## Safety Rules

- Verify after EACH file change — don't batch
- Run tests after refactoring — catch regressions immediately
- Never refactor and add features simultaneously
- Revert if tests fail — don't try to fix both at once

## Usage

```
@refactor src/auth/ extract
@refactor getUserById rename
```
