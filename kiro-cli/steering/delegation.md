# Delegation

## Agent Routing

| Task Type | Subagent |
|-----------|----------|
| Architecture questions | `oracle` |
| UI/Frontend work | `designer` |
| Codebase search / file reading | `explore` |
| External docs / OSS | `librarian` |
| Documentation | `writer` |
| Plan review | `momus` |
| Testing | `qa-tester` |
| Build errors | `build-error-resolver` |
| Code review | `code-reviewer` |
| Visual analysis | `multimodal-looker` |
| Complex autonomous work | `hephaestus` |
| Plan execution | `atlas` |
| Code implementation | `executor` |

## Subagent Delegation

Orchestrators (sisyphus, atlas) work exclusively through the `use_subagent` tool. Direct tool use is not allowed.

### Required Procedure (violations are blocked)

1. **ListAgents first** — before the first subagent call in a session, always run ListAgents to confirm the available agents.
2. **Specify agent_name** — only use names returned by ListAgents. Never omit it.
3. **No kiro_default** — falling back to the default agent is blocked.

### Delegation Patterns

- File reading/search → call the `explore` subagent
- External docs research → call the `librarian` subagent
- Implementation → call the `executor` or `hephaestus` subagent
- Multiple independent tasks → call multiple subagents in parallel (up to 4)

## Delegation Rules

- Prefer one good subagent over many unnecessary ones.
- Parallelize only when tasks are independent.
- Keep instructions concrete: task, expected outcome, constraints, and verification.

## Delegation Format

Every delegation MUST include:

```
1. TASK: Atomic, specific goal
2. EXPECTED OUTCOME: Concrete deliverables
3. MUST DO: Exhaustive requirements
4. MUST NOT DO: Forbidden actions
5. CONTEXT: File paths, patterns, constraints
```

## Result Reporting Convention

Delegated results should stay human-readable, but follow a consistent shape:

1. `STATUS` - `done`, `blocked`, or `partial`
2. `WHAT CHANGED` - files touched, outputs produced, or findings collected
3. `EVIDENCE` - commands run, checks performed, or concrete observations
4. `OPEN ITEMS` - follow-up work, blockers, or risks if anything remains

Do NOT invent machine-readable XML, JSON envelopes, or fake protocol markers unless the runtime actually supports them.

## Delegation Request Quality

- Ask for the smallest useful result, not a vague exploration dump.
- Require file paths and concrete evidence in every meaningful result.
- If a task can fail in multiple ways, ask the subagent to distinguish root cause from symptoms.
- If the result will feed another step, ask for the exact decision it should unblock.

## Turn Limit Awareness

- Simple, well-scoped tasks (single file edit, lookup) → `executor` (fast, focused)
- Complex multi-step tasks (cross-file changes, architecture) → `hephaestus` (autonomous, deep)
- Do not send complex work to executor — it cannot re-delegate or recover from ambiguity
- Do not send trivial work to hephaestus — it wastes capacity
- When delegating, estimate complexity: trivial (1-2 tool calls), moderate (3-10), complex (10+)


## Subagent Communication Language

- Delegate to subagents in English — queries, task descriptions, and expected outcomes should be in English
- Subagent responses are expected in English for consistency and token efficiency
- Final user-facing responses remain in the user's language (Korean, etc.)
- This applies to all agent-to-agent communication via use_subagent

## Deep Parallel Delegation

When a task decomposes into multiple independent work units:

1. **Decompose** into independent work units
2. **Spawn** one `hephaestus` subagent per unit — all run simultaneously
3. **Give each a clear GOAL** with success criteria, not step-by-step instructions
4. **Collect** all results, integrate, and verify coherence

## Plan Agent Dependency

For multi-step tasks (2+ steps, unclear scope, architecture decisions):

- ALWAYS spawn `prometheus` subagent first before implementation
- Single-file fix or trivial change → delegate directly to `executor`
- If ANY part is ambiguous → spawn `prometheus` before guessing

## Oracle Usage Protocol

Spawn `oracle` subagent for:
- Architecture decisions
- Self-review before completing important tasks
- Hard debugging after 3+ failed attempts
- Unfamiliar patterns or frameworks
- Security and performance concerns

Do NOT spawn oracle for:
- Simple lookups (use explore)
- Trivial decisions (naming, formatting)
