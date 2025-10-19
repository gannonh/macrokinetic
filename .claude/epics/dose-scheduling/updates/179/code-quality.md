# Code Quality Analysis: PR #261 (Issue #179)

**PR**: Issue #179: Medication Profile CRUD
**Branch**: issue/179-medication-profile-crud
**Analyzed**: 2025-10-19
**Files Changed**: 39 files (+5,629 lines, -216 lines)

---

## Executive Summary

**Overall Assessment**: ⚠️ **Needs Cleanup Before Merge**

This PR introduces comprehensive medication schedule management functionality with good architectural patterns and test coverage. However, **critical code hygiene issues** must be addressed before merging:

### Critical Issues (🔴 High Priority)
1. **Temporary/backup files committed** - 4 files that should never be in version control
2. **TODOs in production code** - Unfinished implementation placeholder
3. **Direct ModelContext manipulation** - Bypasses service layer in edge case

### Medium Priority Issues (🟡)
4. **Code duplication** - Repetitive schedule creation patterns across tests
5. **Magic numbers** - Hard-coded time values without constants
6. **Error handling gaps** - Silent failures in some edge cases
7. **Missing input validation** - User input not validated in some flows

### Strengths (✅)
- Excellent test coverage (18 unit + 8 E2E tests)
- Clean separation of concerns (ViewModel, Services, Views)
- Good accessibility support
- Proper use of @Observable pattern
- Well-documented code with clear comments

---

## 🔴 CRITICAL: Files That Must Not Be Committed

### 1. Backup Files (4 files - 68KB of unnecessary content)

**Issue**: Four temporary/backup files are committed to the repository:

```
JabTracker/Views/Settings/MedicationProfileSettingsView.swift.bak   (31KB)
JabTracker/Views/Settings/MedicationProfileSettingsView.swift.bak2  (31KB)
JabTracker/Views/Settings/MedicationProfileScheduleSection.swift.bak3 (6KB)
JabTracker/Views/Settings/Medication ProfileDetailView_Patch.txt
```

**Impact**:
- Pollutes repository history with redundant code
- Increases PR size unnecessarily (68KB of backup files)
- Violates project code hygiene standards
- Confuses future developers about which files are authoritative

**Recommendation**:
```bash
# Remove these files immediately
git rm "JabTracker/Views/Settings/MedicationProfileSettingsView.swift.bak"
git rm "JabTracker/Views/Settings/MedicationProfileSettingsView.swift.bak2"
git rm "JabTracker/Views/Settings/MedicationProfileScheduleSection.swift.bak3"
git rm "JabTracker/Views/Settings/Medication ProfileDetailView_Patch.txt"
git commit -m "chore: Remove backup files and patches from repository"
```

**Prevention**: Add to `.gitignore`:
```
*.bak
*.bak[0-9]
*_Patch.txt
```

---

## 🔴 CRITICAL: Incomplete Implementation (TODO in Production Code)

### Location: `DoseScheduleEditView.swift:74`

```swift
// TODO: Parse existing schedule baseSchedule Data to populate fields if editing
```

**Issue**: Editing an existing schedule doesn't pre-populate the form with current values.

**Impact**:
- **User Experience Bug**: Users see default values instead of current schedule when editing
- **Data Loss Risk**: Users might not notice and accidentally change schedule settings
- **Medical Safety**: Incorrect schedule modifications could affect medication adherence

**Current Behavior**:
```swift
init(medicationProfile: MedicationProfile, existingSchedule: DoseSchedule?, onSave: ...) {
    // Always uses defaults, ignoring existingSchedule data
    _selectedPattern = State(initialValue: existingSchedule?.patternType ?? .weekly)
    _dayOfWeek = State(initialValue: 1)  // ❌ Always Monday
    _timeOfDay = State(initialValue: TimeComponents(hour: 8, minute: 0))  // ❌ Always 8 AM
    _interval = State(initialValue: 7)  // ❌ Always weekly
    _windowMinutesBefore = State(initialValue: 120)  // ❌ Always 2 hours
    _windowMinutesAfter = State(initialValue: 120)  // ❌ Always 2 hours
}
```

**Expected Behavior**:
```swift
init(medicationProfile: MedicationProfile, existingSchedule: DoseSchedule?, onSave: ...) {
    self.medicationProfile = medicationProfile
    self.existingSchedule = existingSchedule
    self.onSave = onSave

    _selectedPattern = State(initialValue: existingSchedule?.patternType ?? .weekly)

    // Parse existing baseSchedule configuration
    if let schedule = existingSchedule,
       let data = schedule.baseSchedule,
       let config = try? JSONDecoder().decode(ScheduleConfiguration.self, from: data) {
        _dayOfWeek = State(initialValue: config.dayOfWeek ?? 1)
        _timeOfDay = State(initialValue: config.timeOfDay ?? TimeComponents(hour: 8, minute: 0))
        _interval = State(initialValue: config.interval ?? 7)
        _windowMinutesBefore = State(initialValue: config.adherenceWindowMinutesBefore ?? 120)
        _windowMinutesAfter = State(initialValue: config.adherenceWindowMinutesAfter ?? 120)
    } else {
        // Defaults for new schedule
        _dayOfWeek = State(initialValue: 1)
        _timeOfDay = State(initialValue: TimeComponents(hour: 8, minute: 0))
        _interval = State(initialValue: 7)
        _windowMinutesBefore = State(initialValue: 120)
        _windowMinutesAfter = State(initialValue: 120)
    }
}
```

**Test Gap**: `testEditExistingSchedule` E2E test doesn't validate form pre-population.

**Recommendation**:
1. Implement the TODO before merging
2. Add unit test validating form initialization with existing schedule
3. Add E2E test assertion verifying pre-populated values

---

## 🔴 CRITICAL: Service Layer Bypass

### Location: `MedicationProfileViewModel.swift:198-203`

```swift
func pauseSchedule(until date: Date?) async {
    // ...
    if let until = date {
        try scheduleService.pauseSchedule(schedule, until: until)  // ✅ Uses service
    } else {
        // ❌ Bypasses service layer - direct ModelContext manipulation
        schedule.pausedAt = Date()
        schedule.pausedUntil = nil
        schedule.updatedAt = Date()
        try context.save()
    }
}
```

**Issue**: Indefinite pause bypasses ScheduleService, directly manipulating SwiftData.

**Impact**:
- **Architectural Inconsistency**: Violates single responsibility principle
- **Business Logic Leakage**: Pause logic split between ViewModel and Service
- **Maintainability**: Future pause logic changes must update two locations
- **Testing Complexity**: Can't mock ScheduleService for indefinite pause testing
- **Notification Updates**: May miss NotificationService queue updates

**Root Cause**: `ScheduleService.pauseSchedule()` might require `until` parameter, but ViewModel supports indefinite pause.

**Recommendation**:

**Option A** (Preferred): Update ScheduleService to accept `nil` for indefinite pause:
```swift
// ScheduleService.swift
func pauseSchedule(_ schedule: DoseSchedule, until: Date?) throws {
    schedule.pausedAt = Date()
    schedule.pausedUntil = until  // nil = indefinite
    schedule.updatedAt = Date()
    try modelContext.save()

    // Update notification queue
    notificationService.updateNotificationQueue(for: schedule)
}

// MedicationProfileViewModel.swift
func pauseSchedule(until date: Date?) async {
    guard let schedule = activeSchedule else { return }
    do {
        try scheduleService.pauseSchedule(schedule, until: date)  // ✅ Always uses service
        await loadActiveSchedule()
        await loadScheduleHistory()
    } catch {
        // Error handling
    }
}
```

**Option B**: Add separate service method:
```swift
// ScheduleService.swift
func pauseScheduleIndefinitely(_ schedule: DoseSchedule) throws {
    schedule.pausedAt = Date()
    schedule.pausedUntil = nil
    schedule.updatedAt = Date()
    try modelContext.save()
}
```

---

## 🟡 MEDIUM PRIORITY: Code Duplication

### 1. Test Setup Duplication (8 occurrences)

**Location**: `MedicationProfileScheduleUITests.swift` - Tests 2-8

**Pattern repeated 7 times**:
```swift
// Create a schedule first
let createScheduleButton = app.buttons["create-schedule-button"]
if createScheduleButton.waitForExistence(timeout: 3) {
    createScheduleButton.tap()

    let saveButton = app.buttons["save-schedule-edit"]
    XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")
    saveButton.tap()

    XCTAssertFalse(
        saveButton.waitForExistence(timeout: 3),
        "Sheet should dismiss after save")
}
```

**Impact**:
- **Maintainability**: Changes to schedule creation require updating 7 test methods
- **Test Fragility**: Inconsistent timeouts and assertions across tests
- **Code Volume**: ~70 lines of duplicated code

**Recommendation**: Extract to helper method:
```swift
// Add to MedicationProfileScheduleUITests
private func createDefaultSchedule() throws {
    let createScheduleButton = app.buttons["create-schedule-button"]
    guard createScheduleButton.waitForExistence(timeout: 3) else {
        XCTFail("Schedule already exists or view not ready")
        return
    }

    createScheduleButton.tap()

    let saveButton = app.buttons["save-schedule-edit"]
    XCTAssertTrue(
        saveButton.waitForExistence(timeout: 3),
        "Save button should exist in schedule edit sheet")
    saveButton.tap()

    // Verify sheet dismissed
    XCTAssertFalse(
        saveButton.waitForExistence(timeout: 3),
        "Sheet should dismiss after successful save")
}

// Usage in tests
func testPauseScheduleOneWeek() throws {
    try navigateToMedicationProfileSettings()
    try createDefaultSchedule()  // ✅ Single line

    let pauseScheduleButton = app.buttons["pause-schedule-button"]
    // ... rest of test
}
```

**Benefits**:
- Reduces code from ~70 to ~10 lines across tests
- Single source of truth for schedule creation
- Easier to update if UI changes
- More consistent error messages

---

### 2. Schedule Description Logic Duplication

**Locations**:
- `MedicationProfileViewModel.swift:277-292`
- `ScheduleHistoryRow.swift` (similar pattern)

**Pattern**:
```swift
// MedicationProfileViewModel.swift
private func descriptionForSchedule(_ schedule: DoseSchedule) -> String {
    let patternName = schedule.patternType == .weekly ? "Weekly"
                    : schedule.patternType == .splitDose ? "Split Dose"
                    : "Custom"

    if !schedule.isActive {
        return "\(patternName) schedule deactivated"
    } else if schedule.pausedAt != nil {
        if let until = schedule.pausedUntil {
            return "\(patternName) schedule paused until \(until.formatted(...))"
        } else {
            return "\(patternName) schedule paused indefinitely"
        }
    } else {
        return "\(patternName) schedule created"
    }
}
```

**Issue**: Schedule description generation logic could be centralized.

**Recommendation**: Add computed property or extension:
```swift
// DoseSchedule+Extensions.swift
extension DoseSchedule {
    var statusDescription: String {
        let patternName = patternType.displayName  // Use existing displayName

        if !isActive {
            return "\(patternName) schedule deactivated"
        } else if let pausedAt = pausedAt {
            if let until = pausedUntil {
                return "\(patternName) schedule paused until \(until.formatted(date: .abbreviated, time: .omitted))"
            } else {
                return "\(patternName) schedule paused indefinitely"
            }
        } else {
            return "\(patternName) schedule active"
        }
    }
}

// Usage
let description = schedule.statusDescription  // ✅ Consistent everywhere
```

---

## 🟡 MEDIUM PRIORITY: Magic Numbers

### Time Constants Without Named Values

**Locations** (14 occurrences):
- `ScheduleSummaryView.swift:196-204` - Time formatting logic
- `PauseScheduleSheet.swift:44-50` - Duration calculations
- `DoseScheduleEditView.swift:71-72` - Default window values
- Test files - Various timeout values

**Examples**:
```swift
// ScheduleSummaryView.swift:196
if interval < 3600 {  // ❌ What is 3600?
    return "Less than 1 hour"
} else if interval < 86400 {  // ❌ What is 86400?
    let hours = Int(interval / 3600)
    return "\(hours) hour\(hours == 1 ? "" : "s")"
}

// DoseScheduleEditView.swift:71
_windowMinutesBefore = State(initialValue: 120)  // ❌ Why 120?
_windowMinutesAfter = State(initialValue: 120)
```

**Impact**:
- **Readability**: Hard to understand intent
- **Maintainability**: Easy to introduce bugs during modification
- **Consistency**: Same values might be defined differently elsewhere

**Recommendation**: Create constants file or use existing `TimeConstants.swift`:

```swift
// TimeConstants.swift (project already has this from Issue #175)
extension TimeConstants {
    // Add these constants
    static let secondsPerHour: TimeInterval = 3600
    static let secondsPerDay: TimeInterval = 86400
    static let defaultAdherenceWindowMinutes: Int = 120  // 2 hours
}

// Usage in ScheduleSummaryView.swift
if interval < TimeConstants.secondsPerHour {
    return "Less than 1 hour"
} else if interval < TimeConstants.secondsPerDay {
    let hours = Int(interval / TimeConstants.secondsPerHour)
    return "\(hours) hour\(hours == 1 ? "" : "s")"
}

// Usage in DoseScheduleEditView.swift
_windowMinutesBefore = State(initialValue: TimeConstants.defaultAdherenceWindowMinutes)
_windowMinutesAfter = State(initialValue: TimeConstants.defaultAdherenceWindowMinutes)
```

---

## 🟡 MEDIUM PRIORITY: Error Handling Gaps

### 1. Silent Query Failures

**Location**: `MedicationProfileViewModel.swift:84-92`

```swift
func loadActiveSchedule() async {
    do {
        let schedules = try context.fetch(descriptor)
        activeSchedule = schedules.first
        logger.info("Loaded active schedule: \(String(describing: self.activeSchedule?.id))")
    } catch {
        logger.error("Failed to load active schedule: \(error.localizedDescription)")
        activeSchedule = nil  // ❌ Silent failure - no user feedback
    }
}
```

**Issue**: Query failures are logged but not communicated to user.

**Impact**:
- User sees empty state but doesn't know why
- No retry mechanism
- Hard to debug in production

**Recommendation**:
```swift
func loadActiveSchedule() async {
    do {
        let schedules = try context.fetch(descriptor)
        activeSchedule = schedules.first
        logger.info("Loaded active schedule: \(String(describing: self.activeSchedule?.id))")
    } catch {
        logger.error("Failed to load active schedule: \(error.localizedDescription)")
        activeSchedule = nil

        // ✅ Inform user
        errorMessage = "Unable to load schedule. Please try again."
        showError = true
    }
}
```

### 2. Missing Input Validation

**Location**: `DoseScheduleEditView.swift:258-283` (saveSchedule method)

**Missing validations**:
- No check for valid dayOfWeek range (1-7)
- No check for valid hour/minute range
- No check for reasonable interval values
- No check for window values (before/after should be positive)

**Example issue**:
```swift
func saveSchedule() {
    isSaving = true

    // ❌ No validation before creating config
    let config = ScheduleConfiguration(
        dayOfWeek: dayOfWeek,  // Could be invalid
        timeOfDay: timeOfDay,
        interval: interval,
        adherenceWindowMinutesBefore: windowMinutesBefore,  // Could be negative
        adherenceWindowMinutesAfter: windowMinutesAfter
    )
    // ...
}
```

**Recommendation**:
```swift
private func validateInputs() -> String? {
    if dayOfWeek < 1 || dayOfWeek > 7 {
        return "Please select a valid day of the week"
    }

    if timeOfDay.hour < 0 || timeOfDay.hour > 23 {
        return "Please select a valid hour (0-23)"
    }

    if interval < 1 {
        return "Interval must be at least 1 day"
    }

    if windowMinutesBefore < 0 || windowMinutesAfter < 0 {
        return "Adherence window must be positive"
    }

    return nil  // All valid
}

func saveSchedule() {
    isSaving = true

    // ✅ Validate first
    if let error = validateInputs() {
        errorMessage = error
        showError = true
        isSaving = false
        return
    }

    let config = ScheduleConfiguration(...)
    // ...
}
```

---

## 🟡 MEDIUM PRIORITY: Missing Edge Case Handling

### 1. Schedule History Pagination

**Location**: `MedicationProfileViewModel.swift:96-136`

**Issue**: No limit on history items returned.

```swift
func loadScheduleHistory() async {
    let descriptor = FetchDescriptor<DoseSchedule>(
        predicate: #Predicate<DoseSchedule> { schedule in
            schedule.medicationProfile?.id == profileId
        },
        sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
    )
    // ❌ Could return hundreds of schedules for long-term users
}
```

**Impact**:
- Memory issues for users with many schedule modifications
- Slow UI rendering with large lists
- Poor UX for history timeline

**Recommendation**:
```swift
func loadScheduleHistory() async {
    let descriptor = FetchDescriptor<DoseSchedule>(
        predicate: #Predicate<DoseSchedule> { schedule in
            schedule.medicationProfile?.id == profileId
        },
        sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
    )
    descriptor.fetchLimit = 50  // ✅ Limit to recent 50 entries

    // ... rest of method
}
```

### 2. Concurrent Schedule Loading

**Location**: `MedicationProfileViewModel.swift:146-180`

**Potential race condition**:
```swift
func updateSchedule(_ config: ScheduleConfiguration, pattern: SchedulePatternType) async {
    do {
        if activeSchedule == nil {
            activeSchedule = try scheduleService.createSchedule(...)
        } else if let schedule = activeSchedule {
            try scheduleService.updateSchedule(...)
        }

        // ❌ activeSchedule could be modified by another call before these complete
        await loadActiveSchedule()
        await loadScheduleHistory()
    }
}
```

**Recommendation**: Add mutual exclusion or operation queueing for safety.

---

## 🟢 STRENGTHS: What This PR Does Well

### 1. Excellent Test Coverage ✅

**Unit Tests**: 18 tests across 5 files
- `ScheduleHistoryRowTests.swift`: 6 tests ✅
- `PauseScheduleSheetTests.swift`: 8 tests ✅
- `ScheduleSummaryViewTests.swift`: 4 tests ✅
- `MedicationProfileViewModelScheduleTests.swift`: 9 tests ✅
- `DoseScheduleEditViewTests.swift`: 4 tests ✅

**E2E Tests**: 8 comprehensive tests
- Schedule creation flow ✅
- Edit existing schedule ✅
- Pause/resume functionality ✅
- Deactivation with confirmation ✅
- Cancel operations ✅
- History timeline ✅
- Accessibility ✅

**Test Quality**:
- All sleep() calls removed (anti-pattern eliminated)
- Proper wait conditions with `waitForExistence(timeout:)`
- TestDataSeeding for performance (2-3x faster)
- Negative assertions for sheet dismissal
- Clear test naming and structure

### 2. Clean Architecture ✅

**Separation of Concerns**:
- `MedicationProfileViewModel`: Coordinates UI ↔ Service
- `ScheduleService`: Business logic and persistence
- View Components: Pure UI presentation
- No direct SwiftData access in views (except one edge case noted above)

**MVVM Pattern**:
- ViewModel uses `@Observable` (iOS 17+ pattern)
- Clear data flow: View → ViewModel → Service → SwiftData
- Proper state management with published properties

### 3. Accessibility Excellence ✅

**All interactive elements have identifiers**:
```swift
.accessibilityIdentifier("create-schedule-button")
.accessibilityIdentifier("pause-duration-picker")
.accessibilityIdentifier("pause-confirm-button")
```

**Semantic labels and hints**:
```swift
.accessibilityLabel("Next dose in \(formatTimeUntil(nextDose))")
.accessibilityHint("Tap to view dose titration plan")
```

**VoiceOver tested** in E2E suite (Test #8).

### 4. Documentation Quality ✅

**All major types documented**:
```swift
/// ViewModel for managing medication profile schedule operations
///
/// Coordinates between the UI layer and ScheduleService for schedule
/// CRUD operations, pause/resume functionality, and schedule history tracking.
@Observable
final class MedicationProfileViewModel {
```

**Method documentation**:
```swift
/// Pause the active schedule
///
/// - Parameter until: Optional date to automatically resume (nil = indefinite)
@MainActor
func pauseSchedule(until date: Date?) async {
```

### 5. Proper Logging ✅

**OSLog usage throughout**:
```swift
private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "MedicationProfileViewModel")

logger.debug("Loading active schedule for profile: \(self.medicationProfile.id)")
logger.info("Loaded active schedule: \(String(describing: self.activeSchedule?.id))")
logger.error("Failed to load active schedule: \(error.localizedDescription)")
```

**Appropriate log levels**: debug, info, warning, error used correctly.

---

## Performance Considerations

### E2E Test Performance Improvements ✅

**Before refactoring**:
- 228 seconds for 8 tests (18 sleep() calls + manual navigation)

**After refactoring**:
- ~80-120 seconds expected (2-3x faster)
- Proper wait conditions
- TestDataSeeding eliminates navigation overhead

**Code reduction**: 493 → 437 lines (11% smaller)

### Potential Performance Issues ⚠️

1. **History Loading**: No pagination (could be slow with 100+ schedules)
2. **Concurrent Queries**: Multiple async operations without coordination
3. **UI Updates**: `loadActiveSchedule()` + `loadScheduleHistory()` called after every modification

**Recommendation**: Consider batching UI updates or implementing local caching.

---

## Security Considerations

### No Critical Security Issues Found ✅

- No hardcoded credentials
- No sensitive data in logs
- Proper use of ModelContext (SwiftData's security model)
- No user input sanitization issues (though validation needed)

### Minor Concerns ⚠️

1. **Input Validation**: Missing range checks (noted above)
2. **Error Messages**: Could expose internal state in some cases

---

## Recommendations Summary

### Before Merge (MUST FIX)

1. **🔴 Remove backup files** (4 files)
   ```bash
   git rm "JabTracker/Views/Settings/*.bak*"
   git rm "JabTracker/Views/Settings/*_Patch.txt"
   ```

2. **🔴 Complete TODO** in `DoseScheduleEditView.swift:74`
   - Implement form pre-population for schedule editing
   - Add test validating pre-populated values

3. **🔴 Fix service layer bypass** in `MedicationProfileViewModel.swift:198-203`
   - Update `ScheduleService.pauseSchedule()` to accept `nil` for indefinite pause
   - Remove direct ModelContext manipulation from ViewModel

### High Priority (SHOULD FIX)

4. **Extract test helper** for schedule creation (reduces 70 lines duplication)
5. **Add input validation** in `DoseScheduleEditView.saveSchedule()`
6. **Add history pagination** (limit to 50 most recent entries)
7. **Use `TimeConstants`** for magic numbers

### Medium Priority (NICE TO HAVE)

8. Centralize schedule description logic in DoseSchedule extension
9. Add user feedback for query failures
10. Consider operation queueing for concurrent updates
11. Add `.gitignore` entries for backup files

---

## Test Coverage Analysis

### Unit Test Coverage: ✅ Excellent
- **ViewModel**: 9 tests covering all CRUD operations
- **UI Components**: 18 tests total (PauseSheet: 8, Summary: 4, History: 6)
- **Critical Paths**: All major user flows tested

### E2E Test Coverage: ✅ Comprehensive
- **Happy Paths**: Create, edit, pause, resume, deactivate ✅
- **Error Paths**: Cancel operations ✅
- **Edge Cases**: Indefinite pause, custom dates ✅
- **Accessibility**: VoiceOver navigation ✅

### Test Quality Improvements from Refactoring ✅
- Removed all 18 `sleep()` calls (anti-pattern)
- Implemented proper wait conditions
- Added TestDataSeeding for 2-3x performance gain
- Reduced test code by 11% while maintaining coverage

---

## Code Metrics

### Complexity
- **High**: `MedicationProfileViewModel` (293 lines, 9 methods)
- **Medium**: `DoseScheduleEditView` (386 lines, form-heavy)
- **Low**: Component views (100-275 lines each)

### Files Added: 14
- Implementation: 7 files
- Unit Tests: 5 files
- E2E Tests: 1 file
- Documentation: 1 file

### Files Modified: 25
- Most significant: `MedicationProfileSettingsView.swift`
- Test files: 10 E2E test files (removed sleep() calls)

---

## Conclusion

This PR delivers **solid medication schedule management functionality** with excellent test coverage and clean architecture. However, **critical code hygiene issues must be addressed before merging**:

### Must Fix Before Merge:
1. ❌ Remove 4 backup/temporary files
2. ❌ Complete TODO for schedule editing form pre-population
3. ❌ Fix service layer bypass for indefinite pause

### Recommended Before Merge:
4. Extract test helper to reduce duplication
5. Add input validation
6. Add history pagination
7. Use TimeConstants for magic numbers

**Estimated Fix Time**: 2-3 hours for must-fix items, 3-4 hours for recommended improvements.

**Overall Grade**: B+ (would be A after fixes)

---

*Analysis conducted using PR diff, file inspection, and project context documentation.*
