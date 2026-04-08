Ultrawork Loop — combines ralph's completion guarantee with ultrawork's maximum parallelism.

## Behavior

1. Activate Ultrawork mode
2. Fire explore/librarian agents in parallel for context
3. Create detailed todos
4. Execute with maximum parallelism and category-based delegation
5. Oracle verification at completion
6. Loop until truly complete

## Usage

```
@ulw-loop "Refactor the entire API layer to use proper error handling"
```

## Verification Fallback

- Oracle verification failure → retry once → fall back to code-reviewer
- Never declare completion without at least one successful verification pass
