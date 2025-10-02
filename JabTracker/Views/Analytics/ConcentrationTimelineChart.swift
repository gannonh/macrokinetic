//
//  ConcentrationTimelineChart.swift
//  JabTracker
//

import Charts
import SwiftUI

/// Interactive concentration timeline chart displaying medication concentration over time
/// Integrates with ChartDataProcessor for data transformation and Swift Charts for native iOS visualization
struct ConcentrationTimelineChart: View {

    // MARK: - Properties

    /// Chart dataset containing concentration curves, dose markers, and configuration
    let dataset: ConcentrationChartDataset

    /// Current chart configuration for appearance and behavior
    var configuration: ConcentrationChartConfiguration {
        chartState.currentConfiguration
    }

    /// Indicates whether to show empty state when no data is available
    var showsEmptyState: Bool {
        dataset.concentrationCurves.isEmpty && dataset.doseMarkers.isEmpty
    }

    /// Processed concentration points ready for chart display
    /// NOTE: No filtering here - parent view (AnalyticsView) filters dataset before passing it
    var processedConcentrationPoints: [AdvancedConcentrationPoint] {
        dataset.concentrationCurves.flatMap { curve in
            curve.points
        }
    }

    /// Processed dose markers ready for chart display
    /// NOTE: No filtering here - parent view (AnalyticsView) filters dataset before passing it
    var processedDoseMarkers: [AdvancedDoseMarker] {
        dataset.doseMarkers
    }

    /// Accessibility label for the chart
    var accessibilityLabel: String? {
        "Concentration Timeline Chart showing medication concentration over time"
    }

    /// Accessibility value describing current chart data
    var accessibilityValue: String? {
        ConcentrationChartAccessibility.accessibilityValue(
            for: processedConcentrationPoints,
            markers: processedDoseMarkers,
            timeRange: configuration.timeRange,
            zoomLevel: gestureHandler.zoomLevel
        )
    }

    /// Detailed accessibility description for VoiceOver users
    var accessibilityHint: String? {
        ConcentrationChartAccessibility.accessibilityHint(for: processedConcentrationPoints)
    }

    // MARK: - State

    @State private var chartState: ConcentrationChartState
    @State private var gestureHandler = ConcentrationChartGestureHandler()

    // MARK: - Initialization

    /// Creates a concentration timeline chart with the specified dataset
    /// - Parameter dataset: Chart dataset containing all concentration and dose data
    init(dataset: ConcentrationChartDataset) {
        self.dataset = dataset
        self._chartState = State(initialValue: ConcentrationChartState(configuration: dataset.configuration))
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsEmptyState {
                emptyChartView()
            } else {
                // Chart Header
                HStack {
                    Text("Concentration Timeline")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(configuration.timeRange.displayName)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                }

                concentrationChartView()

                ConcentrationChartControls(
                    configuration: $chartState.currentConfiguration,
                    resetAction: resetChartView,
                    showTimePeriodSelector: false  // Parent view (AnalyticsView) controls time period
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.secondaryBackground)
        )
        .onChange(of: dataset.configuration.timeRange) { _, _ in
            // Update chart state when time range changes
            chartState = ConcentrationChartState(configuration: dataset.configuration)
        }
    }

    // MARK: - Chart Components

    /// Header view displaying chart title and metadata
    @ViewBuilder
    private func chartHeaderView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dataset.metadata.title)
                .font(DesignTokens.Typography.headline)
                .foregroundColor(.primary)

            if let subtitle = dataset.metadata.subtitle {
                Text(subtitle)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    /// Main chart view displaying concentration timeline and dose markers
    @ViewBuilder
    private func concentrationChartView() -> some View {
        chartContent
            .scaleEffect(gestureHandler.zoomLevel)
            .offset(gestureHandler.panOffset)
            .gesture(gestureHandler.zoomGesture)
            .gesture(gestureHandler.panGesture)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("concentration-timeline-chart")
            .accessibilityLabel(accessibilityLabel ?? "")
            .accessibilityValue(accessibilityValue ?? "")
            .accessibilityHint(accessibilityHint ?? "")
            .accessibilityAction(named: "Reset zoom") {
                gestureHandler.resetZoomAndPan()
            }
            .accessibilityAction(named: "Describe trend") {
                // Announce chart trend for VoiceOver users
                let trend = ConcentrationChartAccessibility.trendDescription(for: processedConcentrationPoints)
                // This would trigger a spoken description in a real implementation
                print("Chart trend: \(trend)")
            }
            .accessibilityAddTraits(.allowsDirectInteraction)
    }

    /// Core chart content without gestures
    @ViewBuilder
    private var chartContent: some View {
        Chart {
            // Therapeutic range band (drawn first, behind everything)
            if case .therapeuticWindow(let minConc, let maxConc, _) = configuration.concentrationRange {
                RectangleMark(
                    yStart: .value("Min", minConc),
                    yEnd: .value("Max", maxConc)
                )
                .foregroundStyle(DesignTokens.Colors.success.opacity(0.15))
                .accessibilityLabel("Therapeutic range")
                .accessibilityValue(
                    """
                    Optimal concentration between \(String(format: "%.1f", minConc)) \
                    and \(String(format: "%.1f", maxConc))
                    """
                )
            }

            // Concentration line series
            ForEach(processedConcentrationPoints) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Concentration", point.concentration)
                )
                .foregroundStyle(DesignTokens.Colors.primary)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
            }

            // Dose markers - dots on the concentration line at dose times
            ForEach(processedDoseMarkers) { marker in
                // Find the concentration at this dose time
                if let concentrationAtDose = processedConcentrationPoints.first(where: {
                    abs($0.date.timeIntervalSince(marker.date)) < 1800  // Within 30 min
                }) {
                    PointMark(
                        x: .value("Time", concentrationAtDose.date),
                        y: .value("Concentration", concentrationAtDose.concentration)
                    )
                    .foregroundStyle(DesignTokens.Colors.success)
                    .symbolSize(100)
                    .symbol(.circle)
                    .accessibilityLabel("Dose administered")
                    .accessibilityValue(
                        "Dose: \(String(format: "%.1f", marker.amount)) mg at \(marker.date.formatted())")
                }
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel(format: .dateTime.month(.narrow).day())
                    .font(.caption)
                AxisTick()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic) { value in
                AxisValueLabel {
                    if let concentration = value.as(Double.self) {
                        Text("\(String(format: "%.1f", concentration))")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
    }

    /// Grid background for the chart
    @ViewBuilder
    private func chartGridBackground(proxy: ChartProxy) -> some View {
        Rectangle()
            .fill(configuration.theme.backgroundColor)
            .clipped()
    }

    /// Empty state view when no data is available
    @ViewBuilder
    private func emptyChartView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Concentration Data")
                .font(DesignTokens.Typography.headline)
                .foregroundColor(.primary)

            Text("Concentration data will appear here once you start tracking doses")
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(height: 300)
        .accessibilityIdentifier("empty-chart-state")
    }

    // MARK: - Chart Interaction Methods

    /// Updates the chart's time period and refreshes the display
    /// - Parameter timeRange: New time range to display
    func updateTimePeriod(_ timeRange: TimeRange) {
        chartState.updateTimePeriod(timeRange)
    }

    /// Resets zoom, pan, and configuration to default state
    private func resetChartView() {
        withAnimation(.easeInOut(duration: 0.5)) {
            gestureHandler.resetZoomAndPan()
            chartState.resetConfiguration()
        }
    }

    /// Sets zoom level programmatically
    /// - Parameter level: Zoom level (0.5 to 3.0)
    func setZoomLevel(_ level: Double) {
        gestureHandler.setZoomLevel(level)
    }

    /// Sets pan offset programmatically
    /// - Parameter offset: Pan offset in points
    func setPanOffset(_ offset: CGSize) {
        gestureHandler.setPanOffset(offset)
    }

    // MARK: - Gesture State Access

    /// Current zoom level (read-only)
    var currentZoomLevel: Double {
        gestureHandler.zoomLevel
    }

    /// Current pan offset (read-only)
    var currentPanOffset: CGSize {
        gestureHandler.panOffset
    }

    /// Whether user is currently dragging (read-only)
    var isCurrentlyDragging: Bool {
        gestureHandler.isDragging
    }

}

// MARK: - Preview

#Preview {
    let samplePoints = [
        AdvancedConcentrationPoint(date: Date().addingTimeInterval(-24 * 3600), concentration: 0.0),
        AdvancedConcentrationPoint(date: Date().addingTimeInterval(-12 * 3600), concentration: 5.2),
        AdvancedConcentrationPoint(date: Date(), concentration: 2.1),
    ]

    let sampleMarkers = [
        AdvancedDoseMarker(
            date: Date().addingTimeInterval(-24 * 3600),
            amount: 1.0,
            markerStyle: .firstDose
        )
    ]

    let sampleCurve = ConcentrationCurve(
        points: samplePoints,
        medication: "semaglutide"
    )

    let sampleDataset = ConcentrationChartDataset(
        concentrationCurves: [sampleCurve],
        doseMarkers: sampleMarkers,
        configuration: .default
    )

    return ConcentrationTimelineChart(dataset: sampleDataset)
}
