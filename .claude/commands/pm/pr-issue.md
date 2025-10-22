---
description: Begin work on one or more GitHub PR Issues
argument-hint: [Issue number] [additional context (optional)]
---

# PR Issue

Begin work on the following GitHub PR Issue(s): $1

Additional context (if any): $2

## Preflight

1. **Get issue details:**

```bash
gh issue view $1 --json state,title,labels,body,assignees
```

2. **Confirm Issue Type**

**PR Issues Defined** 
- New issues resulting from the PR Review process
- These issues are identified by their titles, which are **prefixed by "PR #"**
- These issues are typically small, focused tasks that can be completed quickly
- They often relate to code changes, bug fixes, or minor enhancements
- They do not have a corresponding local markdown file.

If for any reason the issue is not a PR Issue, **STOP AND REPORT**:

- "❌ Issue $1 is not a PR Issue. Did you mean to start a Task issue instead? If so, run `/pm:issue-start $1`."

## Instructions for PR Issues

**IMPORTANT**: If more than 1 issue, run the following workflow sequentially for each individual issue.

1. Read the issue description and recommended solution (if any) from GitHub.
2. Label the issue as `in-progress` in GitHub
3. Assess the implementation requirements and acceptance criteria.
4. Determine if any additional context or clarification is needed - if so, as the human for clarification.
5. Present to the user your recommended solution and implementation plan for approval: Iterate until approved.
6. Implement the solution.
7. Validate changes by running the relevant ui and unit tests, and/or creating new tests.
8. Ensure all checks pass: `./scripts/check-all.sh`
9. Commit your work, referencing the issue number: `git commit -m "Fix for #$1: [description of work]"`
10. Push to GitHub: `git push`
11. Remove the `in-progress` label and close the issue on GitHub: `gh issue close $1 --comment "Fix implemented in PR #[pr-number]"`

## Error Handling

If any step fails, report clearly:
- "❌ {What failed}: {How to fix}"
- Continue with what's possible
- Never leave partial state

## Important Notes

Follow `/rules/datetime.md` for timestamps.
Keep it simple - trust that GitHub and file system work.