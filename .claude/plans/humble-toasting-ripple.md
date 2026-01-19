# Plan: Fix Auto-Population Not Working

## Problem
User creates a schedule for Mon-Fri breakfast, but no entries appear in the food log. The weekly strategy architecture exists but isn't functioning.

## Root Cause Investigation

The code has the right architecture:
- `FoodEntry.scheduleId: UUID?` - links entries to schedules
- `FoodAutoPopulationService.populateWeek(for:)` - creates week's entries
- `FoodAutoPopulationService.deleteScheduledEntries(for:)` - cascade delete
- `ScheduleConfigSheet.saveSchedule()` - calls `populateWeek` after save

But the call on line 241 uses optional chaining (`?.`) which silently fails if service is nil:
```swift
try await AppServices.shared.foodAutoPopulationService?.populateWeek(for: schedule)
```

## Fix Plan

### Task 1: Add Explicit Error Handling in ScheduleConfigSheet
**File:** `JabTracker/Views/Nutrition/ScheduleConfigSheet.swift`

Replace silent optional chaining with explicit error handling:
```swift
// Before (silent failure):
try await AppServices.shared.foodAutoPopulationService?.populateWeek(for: schedule)

// After (explicit):
guard let autoPopService = AppServices.shared.foodAutoPopulationService else {
    logger.error("FoodAutoPopulationService not available - entries not populated")
    // Still dismiss - schedule was saved, just not populated
    dismiss()
    onComplete()
    return
}
let entriesCreated = try await autoPopService.populateWeek(for: schedule)
logger.info("Created \(entriesCreated) scheduled entries for \(food.name)")
```

### Task 2: Add Debug Logging to populateWeek
**File:** `JabTracker/Services/FoodAutoPopulationService.swift`

Add logging at key decision points:
```swift
func populateWeek(for schedule: FoodSchedule) async throws -> Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let endOfWeek = getEndOfWeek(for: today)

    Self.logger.info("populateWeek: \(schedule.foodName) from \(today) to \(endOfWeek)")

    // ... existing code with more logging at each step
}
```

### Task 3: Verify Schedule Config is Valid
**File:** `JabTracker/Services/FoodAutoPopulationService.swift`

Add validation in `populateDayForSchedule`:
```swift
private func populateDayForSchedule(_ schedule: FoodSchedule, date: Date) async throws -> Int {
    guard let config = schedule.scheduleConfig else {
        Self.logger.error("Schedule \(schedule.id) has nil config")
        return 0
    }

    let meals = schedule.scheduledMeals(for: date)
    Self.logger.debug("Day \(date): \(meals.count) meals from config")
    // ...
}
```

### Task 4: Test with Console Logging
Run app with Console.app filtering for "FoodAutoPopulationService" to trace the flow.

## Verification
1. Create schedule for Mon-Fri breakfast
2. Check Console for logging showing entries being created
3. Verify entries appear in food log for Mon-Fri
4. Delete schedule and verify entries are removed

## Files to Modify
- `JabTracker/Views/Nutrition/ScheduleConfigSheet.swift`
- `JabTracker/Services/FoodAutoPopulationService.swift`
