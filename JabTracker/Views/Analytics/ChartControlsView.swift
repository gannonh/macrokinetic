//
//  ChartControlsView.swift
//  JabTracker
//

import SwiftUI

/// Comprehensive chart controls including time period selection and export options
/// Provides unified control interface for concentration timeline chart interactions
struct ChartControlsView: View {
  @Binding var selectedPeriod: ChartDataProcessor.TimePeriod
  @Binding var showExportSheet: Bool

  init(
    selectedPeriod: Binding<ChartDataProcessor.TimePeriod>,
    showExportSheet: Binding<Bool>
  ) {
    self._selectedPeriod = selectedPeriod
    self._showExportSheet = showExportSheet
  }

  var body: some View {
    HStack {
      // Time period selector on the left
      TimePeriodSelector(selectedPeriod: $selectedPeriod)

      Spacer()

      // Action buttons on the right
      HStack(spacing: 12) {
        Button {
          showExportSheet = true
        } label: {
          Image(systemName: "square.and.arrow.up")
            .font(.caption)
            .foregroundColor(.blue)
        }
        .accessibilityLabel("Export chart")
        .accessibilityHint("Tap to export chart for medical records")
        .accessibilityIdentifier("export-chart-button")

        Button {
          selectedPeriod = .last30Days
        } label: {
          Image(systemName: "arrow.clockwise")
            .font(.caption)
            .foregroundColor(.blue)
        }
        .accessibilityLabel("Reset chart view")
        .accessibilityHint("Tap to reset chart to default 30-day view")
        .accessibilityIdentifier("reset-chart-button")
      }
    }
    .padding(.horizontal)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("chart-controls-view")
    .accessibilityLabel("Chart controls")
    .accessibilityHint("Controls for adjusting chart time period and exporting data")
  }
}

// MARK: - Preview

#Preview {
  @Previewable @State var selectedPeriod: ChartDataProcessor.TimePeriod = .last30Days
  @Previewable @State var showExportSheet = false

  return VStack {
    ChartControlsView(
      selectedPeriod: $selectedPeriod,
      showExportSheet: $showExportSheet
    )

    Text("Selected: \(selectedPeriod.displayName)")
    Text("Export sheet: \(showExportSheet ? "shown" : "hidden")")
  }
  .padding()
}
