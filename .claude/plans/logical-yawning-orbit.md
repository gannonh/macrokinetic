# Plan: Fix All PR Review Issues

Address remaining issues from PR #343 review: silent failures, error swallowing, misleading comments, and test coverage gaps.

## Files to Modify

| File | Changes |
|------|---------|
| `JabTracker/Views/Nutrition/ScheduleConfigSheet.swift` | Fix silent failures with guard statements |
| `JabTracker/Services/FoodAutoPopulationService.swift` | Add result types, fix error handling, update comments |
| `JabTrackerTests/Services/FoodAutoPopulationServiceTests.swift` | Add 7 new tests |

---

## 1. Fix Silent Failures in ScheduleConfigSheet.swift

**Problem:** Lines 224, 241, 260 use optional chaining (`?.`) which silently fails if service is nil.

**Solution:** Replace optional chaining with guard statements that throw errors.

```swift
// Add error type at top of file
private enum ScheduleConfigError: LocalizedError {
    case autoPopulationServiceUnavailable

    var errorDescription: String? {
        switch self {
        case .autoPopulationServiceUnavailable:
            return "Unable to manage scheduled entries. Please try again."
        }
    }
}

// Line ~224 - replace optional chaining:
guard let autoPopService = AppServices.shared.foodAutoPopulationService else {
    logger.error("FoodAutoPopulationService unavailable when editing schedule")
    throw ScheduleConfigError.autoPopulationServiceUnavailable
}
try await autoPopService.deleteScheduledEntries(for: existingSchedule.id)

// Line ~241 - replace optional chaining:
guard let autoPopService = AppServices.shared.foodAutoPopulationService else {
    logger.error("FoodAutoPopulationService unavailable when populating week")
    throw ScheduleConfigError.autoPopulationServiceUnavailable
}
try await autoPopService.populateWeek(for: schedule)

// Line ~260 - replace optional chaining:
guard let autoPopService = AppServices.shared.foodAutoPopulationService else {
    logger.error("FoodAutoPopulationService unavailable when deleting schedule")
    throw ScheduleConfigError.autoPopulationServiceUnavailable
}
try await autoPopService.deleteScheduledEntries(for: schedule.id)
```

---

## 2. Fix Error Swallowing in FoodAutoPopulationService.swift

**Problem:** `checkAndPopulateNewWeek()` and `populateToday()` catch errors and only log them.

**Solution:** Return result structs so callers can check for errors.

```swift
// Add result types after class declaration:

/// Result of a week population operation
struct WeekPopulationResult {
    let entriesCreated: Int
    let schedulesProcessed: Int
    let error: Error?
    var isSuccess: Bool { error == nil }
}

/// Result of a day population operation
struct DayPopulationResult {
    let entriesCreated: Int
    let error: Error?
    var isSuccess: Bool { error == nil }
}

// Update checkAndPopulateNewWeek() to return WeekPopulationResult
// Update populateToday() to return DayPopulationResult
```

---

## 3. Fix Misleading Week Start Comment

**Problem:** Line 158 says "Sunday" but code uses locale-dependent Calendar.

**Solution:** Update comment:
```swift
/// Get the start of the week for a given date.
/// Uses the device's calendar settings to determine week start (Sunday in US, Monday in most of Europe).
private func getStartOfWeek(for date: Date) -> Date {
```

Also update `getEndOfWeek` comment similarly.

---

## 4. Add Missing Tests

Add 7 tests to `FoodAutoPopulationServiceTests.swift`:

### deleteScheduledEntries Tests
1. `testDeleteScheduledEntries_RemovesEntriesAfterCutoff` - Verify entries deleted
2. `testDeleteScheduledEntries_PreservesEntriesBeforeCutoff` - Verify past entries preserved

### populateWeek Tests
3. `testPopulateWeek_CreatesEntriesThroughEndOfWeek` - Week boundary logic
4. `testPopulateWeek_RespectsDateRange` - Future start date respected

### checkAndPopulateNewWeek Tests
5. `testCheckAndPopulateNewWeek_PopulatesOnWeekChange` - Week rollover detection
6. `testCheckAndPopulateNewWeek_SkipsWhenSameWeek` - No duplicate population
7. `testCheckAndPopulateNewWeek_ReturnsErrorOnFailure` - Error captured in result

---

## Verification

```bash
# Run unit tests
./scripts/test.sh unit 1 FoodAutoPopulationServiceTests

# Run all unit tests to check for regressions
./scripts/test.sh unit 1

# Run lint
swiftlint
```
