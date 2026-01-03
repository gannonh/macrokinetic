---
Workspace_root: /Users/gannonhall/dev/jab-tracker-ios
---

# Manager Agent Bootstrap Prompt
You are the first Manager Agent of this APM session: Manager Agent 1.

## User Intent and Requirements
- Implement v0.4.0 Calorie Expenditure Enhancements for MacroKinetic iOS app
- **Add Burned Calories**: Read activeEnergyBurned from HealthKit, add to daily calorie targets in real-time (base + burned = adjusted)
- **Rollover Calories**: Add up to 200 unused calories from yesterday to today's targets (fixed cap, only yesterday)
- **Predictive Activity Adjustment**: Use 7-day activity average with goal-mode multipliers (80% loss, 100% maintenance, 120% gain), calculated during weekly check-in
- Features require HealthKit integration expansion, new User model preferences (CloudKit sync), CalorieAdjustmentService with layered calculation, and UI updates
- Toggles disabled when Health sync is off
- Testing: TDD for unit tests with mocks, E2E tests stubbed then implemented per phase, 90% business logic / 85% ViewModel coverage
- Run `xcodegen generate` after new Swift files

## Implementation Plan Overview
- **4 Phases**: (1) HealthKit Active Energy Integration, (2) Add Burned Calories Feature, (3) Rollover Calories Feature, (4) Predictive Activity Adjustment
- **17 Tasks** across 3 Implementation Agents:
  - **Agent_HealthKit** (3 tasks): Authorization expansion, query methods, real-time observation
  - **Agent_Logic** (8 tasks): User properties, CalorieAdjustmentService, rollover calculation, predictive algorithm, weekly check-in integration
  - **Agent_UI** (6 tasks): CalorieExpenditureView wiring, NutritionSummaryCard updates, E2E tests
- **6 Cross-Agent Dependencies** requiring coordination between Agent_HealthKit → Agent_Logic and Agent_Logic → Agent_UI
- Architecture: MVVM + Service Layer, @Observable, iOS 17+, SwiftData, CloudKit

4. Next steps for the Manager Agent - Follow this sequence exactly. Steps 1-8 in one response. Step 9 (Memory Root Header) and Step 10 (Execution) after explicit User confirmation:

  **Plan Responsibilities & Project Understanding**
  1. Read the entire [.apm/Implementation_Plan.md](cci:7://file:///Users/gannonhall/dev/jab-tracker-ios/.apm/Implementation_Plan.md:0:0-0:0) file created by Setup Agent and evaluate the plan's integrity and structure.  
  2. Concisely, confirm your understanding of the project scope, phases, and task structure & your plan management responsibilities

  **Memory System Responsibilities**  
  3. Read .apm/guides/Memory_System_Guide.md
  4. Read .apm/guides/Memory_Log_Guide.md
  5. Concisely, confirm your understanding of memory management responsibilities

  **Task Coordination Preparation**
  6. Read .apm/guides/Task_Assignment_Guide.md  
  7. Concisely, confirm your understanding of task assignment prompt creation and coordination duties

  **Execution Confirmation**
  8. Concisely, summarize your complete understanding, avoiding repetitions and **AWAIT USER CONFIRMATION** - Do not proceed to phase execution until confirmed

  **Memory Root Header Initialization**
  9. **MANDATORY**: When User confirms readiness, before proceeding to phase execution, you **MUST** fill in the header of the [.apm/Memory/Memory_Root.md](cci:7://file:///Users/gannonhall/dev/jab-tracker-ios/.apm/Memory/Memory_Root.md:0:0-0:0) file created by the `apm init` CLI tool.
    - The file already contains a header template with placeholders
    - **Fill in all header fields**:
      - Replace `<Project Name>` with the actual project name (from Implementation Plan)
      - Replace `[To be filled by Manager Agent before first phase execution]` in **Project Overview** field with a concise summary (from Implementation Plan)
    - **Save the updated header** - This is a dedicated file edit operation that must be completed before any phase execution begins

  **Execution**
  10. When Memory Root header is complete, proceed as follows:
    a. Read the first phase from the Implementation Plan.
    b. Create `Memory/Phase_01_HealthKit_Active_Energy/` in the `.apm/` directory for the first phase.
    c. For all tasks in the first phase, create completely empty [.md](cci:7://file:///Users/gannonhall/dev/jab-tracker-ios/CLAUDE.md:0:0-0:0) Memory Log files in the phase's directory.
    d. Once all empty logs/sections exist, issue the first Task Assignment Prompt.