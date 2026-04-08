#!/usr/bin/env python3
"""Improve a skill description based on eval results.

Takes eval results from run_eval.py and generates improved selection metadata
for a skill or reusable workflow bundle.
"""

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

from scripts.utils import parse_skill_md


MAX_TOKENS = 16000
THINKING_BUDGET = 10000
DESCRIPTION_CHAR_LIMIT = 1024



def extract_text_from_response(response: Any) -> tuple[str, str]:
    if isinstance(response, dict):
        thinking = str(response.get("thinking", ""))
        text = str(response.get("text") or response.get("response") or response.get("content") or "")
        return thinking, text

    content = getattr(response, "content", None)
    if content is None:
        return "", str(response)

    thinking_text = ""
    text = ""
    for block in content:
        block_type = getattr(block, "type", None)
        if block_type == "thinking":
            thinking_text = getattr(block, "thinking", "")
        elif block_type == "text":
            text = getattr(block, "text", "")
    return thinking_text, text



def run_anthropic_messages(messages: list[dict], model: str) -> tuple[str, str]:
    try:
        import anthropic
    except ImportError as exc:
        raise RuntimeError(
            "anthropic package is required unless you provide --optimizer-command"
        ) from exc

    client = anthropic.Anthropic()
    response = client.messages.create(
        model=model,
        max_tokens=MAX_TOKENS,
        thinking={
            "type": "enabled",
            "budget_tokens": THINKING_BUDGET,
        },
        messages=messages,
    )
    return extract_text_from_response(response)



def run_optimizer_command(command_path: str, messages: list[dict], model: str) -> tuple[str, str]:
    payload = {
        "model": model,
        "max_tokens": MAX_TOKENS,
        "thinking_budget": THINKING_BUDGET,
        "messages": messages,
    }

    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as handle:
        json.dump(payload, handle)
        payload_path = Path(handle.name)

    try:
        completed = subprocess.run(
            [command_path, str(payload_path)],
            capture_output=True,
            text=True,
            check=False,
        )
        if completed.returncode != 0:
            raise RuntimeError(
                f"optimizer command failed with exit code {completed.returncode}: {completed.stderr.strip()}"
            )

        stdout = completed.stdout.strip()
        if not stdout:
            raise RuntimeError("optimizer command produced no stdout")

        try:
            parsed = json.loads(stdout)
        except json.JSONDecodeError:
            return "", stdout

        return extract_text_from_response(parsed)
    finally:
        payload_path.unlink(missing_ok=True)



def request_optimizer_response(
    messages: list[dict],
    model: str,
    optimizer_command: str | None = None,
) -> tuple[str, str]:
    if optimizer_command:
        return run_optimizer_command(optimizer_command, messages, model)
    return run_anthropic_messages(messages, model)



def parse_description(text: str) -> str:
    match = re.search(r"<new_description>(.*?)</new_description>", text, re.DOTALL)
    if match:
        return match.group(1).strip().strip('"')
    return text.strip().strip('"')



def build_optimizer_prompt(
    skill_name: str,
    skill_content: str,
    current_description: str,
    eval_results: dict,
    history: list[dict],
    test_results: dict | None = None,
) -> str:
    failed_triggers = [
        result for result in eval_results["results"]
        if result["should_trigger"] and not result["pass"]
    ]
    false_triggers = [
        result for result in eval_results["results"]
        if not result["should_trigger"] and not result["pass"]
    ]

    train_score = f"{eval_results['summary']['passed']}/{eval_results['summary']['total']}"
    if test_results:
        test_score = f"{test_results['summary']['passed']}/{test_results['summary']['total']}"
        scores_summary = f"Train: {train_score}, Test: {test_score}"
    else:
        scores_summary = f"Train: {train_score}"

    prompt = f"""You are optimizing short selection metadata for a reusable skill or workflow bundle called \"{skill_name}\".

In some hosts this metadata appears as the SKILL.md description in a visible registry. In other hosts it acts as router text, command help text, or invocation metadata. The host typically decides whether to select the workflow based primarily on the title and this short description. Your goal is to write metadata that gets selected for relevant queries and skipped for irrelevant ones.

Here is the current description:
<current_description>
\"{current_description}\"
</current_description>

Current scores ({scores_summary}):
<scores_summary>
"""

    if failed_triggers:
        prompt += "FAILED TO SELECT (should have selected but didn't):\n"
        for result in failed_triggers:
            prompt += f'  - "{result["query"]}" (selected {result["triggers"]}/{result["runs"]} times)\n'
        prompt += "\n"

    if false_triggers:
        prompt += "FALSE SELECTIONS (selected but shouldn't have):\n"
        for result in false_triggers:
            prompt += f'  - "{result["query"]}" (selected {result["triggers"]}/{result["runs"]} times)\n'
        prompt += "\n"

    if history:
        prompt += "PREVIOUS ATTEMPTS (do NOT repeat these — try something structurally different):\n\n"
        for item in history:
            train_s = f"{item.get('train_passed', item.get('passed', 0))}/{item.get('train_total', item.get('total', 0))}"
            test_s = f"{item.get('test_passed', '?')}/{item.get('test_total', '?')}" if item.get('test_passed') is not None else None
            score_str = f"train={train_s}" + (f", test={test_s}" if test_s else "")
            prompt += f"<attempt {score_str}>\n"
            prompt += f'Description: "{item["description"]}"\n'
            if "results" in item:
                prompt += "Train results:\n"
                for result in item["results"]:
                    status = "PASS" if result["pass"] else "FAIL"
                    prompt += f'  [{status}] "{result["query"][:80]}" (selected {result["triggers"]}/{result["runs"]})\n'
            if item.get("note"):
                prompt += f'Note: {item["note"]}\n'
            prompt += "</attempt>\n\n"

    prompt += f"""</scores_summary>

Skill content (for context on what the skill does):
<skill_content>
{skill_content}
</skill_content>

Based on the failures, write a new and improved description that is more likely to select correctly. Generalize from the failures instead of memorizing the exact examples. We do NOT want an ever-expanding list of narrow trigger phrases.

The constraints are:
1. Avoid overfitting
2. Keep the description compact because this text may be loaded or consulted frequently
3. Preserve the skill's real scope rather than chasing individual examples

Concretely, aim for about 100-200 words even if that costs a little accuracy.

Helpful heuristics:
- Phrase the description imperatively when possible
- Focus on the user's intent rather than the implementation details
- Make the workflow distinctive and easy to recognize among competing skills or commands
- If repeated attempts fail, change the structure instead of doing tiny word swaps

Respond with only the new description text inside <new_description> tags, nothing else."""

    return prompt



def improve_description(
    skill_name: str,
    skill_content: str,
    current_description: str,
    eval_results: dict,
    history: list[dict],
    model: str,
    test_results: dict | None = None,
    log_dir: Path | None = None,
    iteration: int | None = None,
    optimizer_command: str | None = None,
) -> str:
    """Improve the selection description based on eval results."""
    prompt = build_optimizer_prompt(
        skill_name=skill_name,
        skill_content=skill_content,
        current_description=current_description,
        eval_results=eval_results,
        history=history,
        test_results=test_results,
    )

    messages = [{"role": "user", "content": prompt}]
    thinking_text, text = request_optimizer_response(messages, model, optimizer_command)
    description = parse_description(text)

    transcript: dict = {
        "iteration": iteration,
        "prompt": prompt,
        "thinking": thinking_text,
        "response": text,
        "parsed_description": description,
        "char_count": len(description),
        "over_limit": len(description) > DESCRIPTION_CHAR_LIMIT,
        "optimizer_command": optimizer_command,
    }

    if len(description) > DESCRIPTION_CHAR_LIMIT:
        shorten_prompt = (
            f"Your description is {len(description)} characters, which exceeds the hard {DESCRIPTION_CHAR_LIMIT} character limit. "
            "Rewrite it under the limit while preserving the most important selection cues and intent coverage. "
            "Respond with only the new description in <new_description> tags."
        )
        shorten_messages = [
            {"role": "user", "content": prompt},
            {"role": "assistant", "content": text},
            {"role": "user", "content": shorten_prompt},
        ]
        shorten_thinking, shorten_text = request_optimizer_response(
            shorten_messages,
            model,
            optimizer_command,
        )
        shortened = parse_description(shorten_text)

        transcript["rewrite_prompt"] = shorten_prompt
        transcript["rewrite_thinking"] = shorten_thinking
        transcript["rewrite_response"] = shorten_text
        transcript["rewrite_description"] = shortened
        transcript["rewrite_char_count"] = len(shortened)
        description = shortened

    transcript["final_description"] = description

    if log_dir:
        log_dir.mkdir(parents=True, exist_ok=True)
        log_file = log_dir / f"improve_iter_{iteration or 'unknown'}.json"
        log_file.write_text(json.dumps(transcript, indent=2))

    return description



def main():
    parser = argparse.ArgumentParser(description="Improve a skill description based on eval results")
    parser.add_argument("--eval-results", required=True, help="Path to eval results JSON (from run_eval.py)")
    parser.add_argument("--skill-path", required=True, help="Path to skill directory")
    parser.add_argument("--history", default=None, help="Path to history JSON (previous attempts)")
    parser.add_argument("--model", required=True, help="Model identifier for the optimizer backend")
    parser.add_argument("--optimizer-command", default=None, help="Optional executable that accepts one JSON payload file path and returns either raw text or JSON with text/thinking fields")
    parser.add_argument("--verbose", action="store_true", help="Print progress to stderr")
    args = parser.parse_args()

    skill_path = Path(args.skill_path)
    if not (skill_path / "SKILL.md").exists():
        print(f"Error: No SKILL.md found at {skill_path}", file=sys.stderr)
        sys.exit(1)

    eval_results = json.loads(Path(args.eval_results).read_text())
    history = []
    if args.history:
        history = json.loads(Path(args.history).read_text())

    name, _, content = parse_skill_md(skill_path)
    current_description = eval_results["description"]

    if args.verbose:
        print(f"Current: {current_description}", file=sys.stderr)
        print(f"Score: {eval_results['summary']['passed']}/{eval_results['summary']['total']}", file=sys.stderr)

    new_description = improve_description(
        skill_name=name,
        skill_content=content,
        current_description=current_description,
        eval_results=eval_results,
        history=history,
        model=args.model,
        optimizer_command=args.optimizer_command,
    )

    if args.verbose:
        print(f"Improved: {new_description}", file=sys.stderr)

    output = {
        "description": new_description,
        "history": history + [{
            "description": current_description,
            "passed": eval_results["summary"]["passed"],
            "failed": eval_results["summary"]["failed"],
            "total": eval_results["summary"]["total"],
            "results": eval_results["results"],
        }],
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
