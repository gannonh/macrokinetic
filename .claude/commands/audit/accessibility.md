---
description: Comprehensive accessibility audit for iOS/macOS apps - VoiceOver, Dynamic Type, color contrast, touch targets, keyboard navigation, Reduce Motion, and App Store Review preparation
argument-hint: Scope to audit (optional)
---

# Accessibility Audit

Perform a systematic accessibility audit for iOS/macOS apps. This audit covers the 7 most common accessibility issues that cause App Store rejections and user complaints.

**Scope (optional)**: $ARGUMENTS

If no scope is provided, "all" is assumed.

---

## Step 1: Identify Files to Audit

Search for SwiftUI views and UIKit view controllers in the target path:

```bash
# Find all view files
find {target_path} -name "*.swift" | xargs grep -l "View\|ViewController"
```

For each file found, proceed through Steps 2-8.

---

## Step 2: Audit VoiceOver Labels & Hints (CRITICAL - App Store Rejection)

**WCAG** 4.1.2 Name, Role, Value (Level A)

Search for these violations in each file:

### 2.1 Find icon-only buttons without labels
```swift
// Pattern to find: Button with Image but no accessibilityLabel
Grep: Button.*Image\(systemName:
```

**Violations:**
```swift
// ❌ WRONG - No label (VoiceOver says "Button")
Button(action: addToCart) {
  Image(systemName: "cart.badge.plus")
}

// ❌ WRONG - Generic label
.accessibilityLabel("Button")

// ❌ WRONG - Reads implementation details
.accessibilityLabel("cart.badge.plus") // VoiceOver: "cart dot badge dot plus"
```

**Fixes:**
```swift
// ✅ CORRECT - Descriptive label
Button(action: addToCart) {
  Image(systemName: "cart.badge.plus")
}
.accessibilityLabel("Add to cart")

// ✅ CORRECT - With hint for complex actions
.accessibilityLabel("Add to cart")
.accessibilityHint("Double-tap to add this item to your shopping cart")
```

### 2.2 Find decorative images that should be hidden
```swift
// Pattern: Image without accessibilityHidden or accessibilityLabel
Grep: Image\(".*"\)(?!.*accessibility)
```

**Fixes:**
```swift
// ✅ CORRECT - Hide decorative images from VoiceOver
Image("decorative-pattern")
  .accessibilityHidden(true)

// ✅ CORRECT - Combine multiple elements into one label
HStack {
  Image(systemName: "star.fill")
  Text("4.5")
  Text("(234 reviews)")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Rating: 4.5 stars from 234 reviews")
```

### 2.3 When to use hints
- Action is not obvious from label ("Add to cart" is obvious, no hint needed)
- Multi-step interaction ("Swipe right to confirm, left to cancel")
- State change ("Double-tap to toggle notifications on or off")

**Report format:**
```
VoiceOver Issues Found:
- [ ] {file}:{line} - Button with Image missing accessibilityLabel
- [ ] {file}:{line} - Decorative image not hidden from VoiceOver
- [ ] {file}:{line} - Generic "Button" label
```

---

## Step 3: Audit Dynamic Type Support (HIGH - User Experience)

**WCAG** 1.4.4 Resize Text (Level AA - support 200% scaling)

### 3.1 Find fixed font sizes
```swift
// Pattern to find:
Grep: \.font\(\.system\(size:
Grep: UIFont\.systemFont\(ofSize:
Grep: Font\.custom\(.*size:
```

**Violations:**
```swift
// ❌ WRONG - Fixed size, won't scale
Text("Price: $19.99")
  .font(.system(size: 17))

UILabel().font = UIFont.systemFont(ofSize: 17)

// ❌ WRONG - Custom font without scaling
Text("Headline")
  .font(Font.custom("CustomFont", size: 24))
```

**Fixes:**
```swift
// ✅ CORRECT - SwiftUI semantic styles (auto-scales)
Text("Price: $19.99")
  .font(.body)

Text("Headline")
  .font(.headline)

// ✅ CORRECT - UIKit semantic styles
label.font = UIFont.preferredFont(forTextStyle: .body)

// ✅ CORRECT - Custom font with scaling
let customFont = UIFont(name: "CustomFont", size: 24)!
label.font = UIFontMetrics.default.scaledFont(for: customFont)
label.adjustsFontForContentSizeCategory = true

// ✅ GOOD - Custom size that scales with Dynamic Type
Text("Large Title")
  .font(.system(size: 60).relativeTo(.largeTitle))

Text("Custom Headline")
  .font(.system(size: 24).relativeTo(.title2))
```

### 3.2 SwiftUI text styles reference
- `.largeTitle` - 34pt (scales to 44pt at accessibility sizes)
- `.title` - 28pt
- `.title2` - 22pt
- `.title3` - 20pt
- `.headline` - 17pt semibold
- `.body` - 17pt (default)
- `.callout` - 16pt
- `.subheadline` - 15pt
- `.footnote` - 13pt
- `.caption` - 12pt
- `.caption2` - 11pt

### 3.3 Find fixed frames that clip text
```swift
// Pattern to find:
Grep: \.frame\(.*height:.*\d+
```

**Violations:**
```swift
// ❌ WRONG - Fixed frame breaks with large text
Text("Long product description...")
  .font(.body)
  .frame(height: 50) // Clips at large text sizes
```

**Fixes:**
```swift
// ✅ CORRECT - Flexible frame
Text("Long product description...")
  .font(.body)
  .lineLimit(nil) // Allow multiple lines
  .fixedSize(horizontal: false, vertical: true)

// ✅ CORRECT - Stack rearranges at large sizes
HStack {
  Text("Label:")
  Text("Value")
}
.dynamicTypeSize(...DynamicTypeSize.xxxLarge) // Limit maximum size if needed
```

**Report format:**
```
Dynamic Type Issues Found:
- [ ] {file}:{line} - Fixed font size .system(size: 17)
- [ ] {file}:{line} - Fixed frame height will clip at large text
- [ ] {file}:{line} - Custom font without UIFontMetrics scaling
```

---

## Step 4: Audit Color Contrast (HIGH - Vision Disabilities)

**WCAG**
- **1.4.3 Contrast (Minimum)** — Level AA: Normal text 4.5:1, Large text 3:1
- **1.4.6 Contrast (Enhanced)** — Level AAA: Normal text 7:1, Large text 4.5:1

### 4.1 Find low-contrast color combinations
```swift
// Pattern to find:
Grep: \.foregroundColor\(\.yellow
Grep: \.foregroundColor\(\.gray\)
Grep: \.foregroundColor\(Color\(
```

**Violations:**
```swift
// ❌ WRONG - Low contrast (1.8:1 - fails WCAG)
Text("Warning")
  .foregroundColor(.yellow) // on white background

// ❌ WRONG - Low contrast in dark mode
Text("Info")
  .foregroundColor(.gray) // on black background
```

**Fixes:**
```swift
// ✅ CORRECT - High contrast (7:1+ passes AAA)
Text("Warning")
  .foregroundColor(.orange) // or .red

// ✅ CORRECT - System colors adapt to light/dark mode
Text("Info")
  .foregroundColor(.primary) // Black in light mode, white in dark

Text("Secondary")
  .foregroundColor(.secondary) // Automatic high contrast
```

### 4.2 Find color-only status indicators
```swift
// Pattern to find:
Grep: \.fill\(.*\.green.*\.red
Grep: \.foregroundColor\(.*\?.*:
```

**Violations:**
```swift
// ❌ WRONG - Color alone indicates status
Circle()
  .fill(isAvailable ? .green : .red)
```

**Fixes:**
```swift
// ✅ CORRECT - Color + icon/text
HStack {
  Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
  Text(isAvailable ? "Available" : "Unavailable")
}
.foregroundColor(isAvailable ? .green : .red)

// ✅ CORRECT - Respect system preference
if UIAccessibility.shouldDifferentiateWithoutColor {
  // Use patterns, icons, or text instead of color alone
}
```

### 4.3 Contrast ratio reference
- Black (#000000) on White (#FFFFFF): 21:1 ✅ AAA
- Dark Gray (#595959) on White: 7:1 ✅ AAA
- Medium Gray (#767676) on White: 4.5:1 ✅ AA
- Light Gray (#959595) on White: 2.8:1 ❌ Fails

**Report format:**
```
Color Contrast Issues Found:
- [ ] {file}:{line} - .yellow foreground likely fails 4.5:1 contrast
- [ ] {file}:{line} - Color-only status indicator (green/red)
- [ ] {file}:{line} - Custom color needs contrast verification
```

---

## Step 5: Audit Touch Target Sizes (MEDIUM - Motor Disabilities)

**WCAG** 2.5.5 Target Size (Level AAA - 44x44pt minimum)
**Apple HIG** 44x44pt minimum for all tappable elements

### 5.1 Find small touch targets
```swift
// Pattern to find:
Grep: \.frame\(width:\s*\d+,\s*height:\s*\d+
Grep: \.frame\(.*[0-3]\d.*[0-3]\d  // frames less than 40
Grep: \.onTapGesture.*Image\(systemName
```

**Violations:**
```swift
// ❌ WRONG - Too small (24x24pt)
Button("×") {
  dismiss()
}
.frame(width: 24, height: 24)

// ❌ WRONG - Small icon without padding
Image(systemName: "heart")
  .font(.system(size: 16))
  .onTapGesture { }
```

**Fixes:**
```swift
// ✅ CORRECT - Minimum 44x44pt
Button("×") {
  dismiss()
}
.frame(minWidth: 44, minHeight: 44)

// ✅ CORRECT - Larger icon or padding
Image(systemName: "heart")
  .font(.system(size: 24))
  .frame(minWidth: 44, minHeight: 44)
  .contentShape(Rectangle()) // Expand tap area
  .onTapGesture { }

// ✅ CORRECT - UIKit button with edge insets
button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
// Total size: icon size + insets ≥ 44x44pt
```

### 5.2 Find closely spaced targets
```swift
// Pattern to find:
Grep: HStack\(spacing:\s*[0-7]\)
Grep: VStack\(spacing:\s*[0-7]\)
```

**Violations:**
```swift
// ❌ WRONG - Targets too close (hard to tap accurately)
HStack(spacing: 4) {
  Button("Edit") { }
  Button("Delete") { }
}
```

**Fixes:**
```swift
// ✅ CORRECT - Adequate spacing (8pt minimum, 12pt better)
HStack(spacing: 12) {
  Button("Edit") { }
  Button("Delete") { }
}
```

**Report format:**
```
Touch Target Issues Found:
- [ ] {file}:{line} - Button frame 24x24 (needs 44x44 minimum)
- [ ] {file}:{line} - HStack spacing 4pt (needs 8pt+ between buttons)
- [ ] {file}:{line} - Icon with onTapGesture missing contentShape
```

---

## Step 6: Audit Keyboard Navigation (MEDIUM - iPadOS/macOS)

**WCAG** 2.1.1 Keyboard (Level A - all functionality via keyboard)

### 6.1 Find gesture-only interactions
```swift
// Pattern to find:
Grep: \.onTapGesture
Grep: \.gesture\(
```

**Violations:**
```swift
// ❌ WRONG - Custom gesture without keyboard alternative
.onTapGesture {
  showDetails()
}
// No way to trigger with keyboard
```

**Fixes:**
```swift
// ✅ CORRECT - Button provides keyboard support automatically
Button("Show Details") {
  showDetails()
}
.keyboardShortcut("d", modifiers: .command) // Optional shortcut

// ✅ CORRECT - Custom control with focus support
struct CustomButton: View {
  @FocusState private var isFocused: Bool

  var body: some View {
    Text("Custom")
      .focusable()
      .focused($isFocused)
      .onKeyPress(.return) {
        action()
        return .handled
      }
  }
}
```

### 6.2 Focus management patterns
```swift
// ✅ CORRECT - Set initial focus
.focusSection() // Group related controls
.defaultFocus($focus, .constant(true)) // Set default

// ✅ CORRECT - Move focus after action
@FocusState private var focusedField: Field?

Button("Next") {
  focusedField = .next
}
```

**Report format:**
```
Keyboard Navigation Issues Found:
- [ ] {file}:{line} - onTapGesture without Button alternative
- [ ] {file}:{line} - Custom control missing focusable()
- [ ] {file}:{line} - Form without focus management
```

---

## Step 7: Audit Reduce Motion Support (MEDIUM - Vestibular Disorders)

**WCAG** 2.3.3 Animation from Interactions (Level AAA)

### 7.1 Find animations without Reduce Motion check
```swift
// Pattern to find:
Grep: withAnimation\(
Grep: \.animation\(
Grep: \.transition\(
Grep: \.offset.*GeometryReader  // parallax
```

**Violations:**
```swift
// ❌ WRONG - Always animates (can cause nausea)
.onAppear {
  withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
    scale = 1.0
  }
}

// ❌ WRONG - Parallax scrolling without opt-out
ScrollView {
  GeometryReader { geo in
    Image("hero")
      .offset(y: geo.frame(in: .global).minY * 0.5) // Parallax
  }
}
```

**Fixes:**
```swift
// ✅ CORRECT - Respect Reduce Motion preference
.onAppear {
  if UIAccessibility.isReduceMotionEnabled {
    scale = 1.0 // Instant
  } else {
    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
      scale = 1.0
    }
  }
}

// ✅ CORRECT - Simpler animation or cross-fade
if UIAccessibility.isReduceMotionEnabled {
  // Cross-fade or instant change
  withAnimation(.linear(duration: 0.2)) {
    showView = true
  }
} else {
  // Complex spring animation
  withAnimation(.spring()) {
    showView = true
  }
}

// ✅ CORRECT - Automatic support via transaction
.animation(.spring(), value: isExpanded)
.transaction { transaction in
  if UIAccessibility.isReduceMotionEnabled {
    transaction.animation = nil // Disable animation
  }
}
```

**Report format:**
```
Reduce Motion Issues Found:
- [ ] {file}:{line} - withAnimation without isReduceMotionEnabled check
- [ ] {file}:{line} - Parallax effect without Reduce Motion opt-out
- [ ] {file}:{line} - Spring animation should use cross-fade when reduced
```

---

## Step 8: Audit Common Violations (HIGH - App Store Review)

### 8.1 Images without accessibility
```swift
// Pattern to find:
Grep: Image\(".*"\)(?!.*accessibility)
Grep: Image\(systemName:.*\)(?!.*accessibility)
```

**Violations:**
```swift
// ❌ WRONG - Informative image without label
Image("product-photo")
```

**Fixes:**
```swift
// ✅ CORRECT - Informative image with label
Image("product-photo")
  .accessibilityLabel("Red sneakers with white laces")

// ✅ CORRECT - Decorative image hidden
Image("background-pattern")
  .accessibilityHidden(true)
```

### 8.2 Custom buttons without traits
```swift
// Pattern to find:
Grep: Text\(.*\).*\.onTapGesture
```

**Violations:**
```swift
// ❌ WRONG - Custom button without button trait
Text("Submit")
  .onTapGesture {
    submit()
  }
// VoiceOver announces as "Submit, text" not "Submit, button"
```

**Fixes:**
```swift
// ✅ CORRECT - Use Button for button-like controls
Button("Submit") {
  submit()
}
// VoiceOver announces as "Submit, button"

// ✅ CORRECT - Custom control with correct trait
Text("Submit")
  .accessibilityAddTraits(.isButton)
  .onTapGesture {
    submit()
  }
```

### 8.3 Custom controls without accessibility actions
```swift
// Pattern to find custom sliders/pickers:
Grep: DragGesture\(\)
Grep: GeometryReader.*gesture
```

**Violations:**
```swift
// ❌ WRONG - Custom slider without accessibility support
struct CustomSlider: View {
  @Binding var value: Double

  var body: some View {
    GeometryReader { geo in
      // ...
    }
    .gesture(DragGesture()...)
  }
}
```

**Fixes:**
```swift
// ✅ CORRECT - Custom slider with accessibility actions
struct CustomSlider: View {
  @Binding var value: Double

  var body: some View {
    GeometryReader { geo in
      // ...
    }
    .gesture(DragGesture()...)
    .accessibilityElement()
    .accessibilityLabel("Volume")
    .accessibilityValue("\(Int(value))%")
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment:
        value = min(value + 10, 100)
      case .decrement:
        value = max(value - 10, 0)
      @unknown default:
        break
      }
    }
  }
}
```

### 8.4 State changes without announcements
```swift
// Pattern to find:
Grep: \.toggle\(\)
Grep: isOn.*=.*!
```

**Violations:**
```swift
// ❌ WRONG - State change without announcement
Button("Toggle") {
  isOn.toggle()
}
```

**Fixes:**
```swift
// ✅ CORRECT - State change with announcement
Button("Toggle") {
  isOn.toggle()
  UIAccessibility.post(
    notification: .announcement,
    argument: isOn ? "Enabled" : "Disabled"
  )
}

// ✅ CORRECT - Automatic state with accessibilityValue
Button("Toggle") {
  isOn.toggle()
}
.accessibilityValue(isOn ? "Enabled" : "Disabled")
```

**Report format:**
```
Common Violations Found:
- [ ] {file}:{line} - Image without accessibilityLabel or accessibilityHidden
- [ ] {file}:{line} - Text with onTapGesture missing .isButton trait
- [ ] {file}:{line} - Custom slider without accessibilityAdjustableAction
- [ ] {file}:{line} - State toggle without announcement
```

---

## Step 9: Run Accessibility Inspector Audit

### 9.1 Launch Accessibility Inspector
```bash
# Open Accessibility Inspector
open -a "Accessibility Inspector"
```

### 9.2 Automated audit steps
1. Select your running simulator or connected device in the dropdown
2. Select your app as the target
3. Click "Audit" tab
4. Click "Run Audit" button
5. Review findings for each category:
   - **Contrast** — Color contrast issues
   - **Hit Region** — Touch target size issues
   - **Clipped Text** — Text truncation with Dynamic Type
   - **Element Description** — Missing labels/hints
   - **Traits** — Wrong accessibility traits

### 9.3 Manual VoiceOver testing
Enable VoiceOver: `Cmd+F5` (simulator) or Settings → Accessibility → VoiceOver

**Navigation Testing:**
1. ☐ Swipe right/left - moves logically through UI elements
2. ☐ Each element announces purpose clearly
3. ☐ No unlabeled elements (except decorative)
4. ☐ Heading navigation works (swipe up/down with 2 fingers)
5. ☐ Container navigation works (swipe left/right with 3 fingers)

**Interaction Testing:**
1. ☐ Double-tap activates buttons
2. ☐ Swipe up/down adjusts sliders/pickers
3. ☐ Custom gestures have VoiceOver equivalents
4. ☐ Text fields announce keyboard type
5. ☐ State changes are announced

**Content Testing:**
1. ☐ Images have descriptive labels or are hidden
2. ☐ Error messages are announced
3. ☐ Loading states are announced
4. ☐ Modal sheets announce role
5. ☐ Alerts announce automatically

---

## Step 10: Generate Audit Report

Compile all findings into a summary report:

```markdown
# Accessibility Audit Report

**Target:** {target_path}
**Date:** {current_date}
**Auditor:** Claude Code

## Summary

| Category            | Issues | Severity |
| ------------------- | ------ | -------- |
| VoiceOver Labels    | X      | CRITICAL |
| Dynamic Type        | X      | HIGH     |
| Color Contrast      | X      | HIGH     |
| Touch Targets       | X      | MEDIUM   |
| Keyboard Navigation | X      | MEDIUM   |
| Reduce Motion       | X      | MEDIUM   |
| Common Violations   | X      | HIGH     |

## Critical Issues (Must Fix for App Store)

### VoiceOver
{list of VoiceOver issues}

### Dynamic Type
{list of Dynamic Type issues}

### Color Contrast
{list of color contrast issues}

## Medium Priority Issues

### Touch Targets
{list of touch target issues}

### Keyboard Navigation
{list of keyboard navigation issues}

### Reduce Motion
{list of reduce motion issues}

## Recommendations

1. {prioritized recommendation}
2. {prioritized recommendation}
3. {prioritized recommendation}

## WCAG Compliance Summary

- **Level A (Required):** {PASS/FAIL}
- **Level AA (Recommended):** {PASS/FAIL}
- **Level AAA (Enhanced):** {PASS/FAIL}
```

---

## Reference: WCAG Compliance Levels

### Level A (Minimum — Required for App Store)
- 1.1.1 Non-text Content — Images have text alternatives
- 2.1.1 Keyboard — All functionality via keyboard (iPadOS/macOS)
- 4.1.2 Name, Role, Value — Elements have accessible names

### Level AA (Standard — Recommended)
- 1.4.3 Contrast (Minimum) — 4.5:1 text, 3:1 UI
- 1.4.4 Resize Text — Support 200% text scaling
- 1.4.5 Images of Text — Use real text when possible

### Level AAA (Enhanced — Best Practice)
- 1.4.6 Contrast (Enhanced) — 7:1 text, 4.5:1 UI
- 2.3.3 Animation from Interactions — Reduce Motion support
- 2.5.5 Target Size — 44x44pt minimum targets

**Goal:** Meet Level AA for all content, Level AAA where feasible.

---

## Reference: App Store Review Preparation

### Required Accessibility Features (iOS)

1. **VoiceOver Support**
   - All UI elements must have labels
   - Navigation must be logical
   - All actions must be performable

2. **Dynamic Type**
   - Text must scale from -3 to +12 sizes
   - Layout must adapt without clipping

3. **Sufficient Contrast**
   - Minimum 4.5:1 for normal text
   - Minimum 3:1 for large text (≥18pt)

### App Store Connect Metadata

When submitting, select supported accessibility features:
- ☑ VoiceOver
- ☑ Dynamic Type
- ☑ Increased Contrast
- ☑ Reduce Motion (if supported)

### Common Rejection Reasons

1. **"App is not fully functional with VoiceOver"**
   - Missing labels on images/buttons
   - Unlabeled custom controls
   - Actions not performable with VoiceOver

2. **"Text is not readable at all Dynamic Type sizes"**
   - Fixed font sizes
   - Text clipping at large sizes
   - Layout breaks at accessibility sizes

3. **"Insufficient color contrast"**
   - Text fails 4.5:1 ratio
   - UI elements fail 3:1 ratio
   - Color-only indicators

---

## Reference: Design Review Pressure

### Red Flags — Designer Requests That Violate Accessibility

If you hear ANY of these, **STOP and cite App Store Guideline 2.5.1**:

- ❌ **"Skip VoiceOver labels on icon-only buttons"** – App Store rejection
- ❌ **"Use fixed 14pt font for compact design"** – Excludes users with vision disabilities
- ❌ **"3:1 contrast ratio is fine"** – Fails WCAG AA for text (needs 4.5:1)
- ❌ **"Make buttons 36x36pt for clean aesthetic"** – Fails touch target requirement (44x44pt)
- ❌ **"Disable Dynamic Type in this screen"** – App Store rejection risk
- ❌ **"Color-code without labels (red=error, green=success)"** – Excludes colorblind users (8% of men)

### How to Push Back

1. **Show the Guideline** — Apple App Store Review Guideline 2.5.1
2. **Demonstrate the Risk** — Enable VoiceOver, show largest text size, use contrast analyzer
3. **Offer Compromise** — Programmatic solutions that preserve visual design
4. **Document the Decision** — If overruled, document in writing for protection

### Quick Reference

- App Store Review Guideline 2.5.1
- WCAG 2.1 Level AA (industry standard)
- ADA compliance requirements (legal risk in US)

---

## Resources

### Apple Documentation
- [Accessibility — Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Supporting VoiceOver](https://developer.apple.com/documentation/accessibility/voiceover)
- [Supporting Dynamic Type](https://developer.apple.com/documentation/uikit/uifont/scaling_fonts_automatically)

### WCAG Guidelines
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [Understanding WCAG 2.1](https://www.w3.org/WAI/WCAG21/Understanding/)

### Testing Tools
- Accessibility Inspector (Xcode → Open Developer Tool)
- [Color Contrast Analyzer](https://www.tpgi.com/color-contrast-checker/)
- VoiceOver (built into iOS/macOS)
