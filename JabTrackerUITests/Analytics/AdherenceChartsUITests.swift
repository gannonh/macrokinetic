//
//  AdherenceChartsUITests.swift
//  JabTrackerUITests
//
//  UI testing for adherence chart components.
//  Enhanced with screenshot capture and performance measurement for UI/UX analysis
//

import XCTest

/// E2E acceptance tests for adherence chart components functionality
/// Defines the complete user experience and acceptance criteria for adherence visualizations
/// Enhanced with screenshot capture and performance measurement for UI/UX analysis
final class AdherenceChartsUITests: XCTestCase {

    var screenshotCapture: ScreenshotCapture!

    // Debug flag - set to true to enable debug output during test development
    private let enableDebugOutput = false

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func setUp() {
        super.setUp()
        let app = XCUIApplication()
        screenshotCapture = ScreenshotCapture(app: app, testCase: self, phase: "baseline")
    }

    // MARK: - ACCEPTANCE CRITERION: Chart components display adherence visualizations
    func testAdherenceChartComponents() throws {
        // GIVEN: User has dose history with adherence data
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile and historical dose data
        TestUtilities.createMedicationProfile(app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")
        TestUtilities.createHistoricalChartData(in: app, count: 5)

        // 📸 PHASE 1: Capture baseline before adherence charts
        screenshotCapture.capture(
            section: "adherence-charts",
            description: "before-navigation",
            metadata: ["state": "ready", "dose_count": "5"]
        )

        // WHEN: User navigates to Analytics tab
        // Measure navigation performance
        let navStart = Date()
        TestUtilities.navigateToTab(app, tabName: "Analytics")

        // Wait for Analytics view to load
        let analyticsView = app.scrollViews["analytics-scroll-view"]
        _ = analyticsView.waitForExistence(timeout: 10)
        let navEnd = Date()
        let navTime = navEnd.timeIntervalSince(navStart) * 1000  // ms

        // 📸 PHASE 1: Capture analytics view loaded
        screenshotCapture.capture(
            section: "adherence-charts",
            description: "analytics-loaded",
            metadata: [
                "navigation_time_ms": String(format: "%.1f", navTime),
                "section": "analytics",
                "state": "loaded",
            ]
        )

        // Debug what's available after navigating to Analytics
        if enableDebugOutput {
            TestUtilities.debugElements(in: app, containing: "analytics")
            TestUtilities.debugElements(in: app, containing: "picker")

            // Debug all segmented controls
            print("🔍 DEBUG: All segmented controls:")
            let allSegmentedControls = app.segmentedControls.allElementsBoundByIndex
            for (index, control) in allSegmentedControls.enumerated() {
                print("  Segmented Control \(index): '\(control.identifier)' - exists: \(control.exists)")
            }
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

        // Measure adherence section transition performance
        let transitionStart = Date()
        adherenceSegment.tap()

        // Wait for adherence view to load
        let adherenceMetricsCard = app.otherElements["adherence-metrics-card"]
        _ = adherenceMetricsCard.waitForExistence(timeout: 5)
        let transitionEnd = Date()
        let transitionTime = transitionEnd.timeIntervalSince(transitionStart) * 1000  // ms

        // 📸 PHASE 1: Capture adherence section loaded
        screenshotCapture.capture(
            section: "adherence-charts",
            description: "adherence-loaded",
            metadata: [
                "transition_time_ms": String(format: "%.1f", transitionTime),
                "section": "adherence",
                "state": "chart_components_loaded",
            ]
        )

        // Debug what adherence elements are available
        if enableDebugOutput {
            TestUtilities.debugElements(in: app, containing: "adherence")
            TestUtilities.debugElements(in: app, containing: "streak")
            TestUtilities.debugElements(in: app, containing: "metrics")
        }

        // THEN: Adherence components should be displayed
        XCTAssertTrue(adherenceMetricsCard.waitForExistence(timeout: 5), "Adherence metrics card should be displayed")

        let streakCountersCard = app.otherElements["streak-counters-card"]
        XCTAssertTrue(streakCountersCard.exists, "Streak counters card should be displayed")

        // Note: adherence-insights-placeholder was removed in Issue #57 scope reduction
        // Personalized improvement recommendations were moved to backlog

        // Verify AdherenceProgressIndicator is displayed (using actual element types found in debug)
        let progressStaticTexts = app.staticTexts.matching(identifier: "adherence-progress-indicator")
        let progressImages = app.images.matching(identifier: "adherence-progress-indicator")
        let totalProgressElements = progressStaticTexts.count + progressImages.count

        // Add debug capability if elements are not found
        if totalProgressElements == 0 && enableDebugOutput {
            TestUtilities.debugElements(in: app, containing: "adherence-progress")
        }
        XCTAssertTrue(totalProgressElements > 0, "Adherence progress indicator should be displayed")

        // Verify adherence percentage is displayed (inside metrics card)
        let adherencePercentageText = app.otherElements.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch

        // Add debug capability if element is not found
        if !adherencePercentageText.waitForExistence(timeout: 3) && enableDebugOutput {
            TestUtilities.debugElements(in: app, containing: "%")
        }
        XCTAssertTrue(adherencePercentageText.exists, "Adherence percentage should be displayed")

        // 📸 PHASE 1: Capture final adherence charts state
        screenshotCapture.capture(
            section: "adherence-charts",
            description: "final-state",
            metadata: [
                "components_verified": "true",
                "metrics_card": "visible",
                "streak_counters": "visible",
                "adherence_percentage": "visible",
            ]
        )

        print("✅ Adherence chart components successfully verified")
    }

    // MARK: - ACCEPTANCE CRITERION: Trend chart displays adherence patterns over time
    func testAdherenceTrendChartDisplay() throws {
        // GIVEN: User has dose history spanning multiple weeks
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile and extensive historical dose data for trend analysis
        TestUtilities.createMedicationProfile(app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")
        TestUtilities.createHistoricalChartData(in: app, count: 10)  // More doses for trend patterns

        // 📸 PHASE 1: Capture baseline before trend chart test
        screenshotCapture.capture(
            section: "trend-chart",
            description: "before-navigation",
            metadata: ["state": "ready", "dose_count": "10"]
        )

        // WHEN: AdherenceTrendChart is displayed
        // Measure navigation performance
        let navStart = Date()
        TestUtilities.navigateToTab(app, tabName: "Analytics")

        // Navigate to Adherence segment
        let segmentedControl = app.segmentedControls["analytics-type-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 5), "Analytics segmented control should exist")

        // Measure adherence section transition performance
        let transitionStart = Date()
        let adherenceSegment = segmentedControl.buttons["Adherence"]
        adherenceSegment.tap()

        // Wait for trend chart to load
        let trendChartElements = app.staticTexts.matching(identifier: "adherence-trend-chart")
        _ = trendChartElements.firstMatch.waitForExistence(timeout: 5)
        let transitionEnd = Date()
        let navTime = transitionEnd.timeIntervalSince(navStart) * 1000  // ms
        let transitionTime = transitionEnd.timeIntervalSince(transitionStart) * 1000  // ms

        // 📸 PHASE 1: Capture trend chart loaded
        screenshotCapture.capture(
            section: "trend-chart",
            description: "chart-loaded",
            metadata: [
                "navigation_time_ms": String(format: "%.1f", navTime),
                "transition_time_ms": String(format: "%.1f", transitionTime),
                "state": "trend_chart_loaded",
            ]
        )

        // THEN: AdherenceTrendChart should be accessible using CodeGen patterns
        _ = TestUtilities.findElementsUsingCodeGenPatterns(in: app, identifier: "adherence-trend-chart")

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

        // 📸 PHASE 1: Capture final trend chart state
        screenshotCapture.capture(
            section: "trend-chart",
            description: "final-state",
            metadata: [
                "chart_verified": "true",
                "accessibility": "enabled",
                "time_periods": "visible",
            ]
        )

        print("✅ Adherence trend chart display successfully verified")
    }

    // MARK: - ACCEPTANCE CRITERION: Missed dose pattern visualization
    func testMissedDosePatternView() throws {
        // GIVEN: User has missed doses in their history
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile with some historical doses (simulating mixed adherence)
        TestUtilities.createMedicationProfile(app, genericName: "tirzepatide", brandName: "Mounjaro", dose: "2.5")
        TestUtilities.createHistoricalChartData(in: app, count: 7)  // Some doses with gaps

        // 📸 PHASE 1: Capture baseline before missed dose pattern test
        screenshotCapture.capture(
            section: "missed-dose-pattern",
            description: "before-navigation",
            metadata: ["state": "ready", "dose_count": "7", "medication": "tirzepatide"]
        )

        // WHEN: MissedDosePatternView is displayed
        // Measure navigation and pattern loading performance
        let navStart = Date()
        TestUtilities.navigateToTab(app, tabName: "Analytics")

        // Navigate to Adherence segment
        let segmentedControl = app.segmentedControls["analytics-type-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 5), "Analytics segmented control should exist")

        // Measure adherence section transition with pattern loading
        let transitionStart = Date()
        let adherenceSegment = segmentedControl.buttons["Adherence"]
        adherenceSegment.tap()

        // Wait for missed dose pattern to load
        let missedDoseElements = app.staticTexts.matching(identifier: "missed-dose-pattern-view")
        _ = missedDoseElements.firstMatch.waitForExistence(timeout: 5)
        let transitionEnd = Date()
        let navTime = transitionEnd.timeIntervalSince(navStart) * 1000  // ms
        let transitionTime = transitionEnd.timeIntervalSince(transitionStart) * 1000  // ms

        // 📸 PHASE 1: Capture missed dose pattern loaded
        screenshotCapture.capture(
            section: "missed-dose-pattern",
            description: "pattern-loaded",
            metadata: [
                "navigation_time_ms": String(format: "%.1f", navTime),
                "transition_time_ms": String(format: "%.1f", transitionTime),
                "state": "pattern_view_loaded",
            ]
        )

        // THEN: MissedDosePatternView should be accessible using CodeGen patterns
        _ = TestUtilities.findElementsUsingCodeGenPatterns(in: app, identifier: "missed-dose-pattern-view")

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

        // 📸 PHASE 1: Capture final missed dose pattern state
        screenshotCapture.capture(
            section: "missed-dose-pattern",
            description: "final-state",
            metadata: [
                "pattern_verified": "true",
                "metrics_impacted": "true",
                "accessibility": "enabled",
            ]
        )

        print("✅ Missed dose pattern visualization successfully verified")
    }

    // MARK: - ACCEPTANCE CRITERION: Progress indicator shows adherence goals
    func testAdherenceProgressIndicator() throws {
        // GIVEN: User has adherence data and goals
        let app = TestUtilities.launchAppWithTestMode()

        // Create medication profile with good adherence data
        TestUtilities.createMedicationProfile(app, genericName: "liraglutide", brandName: "Victoza", dose: "1.2")
        TestUtilities.createHistoricalChartData(in: app, count: 8)  // Good adherence pattern

        // 📸 PHASE 1: Capture baseline before progress indicator test
        screenshotCapture.capture(
            section: "progress-indicator",
            description: "before-navigation",
            metadata: ["state": "ready", "dose_count": "8", "medication": "liraglutide"]
        )

        // WHEN: AdherenceProgressIndicator is displayed
        // Measure navigation and progress indicator loading performance
        let navStart = Date()
        TestUtilities.navigateToTab(app, tabName: "Analytics")

        // Navigate to Adherence segment
        let segmentedControl = app.segmentedControls["analytics-type-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 5), "Analytics segmented control should exist")

        // Measure adherence section transition with progress indicator loading
        let transitionStart = Date()
        let adherenceSegment = segmentedControl.buttons["Adherence"]
        adherenceSegment.tap()

        // Wait for progress indicator to load
        let adherenceMetricsCard = app.otherElements["adherence-metrics-card"]
        _ = adherenceMetricsCard.waitForExistence(timeout: 5)
        let transitionEnd = Date()
        let navTime = transitionEnd.timeIntervalSince(navStart) * 1000  // ms
        let transitionTime = transitionEnd.timeIntervalSince(transitionStart) * 1000  // ms

        // 📸 PHASE 1: Capture progress indicator loaded
        screenshotCapture.capture(
            section: "progress-indicator",
            description: "indicator-loaded",
            metadata: [
                "navigation_time_ms": String(format: "%.1f", navTime),
                "transition_time_ms": String(format: "%.1f", transitionTime),
                "state": "progress_indicator_loaded",
            ]
        )

        // Debug progress indicator elements
        if enableDebugOutput {
            TestUtilities.debugElements(in: app, containing: "progress")
            TestUtilities.debugElements(in: app, containing: "goal")
        }

        // THEN: Progress toward adherence goals is shown
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

        // 📸 PHASE 1: Capture final progress indicator state
        screenshotCapture.capture(
            section: "progress-indicator",
            description: "final-state",
            metadata: [
                "indicator_verified": "true",
                "goals_visible": "true",
                "counters_visible": "true",
                "accessibility": "enabled",
            ]
        )

        print("✅ Adherence progress indicator successfully verified")
    }
}
