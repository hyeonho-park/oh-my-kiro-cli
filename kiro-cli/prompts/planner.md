Activate the Prometheus planning workflow. Switch to `prometheus` agent to gather requirements, then produce a concrete implementation plan.

## Flow

1. Check `tmp/plans/` for existing plans. If a seed plan path is provided, load it.
2. Ask 3-5 focused questions if requirements are incomplete.
3. Read the minimum relevant files.
4. Produce a plan with:
   - Objective
   - In-scope / Out-of-scope
   - Task table with agent assignment
   - Required permissions (shell commands, destructive ops)
   - Verification per step
   - Risks and mitigations
5. Save the plan to `tmp/plans/{slug}.md`.
6. Switch to `metis` for plan consultation.
7. Switch to `momus` for risk review.
8. Present plan with explicit choices: [Approve] [Request Revision] [Discard]

## On Rejection (Request Revision)

1. Collect user feedback.
2. Pass the saved plan file path as seed to Prometheus.
3. Prometheus reads seed, applies feedback, saves updated plan.
4. Re-run Metis → Momus → User Approval.
5. Track rejection count. After 3 rejections, ask if the user wants to start fresh.

## Requirements

- Steps must be atomic.
- Dependencies must be explicit.
- Verification must be included for every step.
- Plans must be saved to `tmp/plans/{slug}.md`.
- Do not start coding inside the planning step.
- Max 5 rounds of clarification before producing best-effort plan.

## After Approval

Use `@start-work` to execute the approved plan. Atlas reads the plan from the saved file.
