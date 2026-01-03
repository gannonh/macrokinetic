---
trigger: glob
globs:  **/*UITests.swift
---


# iOS UI Testing (XCUITest)

**Two core principles eliminate 90% of UI test failures:**

1. **Use accessibility identifiers** - Target elements by explicit identifiers, not labels or element hierarchy
2. **Wait for conditions, not timeouts** - Use `waitForExistence(timeout:)` and predicates instead of `sleep()`

---

## ⛔️ MANDATORY: When Tests Fail, Debug First

**STOP. Before changing ANY code when a test fails, you MUST run these debug steps:**

### Step 1: Capture Screenshot
```swift
// Add this line RIGHT BEFORE the failing assertion
TestUtilities.debugScreenshot(app, name: "before-failure")
```

### Step 2: Print Element Hierarchy
```swift
// Add this line RIGHT BEFORE the failing assertion
print(app.debugDescription)
```

### Step 3: Run Test and Examine Output
```bash
./scripts/test.sh ui 1 YourTestClass/testMethod
open logs/latest/screenshots/
```

### Step 4: Analyze BEFORE Changing Code
- **Screenshot shows**: What the UI actually looks like
- **debugDescription shows**: What elements exist and their identifiers
- **Together they answer**: Why can't the test find/interact with the element?

### ❌ DO NOT:
- Guess at element types or identifiers
- Change accessibility identifiers without seeing the hierarchy
- Add arbitrary timeouts hoping it fixes timing
- Modify SwiftUI views without confirming the element structure

### ✅ ALWAYS:
- Capture visual evidence of the failure state
- Print the element tree to see actual identifiers
- Compare expected vs actual element types
- Only then make targeted fixes based on evidence

**This debug-first approach is not optional. Skipping it leads to wasted effort and incorrect fixes.**

---

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

## Debugging Element Hierarchy (CRITICAL)

**Before writing any test query, debug the actual element hierarchy:**

### Print Element Tree
```swift
// In test - print entire app hierarchy
print(app.debugDescription)

// Print specific container
print(app.otherElements["myContainer"].debugDescription)
```

### Use Accessibility Inspector
1. Open Xcode → Open Developer Tool → Accessibility Inspector
2. Target the simulator
3. Hover over elements to see their type, identifier, and label

### Debug Query Results
```swift
// See how many elements match a query
let matches = app.descendants(matching: .any).matching(identifier: "myId")
print("Found \(matches.count) matches")
print(matches.debugDescription)
```

### Interpret Sparse Tree Errors
When XCUITest reports "Multiple matching elements found", it shows a sparse tree:
```
StaticText, identifier: 'calendar-day-20', label: 'Dec 20'
Other, identifier: 'calendar-day-20', label: 'Dec 20'
```
This means SwiftUI created duplicate accessibility elements (see below for fix).

## Debug Screenshots (CRITICAL for Debugging)

**Capture screenshots during test execution to see exactly what the UI looks like:**

### Quick Debug Screenshot
```swift
// Capture at any point during test
TestUtilities.debugScreenshot(app, name: "after-login")
TestUtilities.debugScreenshot(app, name: "error-dialog", context: "unexpected state")

// Sequential screenshots with step numbers
TestUtilities.debugScreenshot(app, step: 1, description: "initial-state")
TestUtilities.debugScreenshot(app, step: 2, description: "after-tap")
TestUtilities.debugScreenshot(app, step: 3, description: "form-submitted")
```

### Capture on Test Failure
```swift
override func tearDown() {
    if testRun?.hasSucceeded == false {
        TestUtilities.captureFailureScreenshot(app, testName: name)
    }
    super.tearDown()
}
```

### Viewing Screenshots
Screenshots are saved to `logs/latest/screenshots/` as PNG files:
```bash
# Open screenshots folder in Finder
open logs/latest/screenshots/

# View a specific screenshot
open logs/latest/screenshots/after-login.png

# List all screenshots
ls -la logs/latest/screenshots/
```

### When to Use Debug Screenshots
| Scenario             | Usage                                                 |
| -------------------- | ----------------------------------------------------- |
| Element not found    | Capture before the failing assertion to see actual UI |
| Wrong element tapped | Capture before and after tap to compare               |
| Timing issues        | Capture at multiple steps to see animation state      |
| Test flakiness       | Capture on failure to see inconsistent state          |
| Debugging hierarchy  | Screenshot + `print(app.debugDescription)` together   |

### Screenshot vs debugDescription
- **Screenshots**: Show visual layout, actual text, colors, positioning
- **debugDescription**: Shows accessibility hierarchy, identifiers, element types
- **Use both together**: Screenshot for "what does it look like?" + debugDescription for "how do I target it?"

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

| SwiftUI             | XCUITest Query                             |
| ------------------- | ------------------------------------------ |
| Button              | `app.buttons["id"]`                        |
| Text                | `app.staticTexts["id"]`                    |
| TextField           | `app.textFields["id"]`                     |
| SecureField         | `app.secureTextFields["id"]`               |
| Toggle              | `app.switches["id"]`                       |
| Picker              | `app.pickers["id"]` or `app.buttons["id"]` |
| DatePicker          | `app.datePickers["id"]`                    |
| List                | `app.collectionViews["id"]`                |
| NavigationStack     | `app.collectionViews.firstMatch`           |
| View + onTapGesture | `app.otherElements["id"]` ⚠️ NOT buttons    |

### Views with onTapGesture are NOT Buttons

**Critical:** SwiftUI views using `.onTapGesture` are exposed as `otherElements`, NOT `buttons`:

```swift
// SwiftUI source
VStack { Text("Day 20") }
    .onTapGesture { selectDay() }
    .accessibilityIdentifier("calendar-day-20")

// ❌ WRONG - won't find it
let day = app.buttons["calendar-day-20"]  // Returns nothing!

// ✅ CORRECT
let day = app.otherElements["calendar-day-20"]
```

### Handling Multiple Matches with .firstMatch

When a query returns multiple elements, use `.firstMatch`:

```swift
// ❌ Crashes with "Multiple matching elements found"
let element = app.descendants(matching: .any)["myId"]
element.tap()

// ✅ Gets first match
let element = app.descendants(matching: .any)["myId"].firstMatch
element.tap()
```

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
var isStreakExpanded: Bool = false           // Starts 