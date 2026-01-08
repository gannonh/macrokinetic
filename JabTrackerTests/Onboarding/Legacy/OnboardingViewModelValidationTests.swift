import Foundation
import Testing

@testable import JabTracker

@Suite("OnboardingViewModel Schedule Validation Tests")
@MainActor
struct OnboardingViewModelValidationTests {

    // MARK: - Test Properties

    var dataController: DataController
    var authManager: AuthenticationManager
    var viewModel: OnboardingViewModel

    init() throws {
        // Create test container
        dataController = DataController.testContainer()
        authManager = AuthenticationManager(dataController: dataController)
        viewModel = LegacyOnboardingViewModel(dataController: dataController, authManager: authManager)
    }

    // MARK: - Weekly Pattern Validation Tests

    @Test("Weekly pattern is always valid")
    func testWeeklyPatternValidation() {
        // GIVEN: ViewModel with weekly schedule pattern
        viewModel.schedulePattern = .weekly
        viewModel.customScheduleValid = false

        // WHEN: Validating schedule configuration
        let isValid = viewModel.validateScheduleConfiguration()

        // THEN: Configuration should be valid
        #expect(isValid == true)
    }

    // MARK: - Split Dose Pattern Validation Tests

    @Test("Split dose pattern is always valid")
    func testSplitDosePatternValidation() {
        // GIVEN: ViewModel with split dose schedule pattern
        viewModel.schedulePattern = .splitDose
        viewModel.customScheduleValid = false

        // WHEN: Validating schedule configuration
        let isValid = viewModel.validateScheduleConfiguration()

        // THEN: Configuration should be valid
        #expect(isValid == true)
    }

    // MARK: - Custom Pattern Validation Tests

    @Test("Custom pattern requires customScheduleValid = true")
    func testCustomPatternRequiresValidation() {
        // GIVEN: ViewModel with custom schedule pattern but not validated
        viewModel.schedulePattern = .custom
        viewModel.customScheduleValid = false

        // WHEN: Validating schedule configuration
        let isValid = viewModel.validateScheduleConfiguration()

        // THEN: Configuration should be invalid
        #expect(isValid == false)
    }

    @Test("Custom pattern is valid when customScheduleValid = true")
    func testCustomPatternWithValidation() {
        // GIVEN: ViewModel with custom schedule pattern and validated
        viewModel.schedulePattern = .custom
        viewModel.customScheduleValid = true

        // WHEN: Validating schedule configuration
        let isValid = viewModel.validateScheduleConfiguration()

        // THEN: Configuration should be valid
        #expect(isValid == true)
    }

    // MARK: - Reminder Configuration Tests

    @Test("Reminder minutes can be any positive value")
    func testReminderMinutesValidation() {
        // GIVEN: ViewModel with various reminder minute values
        viewModel.schedulePattern = .weekly

        let testValues = [0, 15, 30, 60, 120, 1440]  // 0 min to 24 hours

        for minutes in testValues {
            // WHEN: Setting reminder minutes
            viewModel.reminderMinutes = minutes

            // THEN: Configuration should remain valid
            let isValid = viewModel.validateScheduleConfiguration()
            #expect(isValid == true, "Configuration should be valid with \(minutes) minute reminder")
        }
    }

    @Test("Multiple reminders flag does not affect validation")
    func testMultipleRemindersFlag() {
        // GIVEN: ViewModel with weekly schedule
        viewModel.schedulePattern = .weekly

        // WHEN: Toggling multiple reminders flag
        viewModel.enableMultipleReminders = false
        let validWithoutMultiple = viewModel.validateScheduleConfiguration()

        viewModel.enableMultipleReminders = true
        let validWithMultiple = viewModel.validateScheduleConfiguration()

        // THEN: Both should be valid
        #expect(validWithoutMultiple == true)
        #expect(validWithMultiple == true)
    }
}
