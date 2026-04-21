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
                    ↑                                       |
                    └──── Rejection (seed plan) ────────────┘
```

### Phase 1: Requirements Interview (Prometheus)

Switch to `prometheus` agent to conduct the interview:
- What exactly needs to be built/changed?
- What constraints exist?
- What does "done" look like?
- Are there existing patterns to follow?

### Phase 2: Plan Creation (Prometheus)

Prometheus produces a plan AND saves it to `tmp/plans/{slug}.md`.

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

### Required Permissions
[List any shell commands or destructive operations this plan will execute]

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

Present the reviewed plan with explicit choices:

```
[✅ Approve] — execute via @start-work
[✏️ Request Revision] — Prometheus revises the existing plan as a seed using the feedback
[🗑️ Discard] — discard the plan and start over
```

On **Request Revision**:
1. Pass the saved plan file as seed to Prometheus
2. Prometheus reads the seed, applies user feedback, saves updated plan
3. Re-run Metis → Momus → User Approval (rejection loop)
4. Track rejection count

### Phase 6: Execution

Once approved, use `@start-work` to execute:
1. Atlas reads the plan from `tmp/plans/{slug}.md`
2. Create todos from plan steps
3. Execute in dependency order
4. Parallelize independent steps
5. Verify each step before proceeding

### Planning Principles

- **Atomic Tasks**: Each task independently executable by a single agent
- **Clear Dependencies**: What blocks what is explicit
- **Verification Built-in**: How to know each step succeeded
- **Agent Assignment**: Which agent handles each step
- **Plan Persistence**: Plans survive session interruptions
- **Seed Plans**: Rejected plans become seeds for iteration, not waste
- **Timeout**: Max 5 rounds of clarification before producing best-effort plan
