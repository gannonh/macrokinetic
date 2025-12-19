---
description: Bootstrap a new iOS project from the starter kit
argument-hint: PRD content or file path (optional)
---

# Bootstrap iOS Project

Creates a new iOS project from the starter-ios template.

Input: $ARGUMENTS (optional PRD content or file path)

## CRITICAL: You MUST use the AskUserQuestion tool

Do NOT assume or make up values. You MUST invoke the AskUserQuestion tool to interactively collect project configuration from the user.

## Step 1: Analyze PRD (if provided)

If $ARGUMENTS is provided:
- If it's a file path, read the file to understand the app
- Otherwise, treat it as inline PRD text
- Use this to suggest a recommended app name

## Step 2: Ask User for Configuration

IMMEDIATELY invoke the AskUserQuestion tool with these questions:

**Question 1 - App Name:**
- Header: "App name"
- Question: "What should the app be called?"
- Options: If PRD provided, suggest an inferred name as first option marked "(Recommended)", plus 1-2 alternatives
- Description should note: "PascalCase, no spaces (e.g., MyNewApp)"

**Question 2 - Bundle ID Prefix:**
- Header: "Bundle ID"
- Question: "What bundle ID prefix should be used?"
- Options: "com.gannonhall (Recommended)", "io.{inferredname}", "com.{inferredname}"
- Description: "Reverse domain format - final ID will be {prefix}.{AppName}"

**Question 3 - Team ID:**
- Header: "Team ID"
- Question: "What is your Apple Developer Team ID?"
- Options: "ZBZKKWF95G (Recommended)" with description "Default team ID", plus "Other" option
- Description: "10-character ID from developer.apple.com/account"

**Question 4 - Target Platforms:**
- Header: "Platforms"
- Question: "Which platforms should the app target?"
- multiSelect: true
- Options:
  - "iOS - iPhone (17.4+) (Recommended)" - Primary platform, always included
  - "iPadOS - iPad (17.4+)" - iPad support
  - "macOS - Mac (14.4+)" - Mac support
  - "watchOS - Apple Watch (10.4+)" - Companion watch app

**Question 5 - Multi-Platform Approach (only if multiple platforms selected):**
- Header: "Approach"
- Question: "How should the app support multiple platforms?"
- multiSelect: false
- Options:
  - "Unified SwiftUI (Recommended)" - Single codebase with #if os() conditionals. Best for similar UI across platforms.
  - "Native Targets" - Separate targets per platform with shared code. Best for platform-optimized UX.

**Question 6 - Capabilities:**
- Header: "Capabilities"
- Question: "Which capabilities do you need?"
- multiSelect: true
- Options: "CloudKit (iCloud sync)", "Sign in with Apple", "Push Notifications", "Biometrics (Face ID/Touch ID)"

## Step 3: Execute Bootstrap

After receiving answers, run:

```bash
cd /Users/gannonhall/dev/starter-ios && python3 .claude/scripts/bootstrap-project.py \
  --name "{AppName}" \
  --bundle-prefix "{BundlePrefix}" \
  --team-id "{TeamID}" \
  --platforms "{comma-separated-platforms}" \
  --approach "{approach}" \
  --capabilities "{comma-separated-capabilities}" \
  --output ~/dev \
  --prd "{PRDFilePathOrContent}"
```

Platform mapping for --platforms flag:
- "iOS - iPhone (17.4+)" → ios
- "iPadOS - iPad (17.4+)" → ipados
- "macOS - Mac (14.4+)" → macos
- "watchOS - Apple Watch (10.4+)" → watchos

Approach mapping for --approach flag:
- "Unified SwiftUI" → unified
- "Native Targets" → native

Capability mapping for --capabilities flag:
- "CloudKit (iCloud sync)" → cloudkit
- "Sign in with Apple" → siwa
- "Push Notifications" → push
- "Biometrics (Face ID/Touch ID)" → biometrics

## Step 4: Report Results

After successful bootstrap, tell the user:
- Project location: ~/dev/{AppName}
- Bundle ID: {BundlePrefix}.{AppName}
- Deep link scheme: {lowercase app name}
- Target platforms with minimum versions
- Multi-platform approach used
- Next steps:
  1. `cd ~/dev/{AppName}`
  2. `open {AppName}.xcodeproj`
  3. Build and run (signing and capabilities already configured in project.yml)
