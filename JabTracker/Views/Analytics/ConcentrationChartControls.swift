//
//  ConcentrationChartControls.swift
//  JabTracker
//

import SwiftUI

/// Controls view for concentration timeline chart
/// Provides time period selection and chart action buttons (export, reset)
struct ConcentrationChartControls: View {

    // MARK: - Properties

    /// Current chart configuration
    @Binding var configuration: ConcentrationChartConfiguration

    /// Whether export sheet is currently shown
    @Binding var showingExportSheet: Bool

    /// Action to reset chart view (zoom, pan, and configuration)
    let resetAction: () -> Void

    // MARK: - Body

    var body: some View {
        HStack {
            timePeriodSelector()
            Spacer()
            chartActionButtons()
        }
        .padding(.horizontal)
    }

    // MARK: - Component Views

    /// Time period selection buttons
    @ViewBuilder
    private func timePeriodSelector() -> some View {
        HStack(spacing: 8) {
            ForEach([TimeRange.lastWeek, .lastMonth, .lastQuarter, .lastYear], id: \.displayName) {
                timeRange in
                Button(timeRange.displayName) {
                    configuration = configuration.withTimeRange(timeRange)
                }
                .font(.caption)
                .foregroundColor(configuration.timeRange == timeRange ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            configuration.timeRange == timeRange
                                ? Color.secondary.opacity(0.2) : Color.clear)
                )
                .accessibilityIdentifier("time-period-\(timeRange.displayName.lowercased())")
            }
        }
    }

    /// Action buttons for chart controls (export and reset)
    @ViewBuilder
    private func chartActionButtons() -> some View {
        HStack(spacing: 12) {
            Button(
                action: {
                    showingExportSheet = true
                },
                label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                }
            )
            .accessibilityLabel("Export chart")
            .accessibilityIdentifier("export-chart-button")

            Button(
                action: resetAction,
                label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
            )
            .accessibilityLabel("Reset chart view")
            .accessibilityIdentifier("reset-chart-button")
        }
    }
}
