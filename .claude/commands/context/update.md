---
description: Update project context documentation to reflect current state of the project.
---

# Update Context

This command updates the project context documentation in `.claude/context/` to reflect the current state of the project. Run this at the end of a PR or development session to keep context accurate for future sessions.

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `.claude/rules/datetime.md` - For getting real current date/time

## Phase 1: Information Gathering

### 1.1 Read Current Context State

**First, read the existing context files** to understand what's already documented:

1. Product Requirements Document: @.claude/context/tender-prd.md
2. High-level understanding of the project: @.claude/context/product-context.md
3. Technical stack and dependencies: @.claude/context/tech-context.md
4. Testing framework and setup: @.claude/context/testing.md
5. Current status and recent work: @.claude/context/progress.md
6. Project structure: @.claude/context/project-structure.md
7. Architecture and design patterns: @.claude/context/system-patterns.md
8. Coding conventions: @.claude/context/project-style-guide.md
9. Common workflows and commands: @.claude/context/development-commands.md

Read each context file to understand current state before making updates. This prevents duplicate entries and ensures updates are additive.

### 1.2 Change Detection

Gather comprehensive information about PR changes - enough detail to write release notes.

#### Step 1: Identify the Scope

```bash
# Current branch (often contains issue number)
git branch --show-current

# All PR commits with full messages
git log main..HEAD --format="### %s%n%n%b%n---"

# Files changed with line counts (overview)
git diff main...HEAD --stat

# Just filenames for categorization
git diff main...HEAD --name-only
```

#### Step 2: Read Source Code Changes

**Read the actual diffs for changed source files** to understand what was implemented:

```bash
# Core source code changes (highest priority)
git diff main...HEAD -- 'TenderApp/**/*.swift' ':!TenderApp/**/Preview Content/**'

# View changes (user-facing impact)
git diff main...HEAD -- 'TenderApp/Views/**/*.swift'

# Model changes (data structure impact)
git diff main...HEAD -- 'TenderApp/Models/**/*.swift'

# Service/ViewModel changes (business logic)
git diff main...HEAD -- 'TenderApp/Services/**/*.swift' 'TenderApp/ViewModels/**/*.swift'
```

**For large PRs (50+ files changed):** Focus on:
1. New files (`git diff main...HEAD --diff-filter=A --name-only`)
2. Modified models and services
3. Skim view changes unless they introduce new patterns

#### Step 3: Check Supporting Changes

```bash
# Configuration and dependencies
git diff main...HEAD -- 'project.yml' 'Package.swift' '*.plist'

# Context files already updated during PR
git diff main...HEAD -- '.claude/context/'

# New or modified scripts
git diff main...HEAD -- 'scripts/'

# Test changes (understand what was validated)
git diff main...HEAD --stat -- '*Tests*/**/*.swift'
```

#### Step 4: GitHub Context

```bash
# Check for issue references in commits
git log main..HEAD --grep="#" --oneline

# Check PR description if available
gh pr view --json title,body,labels 2>/dev/null || echo "No PR found"

# Check related GitHub issues
gh issue view <issue-number> --json title,body,comments 2>/dev/null || true
```

#### Step 5: Uncommitted Work

```bash
git status --short
```

### 1.3 Synthesize Findings

**Analyze the output like a Product Manager writing release notes:**

| Question                                 | Where to Find Answer            |
| ---------------------------------------- | ------------------------------- |
| What will users see differently?         | View diffs, commit messages     |
| What technical patterns were introduced? | Service/Model diffs             |
| Any breaking changes?                    | Model diffs, API changes        |
| New dependencies?                        | project.yml, Package.swift      |
| What was tested?                         | Test file stats, test names     |
| What issues were addressed?              | Commit messages, PR description |

### 1.4 Get Current DateTime

```bash
date -u +"%Y-%m-%dT%H:%M:%SZ"
```

Store this for updating `last_updated` fields.

---

## Phase 2: Context File Updates

### 2.1 Determine Which Files Need Updates

**Map your findings to context files:**

| Change Type                   | Context File(s) to Update |
| ----------------------------- | ------------------------- |
| Feature completed/in-progress | `progress.md` (always)    |
| New user-facing feature       | `product-context.md`      |
| New pattern/architecture      | `system-patterns.md`      |
| New technical insight/gotcha  | `tech-context.md`         |
| New files/directories         | `project-structure.md`    |
| New dependencies              | `tech-context.md`         |
| New commands/scripts          | `development-commands.md` |
| Testing improvements          | `testing.md`              |
| Style/convention changes      | `project-style-guide.md`  |
| Feature status change         | `tender-prd.md`           |

### 2.2 Update Each File

For each file that needs updating:

1. **Read the existing file** completely
2. **Identify the specific section** that needs the update
3. **Make surgical edits** - don't rewrite entire sections
4. **Update the frontmatter** `last_updated` field
5. **Add to Update History** at the bottom of the file

#### File-Specific Guidance

**`progress.md`** - Always Update
- Update "Current Development Status" section
- Move completed work from "In Progress" to "Completed"
- Update completion percentages
- Add any new blockers or next steps
- **Write like a standup update**: What was done, what's next, any blockers

**`tech-context.md`** - Technical Learnings
- Add new patterns discovered in `## [Feature Area] Patterns` sections
- Document gotchas that future developers should know
- Include code examples when helpful
- **Write like teaching a colleague**: "When doing X, you need to Y because Z"

**`system-patterns.md`** - Architecture Decisions
- Document new architectural patterns with rationale
- Include code examples showing the pattern
- Link to the issue/PR where pattern was introduced
- **Write like an ADR**: Context, decision, consequences

**`product-context.md`** - Feature Changes
- Update feature descriptions if behavior changed
- Add new features to appropriate sections
- Update navigation structure if changed
- **Write like a product spec**: What it does, why it matters

**`project-structure.md`** - Directory Changes
- Add new directories with descriptions
- Update file counts if significantly changed
- Document new organizational patterns
- **Write like a codebase tour**: Where things are, why they're there

**`testing.md`** - Testing Changes
- Document new testing patterns or utilities
- Update coverage information if changed
- Add new test categories or approaches
- **Write like a testing guide**: How to test X, patterns to follow

**`development-commands.md`** - New Commands
- Add new scripts with usage examples
- Update existing command documentation if changed
- Include common workflows
- **Write like a CLI reference**: Command, options, examples

**`tender-prd.md`** - PRD Status Updates
- Feature completion: Add ✅ after completed features
- Version status: Update `v0 (current)` → `v1 (current)` when implemented
- Implementation notes: Update `(Planned)` → `(Implemented)` where applicable
- **Write like release notes**: What's done, what's next

### 2.3 Update History Format

Add entries to the `## Update History` section at the bottom of each updated file:

```markdown
## Update History
- 2025-11-26: Added More tab navigation (Issue #54) - MoreView, MoreTab enum, navigation structure
- 2025-11-25: Added Activity Feed feature (Issue #51) - historical view of completed interactions
```

**Format**: `- {date}: {brief description} (Issue #{number}) - {key changes}`

---

## Phase 3: Validation & Summary

### 3.1 Validate Updates

After updating each file:
- Verify frontmatter is valid YAML
- Ensure markdown formatting is correct
- Confirm no duplicate entries were added
- Check that code examples are properly formatted

### 3.2 Skip Unchanged Files

**Do NOT update files if:**
- No relevant changes detected from the PR
- Content would be redundant with existing documentation
- Changes are too minor to document (typo fixes, formatting)

Report skipped files in summary - this preserves accurate timestamps.

### 3.3 Provide Summary

```
🔄 Context Update Complete

📋 PR Summary:
  Branch: {branch_name}
  Commits: {commit_count}
  Files Changed: {files_changed}
  Issues: {issue_references}

📝 Updated Context Files:
  ✅ progress.md - {what was updated}
  ✅ tech-context.md - {what was updated}
  ⏭️ project-structure.md - skipped (no structural changes)
  ⏭️ testing.md - skipped (no testing changes)

📌 Key Documentation Added:
  - {Most important thing documented}
  - {Second most important thing}

⏰ Updated: {timestamp}
```

---

## Error Handling

**If updates fail:**
- Report which files were successfully updated
- Note which files failed and why
- Never leave files in a corrupted state
- Suggest manual review if needed

**Common issues:**
- File locked by editor → Close file and retry
- Permission denied → Check file permissions
- Merge conflict in context file → Resolve manually

---

## Important Principles

1. **Additive updates** - Add to existing content, don't replace
2. **Surgical precision** - Update only relevant sections
3. **Future-reader focus** - Write for someone who wasn't here
4. **Link to sources** - Reference issue numbers and PRs
5. **Concrete examples** - Include code snippets when helpful
6. **Skip when appropriate** - No update is better than noise
