---
description: Preflight checks
argument-hint: Additional context or information (optional)
---

# Final PR checks

1. Review git history for current feature branch
2. Review GitHub issue associated with the branch
3. Has the issue been fully implemented and acceptance criteria met? If not, pause and inform the user of gaps and await further instructions. If yes, continue to next step...
4. Run `./scripts/check-all.sh ` and fix any issues
5. Report status to the user and wait for further instruction

- Additional context (if any): $ARGUMENTS
