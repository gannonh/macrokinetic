---
description: Update an issue with recent activity, progress, and learnings from the current session.
argument-hint: Issue number (e.g., 42)
allowed-tools: Read, Write, Edit, LS
---

# Issue Update

Update progress and capture session work & learnings for issue #$ARGUMENTS.

**ULTRATHINK** and use TodoWrite to keep track of your tasks.

## Instructions

### 1. Find Local Task File

First check if `.claude/epics/*/$ARGUMENTS.md` exists (new naming).
If not found, search for task file with `github:.*issues/$ARGUMENTS` in frontmatter (old naming).
If not found: "❌ No local task for issue #$ARGUMENTS"

Extract epic name from path for subsequent operations.

### 2. Gather Session Context

Analyze current session work by examining:
- Recent file modifications and commits
- Current working directory and git status
- Any test results or build outputs mentioned in conversation
- Problems solved or components implemented
- Bugs fixed or features added

### 3. Update Main Task File

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file frontmatter:
```yaml
updated: {current_datetime}
```

### 4. Update Stream Progress Files

Check for existing stream files at `.claude/epics/{epic_name}/updates/$ARGUMENTS/stream-*.md`.

For each existing stream file, analyze session context to determine:
- What work was completed in this stream's scope
- Current implementation status
- Any blockers or issues encountered  
- Testing status and results
- Integration points with other streams

Update each relevant stream file with:

**Add to Progress section:**
```markdown
### {Current Date} Session Update
- **Work Completed**: {specific accomplishments from session}
- **Files Modified**: {list of files changed}
- **Issues Resolved**: {any bugs fixed or problems solved}
- **Testing Status**: {test results, coverage, issues}
- **Integration Status**: {coordination with other streams}
- **Next Steps**: {remaining work for this stream}
```

**Update status if appropriate:**
- If stream work is complete: `status: completed`
- If new issues discovered: add to progress notes
- If ready for testing: `ready_for_testing: true`
- If blocked: `status: blocked` with reason

### 5. Update Epic Progress

If major milestones were reached:
- Check if issue acceptance criteria should be updated
- Update overall epic progress in `epic.md` if appropriate
- Note any new dependencies or blockers discovered

### 6. Commit Changes

```bash
# Add all updated progress files
git add .claude/epics/{epic_name}/updates/$ARGUMENTS/
git add .claude/epics/{epic_name}/$ARGUMENTS.md

# Commit with descriptive message
git commit -m "Issue #$ARGUMENTS: update progress tracking

- {brief summary of session work}
- Updated stream progress files
- {any status changes}"
```

### 7. Capture Session Learnings

Add learnings section to issue file if significant discoveries were made:

```markdown
## Learnings & Knowledge Capture

### Technical Patterns → system-patterns.md
- {testing patterns, architecture decisions, implementation approaches}

### Technology Insights → tech-context.md  
- {framework-specific knowledge, tool discoveries, integration insights}

### Process Insights → progress.md
- {debugging approaches, workflow improvements, coordination lessons}

### Product Insights → product-context.md
- {user experience discoveries, feature insights, requirement clarifications}

### Project Structure → project-structure.md
- {file organization learnings, structure improvements}

**Learnings Status**: `learnings_captured: false`
```

Update frontmatter:
```yaml
learnings_captured: false  # flag for context/update.md to process
```

### 8. GitHub Sync (Optional)

If significant progress made, optionally sync to GitHub:
```bash
# Add progress comment to issue
echo "## Progress Update - $(date '+%Y-%m-%d')

{summary of work completed}

**Stream Updates:**
{list relevant stream progress}

**Technical Details:**
{any important implementation details}

---
Updated: {timestamp}" | gh issue comment $ARGUMENTS --body-file -
```

### 9. Output

```
✅ Updated issue #$ARGUMENTS progress

Epic: {epic_name}
Session work: {summary}

Stream updates:
  Stream A: {status} - {recent work}
  Stream B: {status} - {recent work}  
  Stream C: {status} - {recent work}

Learnings captured: {yes/no}
- Technical patterns: {count}
- Process insights: {count}
- Technology insights: {count}

Files updated:
  .claude/epics/{epic_name}/$ARGUMENTS.md
  .claude/epics/{epic_name}/updates/$ARGUMENTS/stream-*.md

- Next: Run /context:update to propagate learnings or /pm:epic-status {epic_name}
- Sync: Run /pm:issue-sync $ARGUMENTS to push updates to GitHub
- Resume: To resume work on the issue run /pm:issue-resume $ARGUMENTS
```

## Context Analysis Guidelines

When analyzing session context, look for:

**Implementation Work:**
- New files created or modified
- Code features implemented
- Architecture decisions made
- Dependencies added or changed

**Testing & Quality:**
- Tests written, fixed, or run
- Bug fixes applied
- Performance improvements
- Code quality issues resolved

**Integration & Coordination:**
- Work affecting multiple streams
- Dependency resolutions
- Blockers removed
- Communication with other components

**Documentation & Progress:**
- README updates
- Code documentation added
- Process improvements
- Learning captured

## Error Handling

If any step fails, report clearly:
- "❌ {What failed}: {How to fix}"
- Continue with available updates
- Never leave inconsistent state between files

## Important Notes

- Focus on factual progress, not speculation
- Include specific file names and line numbers when relevant
- Note both completed work and discovered issues
- Keep stream-specific updates in appropriate files
- Follow `/rules/datetime.md` for timestamps
- Use present tense for current status, past tense for completed work