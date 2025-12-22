# Codebase Concerns

**Analysis Date:** 2025-12-22

## Tech Debt

**Incomplete split-dose UI:**
- Issue: Settings UI missing second time picker for split-dose schedules
- File: `JabTracker/Views/Settings/DoseScheduleEditView.swift:368`
- Why: Deferred to Phase 3 during initial implementation
- Impact: Users can't configure split-dose medications via UI
- Fix approach: Add second time picker, connect to `ScheduleConfiguration.secondTimeOfDay`

**Incomplete background task scheduling:**
- Issue: BGTaskScheduler registration is a placeholder (no-op)
- File: `JabTracker/Services/NotificationService+Background.swift:21`
- Why: Deferred during notification system implementation
- Impact: Notification queue doesn't refresh when app is backgrounded
- Fix approach: Implement BGTaskScheduler.register() and scheduling

**Duplicate food deduplication logic:**
- Issue: Food deduplication implemented in two places
- Files: `JabTracker/Services/FoodService.swift:223-230`, `JabTracker/ViewModels/FoodSearchSheetViewModel.swift`
- Why: Evolved organically during nutrition feature development
- Impact: Maintenance burden, potential inconsistencies
- Fix approach: Consolidate into FoodService, remove from ViewModel

## Known Bugs

**None critical identified during analysis.**

Minor issues:
- Regex parsing for serving descriptions may fail silently on malformed data
- File: `JabTracker/Views/Nutrition/EditFoodEntrySheet.swift:53-59`
- Workaround: Falls back to `entry.servingGrams`
- Root cause: No logging when parse fails

## Security Considerations

**URL construction without encoding:**
- Risk: Barcode directly interpolated into URL path
- File: `JabTracker/Services/OpenFoodFactsService.swift:88`
- Current mitigation: Barcode trimmed of whitespace only
- Recommendations: Use proper URL encoding for barcode parameter

**No rate limiting on API calls:**
- Risk: Excessive API calls if user types quickly in search
- File: `JabTracker/Services/OpenFoodFactsService.swift`
- Current mitigation: None
- Recommendations: Add debounce/throttle to search, or implement at service level

## Performance Bottlenecks

**Regex compilation on every parse:**
- Problem: Serving option regex compiled for each food item
- File: `JabTracker/Services/FoodService.swift:132`
- Measurement: Not measured, but called per-item in search results
- Cause: Regex pattern `#"^([\d.]+)\s*(\w+)\s*\((\d+(?:\.\d+)?)g\)$"#` created inline
- Improvement path: Compile once as static property

## Fragile Areas

**Fatal errors in production paths:**
- Files with `fatalError`:
  - `JabTracker/DataController.swift:130` - ModelContainer creation failure
  - `JabTracker/Views/Nutrition/FoodSearchSheet.swift:56` - Missing service injection
  - `JabTracker/AuthenticationManager.swift:614` - No window for Sign in with Apple
- Why fragile: App crashes immediately instead of graceful error handling
- Common failures: Missing dependencies, unusual device states
- Safe modification: Replace with error states or fallback behavior
- Test coverage: Not tested (fatalError paths untestable)

**Bidirectional macro calculation:**
- File: `JabTracker/Views/Nutrition/FoodDetailSheet.swift`
- Why fragile: Complex state transitions between quantity and target modes
- Common failures: Values reset unexpectedly when switching modes
- Safe modification: Read system-patterns.md section on bidirectional calculation
- Test coverage: E2E tests cover happy path, unit tests limited

## Scaling Limits

**Local food database:**
- Current capacity: 1.7M+ foods, 382 MB
- Limit: Memory pressure on older devices during large result sets
- Symptoms at limit: App may be terminated by iOS memory pressure
- Scaling path: Pagination in FTS5 queries (already has LIMIT)

## Dependencies at Risk

**None identified.**
- Project uses only Apple frameworks (no third-party dependencies)
- All frameworks are actively maintained by Apple

## Missing Critical Features

**Error tracking/crash reporting:**
- Problem: No Sentry, Crashlytics, or similar service
- Current workaround: OSLog only (requires device access)
- Blocks: Production issue investigation, crash analysis
- Implementation complexity: Low (add Sentry SDK)

**Analytics:**
- Problem: No usage analytics or feature tracking
- Current workaround: None
- Blocks: Understanding user behavior, feature prioritization
- Implementation complexity: Low (add analytics SDK)

## Test Coverage Gaps

**FoodSearchSheet initialization errors:**
- What's not tested: fatalError path when services are nil
- Risk: Crash in production if injection fails
- Priority: High
- Difficulty to test: Cannot test fatalError in unit tests

**LocalFoodDatabase missing bundle:**
- What's not tested: Behavior when bundled SQLite file is missing
- Risk: Silent failure, empty search results
- Priority: Medium
- Difficulty to test: Would need to modify bundle in test

**Service error propagation:**
- What's not tested: OpenFoodFacts API errors distinguishable from empty results
- Risk: User can't tell if search failed vs no results
- Priority: Medium
- Difficulty to test: Need to inject URLSession mock

---

## Summary by Priority

**Critical (must fix before release):**
1. Replace `fatalError` in `DataController.swift:130` with graceful error handling
2. Replace `fatalError` in `FoodSearchSheet.swift:56` with optional service pattern
3. Replace `fatalError` in `AuthenticationManager.swift:614` with error state

**High Priority:**
1. Implement BGTaskScheduler for background notification refresh
2. Add URL encoding for barcode API calls
3. Add error/crash reporting service

**Medium Priority:**
1. Complete split-dose UI (Phase 3 TODO)
2. Consolidate food deduplication logic
3. Add rate limiting to food search
4. Static regex compilation for performance

---

*Concerns audit: 2025-12-22*
*Update as issues are fixed or new ones discovered*
