---
name: strategic-compact
description: Suggests manual context compaction at logical intervals. Use when context window is getting full or between major task phases. Recommends using /compact at strategic points.
---

# Strategic Compact Skill

Suggests `/compact` at strategic points in your workflow rather than relying on arbitrary auto-compaction.

## Why Strategic Compaction?

Auto-compaction triggers at arbitrary points, often mid-task, losing important context. Strategic compaction at logical boundaries preserves what matters.

## Good Times to Compact

1. After planning phase is complete
2. After debugging session concludes
3. Between major task phases
4. When context is getting large but current task is at a natural break

## Bad Times to Compact

1. Mid-implementation of a feature
2. During debugging (lose error context)
3. While waiting for test results
4. During code review analysis

## Before Compacting

- All important decisions documented in code or docs
- Current plan saved as todos
- No in-progress work that needs context
- Key file paths noted in todos

Use `/context show` to check current context window usage.
