//
//  OnboardingMedicationPatternsUITests.swift
//  JabTrackerUITests
//
//  E2E tests for medication-specific pattern filtering in onboarding (Issue #180)
//  Tests verify that daily medications show only Daily pattern,
//  and weekly medications show Weekly + Split-Dose patterns.
//

import XCTest

final class OnboardingMedicationPatternsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data", "--force-onboarding"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - ACCEPTANCE CRITERION 4: Semaglutide (weekly) shows split-dose option

    func testSemaglutideShowsSplitDoseOption() throws {
        // GIVEN: User selects Semaglutide (weekly medication)
        // Navigate through onboarding to schedule setup

        // Welcome screen
        let welcomeContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(welcomeContinue.waitForExistence(timeout: 5), "Continue button should exist on welcome screen")
        welcomeContinue.tap()

        // Medication selection - explicitly select Semaglutide
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

        // Continue to schedule setup
        let doseContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(doseContinue.exists, "Continue button should exist after dose entry")
        doseContinue.tap()

        // Wait for schedule setup view to appear
        var scheduleView = app.scrollViews["schedule-setup-view"]
        if !scheduleView.waitForExistence(timeout: 10) {
            scheduleView = app.otherElements["schedule-setup-view"]
        }
        XCTAssertTrue(scheduleView.waitForExistence(timeout: 10), "Schedule setup view should appear")

        // WHEN: User views pattern options
        // THEN: Split-dose pattern option is visible
        let splitDoseCard = app.buttons["pattern-card-splitDose"]
        XCTAssertTrue(
            splitDoseCard.waitForExistence(timeout: 5),
            "Split-dose pattern card should be visible for Semaglutide (weekly medication)")

        // THEN: Weekly pattern option is also visible
        let weeklyCard = app.buttons["pattern-card-weekly"]
        XCTAssertTrue(
            weeklyCard.exists,
            "Weekly pattern card should be visible for Semaglutide")

        // THEN: Custom pattern option is NOT visible
        let customCard = app.buttons["pattern-card-custom"]
        XCTAssertFalse(
            customCard.exists,
            "Custom pattern card should NOT be visible (removed from UI)")
    }

    // MARK: - ACCEPTANCE CRITERION 5: Liraglutide (daily) does NOT show split-dose option

    func testLiraglutideHidesSplitDoseOption() throws {
        // GIVEN: User selects Liraglutide (daily medication)
        // Navigate through onboarding to schedule setup

        // Welcome screen
        let welcomeContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(welcomeContinue.waitForExistence(timeout: 5), "Continue button should exist on welcome screen")
        welcomeContinue.tap()

        // Medication selection - explicitly select Liraglutide (daily medication)
        let liraglutideButton = app.buttons["medication-liraglutide"]
        XCTAssertTrue(liraglutideButton.waitForExistence(timeout: 5), "Liraglutide button should exist")
        liraglutideButton.tap()

        // Continue to dose setup
        let medicationContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(
            medicationContinue.waitForExistence(timeout: 5), "Continue button should exist after medication selection")
        medicationContinue.tap()

        // Dose setup - select 0.6mg dose button (Liraglutide dose)
        let doseButton = app.buttons["dose-button-0.6"]
        XCTAssertTrue(doseButton.waitForExistence(timeout: 5), "Dose button should exist")
        doseButton.tap()

        // Select injection site (required to proceed)
        let abdomenSite = app.buttons["injection-site-abdomen"]
        XCTAssertTrue(abdomenSite.waitForExistence(timeout: 2), "Injection site button should exist")
        abdomenSite.tap()

        // Continue to schedule setup
        let doseContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(doseContinue.exists, "Continue button should exist after dose entry")
        doseContinue.tap()

        // Wait for schedule setup view to appear
        var scheduleView = app.scrollViews["schedule-setup-view"]
        if !scheduleView.waitForExistence(timeout: 10) {
            scheduleView = app.otherElements["schedule-setup-view"]
        }
        XCTAssertTrue(scheduleView.waitForExistence(timeout: 10), "Schedule setup view should appear")

        // WHEN: User views pattern options
        // THEN: Only daily pattern option is visible (Liraglutide is a daily medication)
        let dailyCard = app.buttons["pattern-card-daily"]
        XCTAssertTrue(
            dailyCard.waitForExistence(timeout: 5),
            "Daily pattern card should be visible for Liraglutide (daily medication)")

        // THEN: Weekly pattern option is NOT visible (daily meds don't use weekly pattern)
        let weeklyCard = app.buttons["pattern-card-weekly"]
        XCTAssertFalse(
            weeklyCard.exists,
            "Weekly pattern card should NOT be visible for Liraglutide (daily medication)")

        // THEN: Split-dose pattern option is NOT visible
        let splitDoseCard = app.buttons["pattern-card-splitDose"]
        XCTAssertFalse(
            splitDoseCard.exists,
            "Split-dose pattern card should NOT be visible for Liraglutide (daily medication)")

        // THEN: Custom pattern option is NOT visible
        let customCard = app.buttons["pattern-card-custom"]
        XCTAssertFalse(
            customCard.exists,
            "Custom pattern card should NOT be visible (removed from UI)")
    }

    // MARK: - Daily Medication Complete Flow Tests

    func testDailyMedicationCompleteOnboardingFlow() throws {
        // GIVEN: User starting onboarding
        // WHEN: User selects Liraglutide (daily medication) and completes onboarding

        // Welcome screen
        let welcomeContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(welcomeContinue.waitForExistence(timeout: 5))
        welcomeContinue.tap()

        // Medication selection - Liraglutide
        let liraglutideButton = app.buttons["medication-liraglutide"]
        XCTAssertTrue(liraglutideButton.waitForExistence(timeout: 5))
        liraglutideButton.tap()

        let medicationContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(medicationContinue.waitForExistence(timeout: 5))
        medicationContinue.tap()

        // Dose setup - select 0.6mg dose button (Liraglutide's starting dose)
        let doseButton = app.buttons["dose-button-0.6"]
        XCTAssertTrue(doseButton.waitForExistence(timeout: 5), "Dose button should exist")
        doseButton.tap()

        // Select injection site (required to proceed)
        let abdomenSite = app.buttons["injection-site-abdomen"]
        XCTAssertTrue(abdomenSite.waitForExistence(timeout: 5), "Injection site button should exist")
        abdomenSite.tap()

        // Small delay for state to update
        usleep(500_000)  // 0.5 seconds

        // Continue to schedule setup
        let doseContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(doseContinue.exists, "Continue button should exist after dose entry")
        XCTAssertTrue(doseContinue.isEnabled, "Continue button should be enabled after selecting dose and site")
        doseContinue.tap()

        // Small delay for navigation animation
        sleep(3)

        // Schedule setup - verify Daily pattern
        // Try different element types for schedule setup view
        var scheduleSetupView = app.scrollViews["schedule-setup-view"]
        if !scheduleSetupView.waitForExistence(timeout: 10) {
            scheduleSetupView = app.otherElements["schedule-setup-view"]
        }
        XCTAssertTrue(scheduleSetupView.waitForExistence(timeout: 10), "Schedule setup view should appear")

        // THEN: Daily pattern card exists
        let dailyCard = app.buttons["pattern-card-daily"]
        XCTAssertTrue(
            dailyCard.waitForExistence(timeout: 5),
            "Daily pattern card must be visible for Liraglutide")

        // THEN: Weekly and split-dose do NOT exist
        let weeklyCard = app.buttons["pattern-card-weekly"]
        let splitDoseCard = app.buttons["pattern-card-splitdose"]
        XCTAssertFalse(weeklyCard.exists, "Weekly card should NOT exist for daily medication")
        XCTAssertFalse(splitDoseCard.exists, "Split-dose card should NOT exist for daily medication")

        // THEN: Daily pattern is auto-selected
        XCTAssertTrue(dailyCard.isSelected, "Daily pattern should be auto-selected")

        // Continue through rest of onboarding
        let scheduleContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(scheduleContinue.exists)
        scheduleContinue.tap()

        // Skip notifications
        let notificationsView = app.otherElements["notifications-permission-view"]
        if notificationsView.waitForExistence(timeout: 5) {
            let skipButton = app.buttons["onboarding-continue-button"]
            XCTAssertTrue(skipButton.exists)
            skipButton.tap()
        }

        // Skip HealthKit
        let healthKitView = app.otherElements["healthkit-permission-view"]
        if healthKitView.waitForExistence(timeout: 5) {
            let skipButton = app.buttons["onboarding-continue-button"]
            XCTAssertTrue(skipButton.exists)
            skipButton.tap()
        }

        // Complete onboarding
        let completeButton = app.buttons["complete-onboarding-button"]
        if completeButton.waitForExistence(timeout: 5) {
            completeButton.tap()
        }

        // THEN: Main app interface should appear
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(
            homeTab.waitForExistence(timeout: 10),
            "Should navigate to main app after completing onboarding")
    }

    // MARK: - ACCEPTANCE CRITERION 6: Custom pattern NOT visible in onboarding

    func testCustomPatternNotVisibleInOnboarding() throws {
        // GIVEN: User on onboarding schedule setup (Semaglutide selected by default)
        // Navigate through onboarding to schedule setup

        // Welcome screen
        let welcomeContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(welcomeContinue.waitForExistence(timeout: 5), "Continue button should exist on welcome screen")
        welcomeContinue.tap()

        // Medication selection - use Semaglutide (weekly medication)
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

        // Continue to schedule setup
        let doseContinue = app.buttons["onboarding-continue-button"]
        XCTAssertTrue(doseContinue.exists, "Continue button should exist after dose entry")
        doseContinue.tap()

        // Wait for schedule setup view to appear
        var scheduleView = app.scrollViews["schedule-setup-view"]
        if !scheduleView.waitForExistence(timeout: 10) {
            scheduleView = app.otherElements["schedule-setup-view"]
        }
        XCTAssertTrue(scheduleView.waitForExistence(timeout: 10), "Schedule setup view should appear")

        // WHEN: User views pattern options
        // THEN: Custom pattern option is NOT visible
        let customCard = app.buttons["pattern-card-custom"]
        XCTAssertFalse(
            customCard.exists,
            "Custom pattern card should NOT be visible in onboarding (removed from UI)")

        // THEN: Only weekly and split-dose patterns are visible
        let weeklyCard = app.buttons["pattern-card-weekly"]
        let splitDoseCard = app.buttons["pattern-card-splitDose"]

        XCTAssertTrue(
            weeklyCard.exists,
            "Weekly pattern card should be visible")
        XCTAssertTrue(
            splitDoseCard.exists,
            "Split-dose pattern card should be visible for weekly medications")

        // THEN: Verify only 2 pattern cards exist (not 3)
        let allPatternCards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'pattern-card-'"))
        XCTAssertEqual(
            allPatternCards.count, 2,
            "Should only have 2 pattern cards (weekly and split-dose), not 3")
    }
}
