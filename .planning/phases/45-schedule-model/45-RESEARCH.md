# Phase 45: Schedule Model - Research

**Researched:** 2026-01-17
**Domain:** SwiftData modeling, CloudKit sync, food scheduling data structures
**Confidence:** HIGH

## Summary

This phase implements the data foundation for food scheduling, allowing users to schedule foods for automatic population. The model must store schedule configuration (days of week, meal types, quantity, optional date ranges) while enforcing a one-schedule-per-food constraint and auto-converting non-custom foods to custom foods when scheduling.

The implementation involves:
1. A new `FoodSchedule` SwiftData model with CloudKit-compatible properties
2. A `FoodScheduleService` to handle CRUD operations with constraint enforcement
3. Auto-conversion logic to create custom foods from USDA/Open Food Facts foods when scheduling
4. JSON-encoded configuration for flexible day/meal combinations

**Primary recommendation:** Create a new `FoodSchedule` model with a one-to-one relationship to `Food`, store multi-day/multi-meal configuration as JSON-encoded Data, and enforce the one-schedule-per-food constraint at the service layer via fetch-before-insert pattern.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData | iOS 17+ | Persistent model with CloudKit sync | Project standard per DataController.swift |
| SwiftUI | iOS 17+ | `@Observable` for schedule service | Project convention per CONVENTIONS.md |
| Foundation | N/A | Date, UUID, JSONEncoder/Decoder | Date handling, JSON serialization |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| OSLog | N/A | Logging schedule operations | Debug and info level logging |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| JSON-encoded day/meal config | Separate relationship table | JSON is simpler for CloudKit, matches NutritionProgram pattern |
| Service-layer constraint | SwiftData `#Unique` | SwiftData `#Unique` not reliable with CloudKit; service pattern matches CustomFoodService |
| Food reference via `foodId: UUID` | `@Relationship` to Food | Direct relationship risks issues if original food deleted; UUID reference matches FoodEntry pattern |

**Installation:**
```bash
# No additional packages needed - all native frameworks
```

## Architecture Patterns

### Recommended Project Structure
```
JabTracker/
├── Services/
│   └── FoodScheduleService.swift     # NEW: Schedule CRUD with constraint enforcement
├── Models/
│   ├── FoodSchedule.swift            # NEW: Schedule configuration model
│   └── ScheduleConfiguration.swift   # NEW: Value types for schedule settings
└── DataController.swift              # MODIFY: Add FoodSchedule to modelTypes
```

### Pattern 1: FoodSchedule Model (CloudKit Compatible)

**What:** A SwiftData `@Model` storing schedule configuration with CloudKit-compatible properties.

**When to use:** For any scheduled food with day/meal/quantity configuration.

**Example:**
```swift
// Source: Codebase patterns from DoseSchedule.swift, NutritionProgram.swift
import Foundation
import SwiftData

/// Scheduled food for automatic population
/// One schedule per food enforced at service layer
@Model
final class FoodSchedule {
    // MARK: - Identity

    var id: UUID = UUID()

    // MARK: - Food Reference (UUID, not relationship)
    // Matches FoodEntry pattern - stores ID reference, food details denormalized

    var foodId: UUID = UUID()          // Reference to custom Food
    var foodName: String = ""          // Denormalized for display
    var foodBrand: String = ""         // Denormalized for display

    // MARK: - Schedule Configuration (JSON-encoded)

    /// JSON-encoded ScheduleDayMealConfig array
    /// Each config specifies: day(s) of week, meal type, serving amount
    var scheduleConfigData: Data = Data()

    // MARK: - Serving Configuration

    var servingGrams: Double = 100.0
    var servingDescription: String = ""
    var servingOptionsJSON: String = "[]"

    // MARK: - Nutrition (denormalized from Food at schedule time)

    var caloriesPer100g: Double = 0.0
    var proteinPer100g: Double = 0.0
    var carbsPer100g: Double = 0.0
    var fatPer100g: Double = 0.0
    var fiberPer100g: Double = 0.0

    // MARK: - Date Range (optional)

    var startDate: Date?               // Optional start date (nil = immediate)
    var endDate: Date?                 // Optional end date (nil = indefinite)

    // MARK: - State

    var isActive: Bool = true

    // MARK: - Timestamps

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Initialization

    init(
        foodId: UUID,
        foodName: String,
        foodBrand: String = "",
        scheduleConfigData: Data = Data(),
        servingGrams: Double = 100.0,
        servingDescription: String = "",
        servingOptionsJSON: String = "[]",
        caloriesPer100g: Double = 0.0,
        proteinPer100g: Double = 0.0,
        carbsPer100g: Double = 0.0,
        fatPer100g: Double = 0.0,
        fiberPer100g: Double = 0.0,
        startDate: Date? = nil,
        endDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.foodId = foodId
        self.foodName = foodName
        self.foodBrand = foodBrand
        self.scheduleConfigData = scheduleConfigData
        self.servingGrams = servingGrams
        self.servingDescription = servingDescription
        self.servingOptionsJSON = servingOptionsJSON
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

### Pattern 2: Schedule Configuration Value Types

**What:** Codable value types for schedule day/meal configuration, encoded as JSON in the model.

**When to use:** For complex configuration that needs flexibility while maintaining CloudKit compatibility.

**Example:**
```swift
// Source: Codebase patterns from WeeklyMacroDistribution, CollaborativeConfigStorage
import Foundation

/// Days of week using Calendar.Component.weekday convention (1=Sunday through 7=Saturday)
enum ScheduleDay: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

/// A single day+meal combination for the schedule
struct ScheduleDayMealConfig: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var day: ScheduleDay
    var meal: MealSection

    init(day: ScheduleDay, meal: MealSection) {
        self.day = day
        self.meal = meal
    }
}

/// Complete schedule configuration
struct ScheduleConfig: Codable, Equatable {
    var dayMealConfigs: [ScheduleDayMealConfig]

    /// All unique days in this schedule
    var scheduledDays: Set<ScheduleDay> {
        Set(dayMealConfigs.map { $0.day })
    }

    /// All unique meals in this schedule
    var scheduledMeals: Set<MealSection> {
        Set(dayMealConfigs.map { $0.meal })
    }

    /// Meals scheduled for a specific day
    func meals(for day: ScheduleDay) -> [MealSection] {
        dayMealConfigs.filter { $0.day == day }.map { $0.meal }
    }

    /// Whether a specific day+meal is scheduled
    func isScheduled(day: ScheduleDay, meal: MealSection) -> Bool {
        dayMealConfigs.contains { $0.day == day && $0.meal == meal }
    }

    /// Validation
    var isValid: Bool {
        !dayMealConfigs.isEmpty
    }
}
```

### Pattern 3: FoodSchedule Model Extensions for Config Access

**What:** Computed properties for type-safe access to JSON-encoded configuration.

**When to use:** To provide type-safe API while storing as JSON for CloudKit.

**Example:**
```swift
// Source: Codebase patterns from NutritionProgram.swift weeklyMacros accessor
extension FoodSchedule {
    /// Decoded schedule configuration
    var scheduleConfig: ScheduleConfig? {
        get {
            guard !scheduleConfigData.isEmpty else { return nil }
            return try? JSONDecoder().decode(ScheduleConfig.self, from: scheduleConfigData)
        }
        set {
            if let config = newValue {
                scheduleConfigData = (try? JSONEncoder().encode(config)) ?? Data()
            } else {
                scheduleConfigData = Data()
            }
            updatedAt = Date()
        }
    }

    /// Whether schedule applies to a given date
    func appliesTo(date: Date) -> Bool {
        // Check active state
        guard isActive else { return false }

        // Check date range if specified
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)

        if let start = startDate, startOfDate < calendar.startOfDay(for: start) {
            return false
        }
        if let end = endDate, startOfDate > calendar.startOfDay(for: end) {
            return false
        }

        return true
    }

    /// Meals scheduled for a specific date (considering day of week and date range)
    func scheduledMeals(for date: Date) -> [MealSection] {
        guard appliesTo(date: date),
              let config = scheduleConfig else { return [] }

        let weekday = Calendar.current.component(.weekday, from: date)
        guard let scheduleDay = ScheduleDay(rawValue: weekday) else { return [] }

        return config.meals(for: scheduleDay)
    }
}
```

### Pattern 4: FoodScheduleService with Constraint Enforcement

**What:** A service class that enforces the one-schedule-per-food constraint and handles auto-conversion.

**When to use:** For all schedule CRUD operations.

**Example:**
```swift
// Source: Codebase patterns from CustomFoodService.swift
import Foundation
import OSLog
import SwiftData

/// Errors that can occur during food schedule operations
enum FoodScheduleError: LocalizedError, Equatable {
    case scheduleAlreadyExists  // Will update existing instead
    case invalidConfiguration
    case foodNotFound

    var errorDescription: String? {
        switch self {
        case .scheduleAlreadyExists:
            return "A schedule already exists for this food"
        case .invalidConfiguration:
            return "Schedule configuration is invalid"
        case .foodNotFound:
            return "Food not found"
        }
    }
}

/// Service for managing food schedules
/// Enforces one-schedule-per-food constraint at service layer
@MainActor
final class FoodScheduleService {
    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "FoodScheduleService"
    )

    private let context: ModelContext
    private let customFoodService: CustomFoodService

    init(context: ModelContext, customFoodService: CustomFoodService) {
        self.context = context
        self.customFoodService = customFoodService
    }

    // MARK: - Create or Update Schedule

    /// Create or update a schedule for a food
    /// - If food is not custom, auto-converts to custom first
    /// - If schedule exists for food, updates it instead of creating new
    /// - Returns the schedule (created or updated)
    func createOrUpdateSchedule(
        for food: Food,
        config: ScheduleConfig,
        servingGrams: Double,
        servingDescription: String,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> FoodSchedule {
        // Validate configuration
        guard config.isValid else {
            throw FoodScheduleError.invalidConfiguration
        }

        // Auto-convert to custom food if needed (SCHED-04)
        let customFood: Food
        if food.isCustomFood {
            customFood = food
        } else {
            customFood = try await convertToCustomFood(food)
        }

        // Check for existing schedule (one-per-food constraint, SCHED-07)
        if let existingSchedule = try await getSchedule(for: customFood.id) {
            // Update existing schedule
            return try await updateSchedule(
                existingSchedule,
                config: config,
                servingGrams: servingGrams,
                servingDescription: servingDescription,
                startDate: startDate,
                endDate: endDate
            )
        }

        // Create new schedule
        let configData = try JSONEncoder().encode(config)

        let schedule = FoodSchedule(
            foodId: customFood.id,
            foodName: customFood.name,
            foodBrand: customFood.brand,
            scheduleConfigData: configData,
            servingGrams: servingGrams,
            servingDescription: servingDescription,
            servingOptionsJSON: customFood.servingOptionsJSON,
            caloriesPer100g: customFood.caloriesPer100g,
            proteinPer100g: customFood.proteinPer100g,
            carbsPer100g: customFood.carbsPer100g,
            fatPer100g: customFood.fatPer100g,
            fiberPer100g: customFood.fiberPer100g,
            startDate: startDate,
            endDate: endDate
        )

        context.insert(schedule)
        try context.save()

        Self.logger.info("Created schedule for '\(customFood.name)'")
        return schedule
    }

    // MARK: - Read

    /// Get schedule for a food (by food ID)
    func getSchedule(for foodId: UUID) async throws -> FoodSchedule? {
        let descriptor = FetchDescriptor<FoodSchedule>(
            predicate: #Predicate { schedule in
                schedule.foodId == foodId
            }
        )
        return try context.fetch(descriptor).first
    }

    /// Get all active schedules
    func getAllActiveSchedules() async throws -> [FoodSchedule] {
        let descriptor = FetchDescriptor<FoodSchedule>(
            predicate: #Predicate { schedule in
                schedule.isActive == true
            },
            sortBy: [SortDescriptor(\.foodName)]
        )
        return try context.fetch(descriptor)
    }

    /// Get schedules that apply to a specific date
    func getSchedules(for date: Date) async throws -> [FoodSchedule] {
        let allActive = try await getAllActiveSchedules()
        return allActive.filter { $0.appliesTo(date: date) }
    }

    // MARK: - Update

    /// Update an existing schedule
    func updateSchedule(
        _ schedule: FoodSchedule,
        config: ScheduleConfig,
        servingGrams: Double,
        servingDescription: String,
        startDate: Date?,
        endDate: Date?
    ) async throws -> FoodSchedule {
        guard config.isValid else {
            throw FoodScheduleError.invalidConfiguration
        }

        schedule.scheduleConfig = config
        schedule.servingGrams = servingGrams
        schedule.servingDescription = servingDescription
        schedule.startDate = startDate
        schedule.endDate = endDate
        schedule.updatedAt = Date()

        try context.save()

        Self.logger.info("Updated schedule for '\(schedule.foodName)'")
        return schedule
    }

    // MARK: - Delete

    /// Delete a schedule
    func deleteSchedule(_ schedule: FoodSchedule) async throws {
        let name = schedule.foodName
        context.delete(schedule)
        try context.save()

        Self.logger.info("Deleted schedule for '\(name)'")
    }

    // MARK: - Private Helpers

    /// Convert a non-custom food to a custom food
    private func convertToCustomFood(_ food: Food) async throws -> Food {
        // Create a custom food copy
        let input = CustomFoodInput(
            name: food.name,
            brand: food.brand,
            caloriesPer100g: food.caloriesPer100g,
            proteinPer100g: food.proteinPer100g,
            carbsPer100g: food.carbsPer100g,
            fatPer100g: food.fatPer100g,
            fiberPer100g: food.fiberPer100g,
            servingSize: food.servingSize,
            servingUnit: food.servingUnit,
            servingDescription: food.servingDescription,
            barcode: ""  // Don't copy barcode - would conflict with original
        )

        let customFood = try await customFoodService.createCustomFood(input)
        Self.logger.info("Auto-converted '\(food.name)' to custom food for scheduling")
        return customFood
    }
}
```

### Anti-Patterns to Avoid

- **Using `@Relationship` for Food reference:** The Food model doesn't have an inverse relationship for schedules. Using `foodId: UUID` reference matches the FoodEntry pattern and avoids cascade delete issues.

- **Storing days/meals in separate columns:** Multi-day/multi-meal support requires flexible configuration. JSON-encoded Data is the established pattern (see NutritionProgram.weeklyMacroDistributionData).

- **Relying on `#Unique` macro:** SwiftData's `#Unique` doesn't work reliably with CloudKit. Enforce constraints at service layer via fetch-before-insert.

- **Modifying original food when scheduling:** Auto-conversion creates a NEW custom food, preserving the original database food.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Day of week handling | Custom enum 0-6 | Calendar.component(.weekday) = 1-7 | Matches existing WeeklyConstants pattern |
| JSON encoding/decoding | Manual string parsing | JSONEncoder/JSONDecoder | Standard Codable pattern |
| Food creation from source | Manual property copying | CustomFoodService.createCustomFood | Handles validation, barcode conflicts |
| Unique constraint | Database constraint | Service layer fetch-before-insert | CloudKit compatible |

**Key insight:** The codebase has established patterns for every aspect of this model. Follow NutritionProgram for JSON config storage, CustomFoodService for constraint enforcement, FoodEntry for food reference pattern.

## Common Pitfalls

### Pitfall 1: CloudKit Sync Issues with Relationships

**What goes wrong:** Using `@Relationship` with delete rules can cause CloudKit sync conflicts.

**Why it happens:** CloudKit sync is eventually consistent; cascade deletes can race with syncs.

**How to avoid:** Use UUID references (like FoodEntry.foodId) instead of `@Relationship` when the parent might be deleted independently.

**Warning signs:** "CloudKit operation failed" errors after deleting related records.

### Pitfall 2: Optional Properties with CloudKit

**What goes wrong:** Optional String/Int properties cause CloudKit schema issues.

**Why it happens:** CloudKit requires non-optional fields or explicit defaults.

**How to avoid:** Use non-optional properties with sensible defaults (empty string, 0, etc.). Optional Date is fine.

**Warning signs:** Schema migration errors, nil values not syncing.

### Pitfall 3: One-to-One Enforcement Race Conditions

**What goes wrong:** Multiple schedules created for same food during rapid operations.

**Why it happens:** Concurrent operations might both pass the "no existing schedule" check.

**How to avoid:** Use `@MainActor` on service, fetch-update-save in single transaction. For CloudKit, accept that a second device might create a duplicate that needs conflict resolution.

**Warning signs:** Duplicate schedules appearing after sync.

### Pitfall 4: Day of Week Off-by-One

**What goes wrong:** Monday shows up as Sunday or vice versa.

**Why it happens:** Different conventions (0-6 vs 1-7, Sunday-first vs Monday-first).

**How to avoid:** Always use `Calendar.current.component(.weekday, from: date)` which returns 1=Sunday through 7=Saturday. Match existing `WeeklyConstants.validWeekdayRange` pattern.

**Warning signs:** Schedules triggering on wrong days.

## Code Examples

Verified patterns from official sources:

### DataController Registration

```swift
// Source: DataController.swift pattern
private static let modelTypes: [any PersistentModel.Type] = [
    // ... existing types
    FoodSchedule.self,  // ADD: Register new model
]
```

### MealSection Reuse

```swift
// Source: MealSection.swift - already exists, reuse it
enum MealSection: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snacks
    // ...
}
```

### WeeklyConstants Pattern

```swift
// Source: ProgramConfiguration.swift - follow this pattern
enum WeeklyConstants {
    /// Valid weekday range (1=Sunday through 7=Saturday, per Calendar.Component.weekday)
    static let validWeekdayRange = 1...7
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Core Data relationships | SwiftData @Relationship | iOS 17 (2023) | Simpler relationship syntax |
| Custom CloudKit code | SwiftData CloudKit integration | iOS 17 (2023) | Automatic sync |
| ObservableObject | @Observable | iOS 17 (2023) | Less boilerplate, better performance |

**Deprecated/outdated:**
- None - project already on iOS 17+ patterns

## Open Questions

Things that couldn't be fully resolved:

1. **CloudKit Conflict Resolution**
   - What we know: SwiftData with CloudKit handles merge automatically for simple properties
   - What's unclear: How duplicate schedules (same food ID) are resolved
   - Recommendation: Accept last-write-wins for schedule config; service layer should fetch-refresh-update to minimize conflicts

2. **Schedule Deletion When Food Deleted**
   - What we know: FoodSchedule uses `foodId` reference, not @Relationship
   - What's unclear: Whether orphaned schedules should be cleaned up
   - Recommendation: Query for orphaned schedules periodically or when displaying schedule list

## Sources

### Primary (HIGH confidence)
- `/JabTracker/Models/Food.swift` - Food model structure, FoodSource enum
- `/JabTracker/Models/FoodEntry.swift` - Pattern for food reference via UUID
- `/JabTracker/Models/MealSection.swift` - Existing meal type enum
- `/JabTracker/Models/NutritionProgram.swift` - JSON config pattern
- `/JabTracker/Models/ProgramConfiguration.swift` - WeeklyConstants, day of week patterns
- `/JabTracker/Services/CustomFoodService.swift` - Service layer constraint enforcement pattern
- `/JabTracker/DataController.swift` - Model registration, CloudKit configuration

### Secondary (MEDIUM confidence)
- Apple SwiftData documentation - Model requirements
- iOS development rules from ~/.claude/rules/development-ios.md

### Tertiary (LOW confidence)
- None - all patterns verified in codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All patterns verified in existing codebase
- Architecture: HIGH - Following established service + model patterns
- Pitfalls: HIGH - Based on actual codebase constraints and comments

**Research date:** 2026-01-17
**Valid until:** 2026-02-17 (30 days - stable domain)
