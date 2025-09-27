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

        // Note: adherence-insights-placeholder was removed in Issue #57 scope reduction
        // Personalized improvement recommendations were moved to backlog

        // Verify AdherenceProgressIndicator is displayed (no specific identifier, but should be present)
        let progressElements = app.staticTexts.matching(identifier: "adherence-progress-indicator")
        XCTAssertTrue(progressElements.count > 0, "Adherence progress indicator should be displayed")

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

        // THEN: AdherenceTrendChart should be accessible using CodeGen patterns
        _ = TestUtilities.findElementsUsingCodeGenPatterns(in: app, identifier: "adherence-trend-chart")

        let trendChartElements = app.staticTexts.matching(identifier: "adherence-trend-chart")
        XCTAssertTrue(trendChartElements.count > 0, "Adherence trend chart elements should be displayed")

        let trendChart = trendChartElements.element(boundBy: 0)
        XCTAssertTrue(trendChart.exists, "First trend chart element should exist")

        // THEN: Chart has proper time period labels
        // Verify time-related text is present (weeks, months, etc.)
        let timeRelatedElements = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'week' OR label CONTAINS 'month' OR label CONTAINS 'day'"))
        XCTAssertTrue(timeRelatedElements.count > 0, "Time period labels should be present for trend analysis")

        // THEN: Chart supports accessibility
        XCTAssertTrue(trendChart.isHittable, "Trend chart area should be accessible")

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

        // THEN: MissedDosePatternView should be accessible using CodeGen patterns
        _ = TestUtilities.findElementsUsingCodeGenPatterns(in: app, identifier: "missed-dose-pattern-view")

        let missedDoseElements = app.staticTexts.matching(identifier: "missed-dose-pattern-view")
        XCTAssertTrue(missedDoseElements.count > 0, "Missed dose pattern elements should be displayed")

        let missedDoseView = missedDoseElements.element(boundBy: 0)
        XCTAssertTrue(missedDoseView.exists, "First missed dose pattern element should exist")

        // THEN: Pattern visualization is accessible
        // MissedDosePatternView should be visible and accessible using CodeGen patterns
        let missedDosePatternElements = app.staticTexts.matching(identifier: "missed-dose-pattern-view")
        XCTAssertTrue(missedDosePatternElements.count > 0, "Missed dose pattern view should be displayed")

        let firstPatternElement = missedDosePatternElements.element(boundBy: 0)
        XCTAssertTrue(firstPatternElement.exists, "First missed dose pattern element should exist")

        // THEN: View is accessible and displays pattern content
        // (Note: Static text elements may not be hittable but should exist and be accessible)

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

        // Scroll down to access elements below the fold
        let analyticsScrollView = app.scrollViews["analytics-scroll-view"]
        if analyticsScrollView.exists {
            analyticsScrollView.swipeUp()
        }

        // THEN: AdherenceProgressIndicator should be accessible (using CodeGen pattern)
        let progressIndicatorElements = app.staticTexts.matching(identifier: "adherence-progress-indicator")
        XCTAssertTrue(progressIndicatorElements.count > 0, "Adherence progress indicator elements should be displayed")

        let progressIndicator = progressIndicatorElements.element(boundBy: 0)
        XCTAssertTrue(progressIndicator.exists, "First progress indicator element should exist")

        // THEN: Visual progress indicator displays percentage
        XCTAssertTrue(progressPercentage.exists, "Progress percentage should be visually displayed")

        // THEN: Adherence goal text should be findable in the UI
        let adherenceGoalText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Adherence Goal'"))
        XCTAssertTrue(adherenceGoalText.count > 0, "Adherence Goal text should be displayed")

        let currentText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Current'"))
        XCTAssertTrue(currentText.count > 0, "Current text should be displayed")

        let targetText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Target'"))
        XCTAssertTrue(targetText.count > 0, "Target text should be displayed")

        // Main functionality verified: progress indicator found with CodeGen pattern,
        // all required text elements ("Adherence Goal", "Current", "Target") are accessible

        // Verify streak counters show goal progress
        let streakCountersCard = app.otherElements["streak-counters-card"]
        XCTAssertTrue(streakCountersCard.exists, "Streak counters should show goal progress")

        print("✅ Adherence progress indicator successfully verified")
    }
}
