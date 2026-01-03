---
task_ref: "Task 1.3 - Implement Real-time Energy Observation"
agent_assignment: "Agent_HealthKit"
memory_log_path: ".apm/Memory/Phase_01_HealthKit_Active_Energy/Task_1_3_Implement_Realtime_Energy_Observation.md"
execution_type: "single-step"
dependency_context: true
ad_hoc_delegation: false
---

# APM Task Assignment: Implement Real-time Energy Observation

## Task Reference
Implementation Plan: **Task 1.3 - Implement Real-time Energy Observation** assigned to **Agent_HealthKit**

## Context from Dependencies
Building on your Task 1.1 and Task 1.2 work:

**Key Outputs to Use:**
- `activeEnergyType` constant in [JabTracker/Services/MetricsService+HealthKit.swift](cci:7://file:///Users/gannonhall/dev/jab-tracker-ios/JabTracker/Services/MetricsService+HealthKit.swift:0:0-0:0) (authorization already includes this type)
- `getTodayActiveEnergy() async -> Double?` method you implemented in Task 1.2 for fetching fresh totals

**Integration Approach:**
Your observation callback should invoke `getTodayActiveEnergy()` to fetch the updated cumulative value whenever HealthKit notifies of changes, then pass the result to the handler.

## Objective
Set up HKObserverQuery for real-time activeEnergyBurned updates with proper lifecycle management (start/stop) and background delivery support.

## Detailed Instructions
Complete all items in one response:

1. **Implement `startActiveEnergyObservation(handler:)`** – Create an `HKObserverQuery` for `activeEnergyType`. When the query fires:
   - Call `getTodayActiveEnergy()` to fetch the fresh cumulative total
   - Invoke the handler closure with the updated value
   - Handle the completion handler properly for background delivery
   
   Signature: `static func startActiveEnergyObservation(handler: @escaping (Double) -> Void)`

2. **Enable background delivery** – Call `healthStore.enableBackgroundDelivery(for:frequency:)` for `activeEnergyType` so updates are received even when the app is backgrounded. Use `.immediate` frequency for real-time updates.

3. **Store query reference** – Store the active `HKObserverQuery` reference (e.g., in a static property) so it can be cancelled later.

4. **Implement `stopActiveEnergyObservation()`** – Stop the observer query using `healthStore.stop(_:)` and clear the stored reference.

5. **Write integration test** – Test the observation lifecycle:
   - Start observation, verify query is active
   - Stop observation, verify query is stopped and reference cleared
   - Use the mock pattern from Task 1.2 if applicable

6. **Verify build and tests** – Run `xcodegen generate` if new files created. Ensure all tests pass.

## Expected Output
- **Deliverables:** Observation mechanism with start/stop lifecycle management
- **Success criteria:**
  - `startActiveEnergyObservation(handler:)` creates and executes HKObserverQuery
  - Background delivery enabled for activeEnergyBurned
  - `stopActiveEnergyObservation()` properly cleans up
  - Integration test verifying lifecycle
  - Project builds without errors
- **File locations:**
  - Modified: [JabTracker/Services/MetricsService+HealthKit.swift](cci:7://file:///Users/gannonhall/dev/jab-tracker-ios/JabTracker/Services/MetricsService+HealthKit.swift:0:0-0:0)
  - New/Modified: Test file for observation lifecycle verification

## Memory Logging
Upon completion, you **MUST** log work in: [.apm/Memory/Phase_01_HealthKit_Active_Energy/Task_1_3_Implement_Realtime_Energy_Observation.md](cci:7://file:///Users/gannonhall/dev/jab-tracker-ios/.apm/Memory/Phase_01_HealthKit_Active_Energy/Task_1_3_Implement_Realtime_Energy_Observation.md:0:0-0:0)
Follow .apm/guides/Memory_Log_Guide.md instructions.

## Reporting Protocol
After logging, you **MUST** output a **Final Task Report** code block.
- **Format:** Use the exact template provided in your .apm/workflows/apm-3-initiate-implementation.md instructions.
- **Perspective:** Write it from the User's perspective so they can copy-paste it back to the Manager.