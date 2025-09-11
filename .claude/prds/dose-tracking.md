---
name: dose-tracking
description: Comprehensive dose logging and management system for GLP-1 medication tracking
status: backlog
created: 2025-09-11T17:18:00Z
---

# PRD: Dose Tracking

## Executive Summary

The dose tracking feature is the core functionality of JabTracker, enabling users to log, monitor, and manage their GLP-1 medication doses with minimal friction. This feature provides both quick-entry and detailed logging capabilities, comprehensive history views, and intelligent tracking to improve medication adherence and provide valuable data for pharmacokinetic modeling.

## Problem Statement

Users taking GLP-1 medications need a reliable, efficient way to track their doses to maintain therapeutic levels and optimize treatment outcomes. Current solutions are either too generic (not designed for injectables) or too complex (requiring multiple steps to log a simple dose). 

Without proper tracking, users face:
- Uncertainty about when they last dosed
- Risk of double-dosing or missing doses
- Inability to identify patterns in their treatment
- Lack of data to share with healthcare providers
- No insight into their medication concentration levels

This feature needs to be implemented now because it's the foundational interaction users will have with the app multiple times per week, directly impacting user retention and the app's core value proposition.

## User Stories

### Primary User Personas

**1. The Routine User (Sarah)**
- Takes weekly Ozempic injections on Sunday mornings
- Wants minimal friction - quick tap to confirm dose taken
- Values consistency and streak tracking
- Needs gentle reminders if dose is overdue

**2. The Data-Driven Bio Hacker (Michael)**
- Acquires lyophilized Semaglutide directly from a peptide compounding "research" lab
- Tracks every detail about his Semaglutide injections
- Logs injection sites, side effects, and observations
- Wants to see patterns and correlations
- Adjust dosages (amounts and frequency) based on daily drug concentration levels and the corresponding effects (appetite, energy level, sleep patterns, etc.)
- Exports data for further analysis
- Would like to see features that support custom peptides beyond the standard GLP-1 agonists

**3. The Forgetful User (Jennifer)**
- Often forgets if she took her dose
- Needs clear visual confirmation of logged doses
- Sometimes needs to backdate entries
- Relies on the app to prevent double-dosing

### Detailed User Journeys

**Quick Dose Logging (Happy Path)**
1. User opens app (Face ID auto-authenticates)
2. "Log Dose" button prominently displayed on dashboard
3. One tap confirms dose at current time with default amount
4. Success confirmation with undo option
5. Dashboard updates with new concentration curve

**Manual Dose Entry**
1. User taps "+" button or "Log Dose"
2. Form pre-fills with smart defaults:
   - Current date/time
   - Last used dose amount
   - Next injection site in rotation
3. User can modify any field
4. Optional: Add notes or photo
5. Save with validation checks
6. Confirmation with entry added to history

**Dose History Review**
1. User navigates to History tab
2. Sees list view by default (most recent first)
3. Can switch to calendar view
4. Taps on any dose to see details
5. Can edit or delete with swipe gestures
6. Can filter by date range or search notes

## Requirements

### Functional Requirements

**Core Dose Entry**
- FR1: Quick-add button on dashboard for one-tap scheduled dose logging
- FR2: Manual entry form with fields:
  - Date picker (default: now)
  - Time picker (default: current time)
  - Dose amount selector (default: user's current dose)
  - Injection site selector (abdomen, thigh, arm, other)
  - Optional notes field (500 char limit)
  - Optional photo attachment
- FR3: Smart defaults based on user's medication profile and history
- FR4: Validation to prevent:
  - Future dates beyond 24 hours
  - Doses exceeding maximum safe amounts
  - Duplicate entries within 4-hour window (with override option)

**Dose History Management**
- FR5: List view showing:
  - Date/time of dose
  - Amount
  - Injection site icon
  - Note indicator if present
  - Relative time (e.g., "2 days ago")
- FR6: Calendar view with:
  - Dose indicators on calendar days
  - Color coding for on-time vs late doses
  - Monthly summary statistics
- FR7: Swipe actions for:
  - Edit (swipe right)
  - Delete (swipe left with confirmation)
- FR8: Search functionality across:
  - Notes content
  - Dose amounts
  - Injection sites
- FR9: Filter options:
  - Date range
  - Injection site
  - Dose amount
  - With/without notes

**Data Persistence**
- FR10: All doses saved to SwiftData immediately
- FR11: CloudKit sync when available
- FR12: Offline capability with queue for sync
- FR13: Timezone-aware storage and display

**Integration Points**
- FR14: Update pharmacokinetic calculations on dose entry
- FR15: Trigger adherence tracking updates
- FR16: Reset reminder notifications on dose logging
- FR17: Update dashboard widgets and complications

### Non-Functional Requirements

**Performance**
- NFR1: Dose entry completion in < 3 seconds
- NFR2: History view loads in < 1 second for 1000+ entries
- NFR3: Search results appear in < 500ms
- NFR4: Smooth 60fps scrolling in history views

**Usability**
- NFR5: Maximum 2 taps for quick dose logging
- NFR6: Maximum 5 taps for detailed dose entry
- NFR7: All actions reversible (undo/edit/delete)
- NFR8: Clear visual feedback for all actions

**Reliability**
- NFR9: Zero data loss even in crashes
- NFR10: Automatic save without explicit user action
- NFR11: Conflict resolution for sync issues
- NFR12: Graceful handling of network failures

**Accessibility**
- NFR13: Full VoiceOver support for all actions
- NFR14: Dynamic Type support in all text
- NFR15: High contrast mode compatibility
- NFR16: One-handed operation possible

**Security**
- NFR17: Dose data encrypted at rest
- NFR18: Biometric authentication for app access
- NFR19: Audit trail for all modifications
- NFR20: No PII in analytics

## Success Criteria

### Key Metrics
- **Dose Logging Rate**: >90% of expected doses logged
- **Time to Log**: <10 seconds average for quick entry
- **User Retention**: 80% of users still logging after 30 days
- **Data Completeness**: >60% of doses include injection site
- **Search Usage**: >30% of users use search/filter monthly

### Qualitative Measures
- User feedback rating >4.5 for ease of use
- Healthcare providers find exported data useful
- Reduced anxiety about dose tracking
- Increased confidence in medication management

## Constraints & Assumptions

### Technical Constraints
- Must work offline with full functionality
- Limited to devices running iOS 17.0+
- Photo attachments limited to 10MB
- History limited to 2 years of data on device

### Resource Constraints
- Single iOS developer
- 2-week implementation timeline
- Must reuse existing design system components
- No backend API development

### Assumptions
- Users have already set up medication profiles
- Users understand their dosing schedule
- Device clock is reasonably accurate
- Users will log doses within 48 hours of administration

## Out of Scope

The following items are explicitly NOT included in this phase:
- Barcode/QR code scanning for medication
- Voice input for dose logging
- Automatic injection detection via Apple Watch
- Social features or dose sharing
- Integration with pharmacy systems
- Medication inventory tracking
- Refill reminders
- Dose splitting or combination doses
- IV or infusion tracking
- Blood glucose correlation

## Dependencies

### Internal Dependencies
- **Medication Profile Management**: Must be complete to provide defaults
- **Authentication System**: User must be authenticated to log doses
- **SwiftData Models**: Dose model must be defined and tested
- **Design System**: All UI components must be available
- **Pharmacokinetic Engine**: Should be ready to consume dose data

### External Dependencies
- **CloudKit**: For sync functionality (graceful degradation if unavailable)
- **PhotosUI**: For image attachment functionality
- **UserNotifications**: For reminder reset after logging

### Technical Dependencies
- SwiftUI framework (iOS 17.0+)
- SwiftData for persistence
- Swift Charts for calendar heat map (optional enhancement)

## Risk Analysis

### High Risk
- **Data Loss**: Mitigated by immediate SwiftData persistence and CloudKit backup
- **Accidental Deletion**: Mitigated by confirmation dialogs and undo functionality

### Medium Risk
- **Complex Form Intimidation**: Mitigated by smart defaults and progressive disclosure
- **Sync Conflicts**: Mitigated by last-write-wins with full audit trail

### Low Risk
- **Performance Issues**: Mitigated by pagination and lazy loading
- **Photo Storage**: Mitigated by compression and storage limits

## Future Enhancements

Potential improvements for future iterations:
- Apple Watch complication for quick logging
- Siri Shortcuts for voice-activated logging
- Widget for home screen dose logging
- Auto-detection of injection via Watch motion
- Smart reminders based on patterns
- Batch import from other apps
- ML-based dose predictions
- Integration with continuous glucose monitors
- Augmented reality injection site guide
- Medication scanning and verification

## Technical Implementation Notes

### Data Model
```swift
@Model
final class Dose {
    var id: UUID = UUID()
    var amount: Double = 0.0
    var timestamp: Date = Date()
    var site: String? = nil
    var notes: String? = nil
    var imageData: Data? = nil
    var skipped: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    @Relationship(inverse: \User.doses) 
    var user: User? = nil
    
    @Relationship(inverse: \MedicationProfile.doses)
    var medicationProfile: MedicationProfile? = nil
}
```

### Key View Components
- `QuickDoseButton`: Dashboard component for one-tap logging
- `DoseEntryForm`: Full form for detailed entry
- `DoseHistoryList`: SwiftUI List with swipe actions
- `DoseCalendarView`: Calendar with heat map visualization
- `DoseDetailSheet`: Read-only view of dose details
- `DoseEditForm`: Edit existing dose entries

### Testing Requirements
- Unit tests for all dose validation logic
- UI tests for happy path dose entry
- UI tests for edit/delete operations
- Performance tests for large datasets
- Accessibility audit for VoiceOver