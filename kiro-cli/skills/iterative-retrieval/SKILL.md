---
name: iterative-retrieval
description: Progressive context retrieval for multi-agent workflows. Use when subagents need to discover relevant code context iteratively before executing tasks.
---

# Iterative Retrieval Pattern

Solves the context problem in multi-agent workflows where subagents don't know what context they need until they start working.

## The Solution: 4-Phase Loop

```
DISPATCH → EVALUATE → REFINE → LOOP (max 3 cycles)
```

### Phase 1: DISPATCH
Start with broad keyword search based on task intent.

### Phase 2: EVALUATE
Score each found file by relevance:
- **High (0.8-1.0)**: Directly implements target functionality
- **Medium (0.5-0.7)**: Contains related patterns or types
- **Low (0.2-0.4)**: Tangentially related
- **None (0-0.2)**: Not relevant, exclude

### Phase 3: REFINE
- Add terminology discovered in high-relevance files
- Exclude confirmed irrelevant paths
- Target identified gaps

### Phase 4: LOOP
Repeat with refined criteria (max 3 cycles). Stop when:
- 3+ high-relevance files found
- No critical gaps remain

## Integration with Agents

Use in delegation prompts:
```
When retrieving context for this task:
1. Start with broad keyword search
2. Evaluate each file's relevance (0-1 scale)
3. Identify missing context
4. Refine and repeat (max 3 cycles)
5. Return files with relevance >= 0.7
```

## Best Practices

1. Start broad, narrow progressively
2. Learn codebase terminology in first cycle
3. Track what's missing explicitly
4. Stop at "good enough" — 3 high-relevance files beats 10 mediocre ones
