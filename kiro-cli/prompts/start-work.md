Execute an approved plan using the Atlas todo-list orchestrator.

## Workflow

1. Load the most recent plan (from `@planner` output or WORK_PLAN.md)
2. Switch to `atlas` agent for structured execution
3. Atlas converts plan into todos with dependencies
4. Atlas delegates each step to the appropriate specialist agent:
   - UI work → `designer`
   - Business logic → `executor`
   - Deep autonomous work → `hephaestus`
   - Testing → `qa-tester`
   - Build fixes → `build-error-resolver`
5. Independent steps run in parallel
6. Atlas handles failure recovery (3 failures → consult `oracle`)
7. On completion, oracle verifies the result

## Execution Rules

- Follow plan step dependencies strictly
- Parallelize independent steps
- Verify each step before proceeding to dependents
- If a step fails, consult oracle before continuing

## Usage

```
@start-work
@start-work auth-migration
```
