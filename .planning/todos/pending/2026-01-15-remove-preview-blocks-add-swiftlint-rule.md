---
created: 2026-01-15T20:10
title: Remove #Preview blocks and add SwiftLint rule
area: tooling
files:
  - JabTracker/Views/**/*.swift
  - .swiftlint.yml
---

## Problem

SwiftUI `#Preview` blocks are development-time conveniences that:
1. Add unnecessary code bloat to production builds
2. Sometimes reference test data or mock objects
3. Can become stale when views change
4. Increase compile times

The codebase likely has many `#Preview` blocks scattered across view files that should be removed, and a SwiftLint rule should prevent new ones from being added.

## Solution

1. Find all `#Preview` blocks: `grep -r "#Preview" JabTracker/`
2. Remove them from all view files
3. Add a custom SwiftLint rule in `.swiftlint.yml`:
   ```yaml
   custom_rules:
     no_preview_blocks:
       regex: '#Preview'
       message: "SwiftUI #Preview blocks are not allowed in production code"
       severity: error
   ```
4. Run SwiftLint to verify no violations remain
