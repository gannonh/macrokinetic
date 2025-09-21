---
description: Use this command to enter complex prompts that may fail if entered directly into the prompt input.
argument-hint:
allowed-tools: 
---

1. Commit your work so far

2. For Acceptable Violations:

  - Test File Line Length: Update .swiftlint.yml is test directories to allow longer lines
  - Medical Logic Complexity: Add justification in code comments for complex medical logic and create exceptions in the file if possible or in .swiftlint.yml
  - Service File Size: Add justification in code comments for complex medical logic and create exceptions in the file if possible or in .swiftlint.yml

  3. Address the following violations:

  - Test Variable Naming: Use camelCase (dose1Point5 instead of dose1_5)
  - Break Down Large Functions: Extract helper methods from complex validation functions
  - Service Decomposition: Consider breaking DoseSearchService into smaller, focused services