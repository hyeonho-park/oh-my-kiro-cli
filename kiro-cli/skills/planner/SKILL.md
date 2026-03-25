---
name: planner
description: Strategic planning with Prometheus, Metis, and Momus agents. Use when the user says "plan", "planner", or needs a structured implementation plan before coding.
---

# Planner Skill

## Strategic Planning Mode

Activates the Prometheus planning workflow with Metis consultation and Momus review.

### Planning Workflow

```
User Request → Prometheus (Plan) → Metis (Consult) → Momus (Review) → User Approval → @start-work
```

### Phase 1: Requirements Interview (Prometheus)

Switch to `prometheus` agent to conduct the interview:
- What exactly needs to be built/changed?
- What constraints exist?
- What does "done" look like?
- Are there existing patterns to follow?

### Phase 2: Plan Creation (Prometheus)

```markdown
## Work Plan: [Title]

### Objective
[One paragraph describing the goal]

### Scope
**In Scope:** [Items]
**Out of Scope:** [Items]

### Tasks
| # | Task | Agent | Depends On | Verification |
|---|------|-------|------------|--------------|
| 1 | [Task] | executor | - | [How to verify] |
| 2 | [Task] | designer | #1 | [How to verify] |

### Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| [Risk] | [Strategy] |
```

### Phase 3: Plan Consultation (Metis)

Switch to `metis` to review the plan for completeness, feasibility, parallelization opportunities.

### Phase 4: Plan Review (Momus)

Switch to `momus` for risk assessment and go/no-go recommendation.

### Phase 5: User Approval

Present the reviewed plan. Ask for approval or modifications.

### Phase 6: Execution

Once approved, use `@start-work` to execute:
1. Create todos from plan steps
2. Execute in dependency order
3. Parallelize independent steps
4. Verify each step before proceeding

### Planning Principles

- **Atomic Tasks**: Each task independently executable by a single agent
- **Clear Dependencies**: What blocks what is explicit
- **Verification Built-in**: How to know each step succeeded
- **Agent Assignment**: Which agent handles each step
