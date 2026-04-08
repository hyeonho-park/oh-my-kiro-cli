#!/usr/bin/env bash
set -euo pipefail

cat > /dev/null

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

exit 0
