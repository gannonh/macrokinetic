//
//  OnboardingScheduleSetupUITests.swift
//  JabTrackerUITests
//
//  E2E acceptance tests for onboarding schedule setup step
//

import XCTest

final class OnboardingScheduleSetupUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data", "--force-onboarding"]
        app.launch()
    }

    // MARK: - Helper Methods

    /// Navigate from app launch through onboarding to schedule setup step
    private func navigateToScheduleSetup() throws {
        // Welcome screen
        let welcomeContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(welcomeContinue.waitForExistence(timeout: 5), "Continue button should exist on welcome screen")
        welcomeContinue.tap()

        // Medication selection - use the actual medication button identifier
        let semaglutideButton = app.buttons["medication-semaglutide"]
        XCTAssertTrue(semaglutideButton.waitForExistence(timeout: 5), "Semaglutide button should exist")
        semaglutideButton.tap()

        // Continue to dose setup
        let medicationContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(
            medicationContinue.waitForExistence(timeout: 5), "Continue button should exist after medication selection")
        medicationContinue.tap()

        // Dose setup - select 0.25mg dose button
        let doseButton = app.buttons["dose-button-0.25"]
        XCTAssertTrue(doseButton.waitForExistence(timeout: 5), "Dose button should exist")
        doseButton.tap()

        // Select injection site (required to proceed)
        let abdomenSite = app.buttons["injection-site-abdomen"]
        XCTAssertTrue(abdomenSite.waitForExistence(timeout: 2), "Injection site button should exist")
        abdomenSite.tap()

        // Continue to schedule setup (button should be enabled now)
        let doseContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(doseContinue.exists, "Continue button should exist after dose entry")
        doseContinue.tap()

        // Wait for schedule setup view to appear (give extra time for navigation)
        // Debug what we see
        sleep(3)
        TestUtilities.debugElements(in: app, containing: "")

        // Try different element types for schedule setup view
        var scheduleView = app.scrollViews["schedule-setup-view"]
        if !scheduleView.exists {
            scheduleView = app.otherElements["schedule-setup-view"]
        }

        XCTAssertTrue(scheduleView.waitForExistence(timeout: 10), "Schedule setup view should appear")
    }

    // MARK: - ACCEPTANCE CRITERION 1: Schedule setup appears after dose setup step

    func testScheduleSetupAppearsAfterDoseSetup() throws {
        // GIVEN: User completes welcome, medication selection, and dose setup steps
        // WHEN: User taps Continue on dose setup step
        try navigateToScheduleSetup()

        // Debug elements to understand actual accessibility hierarchy
        TestUtilities.debugElements(in: app, containing: "schedule")

        // THEN: Schedule setup view appears with "Set Up Your Schedule" title
        let titleText = app.staticTexts["Set Up Your Schedule"]
        XCTAssertTrue(titleText.exists, "Schedule setup title should be visible")

        // THEN: Schedule pattern picker is visible
        let weeklyCard = app.buttons["pattern-card-weekly"]
        XCTAssertTrue(weeklyCard.exists, "Weekly pattern card should be visible")

        // THEN: Concentration preview section is visible
        let preview = app.otherElements["concentration-curve-preview"]
        XCTAssertTrue(preview.exists, "Concentration preview should be visible")

        // THEN: Reminder preferences section is visible
        let reminderPicker = app.buttons["reminder-time-picker"]
        XCTAssertTrue(reminderPicker.exists, "Reminder picker should be visible")
    }

    // MARK: - ACCEPTANCE CRITERION 2: User can select from 3 schedule patterns

    func testUserCanSelectSchedulePatterns() throws {
        // GIVEN: User is on schedule setup step
        // WHEN: User views available patterns
        // THEN: Three pattern cards are displayed: "Standard Weekly", "Split Dose", "Custom Pattern"
        // THEN: Each pattern card shows description
        // THEN: User can tap each pattern card to select
        // THEN: Selected pattern shows visual feedback (blue border, checkmark)
    }

    // MARK: - ACCEPTANCE CRITERION 3: Concentration curve preview updates when pattern changes

    func testConcentrationPreviewUpdatesOnPatternChange() throws {
        // GIVEN: User is on schedule setup step with "Standard Weekly" pattern selected
        // WHEN: User selects "Split Dose" pattern
        // THEN: Concentration curve preview updates to show split-dose pattern
        // THEN: Peak concentration label updates
        // THEN: Trough concentration label updates
        // THEN: Preview update completes in <1 second
    }

    // MARK: - ACCEPTANCE CRITERION 4: Peak and trough levels annotated on preview

    func testPeakAndTroughLevelsDisplayed() throws {
        // GIVEN: User is on schedule setup step
        // WHEN: User views concentration preview
        // THEN: "Peak" label with concentration value is visible
        // THEN: "Trough" label with concentration value is visible
        // THEN: Peak value is higher than trough value
        // THEN: Values update when pattern changes
    }

    // MARK: - ACCEPTANCE CRITERION 5: Reminder preferences configurable

    func testReminderPreferencesConfiguration() throws {
        // GIVEN: User is on schedule setup step
        // WHEN: User taps reminder time picker
        // THEN: Options displayed: "15 min before", "30 min before", "1 hour before", "2 hours before"
        // WHEN: User selects "1 hour before"
        // THEN: Selected value updates in picker
        // WHEN: User toggles "Send multiple reminders"
        // THEN: Toggle switches on/off correctly
    }

    // MARK: - ACCEPTANCE CRITERION 6: Multiple reminders toggle with explanation

    func testMultipleRemindersToggle() throws {
        // GIVEN: User is on schedule setup step
        // WHEN: User views reminder preferences section
        // THEN: "Send multiple reminders" toggle is visible
        // THEN: Toggle has descriptive label
        // WHEN: User taps toggle
        // THEN: Toggle state changes immediately
    }

    // MARK: - ACCEPTANCE CRITERION 7: Continue button validation

    func testContinueButtonValidation() throws {
        // GIVEN: User is on schedule setup step
        // WHEN: No pattern is selected
        // THEN: Continue button is disabled
        // WHEN: User selects "Standard Weekly" pattern
        // THEN: Continue button becomes enabled
        // WHEN: User taps Continue button
        // THEN: User proceeds to notifications step
    }

    // MARK: - ACCEPTANCE CRITERION 8: Complete onboarding flow with weekly schedule

    func testCompleteOnboardingWithWeeklySchedule() throws {
        // GIVEN: User is on schedule setup step
        // WHEN: User selects "Standard Weekly" pattern
        // WHEN: User configures reminder for "30 min before"
        // WHEN: User enables multiple reminders
        // WHEN: User taps Continue through remaining steps
        // WHEN: User completes onboarding
        // THEN: DoseSchedule entity is created with weekly pattern
        // THEN: Notification permissions are requested
        // THEN: User reaches main app with schedule configured
    }

    // MARK: - ACCEPTANCE CRITERION 9: Complete onboarding with split-dose schedule

    func testCompleteOnboardingWithSplitDoseSchedule() throws {
        // GIVEN: User is on schedule setup step
        // WHEN: User selects "Split Dose" pattern
        // WHEN: User configures reminder for "1 hour before"
        // WHEN: User taps Continue through remaining steps
        // WHEN: User completes onboarding
        // THEN: DoseSchedule entity is created with split-dose pattern
        // THEN: User reaches main app with twice-weekly schedule configured
    }

    // MARK: - ACCESSIBILITY: VoiceOver navigation

    func testVoiceOverNavigation() throws {
        // GIVEN: User is on schedule setup step
        // WHEN: VoiceOver is enabled
        // THEN: All pattern cards are accessible with descriptive labels
        // THEN: Concentration preview has accessibility label describing trend
        // THEN: Reminder picker announces selected value
        // THEN: Multiple reminders toggle announces state
        // THEN: Continue button announces enabled/disabled state with reason
    }

    // MARK: - PERFORMANCE: Chart preview rendering

    func testChartPreviewPerformance() throws {
        // GIVEN: User is on schedule setup step
        // WHEN: User selects a pattern
        // THEN: Concentration curve preview renders in <1 second (NFR1)
        // WHEN: User changes pattern
        // THEN: Preview updates in <200ms (NFR2)
    }

    // MARK: - NAVIGATION: Back button preserves state

    func testBackNavigationPreservesState() throws {
        // GIVEN: User is on schedule setup step
        // WHEN: User selects "Split Dose" pattern
        // WHEN: User configures reminder for "1 hour before"
        // WHEN: User enables multiple reminders
        // WHEN: User taps Back button
        // THEN: User returns to dose setup step
        // WHEN: User taps Continue to return to schedule setup
        // THEN: Previously selected pattern is still selected
        // THEN: Previously configured reminder time is preserved
        // THEN: Multiple reminders toggle state is preserved
    }
}
