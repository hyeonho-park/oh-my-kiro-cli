#!/usr/bin/env python3
"""Run selection evaluation for a skill description.

Tests whether a skill or workflow description causes the target host to select
that workflow for a set of queries. Outputs results as JSON.
"""

import argparse
import json
import os
import select
import subprocess
import sys
import time
import uuid
from concurrent.futures import ProcessPoolExecutor, as_completed
from pathlib import Path

from scripts.utils import parse_skill_md


DEFAULT_RUNNER_ARGS = json.dumps([
    "-p",
    "{query}",
    "--output-format",
    "stream-json",
    "--verbose",
    "--include-partial-messages",
])


def parse_csv(raw: str) -> list[str]:
    return [item.strip() for item in raw.split(",") if item.strip()]



def find_project_root(marker_dir: str = ".claude") -> Path:
    """Find the nearest ancestor containing the host marker directory."""
    current = Path.cwd()
    for parent in [current, *current.parents]:
        if (parent / marker_dir).is_dir():
            return parent
    return current



def render_runner_args(template_json: str, query: str, model: str | None) -> list[str]:
    try:
        template = json.loads(template_json)
    except json.JSONDecodeError as exc:
        raise ValueError("runner-args-json must be a valid JSON array of strings") from exc

    if not isinstance(template, list) or not all(isinstance(item, str) for item in template):
        raise ValueError("runner-args-json must be a JSON array of strings")

    rendered: list[str] = []
    for item in template:
        value = item.replace("{query}", query)
        value = value.replace("{model}", model or "")
        if value:
            rendered.append(value)
    return rendered



def write_registry_entry(
    registry_dir: Path,
    clean_name: str,
    skill_name: str,
    skill_description: str,
) -> Path:
    registry_dir.mkdir(parents=True, exist_ok=True)
    entry_path = registry_dir / f"{clean_name}.md"
    indented_desc = "\n  ".join(skill_description.split("\n"))
    entry_path.write_text(
        "---\n"
        "description: |\n"
        f"  {indented_desc}\n"
        "---\n\n"
        f"# {skill_name}\n\n"
        f"This workflow handles: {skill_description}\n"
    )
    return entry_path



def run_single_query(
    query: str,
    skill_name: str,
    skill_description: str,
    timeout: int,
    project_root: str,
    model: str | None = None,
    runner_command: str = "claude",
    runner_args_json: str = DEFAULT_RUNNER_ARGS,
    registry_relative_path: str = ".claude/commands",
    detection_mode: str = "claude-tool-use",
    tool_names_csv: str = "Skill,Read",
    trigger_substring: str | None = None,
    env_strip_csv: str = "CLAUDECODE",
) -> bool:
    """Run a single query and return whether the workflow was selected."""
    unique_id = uuid.uuid4().hex[:8]
    clean_name = f"{skill_name}-skill-{unique_id}"
    registry_dir = Path(project_root) / registry_relative_path
    entry_path = write_registry_entry(registry_dir, clean_name, skill_name, skill_description)
    tool_names = set(parse_csv(tool_names_csv))
    substring_match = trigger_substring or clean_name

    try:
        cmd = [runner_command, *render_runner_args(runner_args_json, query, model)]
        stripped_env_keys = set(parse_csv(env_strip_csv))
        env = {k: v for k, v in os.environ.items() if k not in stripped_env_keys}

        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            cwd=project_root,
            env=env,
        )

        triggered = False
        start_time = time.time()
        buffer = ""
        pending_tool_name = None
        accumulated_json = ""

        try:
            while time.time() - start_time < timeout:
                if process.poll() is not None:
                    remaining = process.stdout.read()
                    if remaining:
                        buffer += remaining.decode("utf-8", errors="replace")
                    break

                ready, _, _ = select.select([process.stdout], [], [], 1.0)
                if not ready:
                    continue

                chunk = os.read(process.stdout.fileno(), 8192)
                if not chunk:
                    break
                buffer += chunk.decode("utf-8", errors="replace")

                if detection_mode == "substring" and substring_match in buffer:
                    return True

                while detection_mode == "claude-tool-use" and "\n" in buffer:
                    line, buffer = buffer.split("\n", 1)
                    line = line.strip()
                    if not line:
                        continue

                    try:
                        event = json.loads(line)
                    except json.JSONDecodeError:
                        continue

                    if event.get("type") == "stream_event":
                        stream_event = event.get("event", {})
                        stream_type = stream_event.get("type", "")

                        if stream_type == "content_block_start":
                            content_block = stream_event.get("content_block", {})
                            if content_block.get("type") == "tool_use":
                                tool_name = content_block.get("name", "")
                                if tool_name in tool_names:
                                    pending_tool_name = tool_name
                                    accumulated_json = ""
                                else:
                                    return False

                        elif stream_type == "content_block_delta" and pending_tool_name:
                            delta = stream_event.get("delta", {})
                            if delta.get("type") == "input_json_delta":
                                accumulated_json += delta.get("partial_json", "")
                                if clean_name in accumulated_json:
                                    return True

                        elif stream_type in ("content_block_stop", "message_stop"):
                            if pending_tool_name:
                                return clean_name in accumulated_json
                            if stream_type == "message_stop":
                                return False

                    elif event.get("type") == "assistant":
                        message = event.get("message", {})
                        for content_item in message.get("content", []):
                            if content_item.get("type") != "tool_use":
                                continue
                            tool_name = content_item.get("name", "")
                            tool_input = content_item.get("input", {})
                            serialized_input = json.dumps(tool_input)
                            if tool_name in tool_names and clean_name in serialized_input:
                                triggered = True
                            return triggered

                    elif event.get("type") == "result":
                        return triggered
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()

        if detection_mode == "substring":
            return substring_match in buffer
        return triggered
    finally:
        if entry_path.exists():
            entry_path.unlink()



def run_eval(
    eval_set: list[dict],
    skill_name: str,
    description: str,
    num_workers: int,
    timeout: int,
    project_root: Path,
    runs_per_query: int = 1,
    trigger_threshold: float = 0.5,
    model: str | None = None,
    runner_command: str = "claude",
    runner_args_json: str = DEFAULT_RUNNER_ARGS,
    registry_relative_path: str = ".claude/commands",
    detection_mode: str = "claude-tool-use",
    tool_names_csv: str = "Skill,Read",
    trigger_substring: str | None = None,
    env_strip_csv: str = "CLAUDECODE",
) -> dict:
    """Run the full eval set and return results."""
    results = []

    with ProcessPoolExecutor(max_workers=num_workers) as executor:
        future_to_info = {}
        for item in eval_set:
            for run_idx in range(runs_per_query):
                future = executor.submit(
                    run_single_query,
                    item["query"],
                    skill_name,
                    description,
                    timeout,
                    str(project_root),
                    model,
                    runner_command,
                    runner_args_json,
                    registry_relative_path,
                    detection_mode,
                    tool_names_csv,
                    trigger_substring,
                    env_strip_csv,
                )
                future_to_info[future] = (item, run_idx)

        query_triggers: dict[str, list[bool]] = {}
        query_items: dict[str, dict] = {}
        for future in as_completed(future_to_info):
            item, _ = future_to_info[future]
            query = item["query"]
            query_items[query] = item
            if query not in query_triggers:
                query_triggers[query] = []
            try:
                query_triggers[query].append(future.result())
            except Exception as exc:
                print(f"Warning: query failed: {exc}", file=sys.stderr)
                query_triggers[query].append(False)

    for query, triggers in query_triggers.items():
        item = query_items[query]
        trigger_rate = sum(triggers) / len(triggers)
        should_trigger = item["should_trigger"]
        did_pass = trigger_rate >= trigger_threshold if should_trigger else trigger_rate < trigger_threshold
        results.append({
            "query": query,
            "should_trigger": should_trigger,
            "trigger_rate": trigger_rate,
            "triggers": sum(triggers),
            "runs": len(triggers),
            "pass": did_pass,
        })

    passed = sum(1 for result in results if result["pass"])
    total = len(results)

    return {
        "skill_name": skill_name,
        "description": description,
        "results": results,
        "summary": {
            "total": total,
            "passed": passed,
            "failed": total - passed,
        },
    }



def main():
    parser = argparse.ArgumentParser(description="Run selection evaluation for a skill description")
    parser.add_argument("--eval-set", required=True, help="Path to eval set JSON file")
    parser.add_argument("--skill-path", required=True, help="Path to skill directory")
    parser.add_argument("--description", default=None, help="Override description to test")
    parser.add_argument("--num-workers", type=int, default=10, help="Number of parallel workers")
    parser.add_argument("--timeout", type=int, default=30, help="Timeout per query in seconds")
    parser.add_argument("--runs-per-query", type=int, default=3, help="Number of runs per query")
    parser.add_argument("--trigger-threshold", type=float, default=0.5, help="Trigger rate threshold")
    parser.add_argument("--model", default=None, help="Optional model identifier passed through to the runner")
    parser.add_argument("--marker-dir", default=".claude", help="Directory marker used to find the project root")
    parser.add_argument("--registry-relative-path", default=".claude/commands", help="Relative directory used to publish temporary registry entries")
    parser.add_argument("--runner-command", default="claude", help="CLI command used to execute raw queries")
    parser.add_argument("--runner-args-json", default=DEFAULT_RUNNER_ARGS, help="JSON array of arguments appended after the runner command. Supports {query} and {model} placeholders.")
    parser.add_argument("--detection-mode", choices=["claude-tool-use", "substring"], default="claude-tool-use", help="How to detect that the skill or workflow was selected")
    parser.add_argument("--tool-names", default="Skill,Read", help="Comma-separated tool names treated as selection evidence in claude-tool-use mode")
    parser.add_argument("--trigger-substring", default=None, help="Substring used for substring detection mode. Defaults to the temporary registry entry name.")
    parser.add_argument("--env-strip", default="CLAUDECODE", help="Comma-separated environment variables to remove before launching the runner")
    parser.add_argument("--verbose", action="store_true", help="Print progress to stderr")
    args = parser.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text())
    skill_path = Path(args.skill_path)

    if not (skill_path / "SKILL.md").exists():
        print(f"Error: No SKILL.md found at {skill_path}", file=sys.stderr)
        sys.exit(1)

    name, original_description, _ = parse_skill_md(skill_path)
    description = args.description or original_description
    project_root = find_project_root(args.marker_dir)

    if args.verbose:
        print(f"Evaluating selection metadata: {description}", file=sys.stderr)

    output = run_eval(
        eval_set=eval_set,
        skill_name=name,
        description=description,
        num_workers=args.num_workers,
        timeout=args.timeout,
        project_root=project_root,
        runs_per_query=args.runs_per_query,
        trigger_threshold=args.trigger_threshold,
        model=args.model,
        runner_command=args.runner_command,
        runner_args_json=args.runner_args_json,
        registry_relative_path=args.registry_relative_path,
        detection_mode=args.detection_mode,
        tool_names_csv=args.tool_names,
        trigger_substring=args.trigger_substring,
        env_strip_csv=args.env_strip,
    )

    if args.verbose:
        summary = output["summary"]
        print(f"Results: {summary['passed']}/{summary['total']} passed", file=sys.stderr)
        for result in output["results"]:
            status = "PASS" if result["pass"] else "FAIL"
            rate_str = f"{result['triggers']}/{result['runs']}"
            print(f"  [{status}] rate={rate_str} expected={result['should_trigger']}: {result['query'][:70]}", file=sys.stderr)

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
