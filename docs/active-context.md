# Complete Issue #260: Notification UI & Configuration

## Overview
Finish the remaining ~10% of Issue #260 with proper E2E testing for local notifications (no APNs needed for MVP). Optionally add remote config capability for future flexibility.

## Phase 1: Complete Remaining Implementation (2-3 hours)

### 1.1 Implement 4 Stubbed Onboarding E2E Tests (~1.5 hours)
**File:** `JabTrackerUITests/OnboardingNotificationFlowUITests.swift`

Implement these 4 tests using the same patterns as working deeplink tests:
- `testOnboardingActivatesNotificationsWhenPermissionGranted`
- `testOnboardingDoesNotActivateNotificationsWhenPermissionDenied`
- `testReminderTimingPersistsFromOnboardingToSettings`
- `testNotificationSettingsPersistAcrossAppRestarts`

**Approach:**
- Use launch arguments for test data seeding
- Follow debug-first methodology with `TestUtilities.debugElements()`
- Test notification activation logic (not actual delivery)
- Verify state persistence via UserDefaults

### 1.2 Implement QuickDoseSheet Navigation (~30 min)
**File:** `JabTracker/App/DeeplinkHandler.swift`

Current code logs only - need to implement actual navigation:
```swift
case .logDose(let scheduledDoseId):
    logger.info("Should navigate to QuickDoseSheet for dose: \(scheduledDoseId)")
    // TODO: Implement navigation
```

**Implementation:**
- Trigger QuickDoseSheet presentation
- Pre-populate with scheduled dose data
- Handle navigation from terminated/background/foreground states

## Phase 2: E2E Testing Strategy (1 hour)

### 2.1 Run Stream A E2E Tests
```bash
./scripts/test.sh ui 1 NotificationSettingsUITests
```
Verify all 8 settings UI tests pass.

### 2.2 E2E Local Notification Testing Approach

**What We CAN Test (Simulators + Devices):**
✅ Authorization flow and permission states
✅ Notification scheduling logic (queue management)
✅ Notification action handling (Take/Skip/Snooze callbacks)
✅ Deeplink handling from notifications
✅ Badge count updates
✅ Settings UI state management

**What We CANNOT Fully Test (Simulators):**
- Actual notification delivery timing
- Real notification banner appearance
- Actual notification sounds/vibrations

**Testing Strategy:**
1. **Unit Tests** - Verify NotificationService methods work correctly
2. **E2E Tests** - Verify UI flows for enabling/configuring notifications
3. **Manual Device Testing** - Verify actual notification delivery (30-min session)

### 2.3 Manual Testing Checklist
**On Physical Device:**
- [ ] Enable notifications in settings
- [ ] Wait for scheduled notification to fire
- [ ] Tap "Take" action - verify dose logged
- [ ] Tap "Skip" action - verify dose skipped
- [ ] Tap notification body - verify app opens to QuickDoseSheet
- [ ] Test from terminated/background/foreground states
- [ ] Verify badge count updates correctly

## Phase 3: Quality Checks (30 min)

```bash
# Full test suite
./scripts/test.sh unit 1

# All notification E2E tests
./scripts/test.sh ui 1 NotificationSettingsUITests
./scripts/test.sh ui 1 NotificationDeeplinkUITests  
./scripts/test.sh ui 1 OnboardingNotificationFlowUITests

# Pre-merge checks
./scripts/check-all.sh --skip-ui
```

## Phase 4: Merge to Main (15 min)

```bash
/pm:pr-merge 313
```

This will:
- Mark PR ready for review
- Merge to main
- Close Issue #260
- Update epic progress
- Process final learnings

---

## OPTIONAL: Remote Config Enhancement (2-3 hours)

**Note:** This is NOT required for Issue #260 completion. Recommend creating separate issue if desired.

### Benefits:
- Update notification timing/messages without app update
- Feature flags for gradual rollout
- A/B testing capabilities
- Instant rollback if issues found

### Implementation:
1. Create `RemoteNotificationConfig` struct
2. Add config fetching on app launch
3. Cache locally with fallback to defaults
4. Host config on GitHub or CloudFlare
5. Update NotificationService to use remote values

### Files to Create:
- `JabTracker/Services/ConfigManager.swift`
- `JabTracker/Models/RemoteNotificationConfig.swift`
- External: `notification-config.json` (hosted on GitHub/CDN)

**Effort:** 2-3 hours additional work

---

## Summary

**Total Effort:** 4-5 hours (without remote config) or 6-8 hours (with remote config)

**Deliverables:**
1. ✅ 4 onboarding E2E tests implemented and passing
2. ✅ QuickDoseSheet navigation working from deeplinks
3. ✅ All E2E tests verified (17+ notification tests total)
4. ✅ Manual device testing completed
5. ✅ PR merged to main
6. ⚠️ Remote config (optional, separate issue recommended)

**Recommendation:** 
- Complete Phase 1-4 to finish Issue #260
- Create separate issue for remote config enhancement
- Focus on shipping MVP with local notifications first