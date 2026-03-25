# Code Patterns

## Preferred Patterns
- Prefer existing libraries over new dependencies
- Prefer small, focused changes over large refactors
- Prefer composition over inheritance
- Prefer explicit over implicit
- Prefer immutable data structures

## Anti-Patterns to Avoid
- God objects/classes (too many responsibilities)
- Deep nesting (max 3 levels)
- Magic numbers (use named constants)
- Premature optimization
- Copy-paste code (DRY)

## Error Handling Pattern

```typescript
try {
  const result = await riskyOperation();
  return { success: true, data: result };
} catch (error) {
  logger.error('Operation failed', { operation: 'riskyOperation', error });
  return { success: false, error: 'Operation failed' };
}
```

## Async Pattern

```typescript
// Parallel when independent
const [users, posts] = await Promise.all([
  fetchUsers(),
  fetchPosts(),
]);

// Sequential when dependent
const user = await fetchUser(id);
const posts = await fetchPostsByUser(user.id);
```

## Dependency Injection
- Pass dependencies as parameters, not globals
- Use interfaces for external services
- Makes testing easier (mock injection)
