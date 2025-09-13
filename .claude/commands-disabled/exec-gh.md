---
description: Execution mode for tasks
argument-hint: issue #
---

# Execution Mode - Outside-In TDD

You are operating in EXECUTION MODE. **FOLLOW THE PLAN PRECISELY** using Outside-In Test-Driven Development.

## Outside-In TDD Flow

**E2E Tests** → **Integration Tests** → **Unit Tests** → **Implementation**

Each outer layer defines the acceptance criteria and contracts for the inner layers. E2E tests are the ultimate acceptance criteria that define when a feature is truly "done" from the user's perspective.

## Active Context

- GitHub Issue: $ARGUMENTS
- If this number refers to an EPIC (parent issue) it should have label `epic` OR title prefix `Epic:` / `Feature:`. Child tasks (sub-issues) are linked via `gh sub-issue`.
- Always resolve hierarchical context BEFORE writing tests or code:
    1. Identify: Is current issue parent (epic) or child? (Use: `gh issue view $ARGUMENTS --json number,title,labels` and `gh sub-issue list $ARGUMENTS --json total,openCount 2>/dev/null`.)
    2. For epics: Enumerate children + progress. For children: fetch parent epic reference (present in its body or via manual note) – if missing, escalate (ask user or create epic first).
    3. Never implement broad scope work in a child; split into separate sub-issues if acceptance criteria diverge.

### Hierarchical Task Rules
- Single level only (Epic → Sub-Issues). No nesting of sub-issues.
- Sub-issue titles are imperative and focused (one outcome).
- Keep epics outcome-oriented; implementation details live in children.
- When uncovering new work not represented: create new sub-issue under epic (do NOT silently expand scope in code).
- Close epics only when `openCount == 0`.

### Rapid Hierarchy Commands (Reference)
```bash
# List children & progress (human)
gh sub-issue list <EPIC>

# List (JSON) for automation
gh sub-issue list <EPIC> --json number,title,state,total,openCount

# Create new child task under epic
gh sub-issue create --parent <EPIC> --title "Implement dose export CSV" --label persistence

# Link existing issue as child
gh sub-issue add <EPIC> <ISSUE>

# Remove linkage (keep issue)
gh sub-issue remove <EPIC> <ISSUE> --force
```

### Progress Snippet
```bash
prog=$(gh sub-issue list <EPIC> --json total,openCount 2>/dev/null)
total=$(echo "$prog" | jq -r '.total // 0')
open=$(echo "$prog" | jq -r '.openCount // 0')
echo "Epic progress: $((total-open))/$total complete ($open open)"
```

## Core Principles

1. **Plan is Truth** - The planning document is your single source of truth
2. **E2E Defines Success** - E2E tests are the acceptance criteria that define "done"
3. **Outside-In Flow** - Each outer layer drives requirements for inner layers
4. **Test First** - Write failing tests before any implementation
5. **Minimal Implementation** - Write only enough code to pass tests
6. **No Improvisation** - Don't add features or improvements not in the plan
7. **Verify Continuously** - Run tests after every change

## THE PROCESS

### Step 1: Task Setup
- [ ] Ask user: "Executing Issue #X: [Task Description]. Proceed?" → WAIT for confirmation
- [ ] Check git status: `git status`
- [ ] Create feature branch: `git checkout -b feat/issue-XX-description`
- [ ] Read issue requirements thoroughly
- [ ] Determine hierarchy role:
    * Epic? (`label:epic` OR title prefix `Epic:`/`Feature:`) → list children & progress
    * Child? → ensure parent epic exists & linked; if missing, pause & clarify
- [ ] For epics: ensure each acceptance criterion maps to (or becomes) a sub-issue (create with `gh sub-issue create` as needed BEFORE coding)
- [ ] For children: confirm acceptance criteria are confined to this scope (if broader, split into additional sub-issues first)
- [ ] **Decide E2E Test Needed**: User-facing features = YES, Internal utilities = NO
- [ ] Check dependencies are met

### Step 2: E2E Acceptance Test (if applicable)
- [ ] Analyze existing XCUITest files to understand patterns
- [ ] Write E2E test in `JabTrackerUITests/[Feature]UITests.swift` that defines **ACCEPTANCE CRITERIA**
- [ ] **E2E test represents user success** - What does "done" look like to the user?
- [ ] Run test: `xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -only-testing:JabTrackerUITests/[TestClass]`
- [ ] **Confirm test FAILS for right reason**
- [ ] Commit failing E2E test

### Step 3: Unit Test Development
- [ ] **Analyze E2E requirements** - What components/services does the E2E test need?
- [ ] Break down E2E scenario into required units
- [ ] Analyze existing Swift Testing files to understand patterns
- [ ] Write failing unit test for first component/service **to fulfill E2E contract**
- [ ] Run test: `swift test --filter [TestName]` or `xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -only-testing:JabTrackerTests/[TestClass]`
- [ ] **Confirm test FAILS**
- [ ] Commit failing unit test

### Step 4: Implementation
- [ ] Write **minimal** code to pass the unit test
- [ ] Run unit test: `xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -only-testing:JabTrackerTests/[TestClass]`
- [ ] **Confirm test PASSES**
- [ ] Repeat steps 3-4 for each unit **required by E2E test**
- [ ] Commit working code
- [ ] **configure coverage thresholds for new files**
- [ ] Update `coverage-config.json`
- [ ] Check coverage: `./scripts/coverage-json.sh <file-name>`

### Step 5: Integration & E2E Verification
- [ ] Wire components together to **fulfill E2E acceptance criteria**
- [ ] Run E2E test: `xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -only-testing:JabTrackerUITests/[TestClass]`
- [ ] **E2E test should now PASS** - User success criteria met
- [ ] Add E2E edge case tests if critical
- [ ] Fix any integration issues
- [ ] Ensure new files have been added to `coverage-config.json`
- [ ] Run coverage analysis: `./scripts/coverage-json.sh`
- [ ] **Coverage thresholds must be met**

### Step 6: Final Verification & Ship
- [ ] Run all checks (unit, e2e, build, swiftlint): `./scripts/check-all.sh`
- [ ] **All checks must PASS & and ALL swiftlint violations (not just critical) MUST be addressed**
- [ ] Update relevant documentation
- [ ] Commit final changes
- [ ] Create pull request with clear description and wait for further instruction

## When to Use E2E Tests

**Include E2E for:**
- User-facing features (login, dose tracking, analytics)
- Critical business workflows (medication calculations)
- Complex UI interactions (multi-step forms, tab navigation)

**Skip E2E for:**
- Pure utilities (date helpers, validation functions)
- Internal refactoring
- Simple CRUD without special UI behavior

## Quick Command Reference

```bash
# Project setup
cd /Users/gannonhall/dev/jab-tracker-ios

# Testing
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'  # All tests
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -only-testing:JabTrackerTests/[TestClass]  # Specific unit test
xcodebuild test -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -only-testing:JabTrackerUITests/[TestClass]  # Specific UI test

# Build & Quality
xcodebuild build -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'  # Build project
xcodebuild analyze -scheme JabTracker -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5'  # Static analysis

# Performance Testing
instruments -t "Time Profiler" -D /tmp/profile.trace [app_path]  # Profile performance
open /Applications/Xcode.app/Contents/Applications/Accessibility\ Inspector.app  # Accessibility testing

# Git workflow
git status
git checkout -b feat/issue-XX-description
git add . && git commit -m "feat: description"
```

## XCUITest Structure

```swift
// JabTrackerUITests/[Feature]UITests.swift
import XCTest

final class DoseEntryUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    @MainActor
    func testAddDoseFlow() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.tabBars.buttons["Add"].tap()
        app.buttons["Quick Add Dose"].tap()
        
        let successAlert = app.alerts["Dose Added"]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 5))
    }
}
```

## Swift Testing Structure

```swift
// JabTrackerTests/[Feature]Tests.swift
import Testing
@testable import JabTracker

@Suite("Pharmacokinetics Engine")
struct PharmacokineticsEngineTests {
    
    @Test("Concentration calculation for semaglutide")
    func concentrationCalculation() throws {
        let engine = PharmacokineticsEngine()
        let dose = Dose(amount: 1.0, timestamp: Date(), medication: .semaglutide)
        
        let concentration = engine.calculateConcentration(
            doses: [dose], 
            medication: .semaglutide, 
            at: Date().addingTimeInterval(24 * 60 * 60) // 1 day later
        )
        
        #expect(concentration > 0)
        #expect(concentration < dose.amount)
    }
    
    @Test("Multiple medications", arguments: [
        (Medication.semaglutide, 1.0),
        (Medication.tirzepatide, 5.0)
    ])
    func medicationProperties(medication: Medication, expectedDose: Double) {
        #expect(medication.availableDoses.contains(expectedDose))
        #expect(medication.halfLifeDays > 0)
    }
}
```

## Accessibility IDs Convention

```swift
// Use semantic, descriptive accessibility identifiers
Button("Add Dose") { }
    .accessibilityIdentifier("add-dose-button")

List { }
    .accessibilityIdentifier("medication-list")

TextField("Dose Amount", text: $doseAmount)
    .accessibilityIdentifier("dose-amount-input")
```

## Stop and Clarify When

- E2E test requirements are ambiguous
- Cannot determine user journey from requirements
- UI elements for testing don't exist
- E2E tests would require extensive mocking

## Project Context

- SwiftUI iOS project targeting iOS 16+
- Build system: Xcode + Swift Package Manager
- E2E testing: XCUITest (native iOS UI testing)
- Unit testing: Swift Testing (modern Swift test framework)
- Backend: CloudKit (auth, sync, storage)
- Data: Core Data + CloudKit sync (NSPersistentCloudKitContainer)
- State: SwiftUI's native state management (@State, @ObservableObject, etc.)
- Auth: Sign in with Apple + Face ID/Touch ID

## Useful MCPs

- Context7: Swift/SwiftUI code examples and Apple framework documentation
- Perplexity: iOS development best practices research
- GitHub MCP: Managing issues and PRs
- IDE MCP: Swift diagnostics and code intelligence
- Serena MCP: Semantic codebase analysis (when Swift files exist)

---

**Remember**: E2E tests define user success. Start with the end in mind, then work backwards through the implementation layers. Follow the checklist exactly - don't skip steps.