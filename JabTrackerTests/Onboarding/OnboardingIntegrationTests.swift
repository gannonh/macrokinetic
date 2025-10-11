// OnboardingIntegrationTests.swift
// JabTrackerTests
//
// Created for testing OnboardingViewModel schedule creation integration
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Integration tests for OnboardingViewModel schedule creation with completeOnboarding()
struct OnboardingIntegrationTests {

    // MARK: - Test Helpers

    /// Creates a test environment with authenticated user
    @MainActor
    private func createTestEnvironment() throws -> (
        viewModel: OnboardingViewModel, context: ModelContext
    ) {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let context = dataController.container.mainContext

        // Create test user and authenticate
        let testUser = User(email: "test@integration.com", name: "Integration Test User")
        context.insert(testUser)
        try context.save()
        authManager.currentUser = testUser

        // Create ViewModel
        let viewModel = OnboardingViewModel(
            dataController: dataController,
            authManager: authManager
        )

        return (viewModel, context)
    }

    /// Cleans up test data from context
    @MainActor
    private func cleanupTestData(context: ModelContext) throws {
        let profiles = try context.fetch(FetchDescriptor<MedicationProfile>())
        for profile in profiles {
            context.delete(profile)
        }
        let schedules = try context.fetch(FetchDescriptor<DoseSchedule>())
        for schedule in schedules {
            context.delete(schedule)
        }
        try context.save()
    }

    /// Sets up viewModel for complete onboarding
    @MainActor
    private func setupForOnboarding(
        viewModel: OnboardingViewModel,
        medication: Medication = .semaglutide,
        dose: Double = 0.5,
        pattern: SchedulePatternType = .weekly
    ) {
        viewModel.selectedMedication = medication
        viewModel.selectedDose = dose
        viewModel.selectedSites = ["Abdomen"]
        viewModel.schedulePattern = pattern
    }

    // MARK: - Integration Tests

    @Test("completeOnboarding creates both MedicationProfile and DoseSchedule")
    @MainActor
    func testCompleteOnboardingCreatesProfileAndSchedule() async throws {
        // GIVEN: ViewModel ready for onboarding completion
        let (viewModel, context) = try createTestEnvironment()
        try cleanupTestData(context: context)
        setupForOnboarding(viewModel: viewModel)

        // WHEN: Completing onboarding
        try await viewModel.completeOnboarding()

        // THEN: Both MedicationProfile and DoseSchedule created
        let profiles = try context.fetch(FetchDescriptor<MedicationProfile>())
        #expect(profiles.count == 1, "Should create one medication profile")

        let schedules = try context.fetch(FetchDescriptor<DoseSchedule>())
        #expect(schedules.count == 1, "Should create one dose schedule")

        // Verify they're linked
        let profile = profiles[0]
        let schedule = schedules[0]
        #expect(schedule.medicationProfile?.id == profile.id)
    }

    @Test("completeOnboarding creates schedule with weekly pattern")
    @MainActor
    func testCompleteOnboardingCreatesWeeklySchedule() async throws {
        // GIVEN: ViewModel configured for weekly dosing
        let (viewModel, context) = try createTestEnvironment()
        try cleanupTestData(context: context)
        setupForOnboarding(viewModel: viewModel, pattern: .weekly)

        // WHEN: Completing onboarding
        try await viewModel.completeOnboarding()

        // THEN: Schedule has weekly pattern
        let schedules = try context.fetch(FetchDescriptor<DoseSchedule>())
        #expect(schedules[0].patternType == .weekly)
        #expect(schedules[0].isActive == true)
    }

    @Test("completeOnboarding creates schedule with splitDose pattern")
    @MainActor
    func testCompleteOnboardingCreatesSplitDoseSchedule() async throws {
        // GIVEN: ViewModel configured for split-dose
        let (viewModel, context) = try createTestEnvironment()
        try cleanupTestData(context: context)
        setupForOnboarding(viewModel: viewModel, medication: .tirzepatide, pattern: .splitDose)

        // WHEN: Completing onboarding
        try await viewModel.completeOnboarding()

        // THEN: Schedule has splitDose pattern
        let schedules = try context.fetch(FetchDescriptor<DoseSchedule>())
        #expect(schedules[0].patternType == .splitDose)
    }

    @Test("completeOnboarding uses correct dose amount in schedule")
    @MainActor
    func testCompleteOnboardingUsesCorrectDose() async throws {
        // GIVEN: ViewModel with specific dose
        let (viewModel, context) = try createTestEnvironment()
        try cleanupTestData(context: context)
        setupForOnboarding(viewModel: viewModel, dose: 0.25)

        // WHEN: Completing onboarding
        try await viewModel.completeOnboarding()

        // THEN: Schedule configuration has correct dose
        let schedules = try context.fetch(FetchDescriptor<DoseSchedule>())
        let schedule = schedules[0]

        // Decode and verify dose amount
        let scheduleService = ScheduleService(context: context)
        let configuration = try scheduleService.decodeScheduleConfiguration(schedule)
        #expect(configuration.doseAmount == 0.25)
    }

    @Test("completeOnboarding fails gracefully without authenticated user")
    @MainActor
    func testCompleteOnboardingFailsWithoutUser() async throws {
        // GIVEN: ViewModel without authenticated user
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        authManager.currentUser = nil  // No authenticated user

        let viewModel = OnboardingViewModel(
            dataController: dataController,
            authManager: authManager
        )
        setupForOnboarding(viewModel: viewModel)

        // WHEN/THEN: Should throw error
        await #expect(throws: OnboardingError.self) {
            try await viewModel.completeOnboarding()
        }
    }

    @Test("completeOnboarding fails gracefully without selected medication")
    @MainActor
    func testCompleteOnboardingFailsWithoutMedication() async throws {
        // GIVEN: ViewModel without medication selection
        let (viewModel, _) = try createTestEnvironment()
        viewModel.selectedMedication = nil  // No medication selected
        viewModel.selectedDose = 0.5
        viewModel.selectedSites = ["Abdomen"]

        // WHEN/THEN: Should throw error
        await #expect(throws: OnboardingError.self) {
            try await viewModel.completeOnboarding()
        }
    }
}
