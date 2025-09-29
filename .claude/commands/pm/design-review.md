---
allowed-tools: Read, Write, Bash(./scripts/test.sh:*), Bash(open:*)
description: Run E2E tests with screenshot capture, create design review document, and guide through UI/UX implementation phases
argument-hint: [test-class] or [test-class/test-method]
---

# Design Review Process

Systematic UI/UX review process using E2E test screenshots to gather feedback and implement improvements.

**ULTRATHINK** and use TodoWrite to keep track of your tasks.

## Quick Check

Verify test exists:
```bash
# Check if test file exists
test_file="JabTrackerUITests/**/${ARGUMENTS%/*}*.swift"
if ! ls $test_file 2>/dev/null; then
  echo "❌ Test file not found: $ARGUMENTS"
  exit 1
fi
```

## Instructions

The design review process has 6 phases. Ask the user which phase to start from:

```
At which phase would you like to start? (1-6)
1. Enhance E2E Tests with Screenshot Capture
2. Evaluation & Design Decisions (Create Review Document)
3. UI/UX Implementation
4. State & Performance Optimization
5. Test Updates & Validation
6. Final Integration & Commit

Current context: Design review for $ARGUMENTS
```

Based on the user's response, proceed to that phase and continue through remaining phases.

---

## Phase 1: Enhance E2E Tests with Screenshot Capture

### 1.1 Add Screenshot Utility to Tests

If the test doesn't already have screenshot capture, enhance it:

```swift
import XCTest

class YourUITests: XCTestCase {
    var screenshotCapture: ScreenshotCapture!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        screenshotCapture = ScreenshotCapture(
            app: app,
            testCase: self,
            phase: "baseline"
        )
    }

    func testYourFeature() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // 📸 PHASE 1: Baseline screenshot
        screenshotCapture.capture(
            section: "feature-name",
            description: "before-interaction",
            metadata: ["state": "ready"]
        )

        // ... test logic ...

        // 📸 PHASE 1: After interaction
        screenshotCapture.capture(
            section: "feature-name",
            description: "after-interaction",
            metadata: ["state": "completed"]
        )
    }
}
```

### 1.2 Run Enhanced Tests

```bash
# Run the specified test with screenshot capture
./scripts/test.sh ui 1 $ARGUMENTS

# Wait for completion
echo "✅ Test completed. Screenshots captured to result bundle."
```

### 1.3 Open Results in Xcode

```bash
# Find the latest test results
latest_result=$(ls -t logs/ui_tests_*/results.xcresult | head -1)

# Open in Xcode Test Results Browser
open "$latest_result"

echo "📱 Xcode Test Results Browser opened"
echo "📸 Review screenshots in the Activities timeline"
echo ""
echo "Next: Extract screenshots for design review document"
```

### 1.4 Extract Screenshots

```bash
# Run the test with screenshots
./scripts/test.sh ui 1 $ARGUMENTS

# Open results in Xcode Test Results Browser
latest_result=$(ls -t logs/ui_tests_*/results.xcresult | head -1)
open "$latest_result"

echo "📸 Xcode Test Results Browser opened"
```

Guide user to extract screenshots:
```
📸 Extracting Screenshots for Design Review

In Xcode Test Results Browser (now open):
1. Navigate to your test method in the left panel
2. Click through the Activities timeline
3. Find screenshots with descriptive names
4. Right-click each screenshot → "Save Attachment..."
5. Save to: .claude/epics/[epic-name]/updates/[issue-number]/design-review/
   (e.g., .claude/epics/analytics/updates/59/design-review/)

Screenshot naming convention:
- Use descriptive filenames (e.g., "adherence-above-fold.png")
- Or keep UUID names and document mapping

Once screenshots are saved, proceed to Phase 2.
```

---

## Phase 2: Evaluation & Design Decisions

### 2.1 Create Design Review Document

Ask user for review directory location:
```
Where should I create the design review document?

Suggested: .claude/epics/[epic-name]/updates/[issue-number]/design-review/design-review.md
(e.g., .claude/epics/analytics/updates/59/design-review/design-review.md)

This keeps design reviews with their related issue work in the PM system.
If working outside the PM system, specify an alternative path.

Use suggested path? (y/n or provide alternative path): ___________
```

### 2.2 Generate Review Document Template

Create comprehensive design review document:

```markdown
# [Feature Name] UI/UX Design Review

**Test Class**: $ARGUMENTS
**Phase**: 2 - Evaluation & Design Decisions
**Date**: [current-date]
**Status**: Ready for Review

## Purpose

This document captures baseline UI/UX analysis and gathers feedback for [feature] improvements. Screenshots were captured via E2E test enhancements in Phase 1.

## Screenshots Reference

### Screenshot Files
- `[filename-1].png` - [Description]
- `[filename-2].png` - [Description]
- `[filename-3].png` - [Description]

---

## Section 1: [View/Component Name]

**Screenshot**: `[filename].png`

![Description]([filename].png)

### Current State
- **Layout**: [Describe current layout]
- **Components**: [List visible components]
- **Interactions**: [Describe interactive elements]

### Design Questions
1. **Visual Hierarchy**: [Question about importance/prominence]
2. **Information Density**: [Question about content amount]
3. **Accessibility**: [Question about accessibility features]
4. **Consistency**: [Question about design system alignment]

### Feedback Needed
- [ ] Rate visual appeal (1-5): ___
- [ ] Rate information clarity (1-5): ___
- [ ] Suggested improvements:
  ```
  [Space for detailed feedback]
  ```

---

## Section 2: [Additional Sections...]

[Repeat structure for each screenshot/view]

---

## Cross-Cutting Concerns

### Accessibility
- **VoiceOver Support**: [Status]
- **Color Independence**: [Status]
- **Touch Targets**: [Status]
- **Dynamic Type**: [Status]

### Performance
- **Load Time**: [Measured or estimated]
- **Interaction Response**: [Measured or estimated]
- **Animation Smoothness**: [Observed quality]

### Consistency
- **Design System Alignment**: [Evaluation]
- **Platform Guidelines**: [iOS HIG compliance]

---

## Priority Issues & Opportunities

### High Priority
- [ ] **Issue**: [Description]
  - **Impact**: [User impact description]
  - **Suggested Fix**: [Proposed solution]

### Medium Priority
- [ ] **Opportunity**: [Description]
  - **Value**: [User value description]
  - **Implementation**: [Approach]

### Low Priority / Future Enhancements
- [ ] **Enhancement**: [Description]

---

## Recommendations Summary

### Must Have (Phase 3)
1. [Critical improvement 1]
2. [Critical improvement 2]
3. [Critical improvement 3]

### Should Have (Phase 3)
1. [Important improvement 1]
2. [Important improvement 2]

### Nice to Have (Future)
1. [Optional enhancement 1]
2. [Optional enhancement 2]

---

## Next Steps

### Phase 3: UI/UX Implementation
Based on this review, implement agreed-upon improvements:
1. [ ] Address high-priority issues
2. [ ] Implement must-have recommendations
3. [ ] Update E2E tests for new/changed UI
4. [ ] Verify accessibility compliance

### Phase 4: State & Performance Optimization
1. [ ] Profile performance with changes
2. [ ] Optimize data loading and caching
3. [ ] Improve perceived performance
4. [ ] Validate against baselines

---

## Review History

| Date   | Reviewer | Key Feedback | Status   |
| ------ | -------- | ------------ | -------- |
| [date] | [name]   | [Summary]    | [Status] |

```

### 2.3 Request Feedback

Provide feedback request template:

```
📋 Design Review Ready

I've created a design review document at:
docs/design/reviews/[feature-name]/design-review.md

The document includes:
✅ Screenshots with inline preview
✅ Design questions for each view
✅ Feedback forms with rating scales
✅ Priority assessment framework
✅ Recommendations summary

Next steps:
1. Review the screenshots and design questions
2. Provide feedback directly in the document
3. Rate visual appeal and clarity (1-5 scale)
4. Note any improvements in the "Suggested improvements" sections
5. Resume with Phase 3: /pm:design-review $ARGUMENTS
```

---

## Phase 3: UI/UX Implementation

### 3.1 Review Feedback

Read the design review document and extract actionable items:

```bash
# Parse the design review document for priorities
grep -A 3 "### High Priority" docs/design/reviews/[feature-name]/design-review.md
grep -A 3 "### Must Have" docs/design/reviews/[feature-name]/design-review.md
```

### 3.2 Create Implementation Plan

Based on feedback, create structured implementation tasks:

```
📋 Phase 3 Implementation Plan

Based on design review feedback, here are the improvements to implement:

**High Priority Issues:**
1. [Issue 1]: [Description]
   - Files: [Affected files]
   - Approach: [Implementation approach]

2. [Issue 2]: [Description]
   - Files: [Affected files]
   - Approach: [Implementation approach]

**Must Have Improvements:**
1. [Improvement 1]: [Description]
2. [Improvement 2]: [Description]
3. [Improvement 3]: [Description]

Shall I proceed with implementing these changes?
```

### 3.3 Implement Changes

For each improvement:
1. Update the relevant SwiftUI components
2. Build and verify compilation
3. Run unit tests for affected components
4. Run E2E test to capture new screenshots
5. Compare before/after in Xcode Test Results

### 3.4 Iterative Review

After each significant change:
```bash
# Run E2E test again
./scripts/test.sh ui 1 $ARGUMENTS

# Open results
latest_result=$(ls -t logs/ui_tests_*/results.xcresult | head -1)
open "$latest_result"

echo "📸 Review updated screenshots"
echo "Compare with previous version"
echo ""
echo "Does this look good? (y/n)"
```

---

## Phase 4: State & Performance Optimization

### 4.1 Profile Performance

```bash
# Run tests with timing measurements
./scripts/test.sh ui 1 $ARGUMENTS

# Extract performance metrics from test metadata
echo "📊 Performance Metrics:"
echo "- Navigation time: [from screenshot metadata]"
echo "- Interaction time: [from screenshot metadata]"
echo "- Render time: [from screenshot metadata]"
```

### 4.2 Optimize State Management

Review and optimize:
- @State property usage
- Computed property efficiency
- View update frequency
- Unnecessary re-renders

### 4.3 Improve Perceived Performance

Implement:
- Loading states
- Skeleton screens
- Optimistic updates
- Smooth transitions

---

## Phase 5: Test Updates & Validation

### 5.1 Update E2E Tests

Ensure tests validate new UI:
```swift
// Verify new accessibility identifiers
XCTAssertTrue(app.buttons["new-element-id"].exists)

// Verify new interactions work
app.buttons["new-element-id"].tap()
XCTAssertTrue(app.staticTexts["expected-result"].exists)

// Capture final screenshots
screenshotCapture.capture(
    section: "feature-updated",
    description: "after-improvements",
    metadata: ["phase": "5", "improvements": "completed"]
)
```

### 5.2 Run Full Test Suite

```bash
# Run all related tests
./scripts/test.sh ui 1 [TestClass]

# Verify all pass
echo "✅ All tests passed"
```

### 5.3 Verify Accessibility

Use Xcode Accessibility Inspector:
```
1. Run app on simulator
2. Open Xcode → Developer Tools → Accessibility Inspector
3. Verify:
   - Touch target sizes (44×44pt minimum)
   - VoiceOver labels are descriptive
   - Contrast ratios meet WCAG standards
   - Dynamic Type scaling works
```

---

## Phase 6: Final Integration & Commit

### 6.1 Run Pre-Commit Checks

```bash
# Run full check suite
./scripts/check-all.sh --skip-ui

# Ensure coverage is maintained
./scripts/check-coverage.sh
```

### 6.2 Commit Changes

```bash
# Stage all changes
git add [modified-files]

# Commit with detailed message
git commit -m "$(cat <<'EOF'
Issue #[number]: [Feature] - Design review improvements

Implemented design review feedback for [feature]:

1. [Component 1] - [Changes]
   - [Specific change 1]
   - [Specific change 2]

2. [Component 2] - [Changes]
   - [Specific change 1]
   - [Specific change 2]

Design review feedback addressed:
- ✅ High priority issue 1
- ✅ High priority issue 2
- ✅ Must-have improvement 1
- ✅ Must-have improvement 2

All changes improve [aspect], reduce [problem], and create
better [benefit] with [design system] patterns.
EOF
)"
```

### 6.3 Final Summary

```
✅ Design Review Process Complete

Phases Completed:
- ✅ Phase 1: E2E tests enhanced with screenshots
- ✅ Phase 2: Design review document created and feedback gathered
- ✅ Phase 3: UI/UX improvements implemented
- ✅ Phase 4: State and performance optimized
- ✅ Phase 5: Tests updated and validated
- ✅ Phase 6: Changes committed

Summary:
- [Number] screenshots captured
- [Number] improvements implemented
- [Number] tests updated
- [Number] commits created

Next steps:
- Continue with remaining design review sections (if any)
- Or proceed to PR creation and merge
```

---

## Tips for Effective Design Reviews

### Screenshot Best Practices
1. **Capture multiple states**: before, during, after interactions
2. **Include metadata**: timing, conditions, test context
3. **Use descriptive names**: section-description-state format
4. **Capture scrolled views**: both above and below fold content

### Feedback Collection
1. **Use rating scales**: 1-5 for quick quantitative feedback
2. **Ask specific questions**: avoid generic "what do you think?"
3. **Focus on user impact**: how does this affect user experience?
4. **Prioritize ruthlessly**: not everything needs fixing immediately

### Implementation Strategy
1. **One section at a time**: don't try to fix everything at once
2. **Test after each change**: verify improvements don't break existing functionality
3. **Iterate based on feedback**: run E2E tests to verify improvements
4. **Document decisions**: capture why certain suggestions weren't implemented

### Performance Considerations
1. **Measure before optimizing**: use test metadata for baseline measurements
2. **Focus on perceived performance**: loading states matter more than raw speed
3. **Don't sacrifice clarity**: clear UI > slightly faster unclear UI
4. **Profile on real devices**: simulators can be misleading

---

## Common Issues & Solutions

### Issue: Screenshots not appearing in Xcode
**Solution**: Ensure `XCTAttachment` is properly created with screenshot data

### Issue: Test timing out during screenshot capture
**Solution**: Increase test timeout or reduce screenshot frequency

### Issue: Screenshots showing wrong state
**Solution**: Add explicit waits before capture: `sleep(0.5)`

### Issue: Design feedback is too vague
**Solution**: Ask specific questions in review document, provide context

### Issue: Too many improvements suggested
**Solution**: Use priority framework, defer nice-to-haves to backlog

---

## Related Commands

- `/testing:run` - Run tests with specific targets
- `/pm:issue-start` - Start implementing improvements as new issue
- `/pm:issue-merge` - Merge improvements after review
- `/context:update` - Update context with design decisions