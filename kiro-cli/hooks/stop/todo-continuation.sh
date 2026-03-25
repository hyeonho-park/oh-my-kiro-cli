#!/usr/bin/env bash
set -euo pipefail

cat > /dev/null

echo "Todo Continuation Check"
echo ""
echo "Before stopping, verify:"
echo "- [ ] All planned todos are marked 'completed'"
echo "- [ ] No todos are still 'in_progress' or 'pending'"
echo "- [ ] Diagnostics clean on changed files"
echo "- [ ] Build passes (if applicable)"
echo ""
echo "If todos remain incomplete, you MUST continue working."
echo "This is the boulder. Roll it until it reaches the top."
echo "Only stop if the user explicitly asks you to."

exit 0
