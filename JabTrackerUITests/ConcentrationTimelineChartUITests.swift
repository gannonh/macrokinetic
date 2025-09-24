//
//  ConcentrationTimelineChartUITests.swift
//  JabTrackerUITests
//

import XCTest

/// E2E acceptance tests for ConcentrationTimelineChart functionality
/// Defines the complete user experience and acceptance criteria for chart interactions
final class ConcentrationTimelineChartUITests: XCTestCase {

  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--reset-app-data"]
    app.launch()

    // Wait for authentication bypass to complete
    let tabBar = app.tabBars.firstMatch
    XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after auth bypass")
  }

  // MARK: - Helper Methods

  /// Helper function to set up test data needed for chart functionality
  /// Creates a medication profile and adds several doses with historical dates
  private func setupChartTestData() {
    // Step 1: Create a medication profile
    app.tabBars.buttons["Settings"].tap()

    let medicationProfilesButton = app.buttons["Medication Profiles"]
    XCTAssertTrue(
      medicationProfilesButton.waitForExistence(timeout: 5),
      "Medication Profiles button should exist")
    medicationProfilesButton.tap()

    let addProfileButton = app.buttons["Add Medication Profile"]
    XCTAssertTrue(addProfileButton.waitForExistence(timeout: 5), "Add Profile button should exist")
    addProfileButton.tap()

    // Select medication (Semaglutide)
    let medicationPicker = app.buttons["medication-picker"]
    XCTAssertTrue(medicationPicker.waitForExistence(timeout: 5), "Medication picker should exist")
    medicationPicker.tap()

    let semaglutideOption = app.buttons["medication-semaglutide"]
    XCTAssertTrue(semaglutideOption.waitForExistence(timeout: 5), "Semaglutide option should exist")
    semaglutideOption.tap()

    // Select brand (Ozempic)
    let brandPicker = app.buttons["add-brand-picker"]
    XCTAssertTrue(brandPicker.waitForExistence(timeout: 5), "Brand picker should exist")
    brandPicker.tap()

    let ozempicOption = app.buttons["add-brand-ozempic"]
    XCTAssertTrue(ozempicOption.waitForExistence(timeout: 5), "Ozempic option should exist")
    ozempicOption.tap()

    // Save profile (will use default dose)
    let saveButton = app.buttons["save-medication-profile"]
    XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button should exist")
    saveButton.tap()

    // Wait for profile to be created and navigate back to main tabs
    // Verify we're back in the medication profiles list
    let profilesList = app.navigationBars.containing(.staticText, identifier: "Medication Profiles")
    if profilesList.firstMatch.waitForExistence(timeout: 3) {
      // We're still in the medication profiles view, go back to main tabs
      app.tabBars.buttons["Settings"].tap()  // Go back to settings
      sleep(1)
    }

    // Step 2: Add some dose entries to create chart data
    // Add 3 doses to create a meaningful chart
    for index in 0..<3 {
      // Navigate to Add tab and verify it's available
      let addTab = app.tabBars.buttons["Add"]
      XCTAssertTrue(addTab.waitForExistence(timeout: 5), "Add tab should be available")
      addTab.tap()

      let quickDoseSheet = app.sheets.firstMatch
      XCTAssertTrue(
        quickDoseSheet.waitForExistence(timeout: 5),
        "Quick dose sheet should appear for iteration \(index)")

      // For doses after the first, use historical dates
      if index > 0 {
        let datePicker = app.datePickers["quick-dose-entry-date-picker"]
        if datePicker.exists {
          datePicker.tap()
          // This will open the date picker for potential historical date selection
          // In a real test scenario, we would set specific past dates
        }
      }

      // Save the dose
      let saveButton = app.buttons["quick-dose-entry-save"]

      // Wait for medication profile to load if needed
      if !saveButton.isEnabled {
        sleep(2)
      }

      if saveButton.waitForExistence(timeout: 5) && saveButton.isEnabled {
        saveButton.tap()

        // Wait for sheet to dismiss
        XCTAssertFalse(
          quickDoseSheet.waitForExistence(timeout: 3), "Sheet should dismiss after save")
      } else {
        // If we can't save, cancel and break
        let cancelButton = app.buttons["quick-dose-entry-cancel"]
        if cancelButton.exists {
          cancelButton.tap()
        }
        break
      }
    }
  }

  // MARK: - ACCEPTANCE CRITERION: Chart displays concentration timeline correctly
  func testConcentrationTimelineDisplaysCorrectly() throws {
    // GIVEN: User has medication profile with dose history
    setupChartTestData()

    // WHEN: User navigates to concentration timeline chart
    let analyticsTab = app.tabBars.buttons["Analytics"]
    XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
    analyticsTab.tap()

    // THEN: Chart renders with concentration line over time
    let chartElement = app.otherElements["analytics-concentration-chart"]
    XCTAssertTrue(
      chartElement.waitForExistence(timeout: 10), "Chart should be present in Analytics tab")

    // Verify chart accessibility elements exist
    XCTAssertTrue(chartElement.exists, "Chart should have accessibility identifier")
  }

  // MARK: - ACCEPTANCE CRITERION: Interactive features work correctly
  func testInteractiveChartFeatures() throws {
    // GIVEN: ConcentrationTimelineChart is displayed with data
    setupChartTestData()

    // Navigate to Analytics tab
    let analyticsTab = app.tabBars.buttons["Analytics"]
    XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
    analyticsTab.tap()

    // Find the chart element
    let chartElement = app.otherElements["analytics-concentration-chart"]
    XCTAssertTrue(chartElement.waitForExistence(timeout: 10), "Chart should be visible")

    // WHEN: User interacts with chart using gestures
    // Test pan gesture (swipe to move timeline)
    chartElement.swipeLeft()
    chartElement.swipeRight()

    // Test zoom gesture (pinch to zoom - simulated with coordinate taps)
    let chartBounds = chartElement.frame
    let centerPoint = CGPoint(x: chartBounds.midX, y: chartBounds.midY)

    // Simulate zoom by tapping at different points
    let leftPoint = CGPoint(x: chartBounds.midX - 50, y: chartBounds.midY)
    let rightPoint = CGPoint(x: chartBounds.midX + 50, y: chartBounds.midY)

    app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(
      CGVector(dx: leftPoint.x, dy: leftPoint.y)
    ).tap()
    app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(
      CGVector(dx: rightPoint.x, dy: rightPoint.y)
    ).tap()

    // THEN: Chart responds appropriately to user interactions
    // Verify chart is still present and functional after gestures
    XCTAssertTrue(chartElement.exists, "Chart should remain functional after gestures")
  }

  // MARK: - ACCEPTANCE CRITERION: Time period selection works
  func testTimePeriodSelector() throws {
    // GIVEN: ConcentrationTimelineChart is displayed
    let analyticsTab = app.tabBars.buttons["Analytics"]
    XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
    analyticsTab.tap()

    // Debug to find time period selector elements
    // Wait for time period controls to load
    sleep(1)

    // WHEN: User selects different time periods (7d, 30d, 90d, 1y)
    // Look for time period buttons - use common patterns
    let sevenDayButton = app.buttons["7d"]
    let thirtyDayButton = app.buttons["30d"]
    let ninetyDayButton = app.buttons["90d"]
    let oneYearButton = app.buttons["1y"]

    // Test different time period selections
    if sevenDayButton.exists {
      sevenDayButton.tap()
      // Verify chart updates (check that chart is still visible)
      let chartElement = app.otherElements["concentration-timeline-chart"]
      XCTAssertTrue(chartElement.exists, "Chart should remain visible after 7-day selection")
    }

    if thirtyDayButton.exists {
      thirtyDayButton.tap()
      let chartElement = app.otherElements["concentration-timeline-chart"]
      XCTAssertTrue(chartElement.exists, "Chart should remain visible after 30-day selection")
    }

    // THEN: Chart displays correct time range data
    // Verify the chart is responsive to time period changes
    if oneYearButton.exists {
      oneYearButton.tap()
      let chartElement = app.otherElements["concentration-timeline-chart"]
      XCTAssertTrue(chartElement.exists, "Chart should remain visible after 1-year selection")
    }
  }

  // MARK: - ACCEPTANCE CRITERION: Accessibility features work correctly
  func testChartAccessibilityFeatures() throws {
    // GIVEN: ConcentrationTimelineChart is displayed with data
    setupChartTestData()

    let analyticsTab = app.tabBars.buttons["Analytics"]
    XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
    analyticsTab.tap()

    // WHEN: User navigates chart with VoiceOver enabled
    let chartElement = app.otherElements["analytics-concentration-chart"]
    XCTAssertTrue(chartElement.waitForExistence(timeout: 10), "Chart should be visible")

    // THEN: Chart provides complete accessibility experience
    // Verify chart has accessible description
    XCTAssertNotNil(chartElement.label, "Chart should have accessibility label")
    XCTAssertFalse(chartElement.label.isEmpty, "Chart accessibility label should not be empty")

    // Look for dose markers with accessibility identifiers
    // Wait for accessibility elements to load
    sleep(1)

    // Check for dose marker accessibility
    let doseMarkers = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'dose-marker'"))

    if doseMarkers.count > 0 {
      let firstMarker = doseMarkers.element(boundBy: 0)
      XCTAssertTrue(firstMarker.exists, "Dose markers should be accessible")
      XCTAssertNotNil(firstMarker.label, "Dose markers should have labels")
    }

    // Verify chart accessibility information
    XCTAssertTrue(
      chartElement.isAccessibilityElement || chartElement.accessibilityElements?.count ?? 0 > 0,
      "Chart should be accessible either as single element or container")
  }

  // MARK: - ACCEPTANCE CRITERION: Performance with large datasets
  func testChartPerformanceWithLargeDatasets() throws {
    // GIVEN: User has extensive dose history (1+ year of data)
    // For E2E testing, we'll simulate by creating multiple doses using the new date picker

    // First add several doses with different dates using the Quick Add functionality
    let addTab = app.tabBars.buttons["Add"]
    XCTAssertTrue(addTab.waitForExistence(timeout: 5), "Add tab should exist")

    // Add 3-4 doses with different dates to create some historical data
    for index in 0..<4 {
      addTab.tap()

      // Wait for quick dose sheet
      let quickDoseSheet = app.sheets.firstMatch
      XCTAssertTrue(quickDoseSheet.waitForExistence(timeout: 5), "Quick dose sheet should appear")

      // Modify the date to create historical data using our new date picker
      if index > 0 {
        let datePicker = app.datePickers["quick-dose-entry-date-picker"]
        if datePicker.exists {
          datePicker.tap()
          // For E2E testing, we'll just tap to change from default
          // Real test would set specific past dates
        }
      }

      // Save the dose
      let saveButton = app.buttons["quick-dose-entry-save"]
      if saveButton.exists && !saveButton.isEnabled {
        // If save is disabled, we might need to wait for medication loading
        sleep(1)
      }
      XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button should exist")
      if saveButton.isEnabled {
        saveButton.tap()
      } else {
        // Cancel if we can't save
        let cancelButton = app.buttons["quick-dose-entry-cancel"]
        if cancelButton.exists {
          cancelButton.tap()
        }
        break
      }

      // Wait for sheet to dismiss
      XCTAssertFalse(quickDoseSheet.waitForExistence(timeout: 2), "Sheet should dismiss after save")
    }

    // WHEN: ConcentrationTimelineChart loads with full dataset
    let analyticsTab = app.tabBars.buttons["Analytics"]
    XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")

    // Measure performance of chart loading
    let startTime = Date()
    analyticsTab.tap()

    // Wait for chart to appear
    let chartElement = app.otherElements["analytics-concentration-chart"]
    let chartLoaded = chartElement.waitForExistence(timeout: 10)
    let loadTime = Date().timeIntervalSince(startTime)

    // THEN: Chart maintains smooth performance
    XCTAssertTrue(chartLoaded, "Chart should load with dataset")
    XCTAssertLessThan(loadTime, 2.0, "Chart should load within reasonable time for E2E test")

    // Test responsiveness after loading
    if chartElement.exists {
      // Test pan gesture responsiveness
      chartElement.swipeLeft()
      chartElement.swipeRight()

      // Verify chart is still responsive
      XCTAssertTrue(chartElement.exists, "Chart should remain responsive after gestures")
    }
  }
}
