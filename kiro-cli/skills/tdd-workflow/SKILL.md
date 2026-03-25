---
name: tdd-workflow
description: Test-driven development with 80%+ coverage enforcement. Use when the user says "tdd" or needs test-first development workflow.
---

# Test-Driven Development Workflow

## Core Principles

### Tests BEFORE Code
ALWAYS write tests first, then implement code to make tests pass.

### Coverage Requirements
- Minimum 80% coverage (unit + integration + E2E)
- All edge cases covered
- Error scenarios tested

## TDD Workflow Steps

1. **Write Test Cases** (should fail)
2. **Implement Code** (minimal to make tests pass)
3. **Run Tests Again** (should now pass)
4. **Refactor** (improve quality, keep tests green)
5. **Verify Coverage** (80%+ achieved)

## Test Types

| Type | Purpose | Location |
|------|---------|----------|
| Unit | Individual functions, components | `tests/unit/` |
| Integration | API, database, services | `tests/integration/` |
| E2E | User flows, browser | `tests/e2e/` |

## Testing Rules

- ALL tests in `tests/` directory — NEVER in `src/` or root
- Test behavior, not implementation
- One assertion per test (when practical)
- Descriptive test names
- NEVER delete tests to make them pass
- Mock external dependencies, not internal logic
- Use Arrange-Act-Assert pattern
