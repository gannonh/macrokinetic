# Task 2.2 - Wire CalorieExpenditureView

## ID
Task 2.2

## Status
Completed

## Context
This task involved wiring the `CalorieExpenditureView` to the `User` model, replacing placeholder mock data with real SwiftData bindings. This UI determines how the app handles active energy, specifically whether to add burned calories back to the daily target and whether to use predictive adjustments.

## Decisions Made
- **SwiftData Source of Truth**: Used `@Query` to fetch the `User` object directly in the view. Since the app is single-user focused, we take the first user from the array.
- **Conditional Logic**: Implemented `disabled` states for "Add Burned Calories" and "Predictive Activity Adjustment" toggles. These are forcibly disabled if `healthSyncEnabled` is false on the user model.
- **Feedback**: Added footer text to explain *why* the toggles are disabled (requires Health Sync), improving UX.
- **Mocking**: Updated the `#Preview` provider to inject an in-memory `ModelContainer` with a sample `User` to ensure the preview works correctly without crashing.

## Outcomes
- `CalorieExpenditureView.swift` is now fully functional and bound to the persistent `User` model.
- Settings changes (toggles) persist immediately to the model.
- Build verified successfully.

## Verification
- **Build**: `./scripts/build.sh` passed.
- **Logic**: Reviewed strict dependency on `healthSyncEnabled` for dependent features.
