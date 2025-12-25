# Phase 9: Weight Tracking - Discovery

**Date:** 2025-12-25
**Depth:** Level 2 (Standard Research)

## Research Summary

### HealthKit Integration

**Authorization:**
- Already configured in entitlements (`JabTracker.entitlements:19-20`)
- Already requested in `OnboardingViewModel.swift:195-232` for `bodyMass` and `bodyMassIndex`
- Info.plist privacy descriptions already in place

**Key Patterns:**
```swift
// Write weight to HealthKit
let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
let sample = HKQuantitySample(type: weightType, quantity: weightQuantity, start: date, end: date)
try await healthStore.save(sample)

// Write body fat
let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
let bodyFatQuantity = HKQuantity(unit: .percent(), doubleValue: percentage / 100.0)
let sample = HKQuantitySample(type: bodyFatType, quantity: bodyFatQuantity, start: date, end: date)
try await healthStore.save(sample)
```

**Common Pitfalls to Avoid:**
1. Authorization result only indicates dialog was shown, not permission granted
2. Cannot check read authorization status (Apple privacy protection)
3. Must check `HKHealthStore.isHealthDataAvailable()` before any operations
4. Graceful degradation when HealthKit unavailable (simulator, denied)

### Existing Codebase Patterns

**User Model:**
- Has `weight: Double = 70.0` and `weightUnit: String = "kg"` (lines 15-16)
- Used for PK calculations, needs to be updated with latest weight

**Entry Model Pattern (FoodEntry):**
- No User relationship (query by date)
- Denormalized snapshot for time-series data
- CloudKit-compatible defaults on all properties

**Service Pattern (MealLogService):**
- `@MainActor final class` with ModelContext dependency
- Extension files for domain-specific logic
- OSLog logging with category-specific logger

**Sheet Pattern (QuickAddContentView):**
- Uses `@State` for form fields
- Validation via computed properties
- Parent passes dependencies and completion handlers

### Architecture Decision

**Approach:** Pragmatic Balance
- WeightEntry model (matches FoodEntry pattern)
- WeightService with HealthKit extension
- QuickWeightSheet for entry UI
- Write-to-HealthKit immediately, read/import deferred

**Rationale:**
1. Ships quickly with room for extension
2. Extension pattern isolates HealthKit complexity
3. Matches existing codebase conventions
4. Good test coverage possible

## Sources

- Apple HealthKit Documentation
- Existing codebase: OnboardingViewModel.swift, FoodEntry.swift, MealLogService.swift
- Context7 HealthKit patterns research
