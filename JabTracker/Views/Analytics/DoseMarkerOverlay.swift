//
//  DoseMarkerOverlay.swift
//  JabTracker
//

import Charts
import SwiftUI

/// Advanced dose marker overlay component for chart visualizations
/// Provides interactive dose markers with rich visual styling and accessibility support
struct DoseMarkerOverlay: View {

  // MARK: - Properties

  /// Array of dose markers to display
  let doseMarkers: [AdvancedDoseMarker]

  /// Currently selected marker for detailed information display
  @State var selectedMarker: AdvancedDoseMarker?

  /// Indicates whether to show empty state when no markers are available
  var shouldShowEmptyState: Bool {
    doseMarkers.isEmpty
  }

  /// Accessibility description for the entire marker overlay
  var accessibilityDescription: String? {
    "dose markers overlay showing medication administration points"
  }

  /// Accessibility value describing current marker data
  var accessibilityValue: String? {
    "\(doseMarkers.count) dose markers displayed"
  }

  // MARK: - Initialization

  /// Creates a dose marker overlay with the specified markers
  /// - Parameter doseMarkers: Array of dose markers to display
  init(doseMarkers: [AdvancedDoseMarker]) {
    self.doseMarkers = doseMarkers
  }

  // MARK: - Body

  var body: some View {
    if shouldShowEmptyState {
      emptyStateView()
    } else {
      markerOverlayView()
    }
  }

  // MARK: - Marker Filtering

  /// Filters dose markers to only those within the specified date range
  /// - Parameter dateRange: Date range to filter markers
  /// - Returns: Array of markers within the date range
  func filteredMarkers(for dateRange: ClosedRange<Date>) -> [AdvancedDoseMarker] {
    doseMarkers.filter({ marker in
      dateRange.contains(marker.date)
    })
  }

  // MARK: - Marker Information

  /// Provides detailed information for a specific marker
  /// - Parameter marker: The marker to get details for
  /// - Returns: Marker detail information or nil if not found
  func detailsForMarker(_ marker: AdvancedDoseMarker) -> MarkerDetailInfo? {
    guard doseMarkers.contains(where: { $0.id == marker.id }) else { return nil }

    return MarkerDetailInfo(
      amount: marker.amount,
      markerStyle: marker.markerStyle,
      formattedDate: formatDate(marker.date),
      site: marker.metadata.site,
      notes: marker.metadata.notes
    )
  }

  // MARK: - Accessibility Support

  /// Provides accessibility information for a specific marker
  /// - Parameter marker: The marker to get accessibility for
  /// - Returns: Accessibility information structure
  func accessibilityForMarker(_ marker: AdvancedDoseMarker) -> MarkerAccessibilityInfo {
    let dateString = formatDate(marker.date)
    let amountString = String(format: "%.1f", marker.amount)

    return MarkerAccessibilityInfo(
      label: "Dose marker",
      value: "Amount: \(amountString) on \(dateString)",
      hint: "Double tap for details"
    )
  }

  // MARK: - Visual Styling

  /// Provides visual style information for a specific marker
  /// - Parameter marker: The marker to get visual style for
  /// - Returns: Visual style configuration
  func visualStyleForMarker(_ marker: AdvancedDoseMarker) -> MarkerVisualStyle {
    MarkerVisualStyle(
      color: marker.markerStyle.color,
      size: marker.markerStyle.size,
      symbol: marker.markerStyle.symbol,
      opacity: marker.alertLevel.opacity
    )
  }

  // MARK: - Marker Selection

  /// Selects a marker for detailed display
  /// - Parameter marker: The marker to select
  mutating func selectMarker(_ marker: AdvancedDoseMarker) {
    selectedMarker = marker
  }

  /// Deselects the currently selected marker
  mutating func deselectMarker() {
    selectedMarker = nil
  }

  /// Checks if a specific marker is currently selected
  /// - Parameter marker: The marker to check
  /// - Returns: True if the marker is selected
  func isMarkerSelected(_ marker: AdvancedDoseMarker) -> Bool {
    selectedMarker?.id == marker.id
  }

  // MARK: - Private Views

  /// Empty state view when no markers are available
  @ViewBuilder
  private func emptyStateView() -> some View {
    VStack(spacing: 16) {
      Image(systemName: "circle.dotted")
        .font(.system(size: 48))
        .foregroundColor(.secondary)

      Text("No Dose Markers")
        .font(.headline)
        .foregroundColor(.primary)

      Text("Dose markers will appear here when you start tracking doses")
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .accessibilityIdentifier("empty-marker-state")
  }

  /// Main marker overlay view displaying all markers
  @ViewBuilder
  private func markerOverlayView() -> some View {
    ForEach(doseMarkers) { marker in
      markerView(for: marker)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(accessibilityDescription ?? "")
    .accessibilityValue(accessibilityValue ?? "")
  }

  /// Individual marker view with interaction support
  @ViewBuilder
  private func markerView(for marker: AdvancedDoseMarker) -> some View {
    let style = visualStyleForMarker(marker)
    let accessibility = accessibilityForMarker(marker)

    Button(
      action: {
        selectedMarker = marker
      },
      label: {
        Image(systemName: style.symbol)
          .foregroundColor(style.color)
          .font(.system(size: style.size))
          .opacity(style.opacity)
          .background(
            Circle()
              .fill(isMarkerSelected(marker) ? Color.blue.opacity(0.3) : Color.clear)
              .frame(width: style.size + 8, height: style.size + 8)
          )
      }
    )
    .accessibilityLabel(accessibility.label)
    .accessibilityValue(accessibility.value)
    .accessibilityHint(accessibility.hint)
    .accessibilityIdentifier("dose-marker-\(marker.id)")
  }

  // MARK: - Utility Methods

  /// Formats a date for display
  /// - Parameter date: The date to format
  /// - Returns: Formatted date string
  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

// MARK: - Supporting Types

/// Detailed information about a dose marker
struct MarkerDetailInfo {
  let amount: Double
  let markerStyle: DoseMarkerStyle
  let formattedDate: String
  let site: String?
  let notes: String?
}

/// Accessibility information for dose markers
struct MarkerAccessibilityInfo {
  let label: String
  let value: String
  let hint: String
}

/// Visual style configuration for dose markers
struct MarkerVisualStyle {
  let color: Color
  let size: CGFloat
  let symbol: String
  let opacity: Double
}

// MARK: - Preview

#Preview {
  let sampleMarkers = [
    AdvancedDoseMarker(
      date: Date().addingTimeInterval(-7 * 24 * 3600),
      amount: 1.0,
      markerStyle: .firstDose
    ),
    AdvancedDoseMarker(
      date: Date().addingTimeInterval(-3 * 24 * 3600),
      amount: 1.0,
      markerStyle: .standard
    ),
    AdvancedDoseMarker(
      date: Date().addingTimeInterval(-1 * 24 * 3600),
      amount: 1.5,
      markerStyle: .emphasized
    ),
  ]

  return VStack {
    DoseMarkerOverlay(doseMarkers: sampleMarkers)
    DoseMarkerOverlay(doseMarkers: [])  // Empty state
  }
  .padding()
}
