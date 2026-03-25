# Coding Style

## Type Safety
- NEVER use `as any`, `@ts-ignore`, `@ts-expect-error` to suppress type errors
- Fix the actual type issue, not the symptom
- Use proper generics instead of `any`

## Comments
- Code should be self-documenting
- Comments explain WHY, never WHAT
- Remove auto-generated comments
- Remove TODO comments unless tracked in issue tracker
- If you need a comment, the code might need refactoring

## Naming
- Functions: verb + noun (`getUserById`, `validateInput`)
- Booleans: `is`/`has`/`should` prefix (`isActive`, `hasPermission`)
- Constants: UPPER_SNAKE_CASE
- Types/Interfaces: PascalCase
- Files: kebab-case or match framework convention

## Structure
- One component/class per file
- Keep functions under 50 lines
- Keep files under 300 lines
- Extract repeated code into utilities

## Error Handling
- Always handle errors explicitly
- Never swallow errors silently
- Use typed error classes when appropriate
- Log errors with context (what, where, why)

## Imports
- Group imports: external → internal → relative
- Remove unused imports
- Prefer named exports over default exports
