Execute an approved plan using the Atlas todo-list orchestrator.

## Workflow

1. Load the plan from `tmp/plans/` (most recent, or specified by name)
2. If no plan file found, check for inline plan from `@planner` output
3. Switch to `atlas` agent for structured execution
4. Atlas converts plan into todos with dependencies
5. Atlas delegates each step to the appropriate specialist agent:
   - UI work → `designer`
   - Business logic → `executor`
   - Deep autonomous work → `hephaestus`
   - Testing → `qa-tester`
   - Build fixes → `build-error-resolver`
6. Independent steps run in parallel
7. Atlas handles failure recovery (3 failures → consult `oracle`)
8. On completion, oracle verifies the result

## Execution Rules

- Follow plan step dependencies strictly
- Parallelize independent steps
- Verify each step before proceeding to dependents
- If a step fails, consult oracle before continuing
- Check Required Permissions section before executing shell commands

## Usage

```
@start-work
@start-work auth-migration
```
