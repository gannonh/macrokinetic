# PM system Documentation

## Command Reference

### Initial Setup
- `/pm:init` - Install dependencies and configure GitHub for new project
- `/re-init` - Update `CLAUDE.md` with important rules from `.claude/CLAUDE.md`

# Context Commands
- `/context:create` - Create initial context from project files
- `/context:update` - Update context with recent changes
- `/context:prime` - Prime context for specific tasks

### PRD Commands
- `/pm:prd-new` - Launch brainstorming for new product requirement
- `/pm:prd-parse` - Convert PRD to implementation epic
- `/pm:prd-list` - List all PRDs
- `/pm:prd-edit` - Edit existing PRD
- `/pm:prd-status` - Show PRD implementation status

### Epic Commands
- `/pm:epic-decompose` - Break epic into task files
- `/pm:epic-sync` - Push epic and tasks to GitHub
- `/pm:epic-oneshot` - Decompose and sync in one command
- `/pm:epic-list` - List all epics
- `/pm:epic-show` - Display epic and its tasks
- `/pm:epic-close` - Mark epic as complete
- `/pm:epic-edit` - Edit epic details
- `/pm:epic-refresh` - Update epic progress from tasks

### Issue Commands
- `/pm:issue-show` - Display issue and sub-issues
- `/pm:issue-status` - Check issue status
- `/pm:issue-start` - Begin work with specialized agent
- `/pm:issue-sync` - Push updates to GitHub
- `/pm:issue-close` - Mark issue as complete
- `/pm:issue-reopen` - Reopen closed issue
- `/pm:issue-edit` - Edit issue details

### Workflow Commands
- `/pm:next` - Show next priority issue with epic context
- `/pm:status` - Overall project dashboard
- `/pm:standup` - Daily standup report
- `/pm:blocked` - Show blocked tasks
- `/pm:in-progress` - List work in progress

### Sync Commands
- `/pm:sync` - Full bidirectional sync with GitHub
- `/pm:import` - Import existing GitHub issues

### Maintenance Commands
- `/pm:validate` - Check system integrity
- `/pm:clean` - Archive completed work
- `/pm:search` - Search across all content


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

### 4. GitHub Synchronization

```bash
/pm:epic-sync feature-name
```
Pushes epic and tasks to GitHub as issues with appropriate labels and relationships.

### 5. Execution Phase

```bash
/pm:issue-analyze issue-number  # Analyze an issue to identify parallel work streams for maximum efficiency.
/pm:issue-start issue-number    # Create issue branch + draft PR + launch agents
/pm:issue-update issue-number   # Update progress and capture session work & learnings
/pm:issue-resume issue-number   # Resume work on in-progress issues
/pm:issue-sync issue-number     # Push progress updates to GitHub
/context:update                 # Update progress and ropagate learnings
/pm:pr-merge pr-number          # Mark PR ready → review → merge to main
/qa:test-quality pr-number      # Run test quality analysis and post as PR comment
/qa:code-quality pr-number      # Run code quality analysis and post as PR comment
/qa:swiftlint                   # Run SwiftLint and SwiftFormat QA workflow with test
/pm:pr-comments path-or-paste   # Process PR review comments with context-aware discretion
/pm:pr-merge pr-number          # Resume merge process after reviews
/pm:issue-close issue-number    # Close issue + update epic progress
/pm:epic-refresh epic-name      # Update epic progress from tasks
/context:update                 # Update progress and ropagate learnings
/pm:sync                        # Full bidirectional sync with GitHub
/pm:epic-close epic-name        # Close epic when all issues complete
```

**Issue/Branch/PR Workflow:** Each issue gets its own branch and pull request for focused development and review. Specialized agents implement features while maintaining comprehensive progress tracking and audit trails. Use `issue-update` to capture progress during development and `issue-resume` to continue work after breaks.
