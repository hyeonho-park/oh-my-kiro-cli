#!/usr/bin/env python3
"""Run the selection-eval + improvement loop until all pass or max iterations.

Combines run_eval.py and improve_description.py in a loop, tracking history
and returning the best description found. Supports train/test split to prevent
overfitting.
"""

import argparse
import json
import random
import sys
import tempfile
import time
import webbrowser
from pathlib import Path

from scripts.generate_report import generate_html
from scripts.improve_description import improve_description
from scripts.run_eval import DEFAULT_RUNNER_ARGS, find_project_root, run_eval
from scripts.utils import parse_skill_md


def split_eval_set(eval_set: list[dict], holdout: float, seed: int = 42) -> tuple[list[dict], list[dict]]:
    """Split eval set into train and test sets, stratified by should_trigger."""
    random.seed(seed)

    positive = [item for item in eval_set if item["should_trigger"]]
    negative = [item for item in eval_set if not item["should_trigger"]]

    random.shuffle(positive)
    random.shuffle(negative)

    n_positive_test = max(1, int(len(positive) * holdout))
    n_negative_test = max(1, int(len(negative) * holdout))

    test_set = positive[:n_positive_test] + negative[:n_negative_test]
    train_set = positive[n_positive_test:] + negative[n_negative_test:]
    return train_set, test_set


def run_loop(
    eval_set: list[dict],
    skill_path: Path,
    description_override: str | None,
    num_workers: int,
    timeout: int,
    max_iterations: int,
    runs_per_query: int,
    trigger_threshold: float,
    holdout: float,
    model: str,
    verbose: bool,
    marker_dir: str = ".claude",
    runner_command: str = "claude",
    runner_args_json: str = DEFAULT_RUNNER_ARGS,
    registry_relative_path: str = ".claude/commands",
    detection_mode: str = "claude-tool-use",
    tool_names_csv: str = "Skill,Read",
    trigger_substring: str | None = None,
    env_strip_csv: str = "CLAUDECODE",
    optimizer_command: str | None = None,
    live_report_path: Path | None = None,
    open_report: bool = False,
    log_dir: Path | None = None,
) -> dict:
    """Run the eval + improvement loop."""
    project_root = find_project_root(marker_dir)
    name, original_description, content = parse_skill_md(skill_path)
    current_description = description_override or original_description

    if holdout > 0:
        train_set, test_set = split_eval_set(eval_set, holdout)
        if verbose:
            print(f"Split: {len(train_set)} train, {len(test_set)} test (holdout={holdout})", file=sys.stderr)
    else:
        train_set = eval_set
        test_set = []

    history = []
    exit_reason = "unknown"

    if live_report_path and open_report:
        webbrowser.open(str(live_report_path))

    for iteration in range(1, max_iterations + 1):
        if verbose:
            print(f"\n{'=' * 60}", file=sys.stderr)
            print(f"Iteration {iteration}/{max_iterations}", file=sys.stderr)
            print(f"Description: {current_description}", file=sys.stderr)
            print(f"{'=' * 60}", file=sys.stderr)

        all_queries = train_set + test_set
        started_at = time.time()
        all_results = run_eval(
            eval_set=all_queries,
            skill_name=name,
            description=current_description,
            num_workers=num_workers,
            timeout=timeout,
            project_root=project_root,
            runs_per_query=runs_per_query,
            trigger_threshold=trigger_threshold,
            model=model,
            runner_command=runner_command,
            runner_args_json=runner_args_json,
            registry_relative_path=registry_relative_path,
            detection_mode=detection_mode,
            tool_names_csv=tool_names_csv,
            trigger_substring=trigger_substring,
            env_strip_csv=env_strip_csv,
        )
        eval_elapsed = time.time() - started_at

        train_queries = {item["query"] for item in train_set}
        train_result_list = [result for result in all_results["results"] if result["query"] in train_queries]
        test_result_list = [result for result in all_results["results"] if result["query"] not in train_queries]

        train_passed = sum(1 for result in train_result_list if result["pass"])
        train_total = len(train_result_list)
        train_summary = {"passed": train_passed, "failed": train_total - train_passed, "total": train_total}
        train_results = {"results": train_result_list, "summary": train_summary}

        if test_set:
            test_passed = sum(1 for result in test_result_list if result["pass"])
            test_total = len(test_result_list)
            test_summary = {"passed": test_passed, "failed": test_total - test_passed, "total": test_total}
            test_results = {"results": test_result_list, "summary": test_summary}
        else:
            test_summary = None
            test_results = None

        history.append({
            "iteration": iteration,
            "description": current_description,
            "train_passed": train_summary["passed"],
            "train_failed": train_summary["failed"],
            "train_total": train_summary["total"],
            "train_results": train_results["results"],
            "test_passed": test_summary["passed"] if test_summary else None,
            "test_failed": test_summary["failed"] if test_summary else None,
            "test_total": test_summary["total"] if test_summary else None,
            "test_results": test_results["results"] if test_results else None,
            "passed": train_summary["passed"],
            "failed": train_summary["failed"],
            "total": train_summary["total"],
            "results": train_results["results"],
        })

        if live_report_path:
            partial_output = {
                "original_description": original_description,
                "best_description": current_description,
                "best_score": "in progress",
                "iterations_run": len(history),
                "holdout": holdout,
                "train_size": len(train_set),
                "test_size": len(test_set),
                "history": history,
            }
            live_report_path.write_text(generate_html(partial_output, auto_refresh=True, skill_name=name))

        if verbose:
            def print_eval_stats(label: str, results: list[dict], elapsed: float) -> None:
                positive = [result for result in results if result["should_trigger"]]
                negative = [result for result in results if not result["should_trigger"]]
                true_positive = sum(result["triggers"] for result in positive)
                positive_runs = sum(result["runs"] for result in positive)
                false_negative = positive_runs - true_positive
                false_positive = sum(result["triggers"] for result in negative)
                negative_runs = sum(result["runs"] for result in negative)
                true_negative = negative_runs - false_positive
                total = true_positive + true_negative + false_positive + false_negative
                precision = true_positive / (true_positive + false_positive) if (true_positive + false_positive) > 0 else 1.0
                recall = true_positive / (true_positive + false_negative) if (true_positive + false_negative) > 0 else 1.0
                accuracy = (true_positive + true_negative) / total if total > 0 else 0.0
                print(
                    f"{label}: {true_positive + true_negative}/{total} correct, precision={precision:.0%} recall={recall:.0%} accuracy={accuracy:.0%} ({elapsed:.1f}s)",
                    file=sys.stderr,
                )
                for result in results:
                    status = "PASS" if result["pass"] else "FAIL"
                    rate_str = f"{result['triggers']}/{result['runs']}"
                    print(
                        f"  [{status}] rate={rate_str} expected={result['should_trigger']}: {result['query'][:60]}",
                        file=sys.stderr,
                    )

            print_eval_stats("Train", train_results["results"], eval_elapsed)
            if test_summary:
                print_eval_stats("Test ", test_results["results"], 0)

        if train_summary["failed"] == 0:
            exit_reason = f"all_passed (iteration {iteration})"
            if verbose:
                print(f"\nAll train queries passed on iteration {iteration}!", file=sys.stderr)
            break

        if iteration == max_iterations:
            exit_reason = f"max_iterations ({max_iterations})"
            if verbose:
                print(f"\nMax iterations reached ({max_iterations}).", file=sys.stderr)
            break

        if verbose:
            print("\nImproving description...", file=sys.stderr)

        started_at = time.time()
        blinded_history = [
            {key: value for key, value in item.items() if not key.startswith("test_")}
            for item in history
        ]
        new_description = improve_description(
            skill_name=name,
            skill_content=content,
            current_description=current_description,
            eval_results=train_results,
            history=blinded_history,
            model=model,
            log_dir=log_dir,
            iteration=iteration,
            optimizer_command=optimizer_command,
        )
        improve_elapsed = time.time() - started_at

        if verbose:
            print(f"Proposed ({improve_elapsed:.1f}s): {new_description}", file=sys.stderr)

        current_description = new_description

    if test_set:
        best = max(history, key=lambda item: item["test_passed"] or 0)
        best_score = f"{best['test_passed']}/{best['test_total']}"
    else:
        best = max(history, key=lambda item: item["train_passed"])
        best_score = f"{best['train_passed']}/{best['train_total']}"

    if verbose:
        print(f"\nExit reason: {exit_reason}", file=sys.stderr)
        print(f"Best score: {best_score} (iteration {best['iteration']})", file=sys.stderr)

    return {
        "exit_reason": exit_reason,
        "original_description": original_description,
        "best_description": best["description"],
        "best_score": best_score,
        "best_train_score": f"{best['train_passed']}/{best['train_total']}",
        "best_test_score": f"{best['test_passed']}/{best['test_total']}" if test_set else None,
        "final_description": current_description,
        "iterations_run": len(history),
        "holdout": holdout,
        "train_size": len(train_set),
        "test_size": len(test_set),
        "history": history,
    }



def main():
    parser = argparse.ArgumentParser(description="Run selection-eval + improve loop")
    parser.add_argument("--eval-set", required=True, help="Path to eval set JSON file")
    parser.add_argument("--skill-path", required=True, help="Path to skill directory")
    parser.add_argument("--description", default=None, help="Override starting description")
    parser.add_argument("--num-workers", type=int, default=10, help="Number of parallel workers")
    parser.add_argument("--timeout", type=int, default=30, help="Timeout per query in seconds")
    parser.add_argument("--max-iterations", type=int, default=5, help="Max improvement iterations")
    parser.add_argument("--runs-per-query", type=int, default=3, help="Number of runs per query")
    parser.add_argument("--trigger-threshold", type=float, default=0.5, help="Trigger rate threshold")
    parser.add_argument("--holdout", type=float, default=0.4, help="Fraction of eval set to hold out for testing (0 to disable)")
    parser.add_argument("--model", required=True, help="Model identifier for the optimizer backend")
    parser.add_argument("--marker-dir", default=".claude", help="Directory marker used to find the project root")
    parser.add_argument("--registry-relative-path", default=".claude/commands", help="Relative directory used to publish temporary registry entries")
    parser.add_argument("--runner-command", default="claude", help="CLI command used to execute raw queries")
    parser.add_argument("--runner-args-json", default=DEFAULT_RUNNER_ARGS, help="JSON array of arguments appended after the runner command. Supports {query} and {model} placeholders.")
    parser.add_argument("--detection-mode", choices=["claude-tool-use", "substring"], default="claude-tool-use", help="How to detect that the skill or workflow was selected")
    parser.add_argument("--tool-names", default="Skill,Read", help="Comma-separated tool names treated as selection evidence in claude-tool-use mode")
    parser.add_argument("--trigger-substring", default=None, help="Substring used for substring detection mode. Defaults to the temporary registry entry name.")
    parser.add_argument("--env-strip", default="CLAUDECODE", help="Comma-separated environment variables to remove before launching the runner")
    parser.add_argument("--optimizer-command", default=None, help="Optional executable that accepts one JSON payload file path and returns either raw text or JSON with text/thinking fields")
    parser.add_argument("--verbose", action="store_true", help="Print progress to stderr")
    parser.add_argument("--report", default="auto", help="Generate HTML report at this path (default: 'auto' for temp file, 'none' to disable)")
    parser.add_argument("--open-report", action="store_true", help="Open the generated report in a browser if the host has one")
    parser.add_argument("--results-dir", default=None, help="Save all outputs (results.json, report.html, log.txt) to a timestamped subdirectory here")
    args = parser.parse_args()

    eval_set = json.loads(Path(args.eval_set).read_text())
    skill_path = Path(args.skill_path)

    if not (skill_path / "SKILL.md").exists():
        print(f"Error: No SKILL.md found at {skill_path}", file=sys.stderr)
        sys.exit(1)

    name, _, _ = parse_skill_md(skill_path)

    if args.report != "none":
        if args.report == "auto":
            timestamp = time.strftime("%Y%m%d_%H%M%S")
            live_report_path = Path(tempfile.gettempdir()) / f"skill_description_report_{skill_path.name}_{timestamp}.html"
        else:
            live_report_path = Path(args.report)
        live_report_path.write_text("<html><body><h1>Starting optimization loop...</h1><meta http-equiv='refresh' content='5'></body></html>")
    else:
        live_report_path = None

    if args.results_dir:
        timestamp = time.strftime("%Y-%m-%d_%H%M%S")
        results_dir = Path(args.results_dir) / timestamp
        results_dir.mkdir(parents=True, exist_ok=True)
    else:
        results_dir = None

    log_dir = results_dir / "logs" if results_dir else None

    output = run_loop(
        eval_set=eval_set,
        skill_path=skill_path,
        description_override=args.description,
        num_workers=args.num_workers,
        timeout=args.timeout,
        max_iterations=args.max_iterations,
        runs_per_query=args.runs_per_query,
        trigger_threshold=args.trigger_threshold,
        holdout=args.holdout,
        model=args.model,
        verbose=args.verbose,
        marker_dir=args.marker_dir,
        runner_command=args.runner_command,
        runner_args_json=args.runner_args_json,
        registry_relative_path=args.registry_relative_path,
        detection_mode=args.detection_mode,
        tool_names_csv=args.tool_names,
        trigger_substring=args.trigger_substring,
        env_strip_csv=args.env_strip,
        optimizer_command=args.optimizer_command,
        live_report_path=live_report_path,
        open_report=args.open_report,
        log_dir=log_dir,
    )

    json_output = json.dumps(output, indent=2)
    print(json_output)
    if results_dir:
        (results_dir / "results.json").write_text(json_output)

    if live_report_path:
        final_report = generate_html(output, auto_refresh=False, skill_name=name)
        live_report_path.write_text(final_report)
        print(f"\nReport: {live_report_path}", file=sys.stderr)
        if results_dir:
            (results_dir / "report.html").write_text(final_report)

    if results_dir:
        print(f"Results saved to: {results_dir}", file=sys.stderr)


if __name__ == "__main__":
    main()
