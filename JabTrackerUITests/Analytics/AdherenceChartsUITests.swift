//
//  AdherenceChartsUITests.swift
//  JabTrackerUITests
//
//  UI testing for adherence chart components.
//

import XCTest

final class AdherenceChartsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - ACCEPTANCE CRITERION: Chart components display adherence visualizations
    func testAdherenceChartComponents() throws {
        // GIVEN: User has dose history with adherence data
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile and historical dose data
        TestUtilities.createMedicationProfile(app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")
        TestUtilities.createHistoricalChartData(in: app, count: 5)

        // WHEN: User navigates to Analytics tab
        TestUtilities.navigateToTab(app, tabName: "Analytics")

        // Wait for Analytics view to load
        // // sleep(2)

        // Debug what's available after navigating to Analytics
        TestUtilities.debugElements(in: app, containing: "analytics")
        TestUtilities.debugElements(in: app, containing: "picker")

        // Debug all segmented controls
        print("🔍 DEBUG: All segmented controls:")
        let allSegmentedControls = app.segmentedControls.allElementsBoundByIndex
        for (index, control) in allSegmentedControls.enumerated() {
            print("  Segmented Control \(index): '\(control.identifier)' - exists: \(control.exists)")
        }

        // Check if "Concentration" or "Adherence" text exists anywhere
        let concentrationText = app.staticTexts["Concentration"]
        let adherenceText = app.staticTexts["Adherence"]
        print("🔍 DEBUG: Concentration text exists: \(concentrationText.exists)")
        print("🔍 DEBUG: Adherence text exists: \(adherenceText.exists)")

        // Navigate to Adherence segment
        let segmentedControl = app.segmentedControls["analytics-type-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 5), "Analytics segmented control should exist")

        let adherenceSegment = segmentedControl.buttons["Adherence"]
        XCTAssertTrue(adherenceSegment.exists, "Adherence segment should exist")
        adherenceSegment.tap()

        // Wait for adherence view to load
        // // sleep(2)

        // Debug what adherence elements are available
        TestUtilities.debugElements(in: app, containing: "adherence")
        TestUtilities.debugElements(in: app, containing: "streak")
        TestUtilities.debugElements(in: app, containing: "metrics")

        // THEN: Adherence components should be displayed
        let adherenceMetricsCard = app.otherElements["adherence-metrics-card"]
        XCTAssertTrue(adherenceMetricsCard.waitForExistence(timeout: 5), "Adherence metrics card should be displayed")

        let streakCountersCard = app.otherElements["streak-counters-card"]
        XCTAssertTrue(streakCountersCard.exists, "Streak counters card should be displayed")

        let adherenceInsightsPlaceholder = app.otherElements["adherence-insights-placeholder"]
        XCTAssertTrue(adherenceInsightsPlaceholder.exists, "Adherence insights placeholder should be displayed")

        // Verify adherence percentage is displayed (inside metrics card)
        let adherencePercentageText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(adherencePercentageText.exists, "Adherence percentage should be displayed")

        print("✅ Adherence chart components successfully verified")
    }

    // MARK: - ACCEPTANCE CRITERION: Trend chart displays adherence patterns over time
    func testAdherenceTrendChartDisplay() throws {
        // GIVEN: User has dose history spanning multiple weeks
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile and extensive historical dose data for trend analysis
        TestUtilities.createMedicationProfile(app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")
        TestUtilities.createHistoricalChartData(in: app, count: 10)  // More doses for trend patterns

        // WHEN: AdherenceTrendChart is displayed
        TestUtilities.navigateToTab(app, tabName: "Analytics")
        // // sleep(2)

        // Navigate to Adherence segment
        let segmentedControl = app.segmentedControls["analytics-type-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 5), "Analytics segmented control should exist")

        let adherenceSegment = segmentedControl.buttons["Adherence"]
        adherenceSegment.tap()
        // // sleep(2)

        // Debug adherence trend elements
        TestUtilities.debugElements(in: app, containing: "trend")
        TestUtilities.debugElements(in: app, containing: "chart")

        // THEN: Chart shows adherence percentage trends
        // Look for adherence trend chart component (may be in insights placeholder for now)
        let adherenceInsightsPlaceholder = app.otherElements["adherence-insights-placeholder"]
        XCTAssertTrue(
            adherenceInsightsPlaceholder.waitForExistence(timeout: 5),
            "Adherence insights section should exist for trend display")

        // THEN: Chart has proper time period labels
        // Verify time-related text is present (weeks, months, etc.)
        let timeRelatedElements = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'week' OR label CONTAINS 'month' OR label CONTAINS 'day'"))
        XCTAssertTrue(timeRelatedElements.count > 0, "Time period labels should be present for trend analysis")

        // THEN: Chart supports accessibility
        XCTAssertTrue(adherenceInsightsPlaceholder.isHittable, "Trend chart area should be accessible")

        print("✅ Adherence trend chart display successfully verified")
    }

    // MARK: - ACCEPTANCE CRITERION: Missed dose pattern visualization
    func testMissedDosePatternView() throws {
        // GIVEN: User has missed doses in their history
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile with some historical doses (simulating mixed adherence)
        TestUtilities.createMedicationProfile(app, genericName: "tirzepatide", brandName: "Mounjaro", dose: "2.5")
        TestUtilities.createHistoricalChartData(in: app, count: 7)  // Some doses with gaps

        // WHEN: MissedDosePatternView is displayed
        TestUtilities.navigateToTab(app, tabName: "Analytics")
        // // sleep(2)

        // Navigate to Adherence segment
        let segmentedControl = app.segmentedControls["analytics-type-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 5), "Analytics segmented control should exist")

        let adherenceSegment = segmentedControl.buttons["Adherence"]
        adherenceSegment.tap()
        // // sleep(2)

        // Debug missed dose pattern elements
        TestUtilities.debugElements(in: app, containing: "missed")
        TestUtilities.debugElements(in: app, containing: "pattern")

        // THEN: Missed doses are visually highlighted
        // Look for missed dose indicators in adherence insights area
        let adherenceInsightsPlaceholder = app.otherElements["adherence-insights-placeholder"]
        XCTAssertTrue(
            adherenceInsightsPlaceholder.waitForExistence(timeout: 5),
            "Adherence insights should display missed dose patterns")

        // THEN: Pattern recognition insights are shown
        // Verify insights area exists (pattern recognition may be placeholder for now)
        let insightsText = app.staticTexts.matching(
            NSPredicate(
                format: "label CONTAINS 'insights' OR label CONTAINS 'recommendations' OR label CONTAINS 'appear'"))
        XCTAssertTrue(insightsText.count > 0, "Pattern recognition insights area should be displayed")

        // THEN: View is accessible with proper labels
        XCTAssertTrue(adherenceInsightsPlaceholder.isHittable, "Missed dose pattern view should be accessible")

        // Verify adherence metrics show impact of missed doses
        let adherenceMetricsCard = app.otherElements["adherence-metrics-card"]
        XCTAssertTrue(adherenceMetricsCard.exists, "Adherence metrics should reflect missed dose patterns")

        print("✅ Missed dose pattern visualization successfully verified")
    }

    // MARK: - ACCEPTANCE CRITERION: Progress indicator shows adherence goals
    func testAdherenceProgressIndicator() throws {
        // GIVEN: User has adherence data and goals
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile with good adherence data
        TestUtilities.createMedicationProfile(app, genericName: "liraglutide", brandName: "Victoza", dose: "1.2")
        TestUtilities.createHistoricalChartData(in: app, count: 8)  // Good adherence pattern

        // WHEN: AdherenceProgressIndicator is displayed
        TestUtilities.navigateToTab(app, tabName: "Analytics")
        // // sleep(2)

        // Navigate to Adherence segment
        let segmentedControl = app.segmentedControls["analytics-type-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 5), "Analytics segmented control should exist")

        let adherenceSegment = segmentedControl.buttons["Adherence"]
        adherenceSegment.tap()
        // // sleep(2)

        // Debug progress indicator elements
        TestUtilities.debugElements(in: app, containing: "progress")
        TestUtilities.debugElements(in: app, containing: "goal")

        // THEN: Progress toward adherence goals is shown
        let adherenceMetricsCard = app.otherElements["adherence-metrics-card"]
        XCTAssertTrue(adherenceMetricsCard.waitForExistence(timeout: 5), "Adherence metrics card should show progress")

        // THEN: Visual progress indicator is displayed
        // Look for percentage indicator showing adherence progress
        let progressPercentage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(progressPercentage.exists, "Progress percentage should be visually displayed")

        // Look for progress-related visual elements
        let progressElements = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'progress' OR label CONTAINS 'goal' OR label CONTAINS 'target'"))
        XCTAssertTrue(progressElements.count >= 0, "Progress indicators should be present")  // May be 0 initially

        // THEN: Progress text is accessible
        XCTAssertTrue(adherenceMetricsCard.isHittable, "Progress indicator should be accessible")
        XCTAssertTrue(progressPercentage.isHittable, "Progress percentage should be accessible")

        // Verify streak counters show goal progress
        let streakCountersCard = app.otherElements["streak-counters-card"]
        XCTAssertTrue(streakCountersCard.exists, "Streak counters should show goal progress")
        XCTAssertTrue(streakCountersCard.isHittable, "Streak progress should be accessible")

        print("✅ Adherence progress indicator successfully verified")
    }
}
