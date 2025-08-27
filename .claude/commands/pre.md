---
description: Preflight checks
argument-hint: Additional context or information (optional)
---

# Final PR checks

- Run `./scripts/test.sh unit 1` and fix any issues
- Run `swiftformat . && swiftlint --fix && swiftlint` and fix all swiftlint errors and warnings
- Run `./scripts/test.sh ui 1` and fix any issues
- Report status to the user and wait for further instruction

- Additional context (if any): $ARGUMENTS
