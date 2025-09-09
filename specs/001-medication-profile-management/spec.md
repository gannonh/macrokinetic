# Feature Specification: Medication Profile Management

**Feature Branch**: `001-medication-profile-management`  
**Created**: 2025-09-05  
**Status**: ✅ **COMPLETED** (2025-09-09)  
**Input**: User description: "Medication Profile Management - Medication Enum & Profile System including Medication enum with properties (half-life, available doses, frequency), support for Semaglutide/Tirzepatide/Liraglutide/Dulaglutide, medication selection wizard for onboarding, medication profile CRUD operations with SwiftData, and dose escalation schedule tracking"

## Execution Flow (main)
```
1. Parse user description from Input
   → ✅ Description parsed: Medication profile management system
2. Extract key concepts from description
   → Actors: Users with GLP-1 medications
   → Actions: Select medication, manage profiles, track escalation
   → Data: Medication types, profiles, dose schedules
   → Constraints: Medical accuracy, supported medication types
3. For each unclear aspect:
   → All aspects clearly defined in medical context
4. Fill User Scenarios & Testing section
   → ✅ Clear user flow for medication management
5. Generate Functional Requirements
   → ✅ All requirements testable and measurable
6. Identify Key Entities
   → ✅ Medication, MedicationProfile entities identified
7. Run Review Checklist
   → ✅ No implementation details, focus on user value
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a user taking GLP-1 medications (Ozempic, Wegovy, Mounjaro, etc.), I need to set up and manage my medication profile so that the app can provide accurate dose tracking, concentration calculations, and personalized guidance based on my specific medication's properties like half-life and available doses. For users with compounded medications, I need simple guidance on reconstituting my vial to achieve my prescribed dose.

### Acceptance Scenarios
1. **Given** a new user during onboarding, **When** they select their GLP-1 medication from the available options, **Then** the system creates a medication profile with the correct medical properties and available dose options
2. **Given** an existing user with a medication profile, **When** they need to change their medication type, **Then** they can update their profile while preserving relevant historical data
3. **Given** a user starting dose escalation, **When** they schedule dose increases, **Then** the system tracks their escalation timeline and provides appropriate reminders
4. **Given** a user viewing their medication profile, **When** they want to understand their medication's properties, **Then** they can access information about half-life, available doses, and dosing frequency
5. **Given** a user with compounded medication, **When** they enter their vial strength (mg) and target dose (mg/week), **Then** the system calculates the water amount needed and units per dose for reconstitution
6. **Given** a user with a branded pen medication, **When** they need to adjust their dose (e.g., from 0.5mg to 0.25mg), **Then** the system shows how many clicks/units to dial on their specific pen type

### Edge Cases
- What happens when a user switches between medications with different half-lives (data migration scenario)?
- How does the system handle discontinued medications or dose formulations that are no longer available?
- What occurs if a user has multiple concurrent GLP-1 medications (though medically uncommon)?
- How does the system handle invalid reconstitution inputs (e.g., vial strength less than target dose)?

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST support exactly four GLP-1 medications: Semaglutide, Tirzepatide, Liraglutide, and Dulaglutide with their medically accurate properties
- **FR-002**: System MUST provide medication selection interface displaying brand names (Ozempic/Wegovy, Mounjaro/Zepbound, Victoza/Saxenda, Trulicity) mapped to generic medication types
- **FR-003**: System MUST store medication half-life values (Semaglutide: 7 days, Tirzepatide: 5 days, Liraglutide: 0.54 days, Dulaglutide: 4.7 days) for pharmacokinetic calculations
- **FR-004**: System MUST provide brand-specific available dose options based on FDA-approved pen specifications (e.g., Ozempic: [0.25, 0.5, 1.0, 2.0], Wegovy: [0.25, 0.5, 1.0, 1.7, 2.4])
- **FR-005**: System MUST enforce proper dosing frequency constraints (daily for Liraglutide, weekly for others)
- **FR-006**: Users MUST be able to create, view, update, and delete their medication profiles
- **FR-007**: System MUST track dose escalation schedules with start date, target dose, and escalation timeline
- **FR-008**: System MUST maintain medication profile history to support switching between different medications
- **FR-009**: Users MUST be able to set their current dose level within the valid range for their selected medication and brand
- **FR-010**: System MUST validate that selected doses are available for the chosen medication type and brand combination
- **FR-011**: System MUST provide compounded medication reconstitution calculator that accepts vial strength (mg) and target dose (mg) and calculates required water volume (ml) and units per dose
- **FR-012**: System MUST display reconstitution results in simple format: "Add X ml water. Your dose is Y units" where units = 10 * (target dose / vial strength)
- **FR-013**: System MUST validate reconstitution inputs to ensure target dose does not exceed vial strength
- **FR-014**: ~~System MUST provide pen click calculator that shows number of clicks/units to dial for branded pen medications~~ **REMOVED** due to liability concerns around off-label dosing recommendations
- **FR-015**: ~~System MUST store pen-specific click-to-dose ratios for accurate dose adjustment calculations~~ **REMOVED** due to liability concerns
- **FR-016**: ~~System MUST display pen instructions in simple format~~ **REMOVED** due to liability concerns
- **FR-017**: System MUST integrate medication profile creation with onboarding flow to ensure selected medication during onboarding persists as a medication profile

### Scope & Boundaries
This feature encompasses two distinct but related medication management capabilities:
1. **Core Medication Profile Management**: CRUD operations for the four supported GLP-1 medications with brand-specific dose validation
2. **Compounded Medication Support**: Simple reconstitution calculator for vial-based medications 

**In Scope**: 
- Medication selection (onboarding wizard)
- Profile management (Settings CRUD operations)
- Dose escalation tracking 
- Reconstitution calculations
- Brand-specific dose validation
- Settings UI for profile modification
- Onboarding integration fixes

**Out of Scope**: 
- Pen click calculations (removed due to liability concerns)
- Pharmacokinetic modeling (separate feature)
- Dose reminders (separate feature)
- Multiple concurrent medications

**Known Issues**:
- ~~Onboarding flow medication selection does not persist as medication profile~~ ✅ **RESOLVED** (fixed in commit ac99407)

### Key Entities *(include if feature involves data)*
- **Medication**: Represents the four supported GLP-1 medication types with properties including generic name, brand names, half-life in days, available dose array, dosing frequency, and pen click-to-dose ratios for branded formulations
- **MedicationProfile**: User-specific medication configuration containing selected medication, current dose, start date, escalation schedule, compounded medication settings (vial strength, reconstitution), and creation/modification timestamps
- **DoseEscalation**: Tracks planned dose increases with target dose, scheduled date, and completion status linked to a medication profile

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous  
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---