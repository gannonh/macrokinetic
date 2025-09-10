# Implementation Plan: Medication Profile Management

**Branch**: `001-medication-profile-management` | **Date**: 2025-09-05 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/Users/gannonhall/dev/jab-tracker-ios/specs/001-medication-profile-management/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
4. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
5. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, or `GEMINI.md` for Gemini CLI).
6. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
7. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
8. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Implement medication profile management system for GLP-1 medications with three core capabilities: (1) Profile CRUD operations for Semaglutide, Tirzepatide, Liraglutide, and Dulaglutide with medically accurate properties, (2) compounded medication reconstitution calculator for vial-based medications, and (3) branded pen click calculator for dose adjustments. System must integrate with existing SwiftData models and provide medical accuracy for pharmacokinetic calculations.

## Technical Context
**Language/Version**: Swift 5.9+ (iOS 17.0+ target)  
**Primary Dependencies**: SwiftUI, SwiftData, CloudKit, Swift Testing, XCUITest  
**Storage**: SwiftData + CloudKit sync (existing DataController with graceful local fallback)  
**Testing**: Swift Testing (unit/integration), XCUITest (E2E), xcbeautify for output formatting  
**Target Platform**: iOS 17.0+, iPhone/iPad with CloudKit sync capability
**Project Type**: mobile (iOS app) - existing project structure  
**Performance Goals**: <50ms calculation updates, medical accuracy for pharmacokinetic properties  
**Constraints**: Offline-capable, medical accuracy requirements, CloudKit sync compatibility  
**Scale/Scope**: 4 medications, 3 calculation types, integration with existing User/MedicationProfile models

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Simplicity**:
- Projects: 1 (iOS app - existing project structure)
- Using framework directly? YES (SwiftUI, SwiftData native usage)
- Single data model? YES (extending existing SwiftData models)
- Avoiding patterns? YES (direct SwiftData usage, no Repository pattern)

**Architecture** (Adapted for iOS):
- Feature as modular components? YES (MedicationManager, calculation utilities)
- Libraries listed: MedicationManager (CRUD), ReconstitutionCalculator, PenClickCalculator  
- CLI per library: N/A (iOS app context)
- Documentation: Inline Swift documentation, README updates

**Testing (NON-NEGOTIABLE)**:
- RED-GREEN-Refactor cycle enforced? YES (Swift Testing TDD approach)
- Git commits show tests before implementation? YES (project requirement)
- Order: Model tests → Service tests → UI tests → Integration tests
- Real dependencies used? YES (actual SwiftData, CloudKit in tests)
- Integration tests for: SwiftData model changes, CloudKit sync, UI flows
- FORBIDDEN: Implementation before test, skipping RED phase

**Observability** (iOS Context):
- Structured logging included? YES (Console.log for development, OSLog for production)
- Error context sufficient? YES (SwiftUI error handling, user feedback)

**Versioning** (iOS Context):
- Version controlled through Xcode project versioning
- Medical data accuracy requires careful validation of breaking changes
- Migration plan for existing MedicationProfile model changes

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# iOS App Structure (Existing JabTracker project)
JabTracker/
├── Models/
│   ├── User.swift (existing)
│   ├── Dose.swift (existing)
│   ├── MedicationProfile.swift (existing - to be enhanced)
│   └── Medication.swift (new - enum with properties)
├── Services/
│   ├── DataController.swift (existing)
│   ├── MedicationManager.swift (new)
│   ├── ReconstitutionCalculator.swift (new)
│   └── PenClickCalculator.swift (new)  
├── Views/
│   ├── Settings/ (existing)
│   │   └── MedicationProfileSettingsView.swift (new)
│   ├── Onboarding/ (existing)
│   │   └── MedicationSelectionView.swift (enhance existing)
│   └── MedicationProfile/ (new views)
│       ├── ReconstitutionCalculatorView.swift
│       ├── PenClickCalculatorView.swift
│       └── DoseTitrationView.swift
└── Utilities/ (existing)

JabTrackerTests/
├── ModelTests/ (existing)
├── ServiceTests/ (existing)
├── MedicationTests/ (new)
└── CalculatorTests/ (new)

JabTrackerUITests/
└── MedicationProfileUITests/ (new)
```

**Structure Decision**: iOS mobile app - extending existing project structure with medication-specific components

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `/scripts/update-agent-context.sh [claude|gemini|copilot]` for your AI assistant
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy for Medication Profile Management**:
- Load `/templates/tasks-template.md` as base structure
- Generate tasks from Phase 1 artifacts:
  - data-model.md → Model enhancement tasks (MedicationProfile, Medication enum)
  - contracts/ → Service implementation tasks (MedicationManager, calculators)
  - quickstart.md → Integration and UI test tasks
- Each contract interface → contract test task [P] (parallel execution)
- Each data model entity → model implementation task [P]
- Each user story scenario → integration test task
- Calculator services → unit test tasks for medical accuracy
- UI workflows → E2E test tasks

**iOS-Specific Ordering Strategy**:
- TDD order: Test files → Model code → Service code → UI code
- Dependency order: 
  1. Medication enum (foundation)
  2. Enhanced MedicationProfile model 
  3. Calculator services (ReconstitutionCalculator, PenClickCalculator)
  4. MedicationManager service
  5. UI components and views
  6. Integration tests
- SwiftData migration tasks for existing model enhancements
- CloudKit sync validation tasks

**Medical Accuracy Priorities**:
- Medication property validation tests (highest priority)
- Calculation accuracy tests with real medical scenarios
- Edge case handling for dosing constraints
- Input validation for user safety

**Estimated Output**: 20-25 numbered, ordered tasks covering:
- 3 model enhancement tasks
- 6 service implementation tasks  
- 8 test implementation tasks
- 4 UI integration tasks
- 2 data migration tasks

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation                  | Why Needed         | Simpler Alternative Rejected Because |
| -------------------------- | ------------------ | ------------------------------------ |
| [e.g., 4th project]        | [current need]     | [why 3 projects insufficient]        |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient]  |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*