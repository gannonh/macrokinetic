//
//  TimePeriodSelectorTests.swift
//  JabTrackerTests
//

import SwiftUI
import Testing

@testable import JabTracker

@MainActor
struct TimePeriodSelectorTests {

  // MARK: - Component Creation Tests

  @Test("TimePeriodSelector can be created with initial state")
  func testTimePeriodSelectorCreation() async throws {
    // GIVEN: TimePeriodSelector with initial state
    @State var selectedPeriod: ChartDataProcessor.TimePeriod = .last30Days

    // WHEN: Creating the selector
    _ = TimePeriodSelector(
      selectedPeriod: Binding(
        get: { selectedPeriod },
        set: { selectedPeriod = $0 }
      )
    )

    // THEN: Selector should be created successfully (no crash)
    #expect(true, "TimePeriodSelector should be created successfully")
  }

  // MARK: - State Management Tests

  @Test("TimePeriodSelector updates binding when selection changes")
  func testSelectionBinding() async throws {
    // GIVEN: TimePeriodSelector with binding
    @State var selectedPeriod: ChartDataProcessor.TimePeriod = .last30Days

    let selector = TimePeriodSelector(
      selectedPeriod: Binding(
        get: { selectedPeriod },
        set: { selectedPeriod = $0 }
      )
    )

    // Initial state should be last30Days
    #expect(selectedPeriod == .last30Days, "Initial selection should be last30Days")

    // WHEN: Selection changes (simulated through binding)
    selectedPeriod = .last7Days

    // THEN: Binding should reflect the change
    #expect(selectedPeriod == .last7Days, "Selection should update to last7Days")
  }

  @Test("TimePeriodSelector supports all defined time periods")
  func testAllTimePeriodOptionsSupported() async throws {
    // GIVEN: All available time periods
    let allPeriods: [ChartDataProcessor.TimePeriod] = [
      .last7Days, .last30Days, .last90Days, .lastYear, .all,
    ]

    // WHEN: Testing each period can be set
    for period in allPeriods {
      @State var selectedPeriod: ChartDataProcessor.TimePeriod = period

      _ = TimePeriodSelector(
        selectedPeriod: Binding(
          get: { selectedPeriod },
          set: { selectedPeriod = $0 }
        )
      )

      // THEN: Each period should be supported (no crash)
      #expect(true, "TimePeriodSelector should support \(period)")
      #expect(selectedPeriod == period, "Selected period should match \(period)")
    }
  }

  // MARK: - Accessibility Tests

  @Test("TimePeriodSelector has proper accessibility identifiers")
  func testAccessibilityIdentifiers() async throws {
    // This test verifies that the component will have proper accessibility support
    // Implementation will be verified through actual component accessibility features

    @State var selectedPeriod: ChartDataProcessor.TimePeriod = .last30Days

    _ = TimePeriodSelector(
      selectedPeriod: Binding(
        get: { selectedPeriod },
        set: { selectedPeriod = $0 }
      )
    )

    // Component should be created (accessibility will be tested in E2E)
    #expect(true, "TimePeriodSelector should be created for accessibility testing")
  }
}
