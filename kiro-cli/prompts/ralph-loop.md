Execute a self-referential development loop that continues until the task is truly complete.

## Behavior

1. Activate Ultrawork mode for maximum parallelism
2. Create detailed todos for the task
3. Execute each todo with full verification
4. After completing all todos, consult oracle for verification
5. If oracle finds issues, fix them and re-verify
6. Only stop when:
   - All requirements met
   - All tests pass
   - Oracle approves
   - OR user explicitly cancels

## Todo Continuation

If todos remain incomplete:
- NEVER stop — continue working
- This is the boulder. Roll it.
- Only the user can cancel

## Usage

```
@ralph-loop "Implement user authentication with OAuth2, including login, logout, token refresh, and session management"
```

## Verification Standards

- Oracle approval requires explicit keywords: VERIFIED, APPROVED, PASSES, CONFIRMED
- Promise language in results ("will do", "going to") means the work is NOT done
- If Oracle fails twice, fall back to code-reviewer for verification
