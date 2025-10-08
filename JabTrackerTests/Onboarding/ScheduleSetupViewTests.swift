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
    let dataController: DataController
    let authManager: AuthenticationManager
    let viewModel: OnboardingViewModel

    init() throws {
        // Create test container
        self.dataController = DataController.testContainer()
        self.authManager = AuthenticationManager(dataController: dataController)

        // Setup test user
        let user = authManager.setupUITestingUser(dataController: dataController)
        try dataController.container.mainContext.save()

        self.viewModel = OnboardingViewModel(
            dataController: dataController,
            authManager: authManager
        )

        // Setup medication selection (prerequisite for schedule setup)
        viewModel.selectedMedication = .semaglutide
        viewModel.selectedDose = 0.5
    }

    // MARK: - Pattern Selection Tests

    @Test("Default pattern is weekly")
    func testDefaultPattern() {
        #expect(viewModel.schedulePattern == .weekly)
    }

    @Test("Can change pattern selection")
    func testPatternChange() {
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
        #expect(viewModel.reminderMinutes == 60)
    }

    @Test("Can configure reminder times")
    func testReminderTimeConfiguration() {
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
        #expect(viewModel.enableMultipleReminders == false)

        viewModel.enableMultipleReminders = true
        #expect(viewModel.enableMultipleReminders == true)

        viewModel.enableMultipleReminders = false
        #expect(viewModel.enableMultipleReminders == false)
    }

    // MARK: - Validation Tests

    @Test("Weekly pattern is always valid")
    func testWeeklyPatternValid() {
        viewModel.schedulePattern = .weekly
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("Split dose pattern is always valid")
    func testSplitDosePatternValid() {
        viewModel.schedulePattern = .splitDose
        #expect(viewModel.canProceedToNext == true)
    }

    @Test("Custom pattern requires validation")
    func testCustomPatternValidation() {
        viewModel.schedulePattern = .custom
        viewModel.customScheduleValid = false
        #expect(viewModel.canProceedToNext == false)

        viewModel.customScheduleValid = true
        #expect(viewModel.canProceedToNext == true)
    }

    // MARK: - Navigation Tests

    @Test("Can navigate to schedule setup step")
    func testNavigateToScheduleSetup() {
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
        viewModel.currentStep = .scheduleSetup
        viewModel.schedulePattern = .custom
        viewModel.customScheduleValid = false

        #expect(viewModel.canProceedToNext == false)
    }

    @Test("Can proceed from schedule setup with valid configuration")
    func testCanProceedWithValidConfig() {
        viewModel.currentStep = .scheduleSetup
        viewModel.schedulePattern = .weekly

        #expect(viewModel.canProceedToNext == true)
    }
}
