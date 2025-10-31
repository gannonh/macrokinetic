---
description: Add an arbitrary learning to the context
argument-hint: file path or paste content
allowed-tools: 
---

Update project context with an important new learning.

## Instructions

### 1. Load Context:

@.claude/context/testing.md
@.claude/context/tech-context.md
@.claude/context/system-patterns.md
@.claude/context/project-style-guide.md
@.claude/context/development-commands.md
@.claude/context/project-structure.md

### 2. Read learning

New learning: $ARGUMENTS

### 4. Update context

Integrate this new learning into the appropriate context file(s). Practice DRY: do not repeat the same content in multiple files