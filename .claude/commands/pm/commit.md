---
allowed-tools: Read, Write, Bash(gh pr view:*), Bash(echo:*), Bash(git add:*)
description: Commit changes with a descriptive message
argument-hint: Issue number (optional)
model: sonnet
---

# Commit Changes
```bash
git add {files}
git commit -m "Issue #{number}: {change}"
```
**IMPORTANT**: Fix all SwiftLint violations if encountered.

Issue number (if provided): $ARGUMENTS