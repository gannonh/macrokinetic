---
description: Review and refine all context files to remove bloat, duplication, and outdated information while maintaining essential context.
---

# Refine Context

This command reviews and refines all context files in `.claude/context/` to keep them lean, relevant, and efficient for agent context loading. Run this periodically (every 2-4 weeks) or when context files feel bloated.

## Purpose

Over time, context files accumulate:
- **Duplicate information** across multiple files
- **Outdated patterns** that have been superseded
- **Excessive detail** in update histories
- **Redundant examples** that don't add value
- **Verbose sections** that could be more concise

This command identifies and removes bloat while preserving essential context.

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `.claude/rules/datetime.md` - For getting real current date/time

## Preflight Checklist

Before proceeding, complete these validation steps.
Do not bother the user with preflight checks progress. Just do them and move on.

### 1. Context Validation
```bash
# Check context directory exists
ls -la .claude/context/ 2>/dev/null
```
- If directory doesn't exist or is empty:
  - Tell user: "❌ No context files to refine. Please run /context:create first."
  - Exit gracefully

```bash
# Count existing files
ls -1 .claude/context/*.md 2>/dev/null | wc -l
```
- Report: "📁 Found {count} context files to analyze for refinement"

### 2. File Size Analysis
```bash
# Check file sizes to identify bloated files
ls -lh .claude/context/*.md | awk '{print $5, $9}'
```
- Note files larger than 50KB (potential bloat)
- Report: "📊 Largest context files: {list}"

### 3. Get Current DateTime
```bash
# Get real current datetime
date -u +"%Y-%m-%dT%H:%M:%SZ"
```
- Store for updating `last_updated` field in modified files

## Refinement Strategy

### Phase 1: Analysis

For each context file, analyze for:

#### 1. **Duplicate Information**
- Same concepts explained in multiple files
- Redundant examples across files
- Overlapping sections that could reference each other

**Example Issues:**
- Same testing pattern documented in `testing.md` AND `system-patterns.md`
- Identical code examples in multiple locations
- Repeated architecture explanations

**Solution:**
- Keep information in ONE canonical location
- Use cross-references: "See testing.md for test patterns"
- Remove duplicate content, keep brief summaries with links

#### 2. **Outdated Information**
- Patterns or approaches that have been superseded
- Old technology versions no longer used
- Deprecated APIs or tools
- Historical decisions no longer relevant

**Example Issues:**
- Migration notes for completed migrations
- Old technology stack information after upgrades
- Superseded patterns still documented

**Solution:**
- Remove completely outdated sections
- Update to reflect current state
- Archive historical context if needed (don't keep in main context)

#### 3. **Excessive Update History**
- Update history sections that span 100+ lines
- Detailed change logs that belong in git history
- Minor updates that don't provide long-term value

**Example Issues:**
```markdown
## Update History
- 2025-01-15: Fixed typo in section 3
- 2025-01-14: Updated example code formatting
- 2025-01-13: Added comma to list
... (50+ more entries)
```

**Solution:**
- Keep only **significant** updates (major changes, important learnings)
- Remove minor updates (typos, formatting, small additions)
- Consider keeping only last 10-15 significant updates
- Summarize old updates into single entries if needed

#### 4. **Verbose Sections**
- Long-winded explanations that could be concise
- Excessive examples when 1-2 would suffice
- Redundant paragraphs saying the same thing differently

**Example Issues:**
- 5 examples showing the same pattern
- Multiple paragraphs explaining a simple concept
- Repeated information within same file

**Solution:**
- Consolidate examples: keep 1-2 best examples
- Make explanations more concise
- Remove redundant paragraphs
- Use bullet points instead of prose where appropriate

#### 5. **Low-Value Content**
- Generic information available in official docs
- Obvious statements that don't add context
- Placeholder sections never filled in
- TODO items that should be tracked elsewhere

**Solution:**
- Remove generic information (reference official docs instead)
- Delete placeholder sections or complete them
- Move TODO items to issues/epics
- Keep only project-specific insights

### Phase 2: File-by-File Refinement

Process each context file systematically:

#### `progress.md`
**Focus:** Current state, recent work, next steps

**Common Bloat:**
- Completed work from months ago (belongs in git history)
- Excessive detail on every minor commit
- Outdated "next steps" sections
- Long lists of completed tasks

**Refinement Actions:**
- Keep only last 2-3 major milestones in "Completed Work"
- Summarize older work into high-level achievements
- Remove completed tasks older than 2-3 weeks
- Keep current/upcoming work detailed
- Archive old "learnings" to appropriate context files

**Target:** 200-400 lines maximum

#### `tech-context.md`
**Focus:** Current technology stack, integration patterns, key technical decisions

**Common Bloat:**
- Outdated framework versions
- Migration notes for completed migrations
- Duplicate pattern documentation (also in system-patterns.md)
- Excessive technology explanations (available in official docs)

**Refinement Actions:**
- Update to current framework versions only
- Remove completed migration notes
- Move patterns to system-patterns.md, keep brief references
- Remove generic framework explanations, keep project-specific insights
- Consolidate similar integration patterns

**Target:** 300-500 lines maximum

#### `system-patterns.md`
**Focus:** Architectural patterns, design decisions, coding patterns

**Common Bloat:**
- Multiple examples of same pattern
- Outdated patterns no longer used
- Duplicate explanations
- Verbose pattern descriptions

**Refinement Actions:**
- One clear example per pattern
- Remove deprecated patterns
- Consolidate similar patterns
- Make descriptions concise
- Keep "why" explanations brief

**Target:** 400-600 lines maximum

#### `project-structure.md`
**Focus:** Directory structure, organization patterns

**Common Bloat:**
- Exhaustive directory listings (use tree command instead)
- Redundant explanations of obvious structures
- Outdated structure from refactoring

**Refinement Actions:**
- Show key directories only, not every subdirectory
- Remove obvious explanations
- Update to current structure
- Use concise tree diagrams

**Target:** 200-300 lines maximum

#### `product-context.md`
**Focus:** Product vision, user needs, feature descriptions

**Common Bloat:**
- Verbose user stories
- Duplicate feature descriptions
- Extensive competitive analysis
- Outdated market research

**Refinement Actions:**
- Concise user stories (keep essential elements)
- One clear feature description per feature
- Brief competitive insights only
- Remove outdated market data

**Target:** 300-500 lines maximum

#### `testing.md`
**Focus:** Testing framework, patterns, commands

**Common Bloat:**
- Duplicate test examples
- Excessive command variations
- Redundant testing philosophy

**Refinement Actions:**
- One example per test pattern
- Show common commands only
- Consolidate philosophy into brief principles

**Target:** 200-400 lines maximum

#### `development-commands.md`
**Focus:** Common development commands, workflows

**Common Bloat:**
- Every possible command variation
- Redundant script examples
- Outdated workflow instructions

**Refinement Actions:**
- Show most common commands only
- One example per workflow
- Remove obsolete workflows
- Keep command reference concise

**Target:** 150-300 lines maximum

#### `project-style-guide.md`
**Focus:** Coding conventions, style rules

**Common Bloat:**
- Too many code examples
- Verbose style explanations
- Duplicate linter rules (already in .swiftlint.yml)

**Refinement Actions:**
- One good example and one bad example per rule
- Concise rule statements
- Reference linter config instead of duplicating
- Remove obvious style rules

**Target:** 300-500 lines maximum

### Phase 3: Cross-File Deduplication

After individual file refinement, look for cross-file duplication:

1. **Identify duplicated content:**
   ```bash
   # Search for similar headings across files
   grep -h "^##" .claude/context/*.md | sort | uniq -d
   ```

2. **Create canonical locations:**
   - Testing patterns → `testing.md`
   - Architecture patterns → `system-patterns.md`
   - Technology integration → `tech-context.md`
   - Product features → `product-context.md`
   - Development workflows → `development-commands.md`

3. **Replace duplicates with references:**
   - Instead of: [Full explanation in multiple files]
   - Use: "See testing.md § Unit Testing Patterns for details"

4. **Create cross-reference index:**
   - Add "See Also" sections to guide readers
   - Keep brief context + link to full explanation

### Phase 4: Update History Cleanup

For each file's update history:

1. **Keep significant updates only:**
   - Major feature additions
   - Important architectural changes
   - Critical bug discoveries
   - Significant pattern introductions

2. **Remove minor updates:**
   - Typo fixes
   - Formatting changes
   - Small additions
   - Routine updates

3. **Consolidate old updates:**
   - Merge updates older than 2-3 months into summary entries
   - Example: "2025-01-XX through 2025-03-XX: Various testing pattern improvements"

4. **Limit update history length:**
   - Maximum 10-15 significant updates per file
   - Older updates should be summarized or removed

### Phase 5: Implementation

For each file that needs refinement:

1. **Create backup:**
   ```bash
   cp .claude/context/file.md .claude/context/file.md.backup
   ```

2. **Read current content:**
   - Use Read tool to load file
   - Identify specific sections to refine

3. **Apply refinements:**
   - Remove duplicate content
   - Delete outdated sections
   - Consolidate verbose explanations
   - Trim update history
   - Add cross-references where appropriate

4. **Update frontmatter:**
   ```yaml
   ---
   last_updated: {current_datetime_from_date_command}
   refined_date: {current_datetime}
   ---
   ```

5. **Add refinement note:**
   ```markdown
   ## Refinement History
   - {date}: Removed duplicate patterns, consolidated examples, trimmed update history
   ```

6. **Verify file integrity:**
   - Check file size reduced (or justified if increased)
   - Ensure markdown formatting preserved
   - Confirm no critical information lost

7. **Remove backup if successful:**
   ```bash
   rm .claude/context/file.md.backup
   ```

### Phase 6: Validation

After refinement:

1. **Size comparison:**
   ```bash
   # Compare file sizes before/after
   ls -lh .claude/context/*.md
   ```

2. **Content validation:**
   - All essential context preserved
   - Cross-references work correctly
   - No broken internal links
   - Formatting intact

3. **Readability check:**
   - Files are more concise
   - Key information is easier to find
   - Structure is clear

## Output Summary

Provide detailed refinement report:

```
🔍 Context Refinement Complete

📊 Refinement Statistics:
  - Files Analyzed: {total_count}
  - Files Refined: {refined_count}
  - Files Unchanged: {unchanged_count}
  - Total Size Before: {total_before_kb} KB
  - Total Size After: {total_after_kb} KB
  - Space Saved: {saved_kb} KB ({percentage}% reduction)

📝 Files Refined:
  ✅ progress.md
     - Removed: 45 outdated completed tasks
     - Consolidated: 3 months of update history → 2 summary entries
     - Size: 580 KB → 320 KB (45% reduction)

  ✅ tech-context.md
     - Removed: 3 completed migration sections
     - Consolidated: 8 duplicate testing patterns → moved to testing.md
     - Updated: Framework versions to current
     - Size: 650 KB → 420 KB (35% reduction)

  ✅ system-patterns.md
     - Removed: 4 deprecated patterns
     - Consolidated: 12 code examples → 5 key examples
     - Size: 480 KB → 380 KB (21% reduction)

🔗 Cross-References Added:
  - tech-context.md → testing.md (test patterns)
  - system-patterns.md → tech-context.md (framework integration)
  - progress.md → product-context.md (feature status)

🗑️ Content Removed:
  - 127 lines of duplicate content
  - 89 lines of outdated information
  - 156 lines of excessive update history
  - 43 lines of low-value content

✨ Improvements:
  - Created canonical locations for patterns
  - Consolidated redundant examples
  - Trimmed update histories to significant changes only
  - Added cross-references for better navigation

⏰ Refinement Date: {timestamp}
🔄 Next: Run this command in 2-4 weeks or when context feels bloated
💡 Tip: Regular refinement prevents context bloat accumulation
```

## Important Notes

- **Preserve essential context** - don't remove important information
- **Create cross-references** - don't duplicate information
- **Keep significant updates** - remove only minor update history
- **Backup before changes** - prevent accidental data loss
- **Validate after refinement** - ensure no broken references
- **Focus on clarity** - make context easier to understand
- **Reduce token usage** - leaner context = more efficient agents

## When to Run This Command

Run `/context:refine` when:
- Context files exceed recommended size limits
- Duplicate information noticed across files
- Old patterns/approaches superseded by new ones
- Update histories become excessive (20+ entries)
- Agents seem to struggle with context overload
- After major refactoring or architecture changes
- Every 2-4 weeks as regular maintenance

## Difference from /context:update

- **`/context:update`**: Adds new information from recent work
- **`/context:refine`**: Removes bloat and improves existing information

Both commands complement each other:
1. Run `/context:update` regularly (after each session)
2. Run `/context:refine` periodically (every 2-4 weeks)

$ARGUMENTS
