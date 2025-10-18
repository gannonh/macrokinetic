//
//  MedicationProfileScheduleIntegrationTests.swift
//  JabTrackerTests
//
//  Created by Stream B Agent on 2025-10-18.
//  Integration tests for MedicationProfileViewModel + ScheduleService.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("Medication Profile Schedule Tests")
struct MedicationProfileScheduleTests {

    // MARK: - Helper Methods

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            Dose.self,
            DoseSchedule.self,
            ScheduledDose.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none  // Critical: Disable CloudKit for tests
        )
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func createTestUser() -> User {
        User(email: "test@example.com", name: "Test User", weight: 70.0)
    }

    private func createTestMedicationProfile(medication: Medication) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: medication.displayName,
            brandName: medication.displayName,
            currentDose: 1.0
        )
        profile.medication = medication
        return profile
    }

    // MARK: - Test 1: Create Schedule Integration

    @Test("Create schedule via ViewModel creates it in ScheduleService")
    @MainActor
    func testCreateScheduleIntegration() async throws {
        // GIVEN: Test container with medication profile
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser()
        let profile = createTestMedicationProfile(medication: .semaglutide)

        context.insert(user)
        context.insert(profile)
        profile.user = user
        user.medicationProfiles?.append(profile)
        try context.save()

        // GIVEN: ViewModel initialized
        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )

        // WHEN: Create a new schedule via ViewModel
        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly,
            baseSchedule: Data()
        )

        await viewModel.updateSchedule(schedule)

        // THEN: Schedule was created in SwiftData
        let descriptor = FetchDescriptor<DoseSchedule>(
            predicate: #Predicate { schedule in
                schedule.medicationProfile == profile && schedule.isActive
            }
        )
        let schedules = try context.fetch(descriptor)

        #expect(schedules.count == 1, "Should create one active schedule")
        #expect(schedules.first?.patternType == .weekly, "Should save correct pattern")
    }

    // MARK: - Test 2: Update Existing Schedule

    @Test("Update existing schedule via ViewModel updates it in ScheduleService")
    @MainActor
    func testUpdateExistingScheduleIntegration() async throws {
        // GIVEN: Test container with medication profile and existing schedule
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser()
        let profile = createTestMedicationProfile(medication: .semaglutide)

        context.insert(user)
        context.insert(profile)
        profile.user = user
        try context.save()

        let originalSchedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly,
            baseSchedule: Data()
        )
        context.insert(originalSchedule)
        try context.save()

        // GIVEN: ViewModel initialized and loaded schedule
        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )
        await viewModel.loadActiveSchedule()

        #expect(viewModel.activeSchedule != nil, "Should load existing schedule")

        // WHEN: Update schedule pattern
        guard let loadedSchedule = viewModel.activeSchedule else {
            #expect(Bool(false), "Active schedule should be loaded")
            return
        }

        loadedSchedule.patternType = .custom
        loadedSchedule.frequency = 2

        await viewModel.updateSchedule(loadedSchedule)

        // THEN: Schedule was updated in SwiftData
        let descriptor = FetchDescriptor<DoseSchedule>(
            predicate: #Predicate { schedule in
                schedule.medicationProfile == profile && schedule.isActive
            }
        )
        let schedules = try context.fetch(descriptor)

        #expect(schedules.count == 1, "Should still have one active schedule")
        #expect(schedules.first?.patternType == .custom, "Should update pattern to custom")
    }

    // MARK: - Test 3: Pause Schedule Integration

    @Test("Pause schedule via ViewModel sets pause fields in ScheduleService")
    @MainActor
    func testPauseScheduleIntegration() async throws {
        // GIVEN: Test container with medication profile and active schedule
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser()
        let profile = createTestMedicationProfile(medication: .semaglutide)

        context.insert(user)
        context.insert(profile)
        profile.user = user
        try context.save()

        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly,
            baseSchedule: Data()
        )
        context.insert(schedule)
        try context.save()

        // GIVEN: ViewModel initialized
        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )
        await viewModel.loadActiveSchedule()

        // WHEN: Pause schedule until tomorrow
        let pauseUntil = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        await viewModel.pauseSchedule(until: pauseUntil)

        // THEN: Schedule has pause fields set
        let descriptor = FetchDescriptor<DoseSchedule>(
            predicate: #Predicate { schedule in
                schedule.medicationProfile == profile && schedule.isActive
            }
        )
        let schedules = try context.fetch(descriptor)

        #expect(schedules.count == 1, "Should still have one active schedule")
        #expect(schedules.first?.pausedAt != nil, "Should set pausedAt")
        #expect(schedules.first?.pausedUntil != nil, "Should set pausedUntil")
    }

    // MARK: - Test 4: Resume Schedule Integration

    @Test("Resume schedule via ViewModel clears pause fields in ScheduleService")
    @MainActor
    func testResumeScheduleIntegration() async throws {
        // GIVEN: Test container with paused schedule
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser()
        let profile = createTestMedicationProfile(medication: .semaglutide)

        context.insert(user)
        context.insert(profile)
        profile.user = user
        try context.save()

        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly,
            baseSchedule: Data()
        )
        schedule.pausedAt = Date()
        schedule.pausedUntil = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        context.insert(schedule)
        try context.save()

        // GIVEN: ViewModel initialized
        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )
        await viewModel.loadActiveSchedule()

        #expect(viewModel.activeSchedule?.pausedAt != nil, "Schedule should be paused initially")

        // WHEN: Resume schedule
        await viewModel.resumeSchedule()

        // THEN: Schedule pause fields are cleared
        let descriptor = FetchDescriptor<DoseSchedule>(
            predicate: #Predicate { schedule in
                schedule.medicationProfile == profile && schedule.isActive
            }
        )
        let schedules = try context.fetch(descriptor)

        #expect(schedules.count == 1, "Should still have one active schedule")
        #expect(schedules.first?.pausedAt == nil, "Should clear pausedAt")
        #expect(schedules.first?.pausedUntil == nil, "Should clear pausedUntil")
    }

    // MARK: - Test 5: Deactivate Schedule Integration

    @Test("Deactivate schedule via ViewModel sets isActive=false in ScheduleService")
    @MainActor
    func testDeactivateScheduleIntegration() async throws {
        // GIVEN: Test container with active schedule
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser()
        let profile = createTestMedicationProfile(medication: .semaglutide)

        context.insert(user)
        context.insert(profile)
        profile.user = user
        try context.save()

        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly,
            baseSchedule: Data()
        )
        context.insert(schedule)
        try context.save()

        // GIVEN: ViewModel initialized
        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )
        await viewModel.loadActiveSchedule()

        #expect(viewModel.activeSchedule != nil, "Should load active schedule")

        // WHEN: Deactivate schedule
        await viewModel.deactivateSchedule()

        // THEN: Schedule is marked inactive
        let descriptor = FetchDescriptor<DoseSchedule>(
            predicate: #Predicate { schedule in
                schedule.medicationProfile == profile
            }
        )
        let schedules = try context.fetch(descriptor)

        #expect(schedules.count == 1, "Should still have one schedule (soft delete)")
        #expect(schedules.first?.isActive == false, "Should mark schedule as inactive")

        // AND: ViewModel's activeSchedule is now nil
        #expect(viewModel.activeSchedule == nil, "ViewModel should clear activeSchedule reference")
    }

    // MARK: - Test 6: Load Schedule History Integration

    @Test("Load schedule history via ViewModel returns correct history items")
    @MainActor
    func testLoadScheduleHistoryIntegration() async throws {
        // GIVEN: Test container with medication profile and multiple schedules
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser()
        let profile = createTestMedicationProfile(medication: .semaglutide)

        context.insert(user)
        context.insert(profile)
        profile.user = user
        try context.save()

        // Create first schedule (now inactive)
        let schedule1 = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly,
            baseSchedule: Data()
        )
        schedule1.createdAt = Date().addingTimeInterval(-86400 * 30)  // 30 days ago
        schedule1.isActive = false
        context.insert(schedule1)

        // Create second schedule (currently active)
        let schedule2 = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly,
            baseSchedule: Data()
        )
        schedule2.createdAt = Date().addingTimeInterval(-86400 * 7)  // 7 days ago
        context.insert(schedule2)

        try context.save()

        // GIVEN: ViewModel initialized
        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )

        // WHEN: Load schedule history
        await viewModel.loadScheduleHistory()

        // THEN: History contains both schedules
        #expect(viewModel.scheduleHistory.count == 2, "Should load 2 schedule history items")

        // AND: Most recent schedule is first
        #expect(viewModel.scheduleHistory.first?.changeType == .created, "Most recent should be created")
        #expect(viewModel.scheduleHistory.first?.patternType == .weekly, "Should have correct pattern")
    }
}
