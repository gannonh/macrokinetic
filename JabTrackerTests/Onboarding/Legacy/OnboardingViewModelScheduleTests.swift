// OnboardingViewModelScheduleTests.swift
// JabTrackerTests
//
// Created for testing schedule configuration logic in OnboardingViewModel
//

import Foundation
import Testing

@testable import JabTracker

/// Tests for OnboardingViewModel schedule configuration methods
struct OnboardingViewModelScheduleTests {

    // MARK: - Test Helpers

    /// Creates a test OnboardingViewModel with required dependencies
    @MainActor
    private func createTestViewModel() -> OnboardingViewModel {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        return LegacyOnboardingViewModel(dataController: dataController, authManager: authManager)
    }

    // MARK: - saveScheduleConfiguration() Tests

    @Test("saveScheduleConfiguration saves weekly pattern and proceeds to next step")
    @MainActor
    func testSaveWeeklyConfiguration() async throws {
        // GIVEN: ViewModel at schedule setup step
        let viewModel = createTestViewModel()
        viewModel.currentStep = .scheduleSetup
        let initialStep = viewModel.currentStep

        // WHEN: Saving valid weekly configuration
        viewModel.saveScheduleConfiguration(
            pattern: .weekly,
            reminderMinutes: 60,
            enableMultiple: false
        )

        // THEN: Configuration saved and moved to next step
        #expect(viewModel.schedulePattern == .weekly)
        #expect(viewModel.reminderMinutes == 60)
        #expect(viewModel.enableMultipleReminders == false)
        #expect(viewModel.currentStep != initialStep, "Should have moved to next step")
        #expect(viewModel.errorMessage == nil)
    }

    @Test("saveScheduleConfiguration saves split-dose pattern correctly")
    @MainActor
    func testSaveSplitDoseConfiguration() async throws {
        // GIVEN: ViewModel at schedule setup step
        let viewModel = createTestViewModel()
        viewModel.currentStep = .scheduleSetup

        // WHEN: Saving split-dose configuration with multiple reminders
        viewModel.saveScheduleConfiguration(
            pattern: .splitDose,
            reminderMinutes: 30,
            enableMultiple: true
        )

        // THEN: Configuration saved with correct values
        #expect(viewModel.schedulePattern == .splitDose)
        #expect(viewModel.reminderMinutes == 30)
        #expect(viewModel.enableMultipleReminders == true)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("saveScheduleConfiguration rejects invalid custom pattern")
    @MainActor
    func testSaveInvalidCustomConfiguration() async throws {
        // GIVEN: ViewModel at schedule setup step with invalid custom pattern
        let viewModel = createTestViewModel()
        viewModel.currentStep = .scheduleSetup
        viewModel.customScheduleValid = false
        let initialStep = viewModel.currentStep

        // WHEN: Attempting to save invalid custom configuration
        viewModel.saveScheduleConfiguration(
            pattern: .custom,
            reminderMinutes: 60,
            enableMultiple: false
        )

        // THEN: Configuration NOT saved, error message set, step unchanged
        #expect(viewModel.currentStep == initialStep, "Should NOT have moved to next step")
        #expect(viewModel.errorMessage != nil, "Should set error message for invalid custom pattern")
    }

    @Test("saveScheduleConfiguration accepts valid custom pattern")
    @MainActor
    func testSaveValidCustomConfiguration() async throws {
        // GIVEN: ViewModel at schedule setup step with VALID custom pattern
        let viewModel = createTestViewModel()
        viewModel.currentStep = .scheduleSetup
        viewModel.customScheduleValid = true
        let initialStep = viewModel.currentStep

        // WHEN: Saving valid custom configuration
        viewModel.saveScheduleConfiguration(
            pattern: .custom,
            reminderMinutes: 120,
            enableMultiple: true
        )

        // THEN: Configuration saved and moved to next step
        #expect(viewModel.schedulePattern == .custom)
        #expect(viewModel.reminderMinutes == 120)
        #expect(viewModel.enableMultipleReminders == true)
        #expect(viewModel.currentStep != initialStep, "Should have moved to next step")
        #expect(viewModel.errorMessage == nil)
    }

    @Test("saveScheduleConfiguration clears previous error messages on success")
    @MainActor
    func testSaveClearsPreviousErrors() async throws {
        // GIVEN: ViewModel with previous error message
        let viewModel = createTestViewModel()
        viewModel.currentStep = .scheduleSetup
        viewModel.errorMessage = "Previous error"

        // WHEN: Saving valid configuration
        viewModel.saveScheduleConfiguration(
            pattern: .weekly,
            reminderMinutes: 60,
            enableMultiple: false
        )

        // THEN: Error message cleared
        #expect(viewModel.errorMessage == nil, "Should clear previous error on success")
    }

    @Test("saveScheduleConfiguration validates before saving")
    @MainActor
    func testSaveValidatesConfiguration() async throws {
        // GIVEN: ViewModel with invalid custom pattern
        let viewModel = createTestViewModel()
        viewModel.currentStep = .scheduleSetup
        viewModel.customScheduleValid = false

        // WHEN: Attempting to save invalid configuration
        viewModel.saveScheduleConfiguration(
            pattern: .custom,
            reminderMinutes: 60,
            enableMultiple: false
        )

        // THEN: Validation failed, configuration not saved
        #expect(viewModel.schedulePattern != .custom, "Should NOT save invalid pattern")
        #expect(viewModel.errorMessage != nil, "Should set validation error")
    }

    @Test("saveScheduleConfiguration updates all state properties")
    @MainActor
    func testSaveUpdatesAllProperties() async throws {
        // GIVEN: ViewModel at schedule setup step
        let viewModel = createTestViewModel()
        viewModel.currentStep = .scheduleSetup

        // WHEN: Saving configuration with all parameters
        viewModel.saveScheduleConfiguration(
            pattern: .splitDose,
            reminderMinutes: 15,
            enableMultiple: true
        )

        // THEN: All properties updated correctly
        #expect(viewModel.schedulePattern == .splitDose)
        #expect(viewModel.reminderMinutes == 15)
        #expect(viewModel.enableMultipleReminders == true)
    }
}
