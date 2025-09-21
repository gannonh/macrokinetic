---
description: Use this command to enter complex prompts that may fail if entered directly into the prompt input.
argument-hint:
allowed-tools: 
---

create a qa slash command here: .claude/commands/qa called swiftlint.md that instructs an agent to:\
  
  1. Run swiftformat .  
  2. Run swiftlint --fix
  3. run `./scripts/test.sh unit 1` to make sure all tests still passing
  4. Run swiftlint
  5. Fix ALL violations
  6. Run `./scripts/test.sh unit 1` to make sure all tests still passing

