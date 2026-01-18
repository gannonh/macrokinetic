# Phase 46: Schedule UX - Research

**Researched:** 2026-01-18
**Domain:** SwiftUI swipe actions, sheet presentation, form configuration, Food Library filtering
**Confidence:** HIGH

## Summary

This phase implements the user interface for creating and managing food schedules from natural entry points: Food Library swipe, search results swipe, and Food Detail action button. The implementation builds on Phase 45's `FoodSchedule` model and `FoodScheduleService`, adding UI components for schedule configuration (day/meal grid selection, serving input, date range) and schedule status display.

The implementation involves:
1. A new `ScheduleConfigSheet` for configuring schedule day/meal combinations and serving amounts
2. Adding "Schedule" swipe action to Food Library rows and search result rows
3. Adding "Schedule" action button to `FoodDetailSheet` with schedule status display
4. Extending `LibraryTab` with a "Scheduled" filter option for Food Library
5. Registering `FoodScheduleService` in `AppServices` for app-wide access

**Primary recommendation:** Create a reusable `ScheduleConfigSheet` that accepts a `Food` (or `FoodSearchResult`) and presents a form with day/meal toggle grid, serving configuration, and optional date range. Use established swipe action patterns from `FoodLibraryContentView` and `FoodSearchSheet+Sections`. Follow `DoseScheduleEditView` Form-based pattern for configuration UI.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | iOS 17+ | Swipe actions, sheets, forms | Project standard UI framework |
| SwiftData | iOS 17+ | Schedule persistence via FoodScheduleService | Project standard per DataController |
| Foundation | N/A | Date handling, Calendar | Day of week calculations |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| OSLog | N/A | Logging UI actions | Debug and info level logging |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Form-based sheet | Custom modal | Form provides consistent iOS navigation/toolbar patterns |
| Toggle grid for day/meal | Separate pickers | Grid is more visual, allows multi-select at a glance |
| Swipe actions | Context menu | Swipe is more discoverable for primary actions per existing codebase patterns |

**Installation:**
```bash
# No additional packages needed - all native frameworks
```

## Architecture Patterns

### Recommended Project Structure
```
JabTracker/
├── Views/
│   └── Nutrition/
│       ├── ScheduleConfigSheet.swift          # NEW: Schedule configuration form
│       ├── ScheduleDayMealGrid.swift          # NEW: Reusable day/meal toggle grid
│       ├── FoodLibraryContentView.swift       # MODIFY: Add Schedule swipe action
│       ├── FoodSearchSheet+Sections.swift     # MODIFY: Add Schedule swipe action
│       └── FoodDetailSheet.swift              # MODIFY: Add Schedule button + status
├── Models/
│   ├── LibraryTab.swift                       # MODIFY: Add .scheduled tab case
│   └── FoodLibraryFilterOption.swift          # NEW: Filter enum for scheduled foods
└── App/
    └── AppServices.swift                      # MODIFY: Register FoodScheduleService
```

### Pattern 1: Swipe Action for Schedule (Follow Existing Patterns)

**What:** Add "Schedule" swipe action to food rows, following the Edit/Delete pattern already established.

**When to use:** For any food row in Food Library or search results.

**Example:**
```swift
// Source: FoodLibraryContentView.swift pattern
.swipeActions(edge: .leading, allowsFullSwipe: false) {
    Button("Edit") {
        editingCustomFood = food
    }
    .tint(.blue)
    .accessibilityIdentifier("edit-food-library-button")

    Button {
        scheduleFood = food
        showingScheduleSheet = true
    } label: {
        Label("Schedule", systemImage: "calendar.badge.plus")
    }
    .tint(.purple)
    .accessibilityIdentifier("schedule-food-library-button")
}
```

### Pattern 2: ScheduleConfigSheet Form (Follow DoseScheduleEditView)

**What:** A NavigationStack with Form for schedule configuration.

**When to use:** When user triggers schedule action from any entry point.

**Example:**
```swift
// Source: DoseScheduleEditView.swift pattern
struct ScheduleConfigSheet: View {
    let food: Food
    let scheduleService: FoodScheduleService
    let existingSchedule: FoodSchedule?
    let onComplete: () -> Void

    @State private var selectedDayMeals: Set<ScheduleDayMealConfig> = []
    @State private var servingGrams: Double = 100.0
    @State private var servingDescription: String = ""
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var isSaving = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                foodInfoSection       // Read-only food info
                dayMealGridSection    // Day/meal toggle grid
                servingSection        // Serving amount configuration
                dateRangeSection      // Optional start/end dates
            }
            .navigationTitle(existingSchedule == nil ? "Schedule Food" : "Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveSchedule() }
                        .disabled(!canSave || isSaving)
                }
            }
        }
    }
}
```

### Pattern 3: Day/Meal Toggle Grid

**What:** A visual grid for selecting which day/meal combinations to schedule.

**When to use:** As the primary configuration element in ScheduleConfigSheet.

**Example:**
```swift
// Source: Inspired by WeeklyConstants, MealSection patterns
struct ScheduleDayMealGrid: View {
    @Binding var selectedConfigs: Set<ScheduleDayMealConfig>

    private let days = ScheduleDay.allCases
    private let meals = MealSection.allCases

    var body: some View {
        VStack(spacing: 0) {
            // Header row with meal names
            HStack {
                Text("") // Empty corner
                    .frame(width: 50)
                ForEach(meals) { meal in
                    Text(meal.displayName.prefix(1))  // B, L, D, S
                        .font(.caption.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)

            // Day rows
            ForEach(days) { day in
                HStack {
                    Text(day.shortName)
                        .font(.caption)
                        .frame(width: 50, alignment: .leading)

                    ForEach(meals) { meal in
                        ToggleCell(
                            isSelected: isSelected(day: day, meal: meal),
                            onToggle: { toggle(day: day, meal: meal) }
                        )
                    }
                }
            }
        }
    }
}
```

### Pattern 4: FoodDetailSheet Schedule Status Display

**What:** Show schedule status and action button in FoodDetailSheet action buttons area.

**When to use:** When displaying a food that may have an active schedule.

**Example:**
```swift
// Source: FoodDetailSheet actionButtons pattern
private var actionButtons: some View {
    HStack(spacing: 16) {
        Button {
            showingCreateCustom = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "square.and.arrow.down")
                    .font(.title3)
                Text("To Custom")
                    .font(.caption)
            }
        }
        .buttonStyle(.bordered)

        // Schedule button - shows different state if already scheduled
        Button {
            scheduleFood = food
            showingScheduleSheet = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: hasSchedule ? "calendar.badge.checkmark" : "calendar.badge.plus")
                    .font(.title3)
                Text(hasSchedule ? "Scheduled" : "Schedule")
                    .font(.caption)
            }
        }
        .buttonStyle(.bordered)
        .tint(hasSchedule ? .green : nil)
        .accessibilityIdentifier("schedule-food-button")

        // ... existing Favorite button
    }
}
```

### Pattern 5: LibraryTab with Scheduled Filter

**What:** Extend LibraryTab enum with a "Scheduled" case for filtering.

**When to use:** In Food Library to show only foods with active schedules.

**Example:**
```swift
// Source: LibraryTab.swift extension
enum LibraryTab: String, CaseIterable {
    case recipes
    case foods
    case scheduled   // NEW: Filter for scheduled foods
    case favorites

    var displayName: String {
        switch self {
        case .recipes: return "Recipes"
        case .foods: return "Foods"
        case .scheduled: return "Scheduled"
        case .favorites: return "Favorites"
        }
    }

    var isEnabled: Bool {
        switch self {
        case .foods, .scheduled: return true  // Enable scheduled
        default: return false
        }
    }
}
```

### Anti-Patterns to Avoid

- **Adding swipe to non-custom foods in search without conversion awareness:** The schedule service auto-converts non-custom foods, but UI should indicate this will happen (e.g., "Will save to My Foods").

- **Presenting schedule sheet from FoodSearchResult directly:** FoodSearchResult is not a Food model. Use `foodService.createFood(from:)` or pass the FoodSearchResult and let the sheet handle conversion.

- **Hardcoding day/meal combinations:** Use `ScheduleDay.allCases` and `MealSection.allCases` for the grid to stay in sync with enum definitions.

- **Storing schedule UI state in FoodDetailSheet permanently:** Schedule status should be fetched when sheet appears, not stored in view state across sessions.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Food row display | Custom row layout | Existing `foodRowContent(_:)` pattern | Consistent styling, accessibility |
| Sheet presentation | Custom modal | `.sheet(isPresented:)` or `.sheet(item:)` | Standard iOS patterns, toolbar support |
| Day of week enum | Custom 0-6 enum | `ScheduleDay` from Phase 45 | Matches Calendar.component(.weekday) |
| Meal type enum | New enum | Existing `MealSection` | Already Codable, has icons/displayNames |
| Card styling | Custom backgrounds | `.cardStyle()` modifier | Design system consistency |
| Conditional view modifiers | Ternary in view | `.if()` extension | Cleaner view composition |

**Key insight:** The codebase has established patterns for every UI element needed. Follow `FoodLibraryContentView` for Food Library swipe, `FoodSearchSheet+Sections` for search swipe, `DoseScheduleEditView` for Form-based configuration, and `FoodDetailSheet` for action buttons.

## Common Pitfalls

### Pitfall 1: FoodSearchResult vs Food Model Confusion

**What goes wrong:** Trying to pass `FoodSearchResult` directly to `FoodScheduleService` which expects `Food`.

**Why it happens:** Search results and Food Library use different types. Search results are lightweight value types; Food is a SwiftData model.

**How to avoid:** When scheduling from search results, either:
1. Convert `FoodSearchResult` to `Food` using `foodService.createFood(from:)` before passing to schedule service
2. Have `ScheduleConfigSheet` accept both types via protocol or overloaded initializer

**Warning signs:** Type mismatch errors when calling `createOrUpdateSchedule`.

### Pitfall 2: Sheet Not Refreshing After Schedule Change

**What goes wrong:** FoodDetailSheet shows stale schedule status after editing schedule.

**Why it happens:** Schedule status is fetched on appear but not re-fetched after dismissing ScheduleConfigSheet.

**How to avoid:** Use `.task(id:)` or `.onChange(of:)` to refetch schedule status when returning from schedule sheet. Or pass a binding that updates.

**Warning signs:** "Schedule" button shows wrong state after saving/deleting schedule.

### Pitfall 3: Swipe Actions on Wrong Food Types

**What goes wrong:** Schedule swipe action appears on database foods (USDA, Open Food Facts) causing confusion about auto-conversion.

**Why it happens:** Not checking `food.isCustomFood` or `result.source` before showing swipe.

**How to avoid:** For custom foods, show "Schedule" swipe. For non-custom foods, either:
1. Show "Schedule" with indicator that it will create a custom copy, OR
2. Show "Schedule" swipe for all foods (service handles conversion)

**Recommendation:** Show for all foods (matches requirement SCHED-01, SCHED-02) since the service handles auto-conversion transparently.

**Warning signs:** Users confused why scheduling created a duplicate food.

### Pitfall 4: Day/Meal Grid State Management

**What goes wrong:** Grid selections don't persist or reflect existing schedule correctly.

**Why it happens:** Binding issues between `Set<ScheduleDayMealConfig>` and grid toggles, or not loading existing schedule on edit.

**How to avoid:**
1. Initialize grid state from `existingSchedule?.scheduleConfig?.dayMealConfigs`
2. Use `@Binding` for parent-child communication or `@State` with `.onChange` to sync

**Warning signs:** Existing schedules show empty grid when editing, or changes don't save.

## Code Examples

Verified patterns from official sources:

### AppServices Registration for FoodScheduleService

```swift
// Source: AppServices.swift pattern
/// Food schedule service for schedule CRUD operations
@Published private(set) var foodScheduleService: FoodScheduleService?

// In initialize(with:):
let foodScheduleService = FoodScheduleService(
    context: modelContext,
    customFoodService: customFoodService
)
self.foodScheduleService = foodScheduleService
```

### Checking Schedule Status for a Food

```swift
// Source: FoodScheduleService pattern
private func checkScheduleStatus(for foodId: UUID) async {
    guard let scheduleService = AppServices.shared.foodScheduleService else { return }
    do {
        let schedule = try await scheduleService.getSchedule(for: foodId)
        hasSchedule = schedule != nil && schedule!.isActive
        existingSchedule = schedule
    } catch {
        hasSchedule = false
        existingSchedule = nil
    }
}
```

### Converting FoodSearchResult to Food for Scheduling

```swift
// Source: FoodDetailSheet.saveFood() pattern
guard let foodService = AppServices.shared.foodService else { return }
let foodModel = foodService.createFood(from: searchResult)
// Now foodModel can be passed to scheduleService
```

### Schedule Config Validation

```swift
// Source: ScheduleConfig.isValid pattern
var canSave: Bool {
    // At least one day/meal selected
    !selectedDayMeals.isEmpty
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ObservableObject for sheets | @State local state | iOS 17+ | Simpler sheet state management |
| sheet(item:) always | sheet(isPresented:) for simple cases | Best practice | Cleaner when item is optional |
| Custom navigation | NavigationStack | iOS 16+ | Standard navigation patterns |

**Deprecated/outdated:**
- `ObservableObject` for simple sheet state - use `@State` instead
- `.navigationBarItems` - use `.toolbar` with `ToolbarItem`

## Open Questions

Things that couldn't be fully resolved:

1. **Swipe Action Positioning**
   - What we know: Existing swipe actions use trailing for Delete, leading for Edit
   - What's unclear: Whether Schedule should be trailing (after Delete) or leading (with Edit)
   - Recommendation: Add Schedule to leading swipe (with Edit) since it's a constructive action, not destructive. Order: Edit, Schedule

2. **FoodSearchResult Schedule Indicator**
   - What we know: FoodSearchResultRow shows source icon (star for custom)
   - What's unclear: How to indicate a food is scheduled in search results
   - Recommendation: Add subtle "calendar" badge overlay on source icon when food has active schedule, fetched asynchronously

3. **Schedule Status in Food Library Row**
   - What we know: Food Library rows show macros and serving info
   - What's unclear: Whether to show schedule status inline or rely on "Scheduled" tab filter
   - Recommendation: Add small calendar icon to row when food is scheduled; this provides discoverability before users know about the Scheduled tab

## Sources

### Primary (HIGH confidence)
- `/JabTracker/Views/Nutrition/FoodLibraryContentView.swift` - Swipe action patterns, food row layout
- `/JabTracker/Views/Nutrition/FoodSearchSheet+Sections.swift` - Search result swipe actions, conditional swipe
- `/JabTracker/Views/Nutrition/FoodDetailSheet.swift` - Action buttons section pattern
- `/JabTracker/Views/Settings/DoseScheduleEditView.swift` - Form-based schedule configuration
- `/JabTracker/Models/LibraryTab.swift` - Tab enum for Food Library
- `/JabTracker/Models/ScheduleConfiguration.swift` - ScheduleDay, ScheduleConfig types
- `/JabTracker/Services/FoodScheduleService.swift` - Schedule CRUD operations
- `/JabTracker/App/AppServices.swift` - Service registration pattern
- `/JabTracker/Extensions/View+Conditional.swift` - `.if()` conditional modifier

### Secondary (MEDIUM confidence)
- `/JabTracker/Design/CardComponents.swift` - Card styling modifiers
- `/JabTracker/Views/FoodLog/FoodLogView.swift` - Swipe actions on food entries

### Tertiary (LOW confidence)
- None - all patterns verified in codebase

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All patterns verified in existing codebase
- Architecture: HIGH - Following established swipe/sheet/form patterns
- Pitfalls: HIGH - Based on actual codebase structure and common SwiftUI issues

**Research date:** 2026-01-18
**Valid until:** 2026-02-18 (30 days - stable domain)
