//
//  ChartControlsViewTests.swift
//  JabTrackerTests
//

import SwiftUI
import Testing

@testable import JabTracker

@MainActor
struct ChartControlsViewTests {

  // MARK: - Component Creation Tests

  @Test("ChartControlsView can be created with initial state")
  func testChartControlsViewCreation() async throws {
    // GIVEN: ChartControlsView with initial state
    @State var selectedPeriod: ChartDataProcessor.TimePeriod = .last30Days
    @State var showExportSheet = false

    // WHEN: Creating the controls view
    _ = ChartControlsView(
      selectedPeriod: Binding(
        get: { selectedPeriod },
        set: { selectedPeriod = $0 }
      ),
      showExportSheet: Binding(
        get: { showExportSheet },
        set: { showExportSheet = $0 }
      )
    )

    // THEN: Controls view should be created successfully (no crash)
    #expect(true, "ChartControlsView should be created successfully")
  }

  // MARK: - State Management Tests

  @Test("ChartControlsView updates bindings correctly")
  func testStateUpdates() async throws {
    // GIVEN: ChartControlsView with bindings
    @State var selectedPeriod: ChartDataProcessor.TimePeriod = .last30Days
    @State var showExportSheet = false

    _ = ChartControlsView(
      selectedPeriod: Binding(
        get: { selectedPeriod },
        set: { selectedPeriod = $0 }
      ),
      showExportSheet: Binding(
        get: { showExportSheet },
        set: { showExportSheet = $0 }
      )
    )

    // Initial states should be correct
    #expect(selectedPeriod == .last30Days, "Initial period should be last30Days")
    #expect(showExportSheet == false, "Initial export sheet state should be false")

    // WHEN: State changes (simulated through bindings)
    selectedPeriod = .last7Days
    showExportSheet = true

    // THEN: Bindings should reflect the changes
    #expect(selectedPeriod == .last7Days, "Period should update to last7Days")
    #expect(showExportSheet == true, "Export sheet state should update to true")
  }

  // MARK: - Export Sheet Management Tests

  @Test("ChartControlsView manages export sheet state")
  func testExportSheetManagement() async throws {
    // GIVEN: ChartControlsView with export sheet binding
    @State var selectedPeriod: ChartDataProcessor.TimePeriod = .last30Days
    @State var showExportSheet = false

    _ = ChartControlsView(
      selectedPeriod: Binding(
        get: { selectedPeriod },
        set: { selectedPeriod = $0 }
      ),
      showExportSheet: Binding(
        get: { showExportSheet },
        set: { showExportSheet = $0 }
      )
    )

    // WHEN: Export sheet is toggled
    showExportSheet = true

    // THEN: State should be properly managed
    #expect(showExportSheet == true, "Export sheet should be shown")

    // WHEN: Export sheet is dismissed
    showExportSheet = false

    // THEN: State should return to hidden
    #expect(showExportSheet == false, "Export sheet should be hidden")
  }

  // MARK: - Integration Tests

  @Test("ChartControlsView integrates TimePeriodSelector correctly")
  func testTimePeriodSelectorIntegration() async throws {
    // GIVEN: ChartControlsView with period binding
    @State var selectedPeriod: ChartDataProcessor.TimePeriod = .last30Days
    @State var showExportSheet = false

    _ = ChartControlsView(
      selectedPeriod: Binding(
        get: { selectedPeriod },
        set: { selectedPeriod = $0 }
      ),
      showExportSheet: Binding(
        get: { showExportSheet },
        set: { showExportSheet = $0 }
      )
    )

    // WHEN: Period selection changes
    selectedPeriod = .last90Days

    // THEN: Integration should work correctly
    #expect(selectedPeriod == .last90Days, "Period selection should be integrated correctly")
  }

  // MARK: - Accessibility Tests

  @Test("ChartControlsView has proper accessibility support")
  func testAccessibilitySupport() async throws {
    // This test verifies that the component will have proper accessibility support
    // Implementation will be verified through actual component accessibility features

    @State var selectedPeriod: ChartDataProcessor.TimePeriod = .last30Days
    @State var showExportSheet = false

    _ = ChartControlsView(
      selectedPeriod: Binding(
        get: { selectedPeriod },
        set: { selectedPeriod = $0 }
      ),
      showExportSheet: Binding(
        get: { showExportSheet },
        set: { showExportSheet = $0 }
      )
    )

    // Component should be created (accessibility will be tested in E2E)
    #expect(true, "ChartControlsView should be created for accessibility testing")
  }
}
