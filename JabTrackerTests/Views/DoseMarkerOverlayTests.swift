//
//  DoseMarkerOverlayTests.swift
//  JabTrackerTests
//

import SwiftUI
import Testing

@testable import JabTracker

/// Unit tests for DoseMarkerOverlay component
/// Tests advanced dose marker visualization functionality
struct DoseMarkerOverlayTests {

  // MARK: - Test Data Factory

  private func createTestDoseMarkers() -> [AdvancedDoseMarker] {
    [
      AdvancedDoseMarker(
        date: Date().addingTimeInterval(-7 * 24 * 3600),  // 1 week ago
        amount: 1.0,
        markerStyle: .firstDose
      ),
      AdvancedDoseMarker(
        date: Date().addingTimeInterval(-3 * 24 * 3600),  // 3 days ago
        amount: 1.0,
        markerStyle: .standard
      ),
      AdvancedDoseMarker(
        date: Date().addingTimeInterval(-1 * 24 * 3600),  // 1 day ago
        amount: 1.5,
        markerStyle: .emphasized
      ),
    ]
  }

  // MARK: - Initialization Tests

  @Test("DoseMarkerOverlay initializes with dose markers correctly")
  func testInitializationWithDoseMarkers() {
    let markers = createTestDoseMarkers()
    let overlay = DoseMarkerOverlay(doseMarkers: markers)

    #expect(overlay.doseMarkers.count == 3, "Should initialize with all provided dose markers")
    #expect(
      overlay.doseMarkers[0].markerStyle == .firstDose, "First marker should have correct style")
    #expect(
      overlay.doseMarkers[1].markerStyle == .standard, "Second marker should have correct style")
    #expect(
      overlay.doseMarkers[2].markerStyle == .emphasized, "Third marker should have correct style")
  }

  @Test("DoseMarkerOverlay handles empty dose markers gracefully")
  func testInitializationWithEmptyMarkers() {
    let overlay = DoseMarkerOverlay(doseMarkers: [])

    #expect(overlay.doseMarkers.isEmpty, "Should handle empty dose markers array")
    #expect(overlay.shouldShowEmptyState == true, "Should show empty state when no markers")
  }

  // MARK: - Marker Filtering Tests

  @Test("DoseMarkerOverlay filters markers by date range correctly")
  func testMarkerFilteringByDateRange() {
    let markers = createTestDoseMarkers()
    let overlay = DoseMarkerOverlay(doseMarkers: markers)

    // Create a date range that includes only the last 2 days
    let endDate = Date()
    let startDate = endDate.addingTimeInterval(-2 * 24 * 3600)

    let filteredMarkers = overlay.filteredMarkers(for: startDate...endDate)

    #expect(filteredMarkers.count == 1, "Should filter to only markers within date range")
    #expect(filteredMarkers[0].amount == 1.5, "Should include the escalated dose from 1 day ago")
    #expect(filteredMarkers[0].markerStyle == .emphasized, "Filtered marker should maintain style")
  }

  @Test("DoseMarkerOverlay handles markers outside date range")
  func testMarkerFilteringWithNoMatches() {
    let markers = createTestDoseMarkers()
    let overlay = DoseMarkerOverlay(doseMarkers: markers)

    // Create a future date range with no markers
    let startDate = Date().addingTimeInterval(24 * 3600)
    let endDate = startDate.addingTimeInterval(7 * 24 * 3600)

    let filteredMarkers = overlay.filteredMarkers(for: startDate...endDate)

    #expect(filteredMarkers.isEmpty, "Should return empty array when no markers in range")
  }

  // MARK: - Interaction Tests

  @Test("DoseMarkerOverlay provides detailed marker information")
  func testMarkerDetailInformation() {
    let marker = AdvancedDoseMarker(
      date: Date().addingTimeInterval(-24 * 3600),
      amount: 2.4,
      markerStyle: .emphasized
    )
    let overlay = DoseMarkerOverlay(doseMarkers: [marker])

    let markerInfo = overlay.detailsForMarker(marker)

    #expect(markerInfo != nil, "Should provide detail information for valid marker")
    #expect(markerInfo?.amount == 2.4, "Should include correct dose amount")
    #expect(markerInfo?.markerStyle == .emphasized, "Should include correct marker style")
    #expect(markerInfo?.formattedDate.isEmpty == false, "Should provide formatted date")
  }

  // MARK: - Accessibility Tests

  @Test("DoseMarkerOverlay provides accessibility information")
  func testAccessibilityInformation() {
    let markers = createTestDoseMarkers()
    let overlay = DoseMarkerOverlay(doseMarkers: markers)

    let accessibilityLabel = overlay.accessibilityDescription
    let accessibilityValue = overlay.accessibilityValue

    #expect(accessibilityLabel?.isEmpty == false, "Should provide accessibility label")
    #expect(
      accessibilityValue?.contains("3") == true,
      "Should include marker count in accessibility value")
    #expect(
      accessibilityLabel?.contains("dose markers") == true, "Should describe dose markers in label")
  }

  @Test("DoseMarkerOverlay provides individual marker accessibility")
  func testIndividualMarkerAccessibility() {
    let marker = AdvancedDoseMarker(
      date: Date().addingTimeInterval(-24 * 3600),
      amount: 1.0,
      markerStyle: .standard
    )
    let overlay = DoseMarkerOverlay(doseMarkers: [marker])

    let markerAccessibility = overlay.accessibilityForMarker(marker)

    #expect(markerAccessibility.label.isEmpty == false, "Should provide marker accessibility label")
    #expect(
      markerAccessibility.value.contains("1.0") == true,
      "Should include dose amount in accessibility")
    #expect(markerAccessibility.hint.isEmpty == false, "Should provide accessibility hint")
  }

  // MARK: - Performance Tests

  @Test("DoseMarkerOverlay handles large marker datasets efficiently")
  func testPerformanceWithLargeDataset() {
    // Create a large dataset (365 markers for a full year)
    let markerCount = 365
    var largeMarkerSet: [AdvancedDoseMarker] = []

    for dayOffset in 0..<markerCount {
      let markerStyle: DoseMarkerStyle
      if dayOffset == 0 {
        markerStyle = .firstDose
      } else if dayOffset % 7 == 0 {
        markerStyle = .emphasized
      } else {
        markerStyle = .standard
      }

      let marker = AdvancedDoseMarker(
        date: Date().addingTimeInterval(-Double(dayOffset) * 24 * 3600),
        amount: Double.random(in: 0.5...2.4),
        markerStyle: markerStyle
      )
      largeMarkerSet.append(marker)
    }

    let startTime = Date()
    let overlay = DoseMarkerOverlay(doseMarkers: largeMarkerSet)
    let initializationTime = Date().timeIntervalSince(startTime)

    #expect(initializationTime < 0.1, "Should initialize large dataset within 100ms")
    #expect(overlay.doseMarkers.count == 365, "Should handle all markers in large dataset")

    // Test filtering performance
    let filterStartTime = Date()
    let lastWeekMarkers = overlay.filteredMarkers(
      for: Date().addingTimeInterval(-7 * 24 * 3600)...Date())
    let filterTime = Date().timeIntervalSince(filterStartTime)

    #expect(filterTime < 0.05, "Should filter large dataset within 50ms")
    #expect(lastWeekMarkers.count == 7, "Should correctly filter to last week's markers")  // 7 days within range
  }

  // MARK: - Visual Style Tests

  @Test("DoseMarkerOverlay applies correct visual styles for different marker types")
  func testMarkerVisualStyles() {
    let markers = [
      AdvancedDoseMarker(date: Date(), amount: 0.25, markerStyle: .firstDose),
      AdvancedDoseMarker(date: Date(), amount: 1.0, markerStyle: .standard),
      AdvancedDoseMarker(date: Date(), amount: 2.4, markerStyle: .emphasized),
      AdvancedDoseMarker(date: Date(), amount: 1.0, markerStyle: .skipped, alertLevel: .warning),
    ]
    let overlay = DoseMarkerOverlay(doseMarkers: markers)

    let firstDoseStyle = overlay.visualStyleForMarker(markers[0])
    let standardStyle = overlay.visualStyleForMarker(markers[1])
    let emphasizedStyle = overlay.visualStyleForMarker(markers[2])
    let skippedStyle = overlay.visualStyleForMarker(markers[3])

    #expect(firstDoseStyle.color != standardStyle.color, "First dose should have distinct color")
    #expect(emphasizedStyle.size > standardStyle.size, "Emphasized dose should have larger marker")
    #expect(skippedStyle.opacity < standardStyle.opacity, "Skipped dose should have lower opacity")
    #expect(firstDoseStyle.symbol == "1.circle.fill", "First dose should use numbered symbol")
    #expect(standardStyle.symbol == "circle.fill", "Standard dose should use circle symbol")
  }

  // MARK: - Interactive Behavior Tests

  @Test("DoseMarkerOverlay selection API provides consistent behavior")
  func testMarkerSelectionAPI() {
    let markers = createTestDoseMarkers()
    let overlay = DoseMarkerOverlay(doseMarkers: markers)

    // Test selection helper methods work correctly with nil selection
    #expect(
      overlay.isMarkerSelected(markers[0]) == false,
      "Should report marker as not selected when none selected")
    #expect(
      overlay.isMarkerSelected(markers[1]) == false,
      "Should report marker as not selected when none selected")

    // Test that different markers have different IDs (ensuring selection logic can work)
    #expect(markers[0].id != markers[1].id, "Different markers should have different IDs")
    #expect(markers[1].id != markers[2].id, "Different markers should have different IDs")

    // Test marker equality and identification works
    let sameMarker = markers[0]
    #expect(
      overlay.isMarkerSelected(sameMarker) == overlay.isMarkerSelected(markers[0]),
      "Same marker should give same selection result")
  }
}
