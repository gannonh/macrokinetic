---
allowed-tools: Read, Bash, Glob
description: Push epic and tasks to GitHub as issues, syncing local epic to GitHub
argument-hint: Epic name (e.g., dose-scheduling)
tools: Read, Write, Bash, Glob
---

# Epic Sync

Push epic and tasks to GitHub.

⚠️ **CRITICAL: Execute these steps EXACTLY in order. Do NOT read files or explore first.**

## ❌ DO NOT DO THESE THINGS:
- Do NOT read files before running scripts
- Do NOT explore the directory structure first  
- Do NOT use sub-agents or parallel execution
- Do NOT skip validation steps
- Do NOT improvise or "understand the epic first"

## ✅ ONLY DO THIS:
- Execute the 6 steps below in exact order
- Execute each bash script exactly as shown
- Follow all instructions precisely

**MANDATORY**: Follow each step precisely. Do not deviate from this workflow.

## STEP 1: PRE-VALIDATION (START HERE IMMEDIATELY)

**EXECUTE THIS FIRST - NO EXCEPTIONS:**

```bash
# Run validation script
.claude/scripts/pm/epic-sync-validate.sh "$ARGUMENTS"
```

**Do not proceed until this completes successfully.**

## STEP 2: Create Epic Issue

```bash
# Run epic creation script
.claude/scripts/pm/epic-sync-create-epic.sh "$ARGUMENTS"
```

## STEP 3: Create Task Sub-Issues Sequentially

**IMPORTANT**: Tasks are created in order (001, 002, 003...) so GitHub issue numbers follow the sequence.

```bash
# Use the gh-sub-issue extension available
use_subissues="true"

# Store for script
echo "$use_subissues" > /tmp/use-subissues.txt

# Run task creation script
epic_number=$(cat /tmp/epic-number.txt)
.claude/scripts/pm/create-tasks-sequential.sh "$ARGUMENTS" "$epic_number" "$use_subissues"
```

## STEP 4: Update Cross-References

Now that all files are renamed, update `depends_on` and `conflicts_with` to use new GitHub issue numbers.

```bash
# Run cross-reference update script
.claude/scripts/pm/update-cross-references.sh "$ARGUMENTS"
```

## STEP 5: Update Epic File

Update epic.md with GitHub URL and task list with real issue numbers.

```bash
# Run epic update script
.claude/scripts/pm/epic-sync-update-epic.sh "$ARGUMENTS"
```

## STEP 6: Final Validation

```bash
# Run final validation script
.claude/scripts/pm/epic-sync-final-validate.sh "$ARGUMENTS"
```

## STEP 7: Summary Output

```bash
# Run summary script
.claude/scripts/pm/epic-sync-summary.sh "$ARGUMENTS"
```

## Cleanup

```bash
# Clean up temp files
rm -f /tmp/epic-body.md /tmp/epic-title.txt /tmp/epic-number.txt
rm -f /tmp/task-body.md /tmp/task-url.txt /tmp/tasks-section.md
rm -f /tmp/issue-mapping.txt /tmp/task-count.txt /tmp/use-subissues.txt
```

## Error Handling

- **Epic creation fails**: Stop immediately, report error
- **Task creation fails**: Stop immediately, report which task failed
- **Validation fails**: Report specific failures, don't proceed
- **gh CLI errors**: Display full error message, suggest fixes

## Important Notes

- Tasks are **always created sequentially** (no parallel agents)
- Files are **renamed immediately** after each creation
- GitHub issue numbers will **follow task order** (001→N, 002→N+1, etc.)
- Cross-references are **updated at the end** using the mapping
- **No mapping file created** - mapping only used during sync
- Validation ensures **everything succeeded** before declaring complete
- **Scripts used**: `create-tasks-sequential.sh` and `update-cross-references.sh` for reliability
- **Label**: Tasks labeled with "task" only (sub-issue relationship shows epic connection)
- **gh sub-issue**: Uses `--body` parameter (reads body content into variable, not file)
