---
description: Create initial project context documentation in .claude/context/ by analyzing the current project state and establishing comprehensive baseline documentation.
argument-hint: Additional context (optional)
---

# Create Initial Context

This command creates the initial project context documentation in `.claude/context/` by analyzing the current project state and establishing comprehensive baseline documentation.

Additional context (optional) $ARGUMENTS

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `.claude/rules/datetime.md` - For getting real current date/time

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress ("I'm not going to ..."). Just do them and move on.

### 1. Context Directory Check
- Run: `ls -la .claude/context/ 2>/dev/null`
- If directory exists and has files:
  - Count existing files: `ls -1 .claude/context/*.md 2>/dev/null | wc -l`
  - Ask user: "⚠️ Found {count} existing context files. Overwrite all context? (yes/no)"
  - Only proceed with explicit 'yes' confirmation
  - If user says no, suggest: "Use /context:update to refresh existing context"

### 2. Project Type Detection
- Check for project indicators:
  - Node.js: `test -f package.json && echo "Node.js project detected"`
  - Python: `test -f requirements.txt || test -f pyproject.toml && echo "Python project detected"`
  - Rust: `test -f Cargo.toml && echo "Rust project detected"`
  - Go: `test -f go.mod && echo "Go project detected"`
  - iOS: `find . -name '*.xcodeproj' 2>/dev/null | grep -q . && echo "iOS project detected"`
  - React Native: `test -f package.json && grep -qE '"(react-native|expo)"' package.json && echo "React Native project detected"`
- Run: `git status 2>/dev/null` to confirm this is a git repository
- If not a git repo, ask: "⚠️ Not a git repository. Continue anyway? (yes/no)"

### 3. Directory Creation
- If `.claude/` doesn't exist, create it: `mkdir -p .claude/context/`
- Verify write permissions: `touch .claude/context/.test && rm .claude/context/.test`
- If permission denied, tell user: "❌ Cannot create context directory. Check permissions."

### 4. Get Current DateTime
- Run: `date -u +"%Y-%m-%dT%H:%M:%SZ"`
- Store this value for use in all context file frontmatter

### 5. Awitch to Plan mode
- Switch to `Plan` mode for systematic execution of context creation steps

### 5. Read PRD

- Read @.claude/context/project-prd.md

## Instructions

### 1. Pre-Analysis Validation
- Confirm project root directory is correct (presence of .git, package.json, etc.)
- Check for existing documentation that can inform context (README.md, docs/, CLAUDE.md)
- If README.md doesn't exist, ask user for project description

### 2. Systematic Project Analysis
Gather information in this order:

1. Project detection
2. Documentation analysis
3. Codebase analysis

### 3. Context File Creation with Frontmatter

Each context file MUST include frontmatter with real datetime:

```yaml
---
created: [Use REAL datetime from date command]
last_updated: [Use REAL datetime from date command]
version: 1.0
author: Claude Code Assistant
---
```

Generate the following initial context files:

- Essential Context:

1. High-level understanding of the project: `.claude/context/project-context.md`
2. Technical stack and dependencies: `.claude/context/tech-context.md`
3. Testing framework and setup: `.claude/context/testing.md`

- Current State:

4. Current status and recent work: `.claude/context/progress.md`
5. Project structure: `.claude/context/project-structure.md`

- Deep Context:

6. Architecture and design patterns: `.claude/context/system-patterns.md`
7. Coding conventions: `.claude/context/project-style-guide.md`
8. Common workflows and commands: `.claude/context/development-commands.md`

### 4. Quality Validation

After creating each file:
- Verify file was created successfully
- Check file is not empty (minimum 10 lines of content)
- Ensure frontmatter is present and valid
- Validate markdown formatting is correct

### 5. Post-Creation Summary

Provide comprehensive summary:
```
📋 Context Creation Complete

📁 Created context in: .claude/context/
✅ Files created: {count}/9

📊 Context Summary:
  - Project Type: {detected_type}
  - Language: {primary_language}
  - Git Status: {clean/changes}
  - Dependencies: {count} packages

📝 File Details:
  ✅ progress.md ({lines} lines) - Current status and recent work
  ✅ project-structure.md ({lines} lines) - Directory organization
  [... list all files with line counts and brief description ...]

⏰ Created: {timestamp}
🔄 Next: Use /context:prime to load context in new sessions
💡 Tip: Run /context:update regularly to keep context current
```

## Context Gathering Commands

Use these commands to gather project information:
- Target directory: `.claude/context/` (create if needed)
- Current git status: `git status --short`
- Recent commits: `git log --oneline -50`
- Project README: Read `README.md` if exists
- Package files: Check for `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, etc.
- Documentation scan: `find . -type f -name '*.md' -path '*/docs/*' 2>/dev/null | head -10`
- Test detection: `find . -type d \( -name 'test' -o -name 'tests' -o -name '__tests__' -o -name 'spec' \) 2>/dev/null | head -5`

## Important Notes

- **Always use real datetime** from system clock, never placeholders
- **Ask for confirmation** before overwriting existing context
- **Validate each file** is created successfully
- **Provide detailed summary** of what was created
- **Handle errors gracefully** with specific guidance

Additional context (if any): $ARGUMENTS
