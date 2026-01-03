# MacroKinetic v0.4.0 Calorie Expenditure Enhancements – APM Memory Root
**Memory Strategy:** Dynamic-MD
**Project Overview:** Implement 3 calorie expenditure features for MacroKinetic iOS app: (1) Add Burned Calories – read activeEnergyBurned from HealthKit and add to daily targets in real-time, (2) Rollover Calories – carry up to 200 unused calories from yesterday to today, (3) Predictive Activity Adjustment – apply 7-day activity average with goal-mode multipliers during weekly check-in. Implementation spans 4 phases across 17 tasks with 3 Implementation Agents (Agent_HealthKit, Agent_Logic, Agent_UI). Architecture: MVVM + Service Layer, @Observable, iOS 17+, SwiftData, CloudKit sync.

## Phase 01 – HealthKit Active Energy Integration Summary
* **Outcome:** Successfully established HealthKit foundation for calorie expenditure tracking. Implemented `activeEnergyBurned` authorization, query methods (daily, historical, today), and real-time background observation using HKObserverQuery. Updated `User` model with persistence for new feature toggles (add burned, rollover, predictive) and predictive bonus storage. All components fully tested with unit and integration tests using mock injection patterns.
* **Agents:** Agent_HealthKit, Agent_Logic
* **Task Logs:**
  * [Task 1.1 - Expand HealthKit Authorization](Phase_01_HealthKit_Active_Energy/Task_1_1_Expand_HealthKit_Authorization.md)
  * [Task 1.2 - Add Active Energy Query Methods](Phase_01_HealthKit_Active_Energy/Task_1_2_Add_Active_Energy_Query_Methods.md)
  * [Task 1.3 - Implement Real-time Energy Observation](Phase_01_HealthKit_Active_Energy/Task_1_3_Implement_Realtime_Energy_Observation.md)
  * [Task 1.4 - Add User Preference Properties](Phase_01_HealthKit_Active_Energy/Task_1_4_Add_User_Preference_Properties.md)
