//
//  PKEngineUITests.swift
//  JabTrackerUITests
//
//  E2E acceptance tests for pharmacokinetics concentration display
//  These tests define the "done" criteria for the concentration display feature
//

import XCTest

@MainActor
final class PKEngineUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - Concentration Display E2E Acceptance Tests

    /// Acceptance Test: Dashboard shows current drug concentration in real-time
    /// Given: User has logged doses for a medication
    /// When: User views the dashboard
    /// Then: Current concentration level is displayed accurately
    /// And: Concentration updates when new doses are added
    func testCurrentConcentrationDisplayOnDashboard() throws {
        // 1. Set up test environment with medication profile and NO initial doses
        // We'll manually create a single dose to isolate the duplication issue
        TestUtilities.setupDoseHistoryTest(
            app: app,
            doseCount: 0, // Start with no doses
            medicationProfiles: 1,
            medicationName: "semaglutide",
            brandName: "Ozempic",
            dose: "1.0"
        )

        // Create exactly 1 dose to test concentration display
        TestUtilities.createMultipleDoses(in: app, count: 1, delay: 0)

        // 2. Navigate to dashboard (home tab)
        TestUtilities.navigateToTab(app, tabName: "Home")

        // 3. Verify concentration card is visible with proper accessibility identifiers
        let concentrationCard = app.otherElements["concentration-card-Semaglutide"]
        XCTAssertTrue(concentrationCard.waitForExistence(timeout: 5),
                      "Concentration card for Semaglutide should be visible on dashboard")

        // 4. Verify current concentration value is displayed (should be > 0)
        let concentrationValue = concentrationCard.staticTexts["current-concentration-value"]
        XCTAssertTrue(concentrationValue.exists,
                      "Current concentration value should be displayed")

        // Extract and validate concentration value
        let concentrationText = concentrationValue.label
        XCTAssertFalse(concentrationText.isEmpty,
                       "Concentration value should not be empty")
        XCTAssertFalse(concentrationText.contains("0.00"),
                       "Concentration should be greater than 0 after dose")

        // 5. Log another dose and verify concentration updates
        TestUtilities.createMultipleDoses(in: app, count: 1, delay: 0)

        // Return to dashboard and verify concentration updated
        TestUtilities.navigateToTab(app, tabName: "Home")

        let updatedConcentrationValue = concentrationCard.staticTexts["current-concentration-value"]
        XCTAssertTrue(updatedConcentrationValue.waitForExistence(timeout: 3),
                      "Updated concentration should appear")

        let updatedConcentrationText = updatedConcentrationValue.label
        XCTAssertNotEqual(concentrationText, updatedConcentrationText,
                          "Concentration should update after adding third dose")

        // 6. Verify concentration metadata is displayed
        let concentrationUnit = concentrationCard.staticTexts["concentration-unit"]
        XCTAssertTrue(concentrationUnit.exists,
                      "Concentration unit should be displayed")

        let lastUpdated = concentrationCard.staticTexts["concentration-last-updated"]
        XCTAssertTrue(lastUpdated.exists,
                      "Last updated timestamp should be displayed")
    }

    /// Acceptance Test: Peak and trough levels are calculated and displayed correctly
    /// Given: User has an active medication with dose history
    /// When: User views concentration details on dashboard
    /// Then: Peak level timing and value are shown
    /// And: Trough level timing and value are shown
    /// And: Peak occurs at medication-specific time after injection
    func testPeakAndTroughLevelCalculations() throws {
        // 1. Set up test environment with semaglutide medication profile
        TestUtilities.setupDoseHistoryTest(
            app: app,
            doseCount: 0, // Start with no doses, we'll add one manually
            medicationProfiles: 1,
            medicationName: "semaglutide",
            brandName: "Ozempic",
            dose: "1.0"
        )

        // 2. Log a dose and note the timestamp
        TestUtilities.createMultipleDoses(in: app, count: 1, delay: 0)

        // 3. Navigate to dashboard concentration card
        TestUtilities.navigateToTab(app, tabName: "Home")

        // Find the concentration card
        let concentrationCard = app.otherElements["concentration-card-Semaglutide"]
        XCTAssertTrue(concentrationCard.waitForExistence(timeout: 5),
                      "Concentration card for Semaglutide should be visible on dashboard")

        // 4. Verify peak level section is displayed
        let peakLevelSection = app.staticTexts["peak-level-section"]
        XCTAssertTrue(peakLevelSection.exists,
                      "Peak level section should be displayed")

        // 5. Verify trough level section is displayed
        let troughLevelSection = app.staticTexts["trough-level-section"]
        XCTAssertTrue(troughLevelSection.exists,
                      "Trough level section should be displayed")

        // 6. Verify current concentration is greater than 0 (indicating bioavailability is applied)
        let concentrationValue = app.staticTexts["current-concentration-value"]
        XCTAssertTrue(concentrationValue.exists,
                      "Current concentration value should be displayed")

        let concentrationText = concentrationValue.label
        XCTAssertFalse(concentrationText.isEmpty,
                       "Concentration value should not be empty")
        XCTAssertFalse(concentrationText.contains("0.00"),
                       "Concentration should be greater than 0, indicating bioavailability is applied")

        // 7. Verify projected concentration values are displayed (peak/trough calculations)
        let projectedValues = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "projected-concentration-value")
        )
        XCTAssertGreaterThan(projectedValues.count, 0,
                             "At least one projected concentration value (peak or trough) should be displayed")

        // 8. Verify concentration units are properly displayed
        let concentrationUnits = app.staticTexts.matching(
            NSPredicate(format: "identifier == %@", "concentration-unit")
        )
        XCTAssertGreaterThan(concentrationUnits.count, 0,
                             "Concentration units should be displayed for all concentration values")
    }

    /// Acceptance Test: Steady-state progress is shown as percentage with helpful context
    /// Given: User has been taking medication for multiple weeks
    /// When: User views the concentration card
    /// Then: Steady-state progress is shown as percentage (0-100%)
    /// And: Clear explanation of what steady-state means
    /// And: Typical timeframe to reach steady-state is indicated
    func testSteadyStateProgressDisplay() throws {
        // 1. Set up test environment with semaglutide medication profile
        TestUtilities.setupDoseHistoryTest(
            app: app,
            doseCount: 0, // Start with no doses, we'll add multiple to simulate regular dosing
            medicationProfiles: 1,
            medicationName: "semaglutide",
            brandName: "Ozempic",
            dose: "1.0"
        )

        // 2. Log multiple doses to simulate regular dosing pattern (for steady-state calculation)
        TestUtilities.createMultipleDoses(in: app, count: 3, delay: 0)

        // 3. Navigate to dashboard concentration display
        TestUtilities.navigateToTab(app, tabName: "Home")

        // Find the concentration card
        let concentrationCard = app.otherElements["concentration-card-Semaglutide"]
        XCTAssertTrue(concentrationCard.waitForExistence(timeout: 5),
                      "Concentration card for Semaglutide should be visible on dashboard")

        // 4. Verify steady-state header elements exist (label and percentage)
        let steadyStateHeaders = app.staticTexts.matching(identifier: "steady-state-header")
        XCTAssertGreaterThanOrEqual(steadyStateHeaders.count, 2,
                                    "Should have steady-state label and percentage elements")

        // Verify the label element exists
        let steadyStateLabel = steadyStateHeaders.element(boundBy: 0)
        XCTAssertTrue(steadyStateLabel.exists,
                      "Steady-state label should be displayed")
        XCTAssertEqual(steadyStateLabel.label, "Steady State Progress",
                       "Steady-state label should show 'Steady State Progress'")

        // Verify the percentage element exists
        let steadyStatePercentage = steadyStateHeaders.element(boundBy: 1)
        XCTAssertTrue(steadyStatePercentage.exists,
                      "Steady-state percentage should be displayed")

        // 5. Verify steady-state progress indicator exists
        let steadyStateProgress = app.progressIndicators["steady-state-progress"]
        XCTAssertTrue(steadyStateProgress.exists,
                      "Steady-state progress indicator should be displayed")

        // 6. Verify progress value is accessible and within valid range (0-100%)
        let progressValue = steadyStateProgress.value as? String ?? ""
        XCTAssertFalse(progressValue.isEmpty,
                       "Progress indicator should have an accessible value")
        XCTAssertTrue(progressValue.contains("percent"),
                      "Progress value should contain 'percent' for accessibility")

        // 7. Verify steady-state explanation text exists
        let steadyStateExplanation = app.staticTexts["steady-state-explanation"]
        XCTAssertTrue(steadyStateExplanation.exists,
                      "Steady-state explanation should be displayed")

        // 8. Verify explanation contains helpful timeframe information
        let explanationText = steadyStateExplanation.label
        XCTAssertFalse(explanationText.isEmpty,
                       "Steady-state explanation should not be empty")
        XCTAssertTrue(explanationText.contains("4-5 weeks") || explanationText.contains("achieved"),
                      "Explanation should mention timeframe or achievement status")

        // 9. Verify steady-state progress percentage is valid
        // With 3 doses, progress should be 0% or greater but less than 100%
        let percentageText = steadyStatePercentage.label
        XCTAssertTrue(percentageText.contains("%"),
                      "Percentage element should contain % symbol")

        // Extract percentage value and validate range
        let percentageComponents = percentageText.components(separatedBy: CharacterSet.decimalDigits.inverted)
        let percentageValues = percentageComponents.compactMap { Int($0) }
        XCTAssertFalse(percentageValues.isEmpty,
                       "Should be able to extract percentage value")

        if let percentage = percentageValues.first {
            XCTAssertGreaterThanOrEqual(percentage, 0,
                                        "Steady-state percentage should be at least 0%")
            XCTAssertLessThanOrEqual(percentage, 100,
                                     "Steady-state percentage should not exceed 100%")
        }
    }

    /// Acceptance Test: Concentration levels display in user-friendly format with visual indicators
    /// Given: User has current concentration data
    /// When: User views concentration information
    /// Then: Concentration values are formatted appropriately (2 decimal places)
    /// And: Visual indicators show if levels are in therapeutic range
    /// And: Units are clearly displayed
    /// And: Color coding helps interpret levels (low/normal/high)
    func testConcentrationDisplayFormatting() throws {
        // 1. Set up test environment with semaglutide medication profile
        TestUtilities.setupDoseHistoryTest(
            app: app,
            doseCount: 0, // Start with no doses, we'll add one to get measurable concentration
            medicationProfiles: 1,
            medicationName: "semaglutide",
            brandName: "Ozempic",
            dose: "1.0"
        )

        // 2. Log a dose to generate concentration data for formatting validation
        TestUtilities.createMultipleDoses(in: app, count: 1, delay: 0)

        // 3. Navigate to dashboard concentration display
        TestUtilities.navigateToTab(app, tabName: "Home")

        // Find the concentration card
        let concentrationCard = app.otherElements["concentration-card-Semaglutide"]
        XCTAssertTrue(concentrationCard.waitForExistence(timeout: 5),
                      "Concentration card for Semaglutide should be visible on dashboard")

        // 4. Verify current concentration value formatting (2 decimal places)
        let currentConcentrationValue = app.staticTexts["current-concentration-value"]
        XCTAssertTrue(currentConcentrationValue.exists,
                      "Current concentration value should be displayed")

        let currentValueText = currentConcentrationValue.label
        XCTAssertFalse(currentValueText.isEmpty,
                       "Current concentration value should not be empty")

        // Verify 2 decimal place formatting (e.g., "1.23", "0.45", "12.00")
        let decimalPattern = #"^\d+\.\d{2}$"#
        let regex = try NSRegularExpression(pattern: decimalPattern)
        let valueRange = NSRange(location: 0, length: currentValueText.utf16.count)
        let hasDecimalFormat = regex.firstMatch(in: currentValueText, range: valueRange) != nil
        XCTAssertTrue(hasDecimalFormat,
                      "Current concentration should be formatted to 2 decimal places, got: '\(currentValueText)'")

        // 5. Verify units are clearly displayed
        let concentrationUnits = app.staticTexts.matching(identifier: "concentration-unit")
        XCTAssertGreaterThan(concentrationUnits.count, 0,
                             "At least one concentration unit should be displayed")

        // Check first unit element
        let firstUnit = concentrationUnits.element(boundBy: 0)
        XCTAssertTrue(firstUnit.exists,
                      "Concentration unit should be displayed")

        let unitText = firstUnit.label
        XCTAssertFalse(unitText.isEmpty,
                       "Unit text should not be empty")
        XCTAssertEqual(unitText, "units",
                       "Unit should display 'units' as expected")

        // 6. Verify projected concentration values (peak/trough) are also properly formatted
        let projectedValues = app.staticTexts.matching(identifier: "projected-concentration-value")
        XCTAssertGreaterThan(projectedValues.count, 0,
                             "At least one projected concentration value should be displayed")

        // Check formatting of first projected value
        let firstProjectedValue = projectedValues.element(boundBy: 0)
        XCTAssertTrue(firstProjectedValue.exists,
                      "Projected concentration value should be displayed")

        let projectedValueText = firstProjectedValue.label
        XCTAssertFalse(projectedValueText.isEmpty,
                       "Projected concentration value should not be empty")

        // Verify projected values also use 2 decimal place formatting
        let projectedValueRange = NSRange(location: 0, length: projectedValueText.utf16.count)
        let projectedHasDecimalFormat = regex.firstMatch(in: projectedValueText, range: projectedValueRange) != nil
        XCTAssertTrue(projectedHasDecimalFormat,
                      "Projected concentration should be formatted to 2 decimal places, got: '\(projectedValueText)'")

        // 7. Verify accessibility of concentration values for screen readers
        // Current concentration accessibility
        let currentAccessibilityLabel = currentConcentrationValue.label
        XCTAssertFalse(currentAccessibilityLabel.isEmpty,
                       "Current concentration should have accessibility label")

        // 8. Verify visual indicators exist (ConcentrationDisplay should show level indicators)
        // The ConcentrationDisplay component includes visual indicators for level interpretation
        // These are implemented as accessibility-hidden images but affect overall accessibility value
        let currentAccessibilityValue = currentConcentrationValue.value as? String ?? ""
        if !currentAccessibilityValue.isEmpty {
            // Accessibility value should contain level interpretation (e.g., "Normal level", "Low level", "High level")
            let containsLevelDescription = currentAccessibilityValue.contains("level") ||
                                           currentAccessibilityValue.contains("Normal") ||
                                           currentAccessibilityValue.contains("Low") ||
                                           currentAccessibilityValue.contains("High")
            XCTAssertTrue(containsLevelDescription,
                          "Accessibility value should describe concentration level for screen readers: " +
                          "'\(currentAccessibilityValue)'")
        }

        // 9. Test that values are greater than 0 (indicating bioavailability calculations work)
        if let currentValue = Double(currentValueText) {
            XCTAssertGreaterThan(currentValue, 0.0,
                                 "Current concentration should be greater than 0 after dose")
        }

        if let projectedValue = Double(projectedValueText) {
            XCTAssertGreaterThan(projectedValue, 0.0,
                                 "Projected concentration should be greater than 0")
        }
    }

    /// Acceptance Test: Concentration card integrates seamlessly with dashboard layout
    /// Given: Dashboard displays multiple cards and information
    /// When: User views the dashboard
    /// Then: Concentration card fits well within overall layout
    /// And: Card can be tapped for more detailed information
    /// And: Card shows summary info at glance (current level, next dose timing)
    /// And: Card updates smoothly without disrupting other UI elements
    func testConcentrationCardDashboardIntegration() throws {
        // TODO: Implement E2E test for dashboard integration
        // 1. Set up user with complete medication profile
        // 2. Navigate to dashboard
        // 3. Verify concentration card is positioned appropriately
        // 4. Verify card shows key information at a glance
        // 5. Test tapping card for detailed view (if implemented)
        // 6. Verify card doesn't interfere with other dashboard elements
        // 7. Test card updates without layout disruption
        throw XCTSkip("E2E acceptance test stub - implementation pending")
    }

    /// Acceptance Test: Multiple medications display separate concentration calculations
    /// Given: User has multiple active medications
    /// When: User views dashboard concentration information
    /// Then: Each medication shows separate concentration data
    /// And: Calculations are independent per medication
    /// And: User can distinguish between different medication levels
    func testMultipleMedicationConcentrations() throws {
        // TODO: Implement E2E test for multiple medication handling
        // 1. Set up user with multiple active medications (e.g., semaglutide + tirzepatide)
        // 2. Log doses for both medications
        // 3. Navigate to dashboard
        // 4. Verify separate concentration displays for each medication
        // 5. Verify calculations are independent (no cross-contamination)
        // 6. Verify clear labeling to distinguish medications
        throw XCTSkip("E2E acceptance test stub - implementation pending")
    }

    /// Acceptance Test: Performance - concentration calculations complete quickly
    /// Given: User has extensive dose history (50+ doses)
    /// When: User navigates to dashboard
    /// Then: Concentration calculations complete within 50ms
    /// And: Dashboard loads smoothly without lag
    /// And: Updates are responsive during dose entry
    func testConcentrationCalculationPerformance() throws {
        // TODO: Implement E2E test for calculation performance
        // 1. Set up user with large dose history (simulate 50+ doses)
        // 2. Measure time for dashboard to display concentration data
        // 3. Verify calculations complete quickly (< 50ms requirement)
        // 4. Test responsiveness during dose entry workflow
        // 5. Verify smooth updates without UI blocking
        throw XCTSkip("E2E acceptance test stub - implementation pending")
    }

    /// Acceptance Test: Error handling when concentration data is unavailable
    /// Given: User has no dose history or incomplete medication setup
    /// When: User views dashboard concentration area
    /// Then: Helpful message explains why concentration data is unavailable
    /// And: Clear guidance on how to enable concentration tracking
    /// And: No crashes or empty states without explanation
    func testConcentrationErrorStates() throws {
        // TODO: Implement E2E test for error/empty states
        // 1. Set up user with no medication profiles
        // 2. Navigate to dashboard
        // 3. Verify helpful message about setting up medications
        // 4. Test with incomplete medication setup (no doses)
        // 5. Verify guidance leads user to appropriate setup flow
        // 6. Test with corrupted/invalid dose data
        throw XCTSkip("E2E acceptance test stub - implementation pending")
    }
}
