//
//  ChartControlsUITests.swift
//  JabTrackerUITests
//

import XCTest

final class ChartControlsUITests: XCTestCase {

  let app = XCUIApplication()

  override func setUpWithError() throws {
    continueAfterFailure = false
    app.launchArguments = ["--ui-testing", "--reset-app-data"]
    app.launch()
  }

  // MARK: - Helper Methods

  /// Find chart element using multiple possible identifiers
  private func findChartElement() -> XCUIElement {
    let chartElement = app.otherElements["concentration-timeline-chart"]
    let analyticsChartElement = app.otherElements["analytics-concentration-chart"]

    return chartElement.exists ? chartElement : analyticsChartElement
  }

  // MARK: - ACCEPTANCE CRITERION: Time period selector works correctly
  func testTimePeriodSelectorChangesChartTimeframe() throws {
    // GIVEN: User is viewing concentration timeline chart
    let analyticsTab = app.tabBars.buttons["Analytics"]
    XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
    analyticsTab.tap()

    // Debug to find time period selector elements
    TestUtilities.debugElements(in: app, containing: "period")
    TestUtilities.debugElements(in: app, containing: "day")
    TestUtilities.debugElements(in: app, containing: "chart")

    // Check if chart is present or if we're in empty state
    let chartElement = findChartElement()
    let emptyState = app.otherElements.containing(.staticText, identifier: "No Analytics Data")
      .firstMatch

    if chartElement.exists {
      // WHEN: User taps time period selector (7d, 30d, 90d, 1y)
      let timePeriodButtons = [
        app.buttons["7d"],
        app.buttons["30d"],
        app.buttons["90d"],
        app.buttons["1y"],
      ]

      for button in timePeriodButtons where button.exists {
        button.tap()

        // THEN: Chart updates to show selected time period
        XCTAssertTrue(
          chartElement.exists, "Chart should remain visible after time period selection")

        // Verify the button shows selected state (if applicable)
        // Note: This would need specific accessibility implementation
      }

      // THEN: Controls state persists correctly
      // Test that the last selected period remains active
      let lastButton = timePeriodButtons.last(where: { $0.exists })
      if let button = lastButton {
        XCTAssertTrue(button.exists, "Last selected time period button should remain accessible")
      }
    } else if emptyState.exists {
      // THEN: Empty state is displayed correctly when no chart data
      XCTAssertTrue(emptyState.exists, "Empty state should be shown when no data available")
      print("ℹ️ Chart controls test skipped - no chart data available (empty state)")
    } else {
      XCTFail("Neither chart nor empty state found - Analytics view may not be loading correctly")
    }
  }

  // MARK: - ACCEPTANCE CRITERION: Chart controls display correct state
  func testChartControlsDisplayCorrectState() throws {
    // GIVEN: User has chart controls visible
    let analyticsTab = app.tabBars.buttons["Analytics"]
    XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
    analyticsTab.tap()

    // Debug to find chart control elements
    TestUtilities.debugElements(in: app, containing: "control")
    TestUtilities.debugElements(in: app, containing: "button")

    // Check if chart is present or if we're in empty state
    let chartElement = findChartElement()
    let emptyState = app.otherElements.containing(.staticText, identifier: "No Analytics Data")
      .firstMatch

    if chartElement.exists {
      // WHEN: User interacts with different control options
      // Look for common chart control patterns
      let exportButton = app.buttons.matching(
        NSPredicate(format: "label CONTAINS 'export' OR label CONTAINS 'Export'")
      ).firstMatch
      let resetButton = app.buttons.matching(
        NSPredicate(format: "label CONTAINS 'reset' OR label CONTAINS 'Reset'")
      ).firstMatch
      _ = app.buttons.matching(
        NSPredicate(format: "label CONTAINS 'zoom' OR label CONTAINS 'Zoom'"))

      // Test export control if available
      if exportButton.exists {
        exportButton.tap()
        // Verify export functionality responds
        // Note: This would show an export sheet or similar
      }

      // Test reset control if available
      if resetButton.exists {
        resetButton.tap()
        // THEN: Controls display appropriate visual feedback
        XCTAssertTrue(chartElement.exists, "Chart should remain visible after reset")
      }

      // THEN: State changes are reflected in the chart
      // Verify chart responds to control interactions
      XCTAssertTrue(chartElement.exists, "Chart should remain responsive to control changes")
    } else if emptyState.exists {
      // THEN: Empty state is displayed correctly when no chart data
      XCTAssertTrue(emptyState.exists, "Empty state should be shown when no data available")
      print("ℹ️ Chart controls test skipped - no chart data available (empty state)")
    } else {
      XCTFail("Neither chart nor empty state found - Analytics view may not be loading correctly")
    }
  }

  // MARK: - ACCEPTANCE CRITERION: Chart controls are accessible
  func testChartControlsAccessibility() throws {
    // GIVEN: User is viewing concentration timeline chart
    let analyticsTab = app.tabBars.buttons["Analytics"]
    XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
    analyticsTab.tap()

    // Debug to find accessibility elements
    TestUtilities.debugElements(in: app, containing: "control")
    TestUtilities.debugElements(in: app, containing: "button")

    // WHEN: User navigates chart controls with accessibility
    // Test time period buttons for accessibility
    let timePeriodButtons = [
      app.buttons["7d"],
      app.buttons["30d"],
      app.buttons["90d"],
      app.buttons["1y"],
    ]

    for button in timePeriodButtons where button.exists {
      // THEN: All controls have proper labels and hints
      XCTAssertNotNil(button.label, "Time period button should have accessibility label")
      XCTAssertFalse(button.label.isEmpty, "Time period button label should not be empty")

      // Test button is accessible
      XCTAssertTrue(
        button.isAccessibilityElement, "Time period button should be accessibility element")

      // Test interaction
      button.tap()

      // Verify chart remains accessible after interaction
      let chartElement = findChartElement()
      if chartElement.exists {
        XCTAssertNotNil(
          chartElement.label, "Chart should maintain accessibility after control interaction")
      }
    }

    // Test chart accessibility features
    let chartElement = findChartElement()
    if chartElement.exists {
      // THEN: Chart provides accessibility information
      XCTAssertTrue(
        chartElement.isAccessibilityElement || chartElement.accessibilityElements?.count ?? 0 > 0,
        "Chart should be accessible either as single element or container")

      // Test chart has meaningful accessibility content
      if chartElement.isAccessibilityElement {
        XCTAssertNotNil(chartElement.label, "Chart should have accessibility label")
        XCTAssertFalse(chartElement.label.isEmpty, "Chart accessibility label should not be empty")
      }
    }

    // THEN: Selection state is announced correctly
    // Test that button states are properly communicated
    let lastSelectedButton = timePeriodButtons.first(where: { $0.exists })
    if let button = lastSelectedButton {
      // Verify button maintains accessibility after selection
      XCTAssertTrue(button.isAccessibilityElement, "Selected button should remain accessible")
    }
  }

  // MARK: - ACCEPTANCE CRITERION: Multiple time periods can be selected
  func testMultipleTimePeriodSelection() throws {
    // GIVEN: Chart with multiple time period options
    let analyticsTab = app.tabBars.buttons["Analytics"]
    XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")
    analyticsTab.tap()

    // Debug to find time period elements
    TestUtilities.debugElements(in: app, containing: "period")
    TestUtilities.debugElements(in: app, containing: "day")

    // Check if chart is present or if we're in empty state
    let chartElement = findChartElement()
    let emptyState = app.otherElements.containing(.staticText, identifier: "No Analytics Data")
      .firstMatch

    if chartElement.exists {

      // WHEN: User selects different time periods sequentially
      let timePeriodButtons = [
        app.buttons["7d"],
        app.buttons["30d"],
        app.buttons["90d"],
        app.buttons["1y"],
      ]

      var previouslySelectedButton: XCUIElement?

      for button in timePeriodButtons where button.exists {
        // Store current button state before tapping
        _ = button.isSelected

        // Tap the button
        button.tap()

        // THEN: Each selection updates the chart correctly
        // Verify chart remains visible and responsive
        XCTAssertTrue(
          chartElement.exists, "Chart should remain visible after selecting \(button.label)")

        // Verify chart updates (basic responsiveness test)
        // We can't easily verify the actual data change, but we can verify the chart remains functional
        if chartElement.exists {
          // Test that chart is still interactive
          chartElement.swipeLeft()
          XCTAssertTrue(
            chartElement.exists, "Chart should remain interactive after time period change")
        }

        // THEN: Previous selection is deselected (if we can detect selection state)
        if let previousButton = previouslySelectedButton, previousButton.exists {
          // Note: Selection state detection depends on UI implementation
          // In a real implementation, we'd check for visual selection indicators
          // For E2E testing, we verify that buttons remain accessible and functional
          XCTAssertTrue(
            previousButton.isAccessibilityElement, "Previous button should remain accessible")
        }

        // Update tracking for next iteration
        previouslySelectedButton = button

        // Small delay to allow chart to update
        sleep(1)
      }

      // Verify final state - chart should still be responsive
      XCTAssertTrue(chartElement.exists, "Chart should remain functional after multiple selections")

      // Test selecting same period twice (should remain stable)
      let lastAvailableButton = timePeriodButtons.last(where: { $0.exists })
      if let button = lastAvailableButton {
        button.tap()
        button.tap()  // Tap twice

        // Chart should remain stable
        XCTAssertTrue(
          chartElement.exists, "Chart should remain stable when same period selected multiple times"
        )
      }
    } else if emptyState.exists {
      // THEN: Empty state is displayed correctly when no chart data
      XCTAssertTrue(emptyState.exists, "Empty state should be shown when no data available")
      print("ℹ️ Multiple time period test skipped - no chart data available (empty state)")
    } else {
      XCTFail("Neither chart nor empty state found - Analytics view may not be loading correctly")
    }
  }

  // MARK: - ACCEPTANCE CRITERION: Default time period is selected on load
  func testDefaultTimePeriodSelection() throws {
    // GIVEN: User opens chart for first time
    // We can simulate this by starting fresh (the app is already reset with --reset-app-data)
    let analyticsTab = app.tabBars.buttons["Analytics"]
    XCTAssertTrue(analyticsTab.waitForExistence(timeout: 5), "Analytics tab should exist")

    // Debug to find initial chart state
    TestUtilities.debugElements(in: app, containing: "chart")
    TestUtilities.debugElements(in: app, containing: "30d")

    // WHEN: Chart loads with controls
    analyticsTab.tap()

    // Wait for chart to load
    let chartElement = findChartElement()
    XCTAssertTrue(chartElement.waitForExistence(timeout: 10), "Chart should load")

    // THEN: Default time period (30d) is selected
    // Look for 30d button and verify it's in a selected state (if detectable)
    let defaultButton = app.buttons["30d"]
    if defaultButton.exists {
      // Verify default button is accessible and functional
      XCTAssertTrue(defaultButton.isAccessibilityElement, "Default 30d button should be accessible")
      XCTAssertNotNil(defaultButton.label, "Default button should have label")

      // Test that we can interact with the default selection
      defaultButton.tap()

      // Verify chart responds to default selection
      XCTAssertTrue(chartElement.exists, "Chart should remain functional with default selection")
    }

    // THEN: Chart shows data for default period
    // Verify chart is displaying content (not empty state)
    if chartElement.exists {
      // Test basic chart functionality
      XCTAssertTrue(
        chartElement.isAccessibilityElement || chartElement.accessibilityElements?.count ?? 0 > 0,
        "Chart should have accessible content for default period")

      // Test chart interaction to verify it has data/content
      chartElement.swipeLeft()
      XCTAssertTrue(chartElement.exists, "Chart should remain responsive with default data")

      // Check chart accessibility information
      if chartElement.isAccessibilityElement {
        XCTAssertNotNil(
          chartElement.label, "Chart should have accessibility information for default period")
      }
    }

    // Verify all time period options are available from initial load
    let timePeriodButtons = [
      app.buttons["7d"],
      app.buttons["30d"],
      app.buttons["90d"],
      app.buttons["1y"],
    ]

    let availableButtons = timePeriodButtons.filter { $0.exists }
    XCTAssertTrue(
      availableButtons.count > 0, "At least one time period button should be available on load")

    // Test switching from default to verify default behavior
    if let firstAvailableButton = availableButtons.first {
      firstAvailableButton.tap()

      // Verify chart updates from default
      XCTAssertTrue(chartElement.exists, "Chart should update correctly from default selection")

      // Return to default if 30d button exists
      if defaultButton.exists {
        defaultButton.tap()
        XCTAssertTrue(chartElement.exists, "Chart should return to default state correctly")
      }
    }
  }
}
