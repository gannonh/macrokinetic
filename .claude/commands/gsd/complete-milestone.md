---
type: prompt
description: Archive completed milestone and prepare for next version
argument-hint: <version>
allowed-tools:
  - Read
  - Write
  - Bash
  - Skill
---

<objective>
Mark milestone {{version}} complete, archive to milestones/, merge PR, and update ROADMAP.md.

Purpose: Create historical record of shipped version, merge milestone PR, collapse completed work in roadmap, and prepare for next milestone.
Output: Milestone archived, PR merged, roadmap reorganized, git tagged.
</objective>

<execution_context>
**Load these files NOW (before proceeding):**

- @./.claude/get-shit-done/workflows/complete-milestone.md (main workflow)
- @./.claude/get-shit-done/templates/milestone-archive.md (archive template)
  </execution_context>

<context>
**Project files:**
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- `.planning/PROJECT.md`

**User input:**

- Version: {{version}} (e.g., "1.0", "1.1", "2.0")
  </context>

<process>

**Follow complete-milestone.md workflow:**

1. **Pre-merge validation:**

   - Check if `/gsd:pre-merge` has been run
   - If not, ask user:
     ```
     Pre-merge validation not detected. Options:
     1. Run /gsd:pre-merge now (recommended)
     2. Skip pre-merge (I already validated manually)
     3. Cancel milestone completion
     ```
   - If option 1: Run `/gsd:pre-merge` first, then continue
   - If option 2: Proceed with warning

2. **Verify readiness:**

   - Check all phases in milestone have completed plans (SUMMARY.md exists)
   - Present milestone scope and stats
   - Wait for confirmation

3. **Gather stats:**

   - Count phases, plans, tasks
   - Calculate git range, file changes, LOC
   - Extract timeline from git log
   - Present summary, confirm

4. **Extract accomplishments:**

   - Read all phase SUMMARY.md files in milestone range
   - Extract 4-6 key accomplishments
   - Present for approval

5. **Archive milestone:**

   - Create `.planning/milestones/v{{version}}-ROADMAP.md`
   - Extract full phase details from ROADMAP.md
   - Fill milestone-archive.md template
   - Update ROADMAP.md to one-line summary with link
   - Offer to create next milestone

6. **Update PROJECT.md:**

   - Add "Current State" section with shipped version
   - Add "Next Milestone Goals" section
   - Archive previous content in `<details>` (if v1.1+)

7. **Commit and tag:**

   - Stage: MILESTONES.md, PROJECT.md, ROADMAP.md, STATE.md, archive file
   - Commit: `chore: archive v{{version}} milestone`
   - Tag: `git tag -a v{{version}} -m "[milestone summary]"`
   - Push commits to remote

8. **Merge milestone PR:**

   - Get PR number from STATE.md (GitHub Tracking section)
   - If PR exists:
     ```bash
     # Merge the milestone PR
     gh pr merge $PR_NUMBER --merge --delete-branch
     echo "✅ PR #$PR_NUMBER merged and branch deleted"
     ```
   - If no PR found: Skip (milestone may have been created before GitHub integration)
   - Push tag after merge:
     ```bash
     git push origin v{{version}}
     ```

9. **Offer next steps:**
   - Plan next milestone
   - Archive planning
   - Done for now

</process>

<success_criteria>

- Pre-merge validation completed (or explicitly skipped)
- Milestone archived to `.planning/milestones/v{{version}}-ROADMAP.md`
- ROADMAP.md collapsed to one-line entry
- PROJECT.md updated with current state
- Git tag v{{version}} created
- Commit successful
- Milestone PR merged (if exists)
- Tag pushed to remote
- User knows next steps
  </success_criteria>

<critical_rules>

- **Load workflow first:** Read complete-milestone.md before executing
- **Pre-merge first:** Encourage /gsd:pre-merge before completing milestone
- **Verify completion:** All phases must have SUMMARY.md files
- **User confirmation:** Wait for approval at verification gates
- **Archive before collapsing:** Always create archive file before updating ROADMAP.md
- **One-line summary:** Collapsed milestone in ROADMAP.md should be single line with link
- **Context efficiency:** Archive keeps ROADMAP.md constant size
- **Merge after archive:** Merge PR only after all archiving is complete
- **Tag after merge:** Push tag to remote after PR is merged
  </critical_rules>
