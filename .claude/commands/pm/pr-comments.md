---
description: Process PR review comments with context-aware discretion
argument-hint: path to PR comments file or paste comments directly
allowed-tools: Task, Read, Edit, MultiEdit, Write, LS, Grep
model: inherit
---

# PR Review Handler

Process PR review comments with context-aware discretion.

## Comments to Process

Process the following PR comments: $ARGUMENTS

## Instructions

### 1. Initial Context

Inform the user:
```
I'll review the PR comments with discretion, as the reviewer doesn't have access to the entire codebase and may not understand the full context.

For each comment, I'll:
- Evaluate if it's valid given our codebase context
- Accept suggestions that improve code quality
- Ignore suggestions that don't apply to our architecture
- Explain my reasoning for accept/ignore decisions
```

### 2. Process Comments

#### Single File Comments
If all comments relate to one file:
- Read the file for context
- Evaluate each suggestion
- Apply accepted changes in batch using MultiEdit
- Report which suggestions were accepted/ignored and why

#### Multiple File Comments
If comments span multiple files:

Launch parallel sub-agents using Task tool:
```yaml
Task:
  description: "pr review fixes for {filename}"
  subagent_type: "general-purpose"
  prompt: |
    Review and apply pr review suggestions for {filename}.
    
    Comments to evaluate:
    {relevant_comments_for_this_file}
    
    Instructions:
    1. Read the file to understand context
    2. For each suggestion:
       - Evaluate validity given codebase patterns
       - Accept if it improves quality/correctness
       - Ignore if not applicable
    3. Apply accepted changes using Edit/MultiEdit
    4. Return summary:
       - Accepted: {list with reasons}
       - Ignored: {list with reasons}
       - Changes made: {brief description}
    
    Use discretion - reviewer lacks full context.

    IMPORTANT: Given that you are operating in parallel with other agents, do not run build or test commands as they may conflict with other agents. Only make code changes.
```

### 3. Consolidate Results

After all sub-agents complete:
```
📋 CodeRabbit Review Summary

Files Processed: {count}

Accepted Suggestions:
  {file}: {changes_made}
  
Ignored Suggestions:
  {file}: {reason_ignored}

Overall: {X}/{Y} suggestions applied
```

### 4. Common Patterns to Ignore

- **Style preferences** that conflict with project conventions
- **Generic best practices** that don't apply to our specific use case
- **Performance optimizations** for code that isn't performance-critical
- **Accessibility suggestions** for internal tools
- **Security warnings** for already-validated patterns
- **Import reorganization** that would break our structure

### 5. Common Patterns to Accept

- **Invalid Tests** (wrong assertions, missing cases, always passing, false confidence)
- **Actual bugs** (null checks, error handling)
- **Security vulnerabilities** (unless false positive)
- **Resource leaks** (unclosed connections, memory leaks)
- **Type safety issues** (TypeScript/type hints)
- **Logic errors** (off-by-one, incorrect conditions)
- **Missing error handling** 

## Decision Framework

For each suggestion, consider:
1. **Is it correct?** - Does the issue actually exist?
2. **Is it relevant?** - Does it apply to our use case?
3. **Is it beneficial?** - Will fixing it improve the code?
4. **Is it safe?** - Could the change introduce problems?

Only apply if all answers are "yes" or the benefit clearly outweighs risks.

## Important Notes

- Comments are helpful but lack context
- Trust your understanding of the codebase over generic suggestions
- Explain decisions briefly to maintain audit trail
- Batch related changes for efficiency
- Use parallel agents for multi-file reviews to save time
- Avoid running build/test commands in parallel agents to prevent conflicts