# Testing

## File Location
- ALL test files must be in `tests/` directory
- Structure: `tests/unit/`, `tests/integration/`, `tests/e2e/`
- Monorepo: `packages/*/tests/`
- NEVER create tests in `src/` or project root

## Before Writing Tests
1. Read existing test files in the same directory
2. Check test patterns and conventions
3. Verify test framework and assertion style
4. NEVER assume — always verify

## Test Quality
- Test behavior, not implementation details
- Cover happy path AND error cases
- Use descriptive test names
- One assertion per test (when practical)
- Mock external dependencies, not internal logic
- Use Arrange-Act-Assert pattern

## Test Execution
- ALWAYS run tests after writing them
- NEVER ignore failures or warnings
- FIX all issues before marking complete
- NEVER delete tests to make them pass

## Coverage
- Target: 80% minimum (unit + integration)
- Critical paths must have 100% coverage
- Use coverage reports to identify gaps
