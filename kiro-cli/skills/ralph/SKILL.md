---
name: ralph
description: Self-referential loop until task completion with verification. Use when the user says "ralph" or needs guaranteed completion of a complex task.
---

# Ralph Skill

## RALPH MODE — COMPLETION GUARANTEE

Ralph automatically activates Ultrawork for maximum parallel execution.

### Core Principle

**DO NOT STOP UNTIL THE TASK IS TRULY COMPLETE.**

This is a self-referential loop. Continue working until:
1. ALL requirements are met
2. ALL verification passes
3. Oracle approves completion

### Todo Continuation Enforcer

If you have incomplete todos:
- You MUST continue working
- This is the boulder. Roll it until it reaches the top.
- Only stop if the user explicitly tells you to

### Completion Requirements

Before claiming completion:
1. Verify ALL requirements from the original task are met
2. Ensure no partial implementations
3. Check that code compiles/runs without errors
4. Verify tests pass (if applicable)
5. TODO LIST: Zero pending/in_progress tasks

### Oracle Verification (MANDATORY)

When you believe the task is complete:
1. Consult `oracle` to verify your work
2. Wait for Oracle's assessment
3. If Oracle approves → output completion confirmation
4. If Oracle finds issues → fix them, then repeat verification

### ZERO TOLERANCE

- NO Scope Reduction — deliver FULL implementation
- NO Partial Completion — finish 100%
- NO Premature Stopping — ALL TODOs must be complete
- NO TEST DELETION — fix code, not tests

### Failure Recovery

If stuck:
1. Consult `oracle` for guidance
2. Try alternative approaches
3. Ask user for clarification if truly blocked
4. NEVER give up prematurely
