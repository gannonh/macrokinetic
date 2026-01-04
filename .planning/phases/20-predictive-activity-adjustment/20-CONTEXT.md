# Phase 20: Predictive Activity Adjustment - Context

**Created:** 2026-01-03T22:40:42Z
**Purpose:** Pre-planning context for Phase 20 implementation

## Roadmap Goal

Apply 7-day activity average with goal-mode multipliers (0.8/1.0/1.2) during weekly check-in.

## Architecture Foundation (from Phase 19)

Phase 19 established a **CalorieAdjustmentProvider** protocol-based pipeline in `CalorieAdjustmentService+Adjustments.swift`. This makes adding predictive activity adjustment straightforward.

### Existing Pipeline Structure

```swift
// Protocol established in Phase 19
protocol CalorieAdjustmentProvider: Sendable {
    func calculateAdjustment(for user: User, on date: Date) async -> Double
}

// Implementations:
// 1. Burned calories (existing in CalorieAdjustmentService)
// 2. RolloverCalorieProvider (Phase 19)
// 3. PredictiveActivityProvider (Phase 20 - to be added)
```

## Implementation Approach

### Step 1: Create PredictiveActivityProvider

Add to `CalorieAdjustmentService+Adjustments.swift`:

```swift
@MainActor
final class PredictiveActivityProvider: CalorieAdjustmentProvider {
    private let activeEnergyDataSource: ActiveEnergyDataSource

    func calculateAdjustment(for user: User, on date: Date) async -> Double {
        guard user.predictiveActivityEnabled else { return 0.0 }

        // 1. Get 7-day activity history
        let history = await activeEnergyDataSource.getActiveEnergyHistory(days: 7)

        // 2. Calculate average
        let average = history.values.reduce(0, +) / Double(max(history.count, 1))

        // 3. Apply goal-mode multiplier
        let multiplier = getGoalMultiplier(for: user)

        // 4. Return predicted bonus
        return average * multiplier
    }

    private func getGoalMultiplier(for user: User) -> Double {
        // Based on user's goal mode:
        // - Cutting (aggressive): 0.8 (conservative prediction)
        // - Maintenance: 1.0 (actual average)
        // - Bulking: 1.2 (slightly more calories for activity)
        switch user.activeNutritionGoal?.goalMode {
        case .cutting: return 0.8
        case .maintenance: return 1.0
        case .bulking: return 1.2
        default: return 1.0
        }
    }
}
```

### Step 2: Wire into CalorieAdjustmentService

```swift
// Add property
private var predictiveProvider: PredictiveActivityProvider?

// Add configuration
func configurePredictiveProvider(activeEnergyDataSource: ActiveEnergyDataSource) {
    self.predictiveProvider = PredictiveActivityProvider(
        activeEnergyDataSource: activeEnergyDataSource
    )
}

// Add to getAdjustedCalorieTarget()
if let predictive = predictiveProvider {
    adjusted += await predictive.calculateAdjustment(for: user, on: date)
}
```

### Step 3: Weekly Check-In Integration

The roadmap mentions "during weekly check-in". This likely means:
- Store `predictedActivityBonus` in User model (already exists: `user.predictedActivityBonus`)
- Update it during weekly check-in flow (WeeklyCheckInService)
- Option A: Recalculate on each view load (real-time)
- Option B: Calculate once per week, store in User model (batch)

**Decision needed:** Real-time vs batch calculation approach.

## Existing Properties (User.swift)

```swift
var predictiveActivityEnabled: Bool = false  // Toggle exists
var predictedActivityBonus: Double = 0.0     // Storage for bonus
```

## Existing Data Source

`MetricsService+HealthKit.swift` already has:
```swift
func getActiveEnergyHistory(days: Int) async -> [Date: Double]
```

This is exposed via `ActiveEnergyDataSource` protocol.

## Testing Strategy

1. **Unit tests for PredictiveActivityProvider:**
   - Test returns 0 when disabled
   - Test calculates 7-day average correctly
   - Test applies multipliers (0.8, 1.0, 1.2) based on goal mode
   - Test handles empty history gracefully

2. **E2E tests:**
   - Toggle predictive activity setting
   - Verify target adjustment with mock activity data
   - Verify multiplier application

## Key Decisions for Phase 20 Planning

1. **Calculation timing:** Real-time on each view load vs. once-per-week during check-in?
2. **Goal mode source:** From NutritionGoal.goalMode or User preference?
3. **History window:** Fixed 7 days or configurable?
4. **Rounding:** Round bonus to nearest integer or keep decimals?

## Files to Create/Modify

### Create:
- `JabTrackerTests/Services/PredictiveActivityProviderTests.swift`

### Modify:
- `JabTracker/Services/CalorieAdjustmentService+Adjustments.swift` (add provider)
- `JabTracker/Services/CalorieAdjustmentService.swift` (wire up provider)
- `JabTrackerUITests/PredictiveActivityUITests.swift` (E2E stubs)

## Estimated Scope

- **Tasks:** 3 (create provider, integrate, test)
- **Complexity:** Simple (follows Phase 19 pattern exactly)
- **Duration:** ~1-2 hours (pipeline already exists)

## Dependencies

- Phase 19 must be complete (pipeline infrastructure)
- ActiveEnergyDataSource must support `getActiveEnergyHistory(days:)`

---

*This context file ensures Phase 20 can be planned quickly by leveraging the foundation from Phase 19.*
