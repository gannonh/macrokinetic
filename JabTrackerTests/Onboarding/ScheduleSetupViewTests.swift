//
//  ScheduleSetupViewTests.swift
//  JabTrackerTests
//
//  Unit tests for ScheduleSetupView component state and validation
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
struct ScheduleSetupViewTests {
    /// Create test environment for schedule setup tests
    func createTestViewModel() -> OnboardingViewModel {
        let dataController = DataController.testContainer()
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(
            dataController: dataController,
            authManager: authManager
        )

        // Setup medication selection (prerequisite for schedule setup)
        viewModel.selectedMedication = .semaglutide
        viewModel.selectedDose = 0.5

        return viewModel
    }

    // MARK: - Pattern Selection Tests

    @Test("Default pattern is weekly")
    func testDefaultPattern() {
        let viewModel = createTestViewModel()
        #expect(viewModel.schedulePattern == .weekly)
    }

    @Test("Can change pattern selection")
    func testPatternChange() {
        let viewModel = createTestViewModel()

        // Change to split dose
        viewModel.schedulePattern = .splitDose
        #expect(viewModel.schedulePattern == .splitDose)

        // Change to custom
        viewModel.schedulePattern = .custom
        #expect(viewModel.schedulePattern == .custom)
    }

    // MARK: - Reminder Configuration Tests

    @Test("Default reminder time is 60 minutes")
    func testDefaultReminderTime() {
        let viewModel = createTestViewModel()
        #expect(viewModel.reminderMinutes == 60)
    }

    @Test("Can configure reminder times")
    func testReminderTimeConfiguration() {
        let viewModel = createTestViewModel()

        // 15 minutes
        viewModel.reminderMinutes = 15
        #expect(viewModel.reminderMinutes == 15)

        // 30 minutes
        viewModel.reminderMinutes = 30
        #expect(viewModel.reminderMinutes == 30)

        // 120 minutes (2 hours)
        viewModel.reminderMinutes = 120
        #expect(viewModel.reminderMinutes == 120)
    }

    @Test("Can toggle multiple reminders")
    func testMultipleRemindersToggle() {
        let viewModel = createTestViewModel()

        #expect(viewModel.enableMultipleReminders == false)

        viewModel.enableMultipleReminders = true
        #expect(viewModel.enableMultipleReminders == true)

        viewModel.enableMultipleReminders = false
        #expect(viewModel.enableMultipleReminders == false)
    }

    // MARK: - Validation Tests

    @Test("Weekly pattern is always valid")
    func testWeeklyPatternValid() {
        let viewModel = createTestViewModel()
        viewModel.currentStep = .scheduleSetup
        viewModel.schedulePattern = .weekly
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("Split dose pattern is always valid")
    func testSplitDosePatternValid() {
        let viewModel = createTestViewModel()
        viewModel.currentStep = .scheduleSetup
        viewModel.schedulePattern = .splitDose
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("Custom pattern requires validation")
    func testCustomPatternValidation() {
        let viewModel = createTestViewModel()
        viewModel.currentStep = .scheduleSetup
        viewModel.schedulePattern = .custom
        viewModel.customScheduleValid = false
        #expect(viewModel.canProceedToNext == false)

        viewModel.customScheduleValid = true
        #expect(viewModel.canProceedToNext == true)
    }

    // MARK: - Navigation Tests

    @Test("Can navigate to schedule setup step")
    func testNavigateToScheduleSetup() {
        let viewModel = createTestViewModel()

        // Navigate through required steps
        viewModel.currentStep = .welcome
        viewModel.moveToNextStep()
        #expect(viewModel.currentStep == .medicationSelection)

        viewModel.moveToNextStep()
        #expect(viewModel.currentStep == .doseSetup)

        viewModel.moveToNextStep()
        #expect(viewModel.currentStep == .scheduleSetup)
    }

    @Test("Cannot proceed from schedule setup without valid configuration")
    func testCannotProceedWithoutValidConfig() {
        let viewModel = createTestViewModel()
        viewModel.currentStep = .scheduleSetup
        viewModel.schedulePattern = .custom
        viewModel.customScheduleValid = false

        #expect(viewModel.canProceedToNext == false)
    }

    @Test("Can proceed from schedule setup with valid configuration")
    func testCanProceedWithValidConfig() {
        let viewModel = createTestViewModel()
        viewModel.currentStep = .scheduleSetup
        viewModel.schedulePattern = .weekly

        #expect(viewModel.canProceedToNext == true)
    }
}
