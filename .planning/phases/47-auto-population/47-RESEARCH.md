# Phase 47: Auto-Population - Research

**Researched:** 2026-01-19
**Domain:** Background task orchestration, SwiftData batch operations, app lifecycle events
**Confidence:** HIGH

## Summary

This phase implements auto-population of scheduled foods into the daily food log. The system must create FoodEntry records from active FoodSchedule configurations at midnight (or on app launch for missed days). The implementation builds on Phase 45's FoodSchedule model and Phase 46's FoodScheduleService.

The implementation involves:
1. A new `FoodAutoPopulationService` to process schedules and create FoodEntry records
2. Integration with app lifecycle (ContentView.onAppear) for on-launch population and backfill
3. Tracking last-populated date via UserDefaults to prevent duplicate population
4. Ensuring auto-populated entries appear as normal food entries (deletable, editable)

**Primary recommendation:** Create a new `FoodAutoPopulationService` that runs on app launch (like the existing TDEE backfill pattern in ContentView). Use UserDefaults to track the last successful population date. Process all schedules for missed days between last-populated-date and today (exclusive of today until after midnight).

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData | iOS 17+ | FoodEntry creation, FoodSchedule queries | Project standard per DataController |
| Foundation | N/A | Date calculations, UserDefaults | Date handling, state persistence |
| OSLog | N/A | Logging population operations | Project logging pattern |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SwiftUI | iOS 17+ | App lifecycle integration | onAppear trigger for backfill |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| On-launch backfill | BGTaskScheduler midnight task | Backfill is simpler, more reliable for MVP; true midnight task adds complexity |
| UserDefaults for last-populated | Model entity | UserDefaults follows existing TDEE pattern, simpler for single scalar state |
| Service in AppServices | Standalone function | Service pattern allows dependency injection, testability |

**Installation:**
```bash
# No additional packages needed - all native frameworks
```

## Architecture Patterns

### Recommended Project Structure
```
JabTracker/
├── Services/
│   └── FoodAutoPopulationService.swift  # NEW: Auto-population orchestration
├── Views/
│   └── ContentView.swift                # MODIFY: Add backfill call in .task
└── App/
    └── AppServices.swift                # MODIFY: Register FoodAutoPopulationService
```

### Pattern 1: FoodAutoPopulationService (Follow TDEEService Pattern)

**What:** A service that populates food entries from active schedules on app launch.

**When to use:** Called from ContentView on app launch, similar to `ensureTDEESnapshots()`.

**Example:**
```swift
// Source: Codebase pattern from ContentView.ensureTDEESnapshots()
import Foundation
import OSLog
import SwiftData

/// Service for auto-populating scheduled foods into the food log
@MainActor
@Observable
final class FoodAutoPopulationService {
    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "FoodAutoPopulationService"
    )

    private let context: ModelContext
    private let scheduleService: FoodScheduleService
    private let mealLogService: MealLogService

    /// UserDefaults key for tracking last successful population date
    private static let lastPopulatedDateKey = "lastFoodAutoPopulationDate"

    init(context: ModelContext, scheduleService: FoodScheduleService, mealLogService: MealLogService) {
        self.context = context
        self.scheduleService = scheduleService
        self.mealLogService = mealLogService
    }

    /// Populate scheduled foods for any missed days since last population
    /// Called on app launch to backfill missed days and populate today
    func populateMissedDays() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get last populated date (or use yesterday as starting point)
        let lastPopulated: Date
        if let stored = UserDefaults.standard.object(forKey: Self.lastPopulatedDateKey) as? Date {
            lastPopulated = calendar.startOfDay(for: stored)
        } else {
            // First run - only populate today
            lastPopulated = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }

        // Skip if already populated today
        guard lastPopulated < today else {
            Self.logger.debug("Already populated today, skipping")
            return
        }

        // Populate each day from (lastPopulated + 1) through today
        var currentDate = calendar.date(byAdding: .day, value: 1, to: lastPopulated) ?? today

        while currentDate <= today {
            try await populateDay(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? today
        }

        // Update last populated date
        UserDefaults.standard.set(today, forKey: Self.lastPopulatedDateKey)
        Self.logger.info("Completed auto-population through \(today)")
    }

    /// Populate a single day from active schedules
    private func populateDay(_ date: Date) async throws {
        let schedules = try await scheduleService.getSchedules(for: date)

        guard !schedules.isEmpty else {
            Self.logger.debug("No schedules for \(date)")
            return
        }

        // Get existing entries for the date to avoid duplicates
        let existingEntries = try await mealLogService.getEntries(for: date)
        let existingFoodMeals = Set(existingEntries.map { FoodMealKey(foodId: $0.foodId, meal: $0.meal) })

        for schedule in schedules {
            let meals = schedule.scheduledMeals(for: date)

            for meal in meals {
                let key = FoodMealKey(foodId: schedule.foodId, meal: meal)

                // Skip if already populated (prevents duplicates on re-run)
                guard !existingFoodMeals.contains(key) else {
                    Self.logger.debug("Skipping already-populated: \(schedule.foodName) for \(meal.displayName)")
                    continue
                }

                // Create FoodEntry from schedule
                let entry = createFoodEntry(from: schedule, meal: meal, date: date)
                context.insert(entry)

                Self.logger.info("Auto-populated: \(schedule.foodName) for \(meal.displayName) on \(date)")
            }
        }

        try context.save()
    }

    /// Create a FoodEntry from a FoodSchedule
    private func createFoodEntry(from schedule: FoodSchedule, meal: MealSection, date: Date) -> FoodEntry {
        FoodEntry(
            foodId: schedule.foodId,
            foodName: schedule.foodName,
            foodBrand: schedule.foodBrand.isEmpty ? nil : schedule.foodBrand,
            mealSection: meal,
            loggedAt: date,
            servingGrams: schedule.servingGrams,
            servingDescription: schedule.servingDescription.isEmpty ? nil : schedule.servingDescription,
            servingOptionsJSON: schedule.servingOptionsJSON,
            caloriesPer100g: schedule.caloriesPer100g,
            proteinPer100g: schedule.proteinPer100g,
            carbsPer100g: schedule.carbsPer100g,
            fatPer100g: schedule.fatPer100g,
            fiberPer100g: schedule.fiberPer100g,
            notes: nil
        )
    }
}

/// Key for identifying unique food+meal combination
private struct FoodMealKey: Hashable {
    let foodId: UUID
    let meal: MealSection
}
```

### Pattern 2: ContentView Integration (Follow ensureTDEESnapshots Pattern)

**What:** Call auto-population service on app launch using the established backfill pattern.

**When to use:** In ContentView's `.task` block, similar to TDEE backfill.

**Example:**
```swift
// Source: ContentView.swift pattern
.task {
    await ensureTDEESnapshots()
    await ensureScheduledFoodsPopulated()  // NEW
    updateCheckInBadge()
}

/// Ensure scheduled foods are populated for today and any missed days
private func ensureScheduledFoodsPopulated() async {
    guard let autoPopService = AppServices.shared.foodAutoPopulationService else {
        Self.logger.debug("FoodAutoPopulationService unavailable")
        return
    }

    do {
        try await autoPopService.populateMissedDays()
    } catch {
        Self.logger.error("Food auto-population failed: \(error.localizedDescription)")
    }
}
```

### Pattern 3: Duplicate Prevention (FoodMealKey Pattern)

**What:** Use a hashable key struct to efficiently check for existing entries and prevent duplicates.

**When to use:** When populating entries to avoid creating duplicates if user re-opens app multiple times.

**Example:**
```swift
// Source: Phase 46-01 DayMealKey pattern
private struct FoodMealKey: Hashable {
    let foodId: UUID
    let meal: MealSection
}

// Usage in populateDay:
let existingFoodMeals = Set(existingEntries.map {
    FoodMealKey(foodId: $0.foodId, meal: $0.meal)
})

guard !existingFoodMeals.contains(key) else { continue }
```

### Pattern 4: AppServices Registration

**What:** Register FoodAutoPopulationService in AppServices for app-wide access.

**When to use:** Service initialization in `initialize(with:)`.

**Example:**
```swift
// Source: AppServices.swift pattern
/// Food auto-population service for scheduled food population
@Published private(set) var foodAutoPopulationService: FoodAutoPopulationService?

// In initialize(with:):
let foodAutoPopulationService = FoodAutoPopulationService(
    context: modelContext,
    scheduleService: foodScheduleService,
    mealLogService: mealLogService
)
self.foodAutoPopulationService = foodAutoPopulationService

// In reset():
foodAutoPopulationService = nil
```

### Anti-Patterns to Avoid

- **Creating entries directly without duplicate check:** Always check for existing entries before inserting to prevent duplicates when app is opened multiple times.

- **Using BGTaskScheduler for MVP:** Background app refresh adds significant complexity (registration, entitlements, testing). On-launch backfill is simpler and reliable for food scheduling use case.

- **Populating future days:** Only populate up to "today" - never create future entries as schedules may change.

- **Storing last-populated date in SwiftData model:** UserDefaults is simpler for single scalar state, follows existing TDEE pattern.

- **Running population synchronously on main thread:** Use async/await in `.task` to avoid blocking UI.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Entry creation | Manual property mapping | `FoodEntry(...)` initializer | Already handles all properties |
| Duplicate detection | Manual array search | Set with FoodMealKey struct | O(1) lookup, follows DayMealKey pattern |
| Date iteration | Manual day-by-day | Calendar.date(byAdding:) | Handles edge cases (DST, month boundaries) |
| State persistence | SwiftData model | UserDefaults | Simpler for single Date, follows TDEE pattern |
| Service access | Global singleton | AppServices pattern | Testable, follows existing architecture |

**Key insight:** The codebase already has established patterns for every aspect of this feature. Follow ContentView's TDEE backfill for lifecycle, FoodEntry for data structure, AppServices for service access.

## Common Pitfalls

### Pitfall 1: Duplicate Entries on Multiple App Opens

**What goes wrong:** User opens app multiple times in a day and gets duplicate entries.

**Why it happens:** Population runs without checking if entries already exist.

**How to avoid:** Query existing entries for the date and create a Set of FoodMealKey for O(1) lookup before inserting any entries. Skip insertion if key already exists.

**Warning signs:** Users reporting duplicate scheduled foods appearing.

### Pitfall 2: Populating Partial Days Incorrectly

**What goes wrong:** User opens app at 2pm, schedule says breakfast - entry appears in current day's log but timing is confusing.

**Why it happens:** Using `Date()` as loggedAt instead of start of day.

**How to avoid:** Use `calendar.startOfDay(for: date)` as the loggedAt date. This ensures entries appear correctly grouped by day, not by the time the app was opened.

**Warning signs:** Entries appearing with odd timestamps.

### Pitfall 3: Race Condition Between Population and Manual Logging

**What goes wrong:** User logs food manually while population is running, gets duplicate.

**Why it happens:** Population query happens before manual save, but insert happens after.

**How to avoid:** This is unlikely in practice (population runs on launch, before UI). Accept minimal risk rather than adding locking complexity. If it becomes an issue, move duplicate check into the insert loop.

**Warning signs:** Occasional duplicates only.

### Pitfall 4: Timezone Changes Breaking Backfill Logic

**What goes wrong:** User travels across timezones, backfill creates entries for wrong days.

**Why it happens:** Not normalizing all dates to start of day before comparison.

**How to avoid:** Always use `calendar.startOfDay(for:)` when comparing dates. Store last-populated as a Date (not string), let UserDefaults handle serialization.

**Warning signs:** Wrong days being populated after timezone changes.

### Pitfall 5: Schedule Changes Not Reflected

**What goes wrong:** User changes schedule, but already-populated entries still show old schedule.

**Why it happens:** Auto-populated entries are denormalized snapshots - they don't update when schedule changes.

**How to avoid:** This is intentional behavior (SCHED-11). Document clearly: changing a schedule affects future days, not already-populated entries. Users can delete and schedule will repopulate next day.

**Warning signs:** None - this is expected behavior.

## Code Examples

Verified patterns from official sources:

### FoodEntry from Schedule (No Food Model Needed)

```swift
// Source: FoodEntry.swift - direct initializer
FoodEntry(
    foodId: schedule.foodId,
    foodName: schedule.foodName,
    foodBrand: schedule.foodBrand.isEmpty ? nil : schedule.foodBrand,
    mealSection: meal,
    loggedAt: date,
    servingGrams: schedule.servingGrams,
    servingDescription: schedule.servingDescription.isEmpty ? nil : schedule.servingDescription,
    servingOptionsJSON: schedule.servingOptionsJSON,
    caloriesPer100g: schedule.caloriesPer100g,
    proteinPer100g: schedule.proteinPer100g,
    carbsPer100g: schedule.carbsPer100g,
    fatPer100g: schedule.fatPer100g,
    fiberPer100g: schedule.fiberPer100g,
    notes: nil
)
```

### UserDefaults Date Pattern

```swift
// Source: ContentView.ensureTDEESnapshots pattern
private static let lastPopulatedDateKey = "lastFoodAutoPopulationDate"

// Read:
if let stored = UserDefaults.standard.object(forKey: Self.lastPopulatedDateKey) as? Date {
    lastPopulated = calendar.startOfDay(for: stored)
}

// Write:
UserDefaults.standard.set(Date(), forKey: Self.lastPopulatedDateKey)
```

### Getting Schedules for a Date

```swift
// Source: FoodScheduleService.swift
let schedules = try await scheduleService.getSchedules(for: date)
// Returns schedules where:
// - isActive == true
// - date is within startDate/endDate range (if set)
// - schedule has meals configured for this day of week
```

### Getting Existing Entries for a Date

```swift
// Source: MealLogService.swift
let existingEntries = try await mealLogService.getEntries(for: date)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| BGAppRefresh | On-launch backfill | 2024 patterns | Simpler, more reliable for non-critical tasks |
| Core Data notifications | SwiftData @Query | iOS 17 (2023) | Automatic UI updates when entries created |
| ObservableObject | @Observable | iOS 17 (2023) | Better performance, simpler service code |

**Deprecated/outdated:**
- None - all patterns are current iOS 17+ approaches

## Open Questions

Things that couldn't be fully resolved:

1. **Midnight Trigger vs On-Launch Only**
   - What we know: On-launch backfill handles 99% of cases; BGTaskScheduler adds complexity
   - What's unclear: Whether users want entries to appear exactly at midnight without opening app
   - Recommendation: Start with on-launch backfill (simpler, testable). Add BGTaskScheduler in future phase if user feedback requests true midnight population.

2. **Multiple Devices with CloudKit**
   - What we know: FoodEntry syncs via CloudKit; same schedule may populate on multiple devices
   - What's unclear: Whether duplicate entries could be created across devices
   - Recommendation: Duplicate check uses foodId + meal + date - CloudKit sync should merge. May need investigation if duplicates appear across devices.

3. **User Notification on Auto-Population**
   - What we know: Entries appear silently in food log
   - What's unclear: Whether users want notification when foods are auto-populated
   - Recommendation: Skip notification for MVP. Silent population is less intrusive. Add optional notification setting if users request it.

## Sources

### Primary (HIGH confidence)
- `/JabTracker/ContentView.swift` - ensureTDEESnapshots pattern for on-launch backfill
- `/JabTracker/Models/FoodEntry.swift` - FoodEntry initializer and properties
- `/JabTracker/Models/FoodSchedule.swift` - FoodSchedule model, scheduledMeals(for:) method
- `/JabTracker/Services/FoodScheduleService.swift` - getSchedules(for:) method
- `/JabTracker/Services/MealLogService.swift` - getEntries(for:), logFood patterns
- `/JabTracker/App/AppServices.swift` - Service registration pattern
- `/JabTracker/Views/Nutrition/ScheduleDayMealGrid.swift` - DayMealKey struct for hashable lookup

### Secondary (MEDIUM confidence)
- `.planning/phases/45-schedule-model/45-RESEARCH.md` - FoodSchedule model design decisions
- `.planning/phases/46-schedule-ux/46-RESEARCH.md` - Schedule UX patterns

### Tertiary (LOW confidence)
- None - all patterns verified in codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All patterns verified in existing codebase
- Architecture: HIGH - Following established ensureTDEESnapshots pattern
- Pitfalls: HIGH - Based on actual codebase constraints and common patterns

**Research date:** 2026-01-19
**Valid until:** 2026-02-19 (30 days - stable domain)
