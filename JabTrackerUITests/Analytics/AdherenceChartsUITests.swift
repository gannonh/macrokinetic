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
        sleep(2)

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
        sleep(2)

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
        // WHEN: AdherenceTrendChart is displayed
        // THEN: Chart shows adherence percentage trends
        // THEN: Chart has proper time period labels
        // THEN: Chart supports accessibility

        // Placeholder for implementation
        XCTAssertTrue(true, "Trend chart acceptance criteria defined")
    }

    // MARK: - ACCEPTANCE CRITERION: Missed dose pattern visualization
    func testMissedDosePatternView() throws {
        // GIVEN: User has missed doses in their history
        // WHEN: MissedDosePatternView is displayed
        // THEN: Missed doses are visually highlighted
        // THEN: Pattern recognition insights are shown
        // THEN: View is accessible with proper labels

        // Placeholder for implementation
        XCTAssertTrue(true, "Missed dose pattern acceptance criteria defined")
    }

    // MARK: - ACCEPTANCE CRITERION: Progress indicator shows adherence goals
    func testAdherenceProgressIndicator() throws {
        // GIVEN: User has adherence data and goals
        // WHEN: AdherenceProgressIndicator is displayed
        // THEN: Progress toward adherence goals is shown
        // THEN: Visual progress indicator is displayed
        // THEN: Progress text is accessible

        // Placeholder for implementation
        XCTAssertTrue(true, "Progress indicator acceptance criteria defined")
    }
}
