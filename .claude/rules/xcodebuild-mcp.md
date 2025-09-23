## XcodeBuildMCP UI Testing & Accessibility

### describe_ui Tool for Precise Element Location
**CRITICAL**: Always use `describe_ui` to get precise coordinates for UI interactions instead of guessing from screenshots.

```bash
# Get complete accessibility hierarchy with precise coordinates
describe_ui({ simulatorUuid: "SIMULATOR_UUID" })

# Returns JSON with AXFrame data for every accessible element
# Use frame coordinates for interactions: center = (x + width/2, y + height/2)
```

**Key Benefits:**
- **Precise Coordinates**: Exact pixel locations for tap, swipe, and gesture actions
- **Accessibility Identifiers**: Find elements by their `AXUniqueId` for reliable test selectors
- **Element State**: See if elements are enabled, selected, or have specific values
- **Element Types**: Distinguish between Button, TextField, Group, StaticText, etc.

### Accessibility Configuration Requirements
For `describe_ui` to work properly, the simulator must have accessibility enabled:

**Common Issue**: `describe_ui` returns empty JSON hierarchy
- **Cause**: Accessibility not properly configured in simulator
- **Solution**: Enable accessibility via command line:
```bash
xcrun simctl spawn 336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB defaults write com.apple.Accessibility VoiceOverTouchEnabled -bool true

# Then run describe_ui again
describe_ui({ simulatorUuid: "336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB" })
```

Now`describe_ui` will return proper accessibility hierarchy with full coordinates and element data.

### UI Testing Element Selector Patterns
Based on onboarding flow implementation analysis:

**Dose Selection Components:**
- Dose buttons use pattern: `dose-button-{amount}` (e.g., `dose-button-1.0`, `dose-button-0.25`)
- NOT TextField with `dose-amount-input` - use individual dose buttons instead
- Each dose button shows selected state in `AXValue` field

**Medication Selection:**
- Medication buttons use pattern: `medication-{medication}` (e.g., `medication-semaglutide`)
- Selection state indicated in `AXValue`: "Selected" or "Not selected"

**Navigation Elements:**
- Continue button: `onboarding-continue-button`
- Back button: `onboarding-back-button`
- Progress indicator: `onboarding-progress`

**Common UI Testing Mistakes:**
- Looking for TextField when implementation uses Button components
- Assuming element visibility without checking if scrolling is required
- Using screenshots for coordinates instead of `describe_ui` data

### SwiftUI Form Testing Patterns (Session 4 Learnings)
**Critical for medication profile management UI testing:**

**Toggle Switch Interaction:**
- **Issue**: Direct `tap()` on Form toggles doesn't change state in UI tests
- **Solution**: Use coordinate-based tapping at the switch control area
```swift
// ❌ This doesn't work reliably in SwiftUI Forms
compoundedToggle.tap()

// ✅ This works - tap at the actual switch control (right side)
compoundedToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
```

**Picker Element Selection:**
- **Issue**: Dynamic accessibility identifiers based on selection state are unreliable
- **Solution**: Use static identifiers for picker elements
```swift
// ✅ Good - static identifier
app.pickers["medication-picker"]

// ❌ Bad - dynamic based on current selection
app.pickers["medication-\(currentSelection)"]
```

**List Item Types:**
- **SwiftUI Lists**: Profile items render as `Button` type, not `Cell` type
- **Navigation**: Use proper element types when searching list items
- **Accessibility**: List items inherit button semantics from SwiftUI

**Test Management:**
- **Unimplemented Features**: Use `throw XCTSkip("reason")` instead of commenting out tests
- **Error Messages**: Provide clear context for debugging UI test failures
- **State Validation**: Always check element state before and after interactions
