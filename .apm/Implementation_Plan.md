# MacroKinetic v0.4.0 Calorie Expenditure Enhancements – APM Implementation Plan
**Memory Strategy:** Dynamic-MD
**Last Modification:** Plan creation by the Setup Agent.
**Project Overview:** Implement calorie expenditure enhancements for MacroKinetic iOS app, including: (1) Add burned calories from HealthKit back to daily targets in real-time, (2) Rollover up to 200 unused calories to next day, (3) Predictive activity adjustment based on historical trends integrated with weekly check-in. Features require HealthKit activeEnergyBurned integration, new User model preferences with CloudKit sync, CalorieAdjustmentService for layered calculation, and UI updates to CalorieExpenditureView and NutritionSummaryCard.

## Phase 1: HealthKit Active Energy Integration

### Task 1.1 – Expand HealthKit Authorization - Agent_HealthKit
**Objective:** Add activeEnergyBurned to HealthKit authorization request.
**Output:** Updated MetricsService+HealthKit with expanded authorization types.
**Guidance:** Follow existing authorization pattern. Only add read permission (no write needed for energy).

- Add `activeEnergyType = HKQuantityType(.activeEnergyBurned)` constant to MetricsService+HealthKit
- Add `activeEnergyType` to `allReadTypes` set for authorization request
- Write unit test verifying authorization includes activeEnergyBurned

### Task 1.2 – Add Active Energy Query Methods - Agent_HealthKit
**Objective:** Create methods to query activeEnergyBurned from HealthKit.
**Output:** Query methods for today's total and historical daily totals.
**Guidance:** Follow TDD. Use HKStatisticsQuery for cumulative sums. **Depends on: Task 1.1 Output**

1. Write unit tests for `getTodayActiveEnergy()` and `getActiveEnergyForDate(_:)` using mock HealthKit
2. Implement `getTodayActiveEnergy() async -> Double?` returning today's cumulative activeEnergyBurned in kcal
3. Implement `getActiveEnergyHistory(days: Int) async -> [Date: Double]` returning daily totals for past N days
4. Verify build succeeds and all tests pass

### Task 1.3 – Implement Real-time Energy Observation - Agent_HealthKit
**Objective:** Set up HKObserverQuery for real-time activeEnergyBurned updates.
**Output:** Observation mechanism with start/stop lifecycle management.
**Guidance:** Use HKObserverQuery pattern. Store query reference for cancellation. **Depends on: Task 1.1 Output**

1. Create `startActiveEnergyObservation(handler: @escaping (Double) -> Void)` method using HKObserverQuery
2. Enable background delivery for activeEnergyBurned type to receive updates when app is backgrounded
3. Implement query callback that fetches fresh total via `getTodayActiveEnergy()` (from Task 1.2) and invokes handler
4. Add `stopActiveEnergyObservation()` method for cleanup and store query reference for cancellation
5. Write integration test verifying observation lifecycle (start, receive update, stop)

### Task 1.4 – Add User Preference Properties - Agent_Logic
**Objective:** Add 3 expenditure preference properties to User model.
**Output:** Updated User.swift with CloudKit-compatible boolean properties.
**Guidance:** Follow existing property patterns. All booleans default to false. Run xcodegen after.

- Add `addBurnedCaloriesEnabled: Bool = false`, `predictiveActivityEnabled: Bool = false`, `rolloverCaloriesEnabled: Bool = false` to User model
- Add `predictedActivityBonus: Double = 0` property for storing weekly calculated prediction
- Update User initializer to include new properties with defaults
- Write unit test verifying property persistence and CloudKit compatibility
- Run `xcodegen generate` if new test files created

## Phase 2: Add Burned Calories Feature

### Task 2.1 – Create CalorieAdjustmentService - Agent_Logic
**Objective:** Create core service for calculating adjusted calorie targets.
**Output:** CalorieAdjustmentService.swift with tested burned calorie calculation.
**Guidance:** Follow TDD. Service should be @MainActor. Inject MetricsService for HealthKit data.

1. Write unit tests for CalorieAdjustmentService `getAdjustedCalorieTarget(for:on:baseTarget:)` method with mock data
2. Create CalorieAdjustmentService.swift with @MainActor annotation following existing service patterns
3. Inject MetricsService+HealthKit for burned calorie retrieval
4. Implement `getAdjustedCalorieTarget(for user: User, on date: Date, baseTarget: Double) async -> Double` returning baseTarget + burnedCalories when `user.addBurnedCaloriesEnabled` is true (baseTarget typically from NutritionProgram)
5. Verify tests pass and build succeeds; run `xcodegen generate`

### Task 2.2 – Wire CalorieExpenditureView - Agent_UI
**Objective:** Connect placeholder CalorieExpenditureView to User preferences.
**Output:** Functional settings view with toggles bound to User model.
**Guidance:** Disable toggles when healthSyncEnabled is false (per mockup). **Depends on: Task 1.4 Output by Agent_Logic**

1. Add `@Query` for User and inject into CalorieExpenditureView
2. Replace local @State with bindings to User properties (addBurnedCaloriesEnabled, etc.)
3. Add conditional `.disabled(!user.healthSyncEnabled)` and helper text when Health sync is off
4. Verify toggles persist correctly and disable state matches mockup

### Task 2.3 – Update NutritionSummaryCard - Agent_UI
**Objective:** Display adjusted calorie targets when Add Burned Calories is enabled.
**Output:** Updated dashboard card with adjusted target and visual indicator.
**Guidance:** Use subtle indicator (flame icon or "+X burned" label). **Depends on: Task 2.1 Output by Agent_Logic, Task 1.3 Output by Agent_HealthKit**

1. Inject CalorieAdjustmentService into NutritionSummaryCard's ViewModel (follow existing service injection patterns)
2. Subscribe to real-time energy observation updates and fetch adjusted calorie target when `user.addBurnedCaloriesEnabled` is true
3. Add subtle visual indicator (e.g., small flame icon or "+X burned" label) next to calorie target when adjustment is active
4. Write unit test for ViewModel verifying adjusted target display logic and observation subscription

### Task 2.4 – E2E Test Implementation - Agent_UI
**Objective:** Implement E2E tests for Add Burned Calories feature.
**Output:** CalorieExpenditureUITests.swift with complete feature coverage.
**Guidance:** Follow existing E2E patterns. Stub HealthKit data for tests. **Depends on: Task 2.2 Output, Task 2.3 Output**

- Create CalorieExpenditureUITests.swift following existing E2E patterns
- Test: Navigate to More > Calorie Expenditure, verify toggles visible and initially disabled
- Test: Toggle Add Burned Calories on (if Health sync enabled stub), verify setting persists
- Test: Verify NutritionSummaryCard reflects adjusted target (use MockHealthStore from existing test patterns)

## Phase 3: Rollover Calories Feature

### Task 3.1 – Implement Rollover Calculation - Agent_Logic
**Objective:** Create rollover calculation logic with 200 calorie cap.
**Output:** Tested calculation method for yesterday's unused calories.
**Guidance:** Cap at 200, never negative. Use existing MealLogService for yesterday's consumption.

1. Write unit tests for `calculateRolloverCalories(yesterdayTarget:yesterdayConsumed:)` with edge cases (over, under, negative)
2. Implement calculation: `max(0, min(yesterdayTarget - yesterdayConsumed, 200))`
3. Add method to retrieve yesterday's consumption from existing FoodEntry/MealLogService queries
4. Verify tests pass with correct cap behavior (never exceeds 200, never negative)

### Task 3.2 – Extend CalorieAdjustmentService for Rollover - Agent_Logic
**Objective:** Integrate rollover into layered calorie calculation.
**Output:** Updated CalorieAdjustmentService with rollover layer.
**Guidance:** Layered: base + burned (if enabled) + rollover (if enabled). **Depends on: Task 3.1 Output, Task 2.1 Output**

1. Write unit tests for adjusted target including rollover (base + burned + rollover)
2. Add `getRolloverCalories(for user: User, on date: Date) async -> Double` method using Task 3.1 calculation
3. Update `getAdjustedCalorieTarget` to add rollover when `user.rolloverCaloriesEnabled` is true
4. Verify layered calculation: base + burnedCalories (if enabled) + rollover (if enabled)

### Task 3.3 – Update UI for Rollover Display - Agent_UI
**Objective:** Add rollover display to NutritionSummaryCard.
**Output:** Updated UI with rollover indicator when applicable.
**Guidance:** Consistent style with burned calories indicator. **Depends on: Task 3.2 Output by Agent_Logic**

- Add rollover amount display to NutritionSummaryCard when `rolloverCaloriesEnabled` and rollover > 0
- Use subtle label (e.g., "+X rollover" below calorie target) consistent with burned calories indicator style
- Write unit test for ViewModel verifying rollover display logic

### Task 3.4 – E2E Test Rollover Feature - Agent_UI
**Objective:** Extend E2E tests for rollover feature coverage.
**Output:** Updated CalorieExpenditureUITests with rollover tests.
**Guidance:** Seed test data for yesterday to verify rollover calculation. **Depends on: Task 3.3 Output**

- Add test: Toggle Rollover Calories on, verify setting persists
- Add test: Seed yesterday's food data below target using `--seed-test-data` launch argument, verify rollover appears in today's target
- Add test: Seed yesterday's food data above target, verify rollover is 0

## Phase 4: Predictive Activity Adjustment

### Task 4.1 – Implement Activity Prediction Algorithm - Agent_Logic
**Objective:** Create prediction algorithm with goal-mode multipliers.
**Output:** Tested prediction calculation using 7-day activity average.
**Guidance:** Multipliers: 0.8 (loss), 1.0 (maintenance), 1.2 (gain). Handle < 7 days gracefully. **Depends on: Task 1.2 Output by Agent_HealthKit**

1. Write unit tests for `calculatePredictedActivityCalories(history:goalType:)` covering all goal modes
2. Implement 7-day average calculation using `getActiveEnergyHistory(days: 7)` from Task 1.2
3. Apply goal-mode multipliers: 0.8 for `weightLoss`, 1.0 for `maintenance`, 1.2 for `weightGain` (verify these match existing NutritionGoal.goalType enum values)
4. Handle edge cases: fewer than 7 days of data (use available average), no data (return 0)
5. Verify tests pass for all goal mode scenarios

### Task 4.2 – Integrate with Weekly Check-in - Agent_Logic
**Objective:** Integrate prediction calculation into weekly check-in flow.
**Output:** Updated WeeklyCheckInService and ProgramOptimizationSheet.
**Guidance:** Store prediction on User model. Recalculate when check-in completes. **Depends on: Task 4.1 Output**

1. Add `recalculatePredictedActivity(for user: User)` method to WeeklyCheckInService using Task 4.1 algorithm
2. Update `user.predictedActivityBonus` with calculated prediction (property added in Task 1.4)
3. Call prediction recalculation in ProgramOptimizationSheet after weight update confirmation but before summary display
4. Write unit test verifying prediction is recalculated during check-in flow

### Task 4.3 – Extend CalorieAdjustmentService for Predictive - Agent_Logic
**Objective:** Add predictive activity bonus to layered calculation.
**Output:** Updated CalorieAdjustmentService with predictive layer.
**Guidance:** Layered: base + burned + rollover + predictive. **Depends on: Task 4.2 Output, Task 3.2 Output**

1. Write unit tests for adjusted target including predictive bonus (base + burned + rollover + predictive)
2. Update `getAdjustedCalorieTarget` to add `user.predictedActivityBonus` when `user.predictiveActivityEnabled` is true
3. Verify correct calculation order: base + real-time burned + rollover + weekly predictive

### Task 4.4 – Update UI for Predictive Display - Agent_UI
**Objective:** Add predictive activity display to NutritionSummaryCard.
**Output:** Updated UI with predictive indicator when applicable.
**Guidance:** Consistent style with other adjustment indicators. **Depends on: Task 4.3 Output by Agent_Logic**

- Add predictive activity display to NutritionSummaryCard when `predictiveActivityEnabled` and bonus > 0
- Use label style consistent with burned/rollover (e.g., "+X predicted" or activity icon)
- Write unit test for ViewModel verifying predictive display logic

### Task 4.5 – E2E Test Predictive Feature - Agent_UI
**Objective:** Extend E2E tests for predictive activity feature.
**Output:** Updated CalorieExpenditureUITests with predictive tests.
**Guidance:** Seed historical activity data and verify check-in recalculates. **Depends on: Task 4.4 Output**

- Add test: Toggle Predictive Activity on, verify setting persists
- Add test: Mock 7 days of activity history using MockHealthStore, trigger check-in flow, verify prediction is calculated and stored
- Add test: Verify NutritionSummaryCard shows predictive bonus after check-in completes
