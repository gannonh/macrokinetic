//
//  ConcentrationChartControls.swift
//  JabTracker
//

import SwiftUI

/// Controls view for concentration timeline chart
/// Provides time period selection and chart action buttons (reset)
struct ConcentrationChartControls: View {

    // MARK: - Properties

    /// Current chart configuration
    @Binding var configuration: ConcentrationChartConfiguration

    /// Action to reset chart view (zoom, pan, and configuration)
    let resetAction: () -> Void

    /// Whether to show time period selector (false when parent view controls time period)
    var showTimePeriodSelector: Bool = true

    // MARK: - Body

    var body: some View {
        HStack {
            if showTimePeriodSelector {
                timePeriodSelector()
            }
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
                let isSelected = configuration.timeRange == timeRange
                Button(shortLabel(for: timeRange)) {
                    configuration = configuration.withTimeRange(timeRange)
                }
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? DesignTokens.Colors.primary : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: isSelected ? 0 : 1)
                )
                .accessibilityIdentifier("time-period-\(timeRange.displayName.lowercased())")
                .accessibilityLabel(timeRange.displayName)
            }
        }
    }

    /// Returns shortened label for time range to prevent truncation
    private func shortLabel(for timeRange: TimeRange) -> String {
        switch timeRange {
        case .lastWeek:
            return "7d"
        case .lastMonth:
            return "30d"
        case .lastQuarter:
            return "90d"
        case .lastYear:
            return "1y"
        default:
            return timeRange.displayName
        }
    }

    /// Action buttons for chart controls (reset)
    @ViewBuilder
    private func chartActionButtons() -> some View {
        Button(
            action: {
                resetAction()
            },
            label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundColor(DesignTokens.Colors.primary)
            }
        )
        .buttonStyle(.plain)
        .padding(8)
        .accessibilityLabel("Reset chart view")
        .accessibilityIdentifier("reset-chart-button")
    }
}
