---
name: handoff
description: Before ending a session, first ask the user for handoff notes, then update handoff.md and summarize the key context for the next session.
user-invocable: true
---

# Handoff Skill

Before the session ends, collect handoff input from the user and update/read `handoff.md` at the project root to summarize current status.

## Execution Order

### 1. Ask the user for handoff notes

Ask the user the following:

> Before ending the session, is there anything that should be carried over to the next session? (work in progress, decisions, caveats, etc.)

- If the user provides content → proceed to step 2
- If the user replies "none" or returns an empty response → skip to step 3

### 2. Update handoff.md

Update `handoff.md` at the project root with these rules:

- Create the file if it does not exist
- If it exists, keep existing content and append/update the user-provided notes under the `## Session Notes` section
- Record the current date and branch information together
- Never delete existing unchecked items (`- [ ]`)

### 3. Read handoff.md

1. Read `handoff.md` at the project root using the Read tool
2. If it is missing, check commit history with `git log --oneline -20`

### 4. Summary output

Produce the summary in the following format:

```
## Project Status

**Branch**: {current branch}
**Last Work**: {summary of the most recent commit}

## Core Structure
{summary of skill/module structure — 3 to 5 lines}

## Key Patterns / Caveats
{key conventions to know — 3 to 5 bullets}

## Open Items
{unchecked items from handoff.md}

## Session Notes
{summary of what the user provided — only if present}
```

## Rules

- Do not dump the contents of handoff.md verbatim; summarize the essentials
- Include every open item without omission
- Skip detailed content such as code blocks, long JSON, or IAM policies, and direct the reader to "see handoff.md"
- Do not skip step 1 — always ask the question and wait for a response
