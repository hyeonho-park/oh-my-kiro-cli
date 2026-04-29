#!/usr/bin/env bash
set -euo pipefail

# Consume stdin (stop hook payload — does not include todo state).
cat > /dev/null

# TODO: Add a companion post-tool-use hook on the 'todo' tool that writes this
# state file so the stop hook can gate on real todo state. Until that hook
# exists, the file must be written externally (e.g. by a pre/post-tool-use hook
# watching CreateTodo / UpdateTodo calls).
# Format: plaintext 'has_pending' or 'empty'.

# Derive session key from parent process-group ID (same as T3/T4 hooks).
SESSION_KEY="$(ps -o pgid= -p $$ | tr -d ' ')"
STATE_FILE="${HOME}/.kiro/state/oh-my-kiro-cli/todo-continuation/${SESSION_KEY}.cache"

# No state file → no todos were tracked this session; stay silent.
[[ ! -f "${STATE_FILE}" ]] && exit 0

STATE="$(cat "${STATE_FILE}")"

# Only emit when there are known pending todos.
if [[ "${STATE}" == "has_pending" ]]; then
  echo "=== TODO CONTINUATION ENFORCEMENT ==="
  echo ""
  echo "STOP. Check your todos before responding."
  echo ""
  echo "- INCOMPLETE TODOS: You have incomplete todos. Continue working — do not stop until all todos are done."
  echo "- IN-PROGRESS TODOS: Mark in_progress todos as completed if done, or continue working on them."
  echo "- PENDING TODOS: The boulder doesn't stop rolling. Resume the next pending todo NOW."
  echo ""
  echo "SKEPTICAL VERIFICATION:"
  echo "Before marking a todo as completed, verify the actual result — do not trust your own claim without evidence."
  echo "Run the check. Read the output. Confirm the file. Only then mark it done."
  echo ""
  echo "COMPLETION GATE:"
  echo "- [ ] All planned todos are marked 'completed'"
  echo "- [ ] No todos are still 'in_progress' or 'pending'"
  echo "- [ ] Diagnostics clean on changed files"
  echo "- [ ] Build passes (if applicable)"
  echo ""
  echo "If ANY todo remains incomplete, you MUST continue working."
  echo "This is the boulder. Roll it until it reaches the top."
  echo "Only stop if the user explicitly asks you to."
fi

exit 0
