# Verification

Before declaring completion:
- verify the requested behavior directly
- run the narrowest relevant checks first
- fix issues introduced by your changes
- review changed files for unintended edits

## Completion gate
- the request is fully addressed
- changed files are internally consistent
- tests or checks relevant to the change pass
- remaining risks are called out clearly

## Review escalation
Use `oracle` or `code-reviewer` when:
- the change affects architecture
- the fix is security-sensitive
- the task required multiple file edits
- the user asked for a review
