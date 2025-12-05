---
description: Validate iOS project coverage configuration
argument-hint: n/a
allowed-tools: Bash
model: claude-sonnet-4-20250514
---

# Validate Coverage Configuration

## Background Context

@.claude/context/testing.md

## Instructions

1. Run `bash ./scripts/check-coverage-config.sh` 

2. Summarize the results and ask me if I want to update the coverage configuration based on the results

Example:
---
The coverage configuration validation shows that 83 Swift files are missing from the coverage-config.json file. This means these files won't be
  included in coverage analysis.

  The script found:
  - 86 total Swift files in the JabTracker target
  - 37 files currently configured (30 in policy tiers + 7 in exclusions)
  - 83 missing files that need to be categorized

  The missing files include various components like:
  - UI Views and ViewModels
  - Models and their extensions
  - Services and utilities
  - Design system components
  - Analytics and chart components

  Would you like me to update the coverage configuration to include these missing files? I can categorize them into appropriate coverage tiers or exclusion categories based on their functionality and importance.


