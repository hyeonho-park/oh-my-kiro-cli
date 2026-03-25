Activate the Prometheus planning workflow. Switch to `prometheus` agent to gather requirements, then produce a concrete implementation plan.

## Flow

1. Ask 3-5 focused questions if requirements are incomplete.
2. Read the minimum relevant files.
3. Produce a plan with:
   - Objective
   - In-scope / Out-of-scope
   - Task table with agent assignment
   - Verification per step
   - Risks and mitigations
4. Switch to `metis` for plan consultation.
5. Switch to `momus` for risk review.
6. Ask for user approval before implementation.

## Requirements

- Steps must be atomic.
- Dependencies must be explicit.
- Verification must be included for every step.
- Do not start coding inside the planning step.

## After Approval

Use `@start-work` to execute the approved plan.
