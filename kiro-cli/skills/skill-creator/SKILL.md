---
name: skill-creator
description: Create new skills, modify and improve existing skills or reusable agent workflow bundles, and measure their performance. Use when users want to create a skill or workflow package from scratch, update or optimize an existing one, run evals, benchmark candidate versus baseline behavior with variance analysis, or improve invocation and selection descriptions so the right workflow gets used at the right time.
---

# Skill Creator

A skill for creating new skills and iteratively improving them.

At a high level, the process of creating a skill goes like this:

- Decide what you want the skill or workflow package to do and roughly how it should do it
- Write a draft of the skill
- Create a few realistic test prompts and run the task with the candidate workflow enabled
- Compare the candidate against a baseline and help the user evaluate the results both qualitatively and quantitatively
  - While runs are in progress, draft quantitative evals if they do not already exist
  - Use the bundled review surface to get the outputs in front of the human as early as possible
- Rewrite the skill based on the user's feedback and any clear failures that show up in the benchmark data
- Repeat until you are satisfied
- Expand the test set and try again at larger scale

Your job when using this skill is to figure out where the user is in this process and then jump in and help them progress through these stages. If they say "I want to make a skill for X," help narrow the intent, draft the skill, write the test cases, decide how to evaluate, run the prompts, and repeat. If they already have a draft, go straight to the eval and iteration part of the loop.

Be flexible if the user explicitly wants a lighter-weight flow, but default back to the full loop as soon as the user wants confidence rather than vibes.

After the skill is working, offer to optimize the description or other selection metadata so the right workflow gets picked more reliably.

## Use this bundle without external docs

Everything needed to operate this bundle is inside this skill directory. Do not rely on any external README.

Read in this order:
1. `SKILL.md` — the main operating procedure and fallback rules
2. `references/schemas.md` — the exact artifact contracts
3. `agents/grader.md`, `agents/comparator.md`, `agents/analyzer.md` — helper roles when you need them
4. `scripts/*.py` — automation entry points when the host can run local commands

### Built-in automation entry points

- `scripts/run_eval.py` — measures whether the current short description or selection text gets selected for the right queries
- `scripts/improve_description.py` — proposes a better description or selection text from eval failures
- `scripts/run_loop.py` — runs the full eval → improve → held-out selection loop
- `eval-viewer/generate_review.py` — renders the review surface for qualitative and quantitative comparison

### Host presets

#### Preset A: Registry-style host with temporary command or skill entries

Use this when the host can discover a temporary registry entry inside the project and the CLI can emit selection evidence.

Default assumptions built into `scripts/run_eval.py` and `scripts/run_loop.py`:
- project marker directory: `.claude`
- registry path: `.claude/commands`
- runner command: `claude`
- runner args: `["-p", "{query}", "--output-format", "stream-json", "--verbose", "--include-partial-messages"]`
- detection mode: `claude-tool-use`
- tool names treated as selection evidence: `Skill,Read`
- stripped env vars before nested execution: `CLAUDECODE`

Example:

```bash
python -m scripts.run_loop \
  --eval-set evals/trigger-evals.json \
  --skill-path . \
  --model <model-id> \
  --verbose \
  --report ./selection-report.html \
  --results-dir ./selection-results
```

#### Preset B: Same pattern, different host layout

Use this when the host has the same basic behavior but different marker paths, registry paths, CLI names, or tool names.

Adjust these flags:
- `--marker-dir`
- `--registry-relative-path`
- `--runner-command`
- `--runner-args-json`
- `--tool-names`
- `--env-strip`

Example:

```bash
python -m scripts.run_eval \
  --eval-set evals/trigger-evals.json \
  --skill-path . \
  --model <model-id> \
  --marker-dir .host \
  --registry-relative-path .host/commands \
  --runner-command <host-cli> \
  --runner-args-json '["run", "{query}", "--model", "{model}"]' \
  --tool-names Command,Read
```

#### Preset C: No structured tool events

Use this when the host does not emit Claude-style stream JSON tool events but does print a reliable marker when the workflow is selected.

Adjust these flags:
- `--detection-mode substring`
- `--trigger-substring <reliable-selection-marker>`

Example:

```bash
python -m scripts.run_eval \
  --eval-set evals/trigger-evals.json \
  --skill-path . \
  --model <model-id> \
  --runner-command <host-cli> \
  --runner-args-json '["run", "{query}"]' \
  --detection-mode substring \
  --trigger-substring '<marker printed only when the workflow is selected>'
```

### Optimizer backend contract

`improve_description.py` and `run_loop.py` can optimize descriptions in two ways:

1. **Anthropic SDK available** — pass `--model <model-id>` and let the script call the SDK directly
2. **External optimizer wrapper** — pass `--optimizer-command <path-to-command>`

If you use `--optimizer-command`, your command receives one argument: the path to a JSON payload file with this structure:

```json
{
  "model": "model-id",
  "max_tokens": 16000,
  "thinking_budget": 10000,
  "messages": [
    {"role": "user", "content": "prompt text"}
  ]
}
```

Your command must write either:
- raw text containing `<new_description>...</new_description>`, or
- JSON containing one of `text`, `response`, or `content`, plus optional `thinking`

### When automation is not available

If none of the presets fit, do not stop. Use the manual loop in this `SKILL.md`:
- draft the description
- create trigger eval queries
- run candidate and baseline manually
- score train vs held-out results
- improve using only train failures
- pick the best version by held-out score

The schemas in `references/schemas.md` stay the same whether the loop is manual or automated.

## Communicating with the user

This skill will be used by people with very different levels of technical familiarity. Match your wording to the user.

In the default case:

- "evaluation" and "benchmark" are usually OK
- For "JSON" and "assertion," make sure the user is already speaking that language or explain the term briefly

If you are unsure, define the term in one short sentence and keep moving.

---

## Creating a skill

### Capture Intent

Start by understanding the user's intent. The current conversation may already contain a workflow the user wants to capture. If so, extract answers from the conversation first: tools used, sequence of steps, corrections the user made, and input or output formats already visible. Let the user fill in the gaps and confirm before moving on.

1. What should this skill or workflow enable the assistant to do?
2. When should this skill be selected, triggered, or invoked?
3. What should the output look like?
4. Should we set up test cases to verify the skill works? Skills with objectively verifiable outputs benefit from tests. Purely subjective skills often do not. Recommend the default that fits the task, but let the user decide.

### Interview and Research

Proactively ask about edge cases, input and output formats, example files, success criteria, and dependencies. Do not write test prompts until this part is solid.

If the host runtime supports search, docs lookup, or parallel workers, use them to gather context. Come prepared so the user does not have to do the research for you.

### Write the SKILL.md

Based on the interview, fill in these components:

- **name**: Skill identifier
- **description**: When to trigger, what it does, and what surrounding contexts should still count. In hosts with native skill selection, this is the main selection mechanism. In hosts without native skill loading, use the same text as concise router metadata, command help text, or invocation summary.
- **compatibility**: Required tools and dependencies if needed
- **the rest of the skill**

Descriptions should be a little pushy. Do not write something so narrow that the workflow only gets used when the user says the exact magic words.

### Skill Writing Guide

#### Anatomy of a Skill

```text
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description required)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/    - Executable code for deterministic or repetitive tasks
    ├── references/ - Docs loaded into context as needed
    └── assets/     - Files used in output or review surfaces
```

#### Progressive Disclosure

Use three conceptual layers:

1. **Metadata** (name + description) — short summary always visible to the host or router
2. **SKILL.md body** — the main operating procedure loaded when the workflow is selected
3. **Bundled resources** — supporting files, schemas, scripts, and templates loaded as needed

If the host does not have formal skill loading, still preserve this layering. It keeps the main instructions compact and stops the model from carrying unnecessary context all the time.

**Key patterns:**
- Keep `SKILL.md` focused; if it grows too large, split detailed material into `references/`
- Reference support files clearly from `SKILL.md` and say when to read them
- For large reference files, give the reader signposts so the model can load only the relevant section

**Domain organization:** When a skill supports multiple domains or frameworks, organize by variant.

```text
cloud-deploy/
├── SKILL.md
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

#### Principle of Lack of Surprise

Skills must not contain malware, exploit code, or content that surprises the user relative to the stated purpose. Do not help create misleading workflows or workflows designed for unauthorized access, exfiltration, or abuse.

#### Writing Patterns

Prefer imperative instructions.

**Defining output formats**

```markdown
## Report structure
ALWAYS use this exact template:
# [Title]
## Executive summary
## Key findings
## Recommendations
```

**Examples pattern**

```markdown
## Commit message format
**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication
```

### Writing Style

Explain why things matter instead of stacking rigid MUST and NEVER statements unless a hard contract is actually required. Strong models do better when they understand the reason behind an instruction.

Write a draft, then look at it again and improve it.

### Test Cases

After writing the draft, come up with 2-3 realistic test prompts — the kind of thing a real user would actually say. Show them to the user and confirm they look right.

Save test cases to `evals/evals.json`. Do not write assertions yet — just the prompts. Draft assertions in the next step while the runs are in progress.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "prompt": "User's task prompt",
      "expected_output": "Description of expected result",
      "files": []
    }
  ]
}
```

See `references/schemas.md` for the full schema, including expectations and the later benchmark artifacts.

## Running and evaluating test cases

This section is one continuous sequence — do not stop partway through.

Do NOT switch to a different testing workflow just because the host has a convenience feature. The value of this skill is the full candidate-versus-baseline loop with explicit artifacts, human review, and iteration.

Put results in `<skill-name>-workspace/` as a sibling to the skill directory. Within the workspace, organize results by iteration (`iteration-1/`, `iteration-2/`, etc.), and within each iteration give each test case its own directory (`eval-0/`, `eval-1/`, etc.). Do not create the whole tree upfront — create directories as you go.

### Step 1: Start all runs (candidate and baseline) in the same batch

For each test case, launch two runs in the same batch if the host supports parallel workers — one with the candidate workflow enabled and one baseline run. Do not run all candidate cases first and come back for baselines later. Start everything together so the results arrive around the same time.

Keep the canonical on-disk names `with_skill`, `without_skill`, and `old_skill`. Even if you think of them conceptually as candidate and baseline, those directory names and configuration labels are expected by the bundled schemas and review tooling.

**Candidate-enabled run:**

```text
Execute this task:
- Skill/workflow path: <path-to-skill>
- Task: <eval prompt>
- Input files: <eval files if any, or "none">
- Save outputs to: <workspace>/iteration-<N>/eval-<ID>/with_skill/outputs/
- Outputs to save: <what the user actually cares about>
```

**Baseline run** (same prompt, but baseline depends on context):
- **Creating a new skill**: run without the skill and save to `without_skill/outputs/`
- **Improving an existing skill**: snapshot the current version before editing and use that snapshot as the baseline, saving to `old_skill/outputs/`

If the host does not support independent workers, run the candidate and baseline back-to-back and note that the comparison is weaker because the same agent saw both sides.

Write an `eval_metadata.json` for each test case. Give each eval a descriptive name based on what it is testing, not just `eval-0`. If this iteration changes the prompts, regenerate the metadata rather than assuming it carries over.

```json
{
  "eval_id": 0,
  "eval_name": "descriptive-name-here",
  "prompt": "The user's task prompt",
  "assertions": []
}
```

### Step 2: While runs are in progress, draft assertions

Do not just wait for the runs to finish. Use that time productively.

Draft quantitative assertions for each test case and explain them to the user. If assertions already exist in `evals/evals.json`, review them and explain what they check.

Good assertions are objectively verifiable and descriptively named. They should read clearly in the benchmark viewer so someone can understand them at a glance. For subjective skills, do not force fake precision — let human review carry more of the load.

Update `eval_metadata.json` and `evals/evals.json` once the assertions are drafted. Also explain what the user will see in the review surface: qualitative outputs plus quantitative benchmark data.

### Step 3: As runs complete, capture timing data

When each worker completes, save timing and usage data to `timing.json` in the run directory.

If the host exposes `total_tokens` and `duration_ms`, record them immediately. If the host exposes different timing or usage metrics, save the closest equivalents. If some values are unavailable, leave them absent or null — do not invent them.

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

Capture this data as soon as it becomes available. In many runtimes it is only visible in the completion event or log stream.

### Step 4: Grade, aggregate, and launch the review surface

Once all runs are done:

1. **Grade each run** — use `agents/grader.md` to evaluate each assertion against the transcript and outputs. Save results to `grading.json`. The `grading.json` expectations array must use the exact fields `text`, `passed`, and `evidence`. Do not rename them.

2. **Aggregate into benchmark** — if the bundled scripts are usable in the current host, run:
   ```bash
   python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
   ```
   If the host cannot run the script, generate `benchmark.json` manually using the exact schema in `references/schemas.md`.

   Put each `with_skill` run before its paired baseline run.

3. **Do an analyst pass** — read the benchmark data and surface patterns the aggregate stats might hide. Use `agents/analyzer.md`, especially the benchmark-analysis section.

4. **Launch the review surface** — if the host supports Python and local files, use:
   ```bash
   nohup python <skill-creator-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N \
     --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json \
     > /dev/null 2>&1 &
   ```
   For iteration 2+, also pass `--previous-workspace <workspace>/iteration-<N-1>`.

   If the host cannot launch a browser or local server, prefer a static HTML review surface. If even that is unavailable, fall back to inline conversational review — but still present the outputs to the human before revising the skill.

5. **Tell the user what to review** — make it easy for them to compare outputs and understand the quantitative comparison.

Use `generate_review.py` if the host supports it. Do not replace it with custom HTML unless you truly have no other option.

### What the user sees in the review surface

The main review view should show one test case at a time:
- **Prompt**: the task that was given
- **Output**: the files or artifacts the skill produced
- **Previous Output** (iteration 2+): last iteration's output
- **Formal Grades**: assertion pass or fail details if grading was run
- **Feedback**: a place for the user to leave comments
- **Previous Feedback** (iteration 2+): last iteration's comments

The benchmark view should show pass rates, timing, and token usage per configuration, plus per-eval breakdowns and analyst observations.

### Step 5: Read the feedback

When the user finishes the review, read `feedback.json` or normalize their feedback into the same shape if the host used a different review method.

```json
{
  "reviews": [
    {"run_id": "eval-0-with_skill", "feedback": "the chart is missing axis labels", "timestamp": "..."},
    {"run_id": "eval-1-with_skill", "feedback": "", "timestamp": "..."},
    {"run_id": "eval-2-with_skill", "feedback": "perfect, love this", "timestamp": "..."}
  ],
  "status": "complete"
}
```

Empty feedback usually means the user thought it was fine. Focus improvements on the test cases with specific complaints.

If you started a local review server, shut it down when you are done.

---

## Improving the skill

This is the heart of the loop. You have run the test cases, the user has reviewed the results, and now you need to make the skill better based on evidence.

### How to think about improvements

1. **Generalize from the feedback.** The examples are there to move fast, not to define the full task forever. If the skill only works for the examples, it is useless.

2. **Keep the prompt lean.** Remove instructions that are not pulling their weight. Read transcripts, not just final outputs. If the skill is making the model waste time, fix the part of the skill that is causing that.

3. **Explain the why.** Good models do better when they understand the reason behind an instruction. If you find yourself writing rigid rules everywhere, that is a yellow flag.

4. **Look for repeated work across test cases.** If multiple runs independently create the same helper script or repeat the same multi-step workaround, bundle that script into `scripts/` and tell the skill to use it.

Take the time to think. The point is not to produce a fast revision; it is to produce a better one.

### The iteration loop

After improving the skill:

1. Apply your improvements
2. Rerun the test cases into a new `iteration-<N+1>/` directory, including baseline runs
3. Launch the review surface with `--previous-workspace` pointing at the previous iteration when possible
4. Wait for the user to review and tell you they are done
5. Read the new feedback, improve again, repeat

Keep going until:
- The user says they are happy
- The feedback is effectively empty
- You are no longer making meaningful progress

---

## Advanced: Blind comparison

If the user asks whether one version is actually better than another, use blind comparison.

Read `agents/comparator.md` and `agents/analyzer.md`. The idea is simple: compare two outputs without revealing which skill or workflow produced which one, choose the better result, then analyze why it won.

This is optional and best when the host can provide truly independent workers or separate evaluation contexts.

---

## Description Optimization

In skill-style hosts, the `description` field in `SKILL.md` frontmatter is the main selection mechanism. In other agentic CLI or IDE hosts, use the same process to optimize whatever short metadata controls routing, invocation, or command selection.

### Step 1: Generate trigger eval queries

Create 20 eval queries — a mix of should-trigger and should-not-trigger. Save them as JSON:

```json
[
  {"query": "the user prompt", "should_trigger": true},
  {"query": "another prompt", "should_trigger": false}
]
```

The queries must be realistic and should look like something a real user of the target host would actually type. They should be concrete, messy, and specific. Use file paths, project context, partial memories, casual phrasing, typos, or backstory when appropriate.

Bad:
- `"Format this data"`
- `"Extract text from PDF"`
- `"Create a chart"`

Good:
- `"ok so my boss just sent me this xlsx file in downloads called something like Q4 sales final FINAL v2.xlsx and wants a profit margin column. revenue is column C and costs are column D i think"`

For **should-trigger** queries, cover multiple phrasings of the same intent, including cases where the user does not explicitly name the skill.

For **should-not-trigger** queries, focus on near-misses. The best negatives share vocabulary or context with the skill but should still route somewhere else.

### Step 2: Review with the user

If the host supports local files or HTML review, use `assets/eval_review.html` to present the eval set for editing. Otherwise present it inline and let the user revise the JSON directly.

This step matters. Bad eval queries lead to bad selection metadata.

### Step 3: Run the optimization loop

If the current host supports the bundled automation, use it. The scripts in `scripts/run_eval.py` and `scripts/run_loop.py` are a working reference implementation for hosts that can publish temporary registry entries and run selection evals from the CLI.

If the current host does not support those scripts, run the same loop manually or with a host-specific wrapper:

1. Split the eval set into train and held-out test
2. Evaluate the current description or selection text across the eval set
3. Propose improvements using train failures only
4. Re-evaluate each new candidate on both train and test
5. Choose the best candidate by held-out test score, not train score

Do not overfit the description to the visible examples.

### How selection works

Most hosts only reach for a specialized workflow when the task is multi-step, specialized, or expensive enough that the default behavior is not obviously sufficient. Simple one-step prompts are weak evals because the base assistant may handle them directly without invoking any specialized workflow.

So make your selection evals substantive.

### Step 4: Apply the result

Take the best description or selection text, update the skill metadata, and show the user the before and after along with the measured results.

---

### Package and Present

If the host supports packaged skill bundles and `scripts/package_skill.py` works, use it.

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

If the host does not use that packaging format, deliver the folder itself along with any installation notes the user needs.

---

## Single-worker or constrained-host instructions

If the target host has no independent workers, limited local tooling, or no browser:

- Run candidate and baseline sequentially when parallel execution is unavailable
- Keep the same workspace structure so the artifacts stay comparable
- If you cannot launch the review surface, show outputs inline and collect feedback in the conversation, then normalize it into `feedback.json`
- If you cannot gather reliable timing or token metrics, leave them null or omitted rather than fabricating them
- Keep the human review step; do not silently replace it with your own judgment

## Tool-rich CLI/IDE instructions

If the target host has workers, filesystem access, local Python, and either a browser or static HTML rendering:

- Run the full candidate-versus-baseline loop
- Capture timing and usage data as runs complete
- Use the bundled scripts where they work
- Generate the review surface before revising the skill
- Prefer static HTML if there is no display
- Save description optimization until the core skill is already in good shape

---

## Reference files

The `agents/` directory contains instructions for specialized helper roles. Read them when you need them.

- `agents/grader.md` — grade assertions against outputs and transcripts
- `agents/comparator.md` — do blind A/B comparison between two outputs
- `agents/analyzer.md` — analyze why one version beat another and surface benchmark patterns

The `references/` directory contains additional documentation:
- `references/schemas.md` — canonical JSON structures for `evals.json`, `grading.json`, `benchmark.json`, and related artifacts

---

Repeating the core loop one more time for emphasis:

- Figure out what the skill is about
- Draft or edit the skill
- Run the task on realistic test prompts with the candidate workflow enabled
- With the user, evaluate the outputs
  - Create `benchmark.json` and use `eval-viewer/generate_review.py` or the closest supported review surface
  - Run quantitative evals when the task supports them
- Repeat until you and the user are satisfied
- Package or deliver the final skill and return it to the user

If you use a todo list, add explicit steps so you do not skip the eval loop or the human review step.

Good luck!
