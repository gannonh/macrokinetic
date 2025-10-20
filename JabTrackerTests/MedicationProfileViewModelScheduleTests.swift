//
//  MedicationProfileViewModelScheduleTests.swift
//  JabTracker
//
//  Created by Stream B Agent on 2025-10-18.
//  Tests for MedicationProfileViewModel schedule management functionality.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Test suite for MedicationProfileViewModel schedule management
@Suite("MedicationProfileViewModel Schedule Management Tests")
@MainActor
struct MedicationProfileViewModelScheduleTests {

    // MARK: - Test Fixtures

    /// Creates a test ModelContext with in-memory storage
    func createTestContext() throws -> ModelContext {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            DoseSchedule.self,
            ScheduledDose.self,
            Dose.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none  // Disable CloudKit for tests
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    /// Creates a test user
    func createTestUser(context: ModelContext) -> User {
        let user = User(
            email: "test@example.com",
            name: "Test User",
            weight: 80.0,
            hasCompletedOnboarding: true
        )
        context.insert(user)
        try? context.save()
        return user
    }

    /// Creates a test medication profile
    func createTestMedicationProfile(
        context: ModelContext,
        user: User
    ) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5,
            startDate: Date(),
            medicationType: "semaglutide",
            preferredInjectionSites: ["Abdomen"]
        )
        profile.user = user
        context.insert(profile)
        try? context.save()
        return profile
    }

    /// Creates a test dose schedule
    func createTestSchedule(
        context: ModelContext,
        profile: MedicationProfile
    ) throws -> DoseSchedule {
        let scheduleService = ScheduleService(context: context)

        let config = ScheduleConfiguration(
            dayOfWeek: 1,  // Monday
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 0.5,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        return try scheduleService.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: Date(),
            baseSchedule: config
        )
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with medication profile")
    func testViewModelInitialization() throws {
        let context = try createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)

        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )

        #expect(viewModel.medicationProfile.id == profile.id)
        #expect(viewModel.activeSchedule == nil)
        #expect(viewModel.scheduleHistory.isEmpty)
    }

    // MARK: - Load Active Schedule Tests

    @Test("Load active schedule succeeds when schedule exists")
    func testLoadActiveScheduleSuccess() async throws {
        let context = try createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )

        await viewModel.loadActiveSchedule()

        #expect(viewModel.activeSchedule != nil)
        #expect(viewModel.activeSchedule?.id == schedule.id)
    }

    @Test("Load active schedule returns nil when no schedule exists")
    func testLoadActiveScheduleNoSchedule() async throws {
        let context = try createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)

        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )

        await viewModel.loadActiveSchedule()

        #expect(viewModel.activeSchedule == nil)
    }

    // MARK: - Update Schedule Tests

    @Test("Update schedule creates new schedule when none exists")
    func testUpdateScheduleCreatesNew() async throws {
        let context = try createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)

        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )

        // Create schedule configuration
        let config = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 0.5,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        await viewModel.updateSchedule(config, pattern: .weekly)

        #expect(viewModel.activeSchedule != nil)
        #expect(viewModel.activeSchedule?.patternType == .weekly)
    }

    // MARK: - Pause Schedule Tests

    @Test("Pause schedule sets pause fields correctly")
    func testPauseSchedule() async throws {
        let context = try createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        _ = try createTestSchedule(context: context, profile: profile)

        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )

        await viewModel.loadActiveSchedule()

        let pauseUntil = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        await viewModel.pauseSchedule(until: pauseUntil)

        #expect(viewModel.activeSchedule?.pausedAt != nil)
        #expect(viewModel.activeSchedule?.pausedUntil == pauseUntil)
    }

    @Test("Pause schedule with nil date pauses indefinitely")
    func testPauseScheduleIndefinite() async throws {
        let context = try createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        _ = try createTestSchedule(context: context, profile: profile)

        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )

        await viewModel.loadActiveSchedule()
        await viewModel.pauseSchedule(until: nil)

        #expect(viewModel.activeSchedule?.pausedAt != nil)
        #expect(viewModel.activeSchedule?.pausedUntil == nil)
    }

    // MARK: - Resume Schedule Tests

    @Test("Resume schedule clears pause fields")
    func testResumeSchedule() async throws {
        let context = try createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = try createTestSchedule(context: context, profile: profile)

        // Manually pause the schedule first
        let scheduleService = ScheduleService(context: context)
        let pauseUntil = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        try scheduleService.pauseSchedule(schedule, until: pauseUntil)

        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )

        await viewModel.loadActiveSchedule()
        #expect(viewModel.activeSchedule?.pausedAt != nil)

        await viewModel.resumeSchedule()

        #expect(viewModel.activeSchedule?.pausedAt == nil)
        #expect(viewModel.activeSchedule?.pausedUntil == nil)
    }

    // MARK: - Deactivate Schedule Tests

    @Test("Deactivate schedule sets isActive to false")
    func testDeactivateSchedule() async throws {
        let context = try createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        _ = try createTestSchedule(context: context, profile: profile)

        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )

        await viewModel.loadActiveSchedule()
        #expect(viewModel.activeSchedule != nil)
        #expect(viewModel.activeSchedule?.isActive == true)

        await viewModel.deactivateSchedule()

        #expect(viewModel.activeSchedule == nil)
    }

    // MARK: - Schedule History Tests

    @Test("Load schedule history returns empty array when no history")
    func testLoadScheduleHistoryEmpty() async throws {
        let context = try createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)

        let viewModel = MedicationProfileViewModel(
            medicationProfile: profile,
            context: context
        )

        await viewModel.loadScheduleHistory()

        #expect(viewModel.scheduleHistory.isEmpty)
    }
}
