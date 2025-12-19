---
name: ios-e2e-testing
description: iOS/XCUITest E2E testing patterns. Use when writing SwiftUI UI tests, debugging XCUITest failures, or fixing flaky iOS tests. Covers accessibility identifiers, XCUIElement queries, SwiftUI-to-XCUITest element mapping, and condition-based waiting patterns.
---

# iOS UI Testing (XCUITest)

## Overview

**Two core principles eliminate 90% of UI test failures:**

1. **Use accessibility identifiers** - Target elements by explicit identifiers, not labels or element hierarchy
2. **Wait for conditions, not timeouts** - Use `waitForExistence(timeout:)` and predicates instead of `sleep()`

## Adding Accessibility Identifiers (SwiftUI)

Every testable element needs an accessibility identifier in the source code.

```swift
// ✅ Add identifiers to SwiftUI views
Button("Save") { save() }
    .accessibilityIdentifier("saveButton")

TextField("Enter name", text: $name)
    .accessibilityIdentifier("nameTextField")

Toggle("Enable notifications", isOn: $enabled)
    .accessibilityIdentifier("notificationsToggle")

Text("Welcome, \(user.name)")
    .accessibilityIdentifier("welcomeMessage")

// ✅ For List rows, add identifier to the row content
List(items) { item in
    ItemRow(item: item)
        .accessibilityIdentifier("itemRow-\(item.id)")
}

// ✅ For navigation titles or screen identification
VStack { /* content */ }
    .accessibilityIdentifier("settingsScreen")
```

### Naming Convention

Use consistent, descriptive identifiers:

| Element Type | Pattern                             | Example                             |
| ------------ | ----------------------------------- | ----------------------------------- |
| Buttons      | `{action}Button`                    | `saveButton`, `deleteButton`        |
| Text fields  | `{field}TextField`                  | `nameTextField`, `emailTextField`   |
| Toggles      | `{feature}Toggle`                   | `notificationsToggle`               |
| Static text  | `{purpose}Text` or `{purpose}Label` | `welcomeText`, `errorLabel`         |
| Screens      | `{screen}Screen`                    | `settingsScreen`, `dashboardScreen` |
| Rows         | `{type}Row-{id}`                    | `itemRow-123`                       |

## Querying Elements (XCUITest)

Query elements by their accessibility identifier:

```swift
// ✅ Query by accessibility identifier
let saveButton = app.buttons["saveButton"]
let nameField = app.textFields["nameTextField"]
let toggle = app.switches["notificationsToggle"]
let welcomeText = app.staticTexts["welcomeMessage"]

// ✅ Always wait for existence before interacting
XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button should appear")
saveButton.tap()
```

### SwiftUI Element Type Mapping

SwiftUI components map to XCUITest element types:

| SwiftUI         | XCUITest Query                             |
| --------------- | ------------------------------------------ |
| Button          | `app.buttons["id"]`                        |
| Text            | `app.staticTexts["id"]`                    |
| TextField       | `app.textFields["id"]`                     |
| SecureField     | `app.secureTextFields["id"]`               |
| Toggle          | `app.switches["id"]`                       |
| Picker          | `app.pickers["id"]` or `app.buttons["id"]` |
| DatePicker      | `app.datePickers["id"]`                    |
| List            | `app.collectionViews["id"]`                |
| NavigationStack | `app.collectionViews.firstMatch`           |

## Condition-Based Waiting

**Never use `sleep()` in UI tests.** It's unreliable and slow.

### Wait for Element to Appear

```swift
// ✅ Wait for element with timeout
let element = app.buttons["submitButton"]
XCTAssertTrue(element.waitForExistence(timeout: 5), "Submit button should appear")
element.tap()
```

### Wait for Element to Disappear

```swift
func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
    let predicate = NSPredicate(format: "exists == false")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
}

// Usage: Wait for loading spinner to disappear
let spinner = app.activityIndicators["loadingSpinner"]
XCTAssertTrue(waitForDisappearance(spinner), "Loading should complete")
```

### Wait for Specific State

```swift
func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
    let predicate = NSPredicate(format: "isEnabled == true")
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
}

// Usage: Wait for button to become enabled after validation
let submitButton = app.buttons["submitButton"]
XCTAssertTrue(waitForEnabled(submitButton), "Submit should enable after input")
submitButton.tap()
```

### Timeout Guidelines

| Operation        | Timeout |
| ---------------- | ------- |
| UI animations    | 2-3s    |
| Local operations | 5s      |
| Network requests | 10s     |
| Complex flows    | 30s max |

## Common Patterns

### System Dialogs (Alerts, Action Sheets)

**Exception to identifier rule:** System dialogs cannot have accessibility identifiers. Query by label text:

```swift
// ✅ Alerts - query by title text
let alert = app.alerts["Delete Account"]  // Uses alert title
XCTAssertTrue(alert.waitForExistence(timeout: 3))

// ✅ Alert buttons - query by button label
let cancelButton = alert.buttons["Cancel"]
let deleteButton = alert.buttons["Delete"]
deleteButton.tap()

// ✅ Action sheets - same pattern
let sheet = app.sheets["Choose Option"]
sheet.buttons["Share"].tap()
```

**Why:** SwiftUI's `.alert()` and `.confirmationDialog()` don't accept `.accessibilityIdentifier()`. These are system-provided UI, so query by their visible text.

### Toggle Interaction (SwiftUI Forms)

SwiftUI Toggles in Forms require coordinate-based tapping:

```swift
// ✅ Tap the switch control (right side of toggle)
let toggle = app.switches["notificationsToggle"]
XCTAssertTrue(toggle.waitForExistence(timeout: 5))
toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
```

### Text Field Entry

```swift
let nameField = app.textFields["nameTextField"]
XCTAssertTrue(nameField.waitForExistence(timeout: 5))
nameField.tap()
nameField.typeText("John Doe")
```

### Verifying Element State

```swift
// ✅ Use isHittable for visibility checks (safe)
if element.exists && element.isHittable {
    element.tap()
}

// ❌ Avoid frame checks (can throw errors)
// if element.frame.width > 0 { }
```

## DisclosureGroup Testing

### Check Default Expansion State

DisclosureGroups have a default expansion state in the ViewModel. **Don't assume they start collapsed.**

```swift
// In ViewModel - check these defaults!
var isDailyEngagementExpanded: Bool = true   // Starts EXPANDED
var isStreakExpanded: Bool = false           // Starts COLLAPSED
```

If section starts expanded, test collapse then expand. If starts collapsed, test expand then collapse.

### Tapping DisclosureGroups

**Don't tap the button directly** - tap the cell containing it:

```swift
// ❌ This often doesn't trigger expansion
let sectionButton = app.buttons["sectionIdentifier"]
sectionButton.tap()

// ✅ Tap the cell containing the disclosure group
let sectionCell = app.cells.containing(.button, identifier: "sectionIdentifier").firstMatch
XCTAssertTrue(sectionCell.waitForExistence(timeout: 5))
sectionCell.tap()
```

## SwiftUI Toggle Identifiers Often Fail

SwiftUI Toggles in Forms often **don't expose their accessibility identifier**. Query by label text instead:

```swift
// ❌ Identifier may not work
let toggle = app.switches["loveTapReminderToggle"]  // Often returns nothing

// ✅ Query by the visible label text
let toggle = app.switches["Love Tap Reminders"]
```

**Always verify in Accessibility Inspector** - actual labels may differ from what you expect:
- Code says "Streak Notifications" but label is "Enable Streak Notifications"

## Index Queries for Multiple Similar Elements

When multiple elements share a parent identifier (e.g., multiple time pickers in a section):

```swift
// ❌ This might match the wrong picker
let timePicker = app.datePickers["sectionId"]

// ✅ Use index query to get specific element
let loveTapTimePicker = app.datePickers.matching(identifier: "dailyEngagementSection").element(boundBy: 0)
let actionTimePicker = app.datePickers.matching(identifier: "dailyEngagementSection").element(boundBy: 1)
```

## Nested Element Queries

For elements inside sections, scope the query using the section identifier:

```swift
// ✅ Find toggle inside a specific section
let intimacyToggle = app.switches["intimacyNotificationSection"].switches.firstMatch
```

## Common Mistakes

| Mistake                           | Problem                         | Solution                             |
| --------------------------------- | ------------------------------- | ------------------------------------ |
| Using `sleep()`                   | Slow, unreliable                | `waitForExistence(timeout:)`         |
| Querying by label text            | Breaks with localization        | Use accessibility identifiers        |
| No identifier in source           | Element not findable            | Add `.accessibilityIdentifier("id")` |
| Not waiting before tap            | Element not ready               | Always `waitForExistence` first      |
| Using `.frame` checks             | Throws invalid frame errors     | Use `.isHittable` instead            |
| Assuming element types            | SwiftUI maps differently        | Check element type mapping table     |
| Adding identifier to alert        | Doesn't work on system dialogs  | Query alerts/sheets by title text    |
| Tapping DisclosureGroup button    | Doesn't expand section          | Tap the containing cell instead      |
| Assuming toggle identifiers work  | SwiftUI Forms don't expose them | Query by label text                  |
| Assuming sections start collapsed | May start expanded              | Check ViewModel defaults             |

## Test Structure

```swift
func testFeatureBehavior() throws {
    // GIVEN: Set up initial state
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing"]
    app.launch()

    // Navigate to screen
    let tab = app.tabBars.buttons["Settings"]
    XCTAssertTrue(tab.waitForExistence(timeout: 5))
    tab.tap()

    // WHEN: Perform action
    let toggle = app.switches["notificationsToggle"]
    XCTAssertTrue(toggle.waitForExistence(timeout: 5))
    toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

    // THEN: Verify outcome
    let confirmation = app.staticTexts["settingsSavedText"]
    XCTAssertTrue(confirmation.waitForExistence(timeout: 5), "Confirmation should appear")
}
```

## Quick Reference

**In SwiftUI (add identifiers):**
```swift
.accessibilityIdentifier("myIdentifier")
```

**In XCUITest (query elements):**
```swift
let element = app.buttons["myIdentifier"]
XCTAssertTrue(element.waitForExistence(timeout: 5))
element.tap()
```

**Two rules that prevent flaky tests:**
1. Every testable element has an accessibility identifier
2. Every interaction waits for condition, never sleeps
