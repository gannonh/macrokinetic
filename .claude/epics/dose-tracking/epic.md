---
name: dose-tracking
status: completed
created: 2025-09-11T17:34:41Z
progress: 100%
updated: 2025-09-21T18:10:06Z
last_sync: 2025-09-21T20:45:38Z
prd: .claude/prds/dose-tracking.md
github: https://github.com/gannonh/jab-tracker-ios/issues/37
---

# Epic: Dose Tracking

## Overview
Implement a streamlined dose tracking system that leverages existing SwiftData models and UI components to enable quick dose logging, comprehensive history management, and seamless integration with the pharmacokinetics engine. The implementation focuses on reusing existing infrastructure while adding minimal new code for maximum efficiency.

## Architecture Decisions

### Key Technical Decisions
- **Leverage existing Dose model**: Already defined in SwiftData with all required fields
- **Reuse MedicationFormComponents**: Adapt existing form components for dose entry
- **Extend DataController**: Add dose-specific operations to existing persistence layer
- **Use existing design system**: All UI components already in DesignTokens
- **Progressive disclosure**: Start with quick-add, expand to detailed form only when needed

### Technology Choices
- **SwiftData**: Already configured with CloudKit sync and relationships
- **PhotosUI**: Built-in iOS framework for photo attachments
- **SwiftUI List**: Native swipe actions and search capabilities
- **FSCalendar alternative**: Use native SwiftUI calendar with overlay indicators

### Design Patterns
- **MVVM**: Single DoseViewModel managing all dose operations
- **Repository pattern**: DataController handles all persistence
- **Observer pattern**: @Published properties for real-time updates
- **Builder pattern**: Smart defaults from medication profiles

## Technical Approach

### Frontend Components
**Reuse Existing Components:**
- `PrimaryButton` for quick-add dose button
- `SecondaryButton` for form actions
- `DesignCard` for dose history items
- Existing form fields from MedicationFormComponents

**New Components (Minimal):**
- `QuickDoseButton`: Thin wrapper around PrimaryButton with dose logic
- `DoseEntrySheet`: Reuses MedicationFormComponents with dose-specific fields
- `DoseHistoryRow`: Styled row with swipe actions
- `DoseCalendarView`: Native calendar with dose indicators

### Backend Services
**Extend Existing Services:**
- `DataController`: Add `saveDose()`, `updateDose()`, `deleteDose()`, `fetchDoses()`
- `MedicationManager`: Add `getDefaultDoseAmount()`, `getNextInjectionSite()`

**New Services (Minimal):**
- `DoseValidation`: Simple validation rules for doses
- `DoseDefaults`: Smart default generation from history

### Infrastructure
- No new infrastructure needed
- CloudKit sync already configured
- SwiftData relationships already defined
- Notification system exists

## Implementation Strategy

### Development Phases
**Phase 1: Core Data Layer (2 days)**
- Extend DataController with dose operations
- Add dose validation logic
- Implement smart defaults

**Phase 2: Quick Entry (2 days)**
- Dashboard quick-add button
- One-tap dose logging
- Success feedback with undo

**Phase 3: Detailed Entry (2 days)**
- Dose entry form sheet
- Photo attachment support
- Notes and injection site

**Phase 4: History Views (3 days)**
- List view with swipe actions
- Search and filter
- Calendar view overlay

**Phase 5: Integration (1 day)**
- Connect to pharmacokinetics engine
- Update dashboard after logging
- Notification reset logic

### Risk Mitigation
- Start with quick-add for immediate value
- Test SwiftData operations thoroughly
- Implement undo for all destructive actions
- Cache recent doses for offline resilience

### Testing Approach
- Unit tests for validation logic
- Integration tests for DataController
- UI tests for critical user flows
- Manual testing for photo attachments

## Task Breakdown Preview

High-level task categories that will be created:
- [ ] **Data Layer Extensions**: Extend DataController with dose CRUD operations and validation
- [ ] **Quick Dose Entry**: Implement dashboard button with one-tap logging and smart defaults
- [ ] **Dose Entry Form**: Create detailed entry sheet reusing existing form components
- [ ] **History List View**: Build searchable list with swipe actions for edit/delete
- [ ] **Calendar Integration**: Add calendar view with dose indicators and statistics
- [ ] **Photo Attachments**: Implement PhotosUI integration with size limits
- [ ] **Search & Filters**: Add search bar and filter options to history view
- [ ] **PK Engine Integration**: Connect dose logging to pharmacokinetics calculations
- [ ] **Testing Suite**: Comprehensive unit and UI tests for all dose operations

## Dependencies

### Internal Dependencies
- ✅ **Medication Profile Management**: Already complete with full CRUD
- ✅ **Authentication System**: Sign in with Apple implemented
- ✅ **SwiftData Models**: Dose model already defined
- ✅ **Design System**: All components available
- ⏳ **Pharmacokinetic Engine**: Can be integrated later

### External Dependencies
- **PhotosUI**: Standard iOS framework (no setup needed)
- **UserNotifications**: Already configured for app
- **CloudKit**: Already integrated with DataController

### Prerequisite Work
- None - all prerequisites completed

## Success Criteria (Technical)

### Performance Benchmarks
- Quick dose logging < 2 seconds end-to-end
- History view loads < 500ms for 1000 entries
- Search responds < 200ms
- Zero data loss in offline mode

### Quality Gates
- 90% unit test coverage for dose logic
- All UI tests passing
- No memory leaks in photo handling
- VoiceOver fully functional

### Acceptance Criteria
- User can log dose in 2 taps
- All doses persist to SwiftData immediately
- CloudKit sync works when online
- Edit/delete operations have undo
- Calendar shows accurate dose history

## Estimated Effort

### Overall Timeline
- **Total Duration**: 10 days (2 weeks)
- **Developer**: 1 iOS developer
- **Complexity**: Medium (mostly integration work)

### Resource Requirements
- Existing SwiftUI/SwiftData knowledge
- Access to test devices for photo testing
- TestFlight for beta testing

### Critical Path Items
1. DataController extensions (blocks everything)
2. Quick-add implementation (core feature)
3. History view (user expectation)
4. Testing suite (quality assurance)

## Tasks Created
- [x] #38 - Data Layer Extensions (parallel: true)
- [x] #39 - Quick Dose Entry (parallel: true) 
- [x] #40 - Dose Entry Form (closed - covered by #39)
- [x] #41 - History List View (parallel: true after 38)
- [x] #42 - Calendar Integration (parallel: true after 38)
- [deferred] #43 - Photo Attachments (deferred: 2025-09-18T17:47:42Z)
- [deferred] #44 - Search & Filter Enhancements (deferred: 2025-09-18T18:32:07Z)
- [ ] #45 - PK Engine Integration (parallel: false, depends on 38, 39)
- [not-planned] #46 - Testing Suite (parallel: false, depends on 38-41)

Total tasks: 9
Parallel tasks: 6
Sequential tasks: 3
Estimated total effort: 49 hours
