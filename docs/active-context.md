---
task_ref: "Task 1.1 - Expand HealthKit Authorization"
agent_assignment: "Agent_HealthKit"
memory_log_path: ".apm/Memory/Phase_01_HealthKit_Active_Energy/Task_1_1_Expand_HealthKit_Authorization.md"
execution_type: "single-step"
dependency_context: false
ad_hoc_delegation: false
---

# APM Task Assignment: Expand HealthKit Authorization

## Task Reference
Implementation Plan: **Task 1.1 - Expand HealthKit Authorization** assigned to **Agent_HealthKit**

## Objective
Add activeEnergyBurned to HealthKit authorization request so the app can read the user's active energy data.

## Detailed Instructions
Complete all items in one response:

1. **Locate MetricsService+HealthKit extension** – Find the existing HealthKit integration file (likely `MetricsService+HealthKit.swift` or similar) where authorization types are defined.

2. **Add activeEnergyBurned quantity type constant** – Add a new constant for the active energy type:
   ```swift
   private let activeEnergyType = HKQuantityType(.activeEnergyBurned)
   ```

Follow the existing naming pattern for other HealthKit quantity types in the file.

Expand authorization read types – Add activeEnergyType to the allReadTypes set (or equivalent) used in the HealthKit authorization request. Only read permission is needed (no write).
Write unit test – Create a unit test verifying that the authorization request includes activeEnergyBurned. Follow existing test patterns in the project. Run xcodegen generate if a new test file is created.
Verify build and tests – Ensure the project builds successfully and all tests pass.
Expected Output
Deliverables: Updated MetricsService+HealthKit with expanded authorization types
Success criteria:
activeEnergyType constant added
activeEnergyBurned included in authorization read types
Unit test passing
Project builds without errors
File locations:
Modified: MacroKinetic/Services/MetricsService+HealthKit.swift (or actual path)
New/Modified: Test file for authorization verification
Memory Logging
Upon completion, you MUST log work in: 
.apm/Memory/Phase_01_HealthKit_Active_Energy/Task_1_1_Expand_HealthKit_Authorization.md
 Follow .apm/guides/Memory_Log_Guide.md instructions.

Reporting Protocol
After logging, you MUST output a Final Task Report code block.

Format: Use the exact template provided in your .apm/workflows/apm-3-initiate-implementation.md instructions.
Perspective: Write it from the User's perspective so they can copy-paste it back to the Manager.