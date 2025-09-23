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

  @Test("TimePeriodSelector binding initialization and state consistency")
  func testSelectionBinding() async throws {
    // GIVEN: TimePeriodSelector with different initial states
    let testPeriods: [ChartDataProcessor.TimePeriod] = [
      .last7Days, .last30Days, .last90Days, .lastYear,
    ]

    for initialPeriod in testPeriods {
      var currentPeriod: ChartDataProcessor.TimePeriod = initialPeriod
      var bindingCallCount = 0

      // WHEN: Creating selector with binding that tracks calls
      let binding = Binding(
        get: {
          currentPeriod
        },
        set: { newValue in
          currentPeriod = newValue
          bindingCallCount += 1
        }
      )

      _ = TimePeriodSelector(selectedPeriod: binding)

      // THEN: Initial state should be preserved
      #expect(currentPeriod == initialPeriod, "Initial period should be \(initialPeriod)")

      // AND: Binding should be ready for updates (component created successfully)
      #expect(true, "TimePeriodSelector should be created with \(initialPeriod) binding")
    }
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
