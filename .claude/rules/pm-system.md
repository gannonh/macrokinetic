# PM system Documentation

## Command Reference

### Initial Setup
- `/pm:init` - Install dependencies and configure GitHub for new project
- `/re-init` - Update `CLAUDE.md` with important rules from `.claude/CLAUDE.md`

# Context Commands
- `/context:create` - Create initial context from project files
- `/context:update` - Update context with recent changes
- `/context:prime` - Prime context for specific tasks
- `/context:add-learning` - Add arbitrary learning to context files

### PRD Commands
- `/pm:prd-new` - Launch brainstorming for new product requirement
- `/pm:prd-parse` - Convert PRD to implementation epic
- `/pm:prd-list` - List all PRDs
- `/pm:prd-edit` - Edit existing PRD
- `/pm:prd-status` - Show PRD implementation status

### Epic Commands
- `/pm:epic-decompose` - Break epic into task files
- `/pm:validate-tasks` - Validate and standardize task file formats
- `/pm:epic-sync` - Push epic and tasks to GitHub
- `/pm:epic-oneshot` - Decompose and sync in one command
- `/pm:epic-list` - List all epics
- `/pm:epic-show` - Display epic and its tasks
- `/pm:epic-status` - Check the status of epics in the project management system
- `/pm:epic-close` - Mark epic as complete
- `/pm:epic-edit` - Edit epic details
- `/pm:epic-refresh` - Update epic progress from tasks

### Issue Commands
- `/pm:issue-show` - Display issue and sub-issues
- `/pm:issue-status` - Check issue status
- `/pm:issue-start` - Begin work with specialized agent
- `/pm:issue-resume` - Begin or resume work on a GitHub issue with parallel agents based on work stream analysis
- `/pm:issue-analyze` - Analyze a GitHub issue to identify parallel work streams for efficient execution
- `/pm:issue-update` - Update an issue with recent activity, progress, and learnings from the current session
- `/pm:issue-sync` - Push updates to GitHub
- `/pm:issue-close` - Mark issue as complete
- `/pm:issue-reopen` - Reopen closed issue
- `/pm:issue-edit` - Edit issue details
- `/pm:issue-merge` - Merge completed PR from branch to main using GitHub Pull Request workflow
- `/pm:issue-import` - Import existing GitHub issues into the PM system

### Workflow Commands
- `/pm:next` - Show next priority issue with epic context
- `/pm:status` - Overall project dashboard
- `/pm:standup` - Daily standup report
- `/pm:blocked` - Show blocked tasks
- `/pm:in-progress` - List work in progress
- `/pm:pr-merge` - Merge completed PR from branch to main using GitHub Pull Request workflow

### Sync Commands
- `/pm:sync` - Full bidirectional sync with GitHub
- `/pm:import` - Import existing GitHub issues

### Development Commands
- `/pm:commit` - Commit changes with a descriptive message
- `/pm:help` - Show help information

### Maintenance Commands
- `/pm:validate` - Check system integrity
- `/pm:validate-tasks` - Validate and fix task file formats
- `/pm:clean` - Archive completed work
- `/pm:search` - Search across all content
- `/pm:test-reference-update` - Update test references

### QA Commands
- `/qa:validate-coverage-config` - Validate iOS project coverage configuration
- `/qa:swiftlint` - Run the SwiftLint and swift-format QA workflow with test verification
- `/qa:test-quality` - Test quality review
- `/qa:tq-fix` - Address test quality issues from analysis report
- `/qa:code-quality` - Code quality review
- `/pm:design-review` - Conduct design review for UI/UX feedback and improvements

### Testing Commands
- `/testing:run` - Run the test suite or specific tests
- `/testing:prime` - Prepare and prime the testing environment by detecting test framework and validating dependencies


## System Architecture

```
.claude/
├── CLAUDE.md          # Always-on instructions (copy content to your project's CLAUDE.md file)
├── agents/            # Task-oriented agents (for context preservation)
├── commands/          # Command definitions
│   ├── context/       # Create, update, and prime context
│   ├── pm/            # ← Project management commands (this system)
│   └── testing/       # Prime and execute tests (edit this)
├── context/           # Project-wide context files
├── epics/             # ← PM's local workspace (place in .gitignore)
│   └── [epic-name]/   # Epic and related tasks
│       ├── epic.md    # Implementation plan
│       ├── [#].md     # Individual task files
│       └── updates/   # Work-in-progress updates
├── prds/              # ← PM's PRD files
├── rules/             # Place any rule files you'd like to reference here
└── scripts/           # Place any script files you'd like to use here
```

## Workflow Phases

### 1. Product Planning Phase

```bash
/pm:prd-new feature-name
```
Launches comprehensive brainstorming to create a Product Requirements Document capturing vision, user stories, success criteria, and constraints.

**Output:** `.claude/prds/feature-name.md`

### 2. Implementation Planning Phase

```bash
/pm:prd-parse feature-name
```
Transforms PRD into a technical implementation plan with architectural decisions, technical approach, and dependency mapping.

**Output:** `.claude/epics/feature-name/epic.md`

### 3. Task Decomposition Phase

```bash
/pm:epic-decompose feature-name
```
Breaks epic into concrete, actionable tasks with acceptance criteria, effort estimates, and parallelization flags.

**Output:** `.claude/epics/feature-name/[task].md`

**Important:** After decomposition, validate task file formats to ensure consistency:

```bash
/pm:validate-tasks feature-name
```
Validates and standardizes task frontmatter format across all tasks in the epic. This ensures:
- Consistent YAML frontmatter fields (task_id, title, epic, status, etc.)
- Proper field ordering for GitHub sync compatibility
- Removal of duplicate or non-standard fields

**When to run:** Always run after `/pm:epic-decompose` if parallel agents were used, or if you notice inconsistent frontmatter formats between task files.

### 4. GitHub Synchronization

```bash
/pm:epic-sync feature-name
```
Pushes epic and tasks to GitHub as issues with appropriate labels and relationships.

### 5. Execution Phase

```bash
/pm:issue-analyze [issue-number]  # Analyze an issue to identify parallel work streams for maximum efficiency.
/pm:validate-tasks [epic-name]  # Validate and fix task file formats
/pm:issue-start [issue-number]    # Create issue branch + draft PR + launch agents
/pm:issue-update [issue-number]   # Update progress and capture session work & learnings
/pm:issue-resume [issue-number]   # Resume work on in-progress issues
/pm:issue-sync [issue-number]     # Push progress updates to GitHub
/context:update                 # Update progress and propagate learnings
/pm:pr-merge [pr-number]        # Mark PR ready → review → merge to main (symlink to issue-merge)
/pm:issue-close [issue-number]    # Close issue + update epic progress
/context:update                 # Update progress and propagate learnings
/pm:epic-refresh [epic-name]      # Update epic progress from tasks
/pm:sync [epic-name]                   # Full bidirectional sync with GitHub
/pm:epic-close [epic-name]        # Close epic when all issues complete
/pm:next                          # Show next priority issue with epic context
```

**Issue/Branch/PR Workflow:** Each issue gets its own branch and pull request for focused development and review. Specialized agents implement features while maintaining comprehensive progress tracking and audit trails. Use `issue-update` to capture progress during development and `issue-resume` to continue work after breaks.
