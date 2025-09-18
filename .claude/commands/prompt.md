---
description: Use this command to enter complex prompts that may fail if entered directly into the prompt input.
argument-hint: Additional context (optional)
allowed-tools: Read, Write, LS
---

I would like to edit this slash command: .claude/commands/pm/issue-edit.md\
In addition to it's current editing capabilities, I would like it to support:\

Deferrment: Issue is postponed indefinitely for re-assessment in the future and no longer part of the current epic scope\
  1. add labels: deferred, backlog (GitHub only)
  2. add note to issue \
  3. Update .claude/epics/[epic-name]/epic.md
  4. Update .claude/epics/[epic-name]/execution-status.md
  5. Update .claude/context/progress.md

AAnything else?

$ARGUMENTS
