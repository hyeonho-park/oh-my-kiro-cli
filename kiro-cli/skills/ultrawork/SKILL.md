---
name: ultrawork
description: Maximum performance mode with parallel agent execution. Use when the user says "ultrawork", "ulw", or "uw" for maximum parallelism.
---

# Ultrawork Skill

## ULTRAWORK MODE ACTIVATED

Execute with extreme parallelism and efficiency.

### Parallel Execution Rules

- **PARALLEL**: Fire independent calls simultaneously — NEVER wait sequentially
- **BACKGROUND FIRST**: Use background tasks for long operations
- **DELEGATE**: Route tasks to specialist agents immediately
- **EXPLORE FIRST**: Fire explore/librarian agents in parallel BEFORE implementation

### Smart Model Routing

| Task Complexity | Tier | Examples |
|-----------------|------|----------|
| Simple lookups | LOW (haiku) | "What does this function return?", "Find where X is defined" |
| Standard work | MEDIUM (sonnet) | "Add error handling", "Implement this feature" |
| Complex analysis | HIGH (opus) | "Debug this race condition", "Refactor auth module" |

### Available Agents by Tier

| Domain | LOW (Haiku) | MEDIUM (Sonnet) | HIGH (Opus) |
|--------|-------------|-----------------|-------------|
| Architecture | - | - | `oracle` |
| Planning | - | - | `prometheus`, `metis`, `momus` |
| Deep Work | - | - | `hephaestus` |
| Orchestration | - | `atlas` | - |
| Execution | - | `executor` | - |
| Search | `explore` | - | - |
| Research | - | `librarian` | - |
| Frontend | - | `designer` | - |
| Testing | - | `qa-tester` | - |
| Build Fix | - | `build-error-resolver` | - |
| Code Review | - | `code-reviewer` | - |
| Docs | `writer` | - | - |
| Visual | - | `multimodal-looker` | - |
| Analysis | - | - | `analyst` |

### Execution Strategy

1. ANALYZE request → identify all independent subtasks
2. FIRE explore/librarian agents in parallel for context
3. SPAWN hephaestus/executor agents in parallel for each subtask
4. CONTINUE working on main thread
5. COLLECT results when ready
6. VERIFY all outputs before completion

### Background Execution Rules

**Run in Background**:
- Package installation, build processes, test suites, deep work units

**Run Blocking (foreground)**:
- Quick status checks, file reads/edits, simple commands

### ZERO TOLERANCE

- NO Scope Reduction — deliver FULL implementation
- NO Partial Completion — finish 100%
- NO Premature Stopping — ALL TODOs must be complete
- NO Excessive Comments — code speaks for itself

## Oracle Verification Fallback

- If Oracle verification fails or returns empty → retry once
- If second Oracle attempt also fails → delegate verification to `code-reviewer` subagent instead
- Never skip verification entirely — always have a fallback verifier
