Auto-fix build and type errors using the build-error-resolver agent.

## Workflow

1. **Run build** — Execute build command to capture errors
2. **Analyze** — Parse error messages and identify root causes
3. **Fix** — Apply minimal fixes one at a time
4. **Verify** — Re-run build after each fix
5. **Report** — Summary of all fixes applied

## Default Build Commands

The agent will try in order:
1. `npm run build`
2. `npx tsc --noEmit`
3. `pnpm build`
4. Custom command if specified

## Rules

- Minimal diffs only — fix the error, nothing else
- No type suppressions (`as any`, `@ts-ignore`)
- No architectural changes
- Preserve runtime behavior

## Usage

```
@build-fix
@build-fix "npm run build:production"
```
