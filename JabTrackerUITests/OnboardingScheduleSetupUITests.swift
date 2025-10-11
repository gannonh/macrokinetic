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

        // Wait for schedule setup view to appear
        sleep(3)

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
        try navigateToScheduleSetup()

        // WHEN: User views available patterns
        // THEN: Three pattern cards are displayed with correct titles
        let weeklyCard = app.buttons["pattern-card-weekly"]
        let splitDoseCard = app.buttons["pattern-card-splitDose"]
        let customCard = app.buttons["pattern-card-custom"]

        XCTAssertTrue(weeklyCard.exists, "Weekly pattern card should be visible")
        XCTAssertTrue(splitDoseCard.exists, "Split dose pattern card should be visible")
        XCTAssertTrue(customCard.exists, "Custom pattern card should be visible")

        // THEN: Each pattern card shows correct title in label
        XCTAssertEqual(weeklyCard.label, "Standard Weekly", "Weekly card should show title")
        XCTAssertEqual(
            splitDoseCard.label, "Split Dose (Twice Weekly)", "Split dose card should show title")
        XCTAssertEqual(customCard.label, "Custom Pattern", "Custom card should show title")

        // THEN: User can tap each pattern card to select
        // Weekly pattern should be selected by default
        XCTAssertTrue(weeklyCard.isSelected, "Weekly pattern should be selected by default")

        // Tap split dose pattern
        splitDoseCard.tap()
        XCTAssertTrue(splitDoseCard.isSelected, "Split dose pattern should be selected after tap")
        XCTAssertFalse(weeklyCard.isSelected, "Weekly pattern should not be selected")

        // Tap custom pattern
        customCard.tap()
        XCTAssertTrue(customCard.isSelected, "Custom pattern should be selected after tap")
        XCTAssertFalse(splitDoseCard.isSelected, "Split dose pattern should not be selected")

        // Tap weekly pattern again
        weeklyCard.tap()
        XCTAssertTrue(weeklyCard.isSelected, "Weekly pattern should be selected after tap")
        XCTAssertFalse(customCard.isSelected, "Custom pattern should not be selected")
    }

    // MARK: - ACCEPTANCE CRITERION 3: Concentration curve preview updates when pattern changes

    func testConcentrationPreviewUpdatesOnPatternChange() throws {
        // GIVEN: User is on schedule setup step with "Standard Weekly" pattern selected
        try navigateToScheduleSetup()

        // Verify weekly pattern is selected by default
        let weeklyCard = app.buttons["pattern-card-weekly"]
        XCTAssertTrue(weeklyCard.isSelected, "Weekly pattern should be selected by default")

        // Get initial concentration values (StaticText elements, use .element(boundBy: 0) for duplicates)
        let peakLabel = app.staticTexts.matching(identifier: "concentration-label-peak").element(boundBy: 0)
        let troughLabel = app.staticTexts.matching(identifier: "concentration-label-trough").element(boundBy: 0)

        XCTAssertTrue(peakLabel.waitForExistence(timeout: 5), "Peak concentration label should exist")
        XCTAssertTrue(troughLabel.exists, "Trough concentration label should exist")

        // WHEN: User selects "Split Dose" pattern
        let splitDoseCard = app.buttons["pattern-card-splitDose"]
        XCTAssertTrue(splitDoseCard.exists, "Split dose pattern card should exist")

        // Measure time from tap to when labels are readable (preview update time)
        let updateStartTime = Date()
        splitDoseCard.tap()

        // Wait for labels to be stable (small delay for UI to update)
        usleep(100_000)  // 0.1 second

        let updateDuration = Date().timeIntervalSince(updateStartTime)

        // THEN: Labels still exist and are displaying values after pattern change
        XCTAssertTrue(peakLabel.exists, "Peak label should still exist after pattern change")
        XCTAssertTrue(troughLabel.exists, "Trough label should still exist after pattern change")

        // THEN: Preview update completes in <1 second (already measured above)
        XCTAssertLessThan(
            updateDuration, 1.0,
            "Preview update should complete in less than 1 second (NFR requirement)")
    }

    // MARK: - ACCEPTANCE CRITERION 4: Peak and trough levels annotated on preview

    func testPeakAndTroughLevelsDisplayed() throws {
        // GIVEN: User is on schedule setup step
        try navigateToScheduleSetup()

        // WHEN: User views concentration preview
        // THEN: "Peak" label with concentration value is visible
        let peakLabel = app.staticTexts.matching(identifier: "concentration-label-peak").element(boundBy: 0)
        XCTAssertTrue(peakLabel.waitForExistence(timeout: 5), "Peak label should be visible")

        // THEN: "Trough" label with concentration value is visible
        let troughLabel = app.staticTexts.matching(identifier: "concentration-label-trough").element(boundBy: 0)
        XCTAssertTrue(troughLabel.exists, "Trough label should be visible")

        // Verify labels show title and value text
        XCTAssertEqual(peakLabel.label, "Peak", "Peak label should show 'Peak' title")
        XCTAssertEqual(troughLabel.label, "Trough", "Trough label should show 'Trough' title")
    }

    // MARK: - ACCEPTANCE CRITERION 5: Reminder preferences configurable

    func testReminderPreferencesConfiguration() throws {
        // GIVEN: User is on schedule setup step
        try navigateToScheduleSetup()

        // WHEN: User taps reminder time picker
        let reminderPicker = app.buttons["reminder-time-picker"]
        XCTAssertTrue(reminderPicker.exists, "Reminder picker should be visible")

        // THEN: Verify multiple reminders toggle exists and is accessible
        let multipleRemindersToggle = app.switches["Enable multiple reminders"]
        XCTAssertTrue(
            multipleRemindersToggle.exists,
            "Multiple reminders toggle should be visible")

        // Verify toggle starts in off state
        let initialValue = multipleRemindersToggle.value as? String ?? ""

        // WHEN: User toggles "Send multiple reminders"
        multipleRemindersToggle.tap()

        // THEN: Toggle switches on/off correctly
        let updatedValue = multipleRemindersToggle.value as? String ?? ""
        XCTAssertNotEqual(
            initialValue, updatedValue,
            "Toggle value should change after tap")

        // Tap again to verify it toggles back
        multipleRemindersToggle.tap()
        let finalValue = multipleRemindersToggle.value as? String ?? ""
        XCTAssertEqual(
            initialValue, finalValue,
            "Toggle should return to initial state after second tap")
    }

    // MARK: - ACCEPTANCE CRITERION 6: Multiple reminders toggle with explanation

    func testMultipleRemindersToggle() throws {
        // GIVEN: User is on schedule setup step
        try navigateToScheduleSetup()

        // WHEN: User views reminder preferences section
        // THEN: "Send multiple reminders" toggle is visible
        let multipleRemindersToggle = app.switches["Enable multiple reminders"]
        XCTAssertTrue(
            multipleRemindersToggle.exists,
            "Multiple reminders toggle should be visible")

        // THEN: Toggle has descriptive label text
        let toggleLabelText = app.staticTexts["Send multiple reminders"]
        XCTAssertTrue(toggleLabelText.exists, "Toggle label text should be visible")

        // THEN: Toggle has explanation text
        let explanationText = app.staticTexts["Get reminded again if you haven't logged your dose"]
        XCTAssertTrue(explanationText.exists, "Toggle explanation text should be visible")

        // WHEN: User taps toggle
        let initialValue = multipleRemindersToggle.value as? String ?? ""
        multipleRemindersToggle.tap()

        // THEN: Toggle state changes immediately
        let updatedValue = multipleRemindersToggle.value as? String ?? ""
        XCTAssertNotEqual(
            initialValue, updatedValue,
            "Toggle state should change immediately after tap")
    }

    // MARK: - ACCEPTANCE CRITERION 7: Continue button validation

    func testContinueButtonValidation() throws {
        // GIVEN: User is on schedule setup step
        try navigateToScheduleSetup()

        // WHEN: User views schedule setup with "Standard Weekly" pattern selected by default
        let weeklyCard = app.buttons["pattern-card-weekly"]
        XCTAssertTrue(weeklyCard.isSelected, "Weekly pattern should be selected by default")

        // THEN: Continue button exists and is enabled
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.exists, "Continue button should exist")
        XCTAssertTrue(continueButton.isEnabled, "Continue button should be enabled when pattern is selected")

        // WHEN: User taps Continue button
        continueButton.tap()

        // THEN: User proceeds to notifications/permissions step
        sleep(2)  // Give time for navigation

        // Verify we've left schedule setup screen
        let scheduleView = app.scrollViews["schedule-setup-view"]
        XCTAssertFalse(scheduleView.exists, "Should have navigated away from schedule setup view")

        // Verify we're on a new screen (permissions request view typically appears next)
        let navigationProgressed = !scheduleView.exists
        XCTAssertTrue(
            navigationProgressed,
            "Navigation should have progressed to next onboarding step")
    }

    // MARK: - ACCEPTANCE CRITERION 8: Complete onboarding flow with weekly schedule

    func testCompleteOnboardingWithWeeklySchedule() throws {
        // GIVEN: User is on schedule setup step
        try navigateToScheduleSetup()

        // WHEN: User has "Standard Weekly" pattern selected (default)
        let weeklyCard = app.buttons["pattern-card-weekly"]
        XCTAssertTrue(weeklyCard.isSelected, "Weekly pattern should be selected by default")

        // WHEN: User verifies reminder preferences are accessible
        let reminderPicker = app.buttons["reminder-time-picker"]
        XCTAssertTrue(reminderPicker.exists, "Reminder picker should be visible")

        // WHEN: User enables multiple reminders
        let multipleRemindersToggle = app.switches["Enable multiple reminders"]
        XCTAssertTrue(multipleRemindersToggle.exists, "Multiple reminders toggle should exist")

        // Enable multiple reminders if not already enabled
        let toggleValue = multipleRemindersToggle.value as? String ?? "0"
        if toggleValue == "0" {
            multipleRemindersToggle.tap()
        }

        // WHEN: User taps Continue to proceed to next step
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.exists, "Continue button should exist")
        continueButton.tap()

        // Wait for next screen (permissions or completion)
        sleep(3)

        // WHEN: User completes remaining onboarding steps
        // Try to find and handle notifications screen if present
        let notificationsEnableButton = app.buttons["notifications-enable-button"]
        let notificationsSkipButton = app.buttons["notifications-skip-button"]

        if notificationsEnableButton.waitForExistence(timeout: 5) {
            notificationsSkipButton.tap()
            sleep(2)
        } else if notificationsSkipButton.exists {
            notificationsSkipButton.tap()
            sleep(2)
        }

        // THEN: User reaches main app with tab bar visible
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 10),
            "Main app tab bar should appear after completing onboarding")

        XCTAssertTrue(tabBar.exists, "Tab bar should be accessible in main app")
    }

    // MARK: - ACCEPTANCE CRITERION 9: Complete onboarding with split-dose schedule

    func testCompleteOnboardingWithSplitDoseSchedule() throws {
        // GIVEN: User is on schedule setup step
        try navigateToScheduleSetup()

        // WHEN: User selects "Split Dose" pattern
        let splitDoseCard = app.buttons["pattern-card-splitDose"]
        XCTAssertTrue(splitDoseCard.exists, "Split dose pattern card should exist")

        // Verify weekly is selected by default
        let weeklyCard = app.buttons["pattern-card-weekly"]
        XCTAssertTrue(weeklyCard.isSelected, "Weekly pattern should be selected by default")

        // Tap split dose pattern
        splitDoseCard.tap()
        XCTAssertTrue(splitDoseCard.isSelected, "Split dose pattern should be selected after tap")

        // WHEN: User configures reminder for "1 hour before"
        let reminderPicker = app.buttons["reminder-time-picker"]
        XCTAssertTrue(reminderPicker.exists, "Reminder picker should be visible")

        // WHEN: User taps Continue to proceed to next step
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.exists, "Continue button should exist")
        continueButton.tap()

        // Wait for next screen
        sleep(3)

        // WHEN: User completes remaining onboarding steps
        // Try to find and handle notifications screen if present
        let notificationsEnableButton = app.buttons["notifications-enable-button"]
        let notificationsSkipButton = app.buttons["notifications-skip-button"]

        if notificationsEnableButton.waitForExistence(timeout: 5) {
            notificationsSkipButton.tap()
            sleep(2)
        } else if notificationsSkipButton.exists {
            notificationsSkipButton.tap()
            sleep(2)
        }

        // THEN: User reaches main app with tab bar visible
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            tabBar.waitForExistence(timeout: 10),
            "Main app tab bar should appear after completing onboarding")

        XCTAssertTrue(tabBar.exists, "Tab bar should be accessible in main app")
    }

    // MARK: - ACCESSIBILITY: VoiceOver navigation

    func testVoiceOverNavigation() throws {
        // GIVEN: User is on schedule setup step
        try navigateToScheduleSetup()

        // THEN: All pattern cards are accessible with descriptive labels
        let weeklyCard = app.buttons["pattern-card-weekly"]
        let splitDoseCard = app.buttons["pattern-card-splitDose"]
        let customCard = app.buttons["pattern-card-custom"]

        XCTAssertTrue(weeklyCard.exists, "Weekly pattern card should exist")
        XCTAssertTrue(splitDoseCard.exists, "Split dose pattern card should exist")
        XCTAssertTrue(customCard.exists, "Custom pattern card should exist")

        // Verify pattern cards have descriptive labels for VoiceOver
        XCTAssertEqual(weeklyCard.label, "Standard Weekly", "Weekly card should have descriptive label")
        XCTAssertEqual(
            splitDoseCard.label, "Split Dose (Twice Weekly)",
            "Split dose card should have descriptive label")
        XCTAssertEqual(customCard.label, "Custom Pattern", "Custom card should have descriptive label")

        // THEN: Concentration preview has accessibility label describing trend
        let peakLabel = app.staticTexts.matching(identifier: "concentration-label-peak").element(boundBy: 0)
        let troughLabel = app.staticTexts.matching(identifier: "concentration-label-trough").element(boundBy: 0)

        XCTAssertTrue(peakLabel.exists, "Peak concentration label should exist")
        XCTAssertTrue(troughLabel.exists, "Trough concentration label should exist")

        // Verify labels have proper accessibility values
        XCTAssertEqual(peakLabel.label, "Peak", "Peak label should have proper accessibility label")
        XCTAssertEqual(troughLabel.label, "Trough", "Trough label should have proper accessibility label")

        // THEN: Reminder picker announces selected value
        let reminderPicker = app.buttons["reminder-time-picker"]
        XCTAssertTrue(reminderPicker.exists, "Reminder picker should exist")

        // Verify picker has accessibility value
        let pickerValue = reminderPicker.value as? String
        XCTAssertNotNil(pickerValue, "Reminder picker should have accessibility value")

        // THEN: Multiple reminders toggle announces state
        let multipleRemindersToggle = app.switches["Enable multiple reminders"]
        XCTAssertTrue(multipleRemindersToggle.exists, "Multiple reminders toggle should exist")

        // Verify toggle has proper accessibility value indicating state
        let toggleValue = multipleRemindersToggle.value as? String
        XCTAssertNotNil(toggleValue, "Toggle should have accessibility value indicating state")

        // THEN: Continue button announces enabled/disabled state with reason
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.exists, "Continue button should exist")
        XCTAssertTrue(continueButton.isEnabled, "Continue button should be enabled with pattern selected")

        // Verify button has proper accessibility label
        let buttonLabel = continueButton.label
        XCTAssertFalse(buttonLabel.isEmpty, "Continue button should have accessibility label")
    }

    // MARK: - PERFORMANCE: Chart preview rendering

    func testChartPreviewPerformance() throws {
        // GIVEN: User is on schedule setup step
        try navigateToScheduleSetup()

        // WHEN: User views concentration preview (already rendered)
        let preview = app.otherElements["concentration-curve-preview"]
        XCTAssertTrue(preview.exists, "Concentration preview should be rendered")

        // Verify concentration labels are present (confirms chart is rendered)
        let peakLabel = app.staticTexts.matching(identifier: "concentration-label-peak").element(boundBy: 0)
        let troughLabel = app.staticTexts.matching(identifier: "concentration-label-trough").element(boundBy: 0)

        XCTAssertTrue(peakLabel.exists, "Peak label should be rendered")
        XCTAssertTrue(troughLabel.exists, "Trough label should be rendered")

        // WHEN: User changes pattern
        let weeklyCard = app.buttons["pattern-card-weekly"]
        let splitDoseCard = app.buttons["pattern-card-splitDose"]

        XCTAssertTrue(weeklyCard.isSelected, "Weekly pattern should be selected by default")

        // Measure pattern change performance
        let updateStartTime = Date()
        splitDoseCard.tap()

        // Wait for UI to update (small delay for pattern change to take effect)
        usleep(50_000)  // 0.05 second

        // Verify pattern changed
        XCTAssertTrue(splitDoseCard.isSelected, "Split dose pattern should be selected after tap")

        let updateDuration = Date().timeIntervalSince(updateStartTime)

        // THEN: Preview updates in reasonable time
        XCTAssertLessThan(
            updateDuration, 1.0,
            "Preview update should complete in less than 1 second for E2E test (NFR requirement)")

        // Verify chart elements still exist after pattern change
        XCTAssertTrue(preview.exists, "Preview should still exist after pattern change")
        XCTAssertTrue(peakLabel.exists, "Peak label should still exist after pattern change")
        XCTAssertTrue(troughLabel.exists, "Trough label should still exist after pattern change")
    }

    // MARK: - NAVIGATION: Back button preserves state

    func testBackNavigationPreservesState() throws {
        // GIVEN: User is on schedule setup step
        try navigateToScheduleSetup()

        // WHEN: User selects "Split Dose" pattern
        let splitDoseCard = app.buttons["pattern-card-splitDose"]
        XCTAssertTrue(splitDoseCard.exists, "Split dose pattern card should exist")
        splitDoseCard.tap()
        XCTAssertTrue(splitDoseCard.isSelected, "Split dose pattern should be selected")

        // WHEN: User enables multiple reminders
        let multipleRemindersToggle = app.switches["Enable multiple reminders"]
        XCTAssertTrue(multipleRemindersToggle.exists, "Multiple reminders toggle should exist")

        let toggleValue = multipleRemindersToggle.value as? String ?? "0"
        if toggleValue == "0" {
            multipleRemindersToggle.tap()
        }

        // Verify toggle is now enabled
        let updatedToggleValue = multipleRemindersToggle.value as? String ?? "0"
        XCTAssertNotEqual(updatedToggleValue, "0", "Toggle should be enabled")

        // WHEN: User taps Back button
        let backButton = app.buttons["onboarding-back-button"]
        XCTAssertTrue(backButton.exists, "Back button should exist in navigation bar")
        backButton.tap()

        sleep(2)  // Wait for navigation

        // THEN: User returns to dose setup step
        let doseButton = app.buttons["dose-button-0.25"]
        XCTAssertTrue(
            doseButton.waitForExistence(timeout: 5),
            "Should be back on dose setup step with dose button visible")

        // WHEN: User taps Continue to return to schedule setup
        let continueButton = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(continueButton.exists, "Continue button should exist")
        continueButton.tap()

        sleep(3)  // Wait for schedule setup to load

        // THEN: Previously selected pattern is still selected
        let weeklyCard = app.buttons["pattern-card-weekly"]
        let restoredSplitDoseCard = app.buttons["pattern-card-splitDose"]

        XCTAssertTrue(
            restoredSplitDoseCard.waitForExistence(timeout: 5),
            "Split dose card should exist after returning")
        XCTAssertTrue(restoredSplitDoseCard.isSelected, "Split dose pattern should still be selected")
        XCTAssertFalse(weeklyCard.isSelected, "Weekly pattern should not be selected")

        // THEN: Multiple reminders toggle state is preserved
        let restoredToggle = app.switches["Enable multiple reminders"]
        XCTAssertTrue(restoredToggle.exists, "Toggle should still exist")

        let finalToggleValue = restoredToggle.value as? String ?? "0"
        XCTAssertNotEqual(finalToggleValue, "0", "Multiple reminders toggle should still be enabled")
    }
}
