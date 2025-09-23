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
    dataset.configuration
  }

  /// Indicates whether to show empty state when no data is available
  var showsEmptyState: Bool {
    dataset.concentrationCurves.isEmpty && dataset.doseMarkers.isEmpty
  }

  /// Processed concentration points ready for chart display
  var processedConcentrationPoints: [AdvancedConcentrationPoint] {
    dataset.concentrationCurves.flatMap { curve in
      curve.points.filter { point in
        // Filter points based on current time range
        let timeRange = configuration.timeRange.dateRange()
        return point.date >= timeRange.start && point.date <= timeRange.end
      }
    }
  }

  /// Processed dose markers ready for chart display
  var processedDoseMarkers: [AdvancedDoseMarker] {
    dataset.doseMarkers.filter { marker in
      // Filter markers based on current time range
      let timeRange = configuration.timeRange.dateRange()
      return marker.date >= timeRange.start && marker.date <= timeRange.end
    }
  }

  /// Accessibility label for the chart
  var accessibilityLabel: String? {
    "Concentration Timeline Chart showing medication concentration over time"
  }

  /// Accessibility value describing current chart data
  var accessibilityValue: String? {
    let pointCount = processedConcentrationPoints.count
    let markerCount = processedDoseMarkers.count
    return "Chart contains \(pointCount) concentration data points and \(markerCount) dose markers"
  }

  // MARK: - State

  @State private var currentConfiguration: ConcentrationChartConfiguration

  // MARK: - Initialization

  /// Creates a concentration timeline chart with the specified dataset
  /// - Parameter dataset: Chart dataset containing all concentration and dose data
  init(dataset: ConcentrationChartDataset) {
    self.dataset = dataset
    self._currentConfiguration = State(initialValue: dataset.configuration)
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 16) {
      if showsEmptyState {
        EmptyChartView()
      } else {
        ChartHeaderView()
        ConcentrationChartView()
        ChartControlsView()
      }
    }
    .background(configuration.theme.backgroundColor)
    .accessibilityLabel(accessibilityLabel ?? "")
    .accessibilityValue(accessibilityValue ?? "")
  }

  // MARK: - Chart Components

  /// Header view displaying chart title and metadata
  @ViewBuilder
  private func ChartHeaderView() -> some View {
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
  private func ConcentrationChartView() -> some View {
    Chart {
      // Concentration line series
      ForEach(processedConcentrationPoints) { point in
        LineMark(
          x: .value("Time", point.date),
          y: .value("Concentration", point.concentration)
        )
        .foregroundStyle(configuration.theme.primaryColor)
        .lineStyle(StrokeStyle(lineWidth: 2))
        .interpolationMethod(.cardinal)
      }

      // Dose marker series
      ForEach(processedDoseMarkers) { marker in
        PointMark(
          x: .value("Time", marker.date),
          y: .value("Dose", 0)  // Position at bottom of chart
        )
        .foregroundStyle(marker.markerStyle.color)
        .symbolSize(marker.markerStyle.size * marker.markerStyle.size)
        .accessibilityLabel("Dose marker")
        .accessibilityValue("Dose: \(marker.amount) at \(marker.date.formatted())")
      }
    }
    .frame(height: 300)
    .chartBackground { proxy in
      // Chart background with grid lines
      if configuration.gridSettings.showHorizontalGrid
        || configuration.gridSettings.showVerticalGrid
      {
        ChartGridBackground(proxy: proxy)
      }
    }
    .chartXAxis {
      AxisMarks(values: .automatic) { _ in
        AxisValueLabel()
          .font(.caption)
        if configuration.gridSettings.showVerticalGrid {
          AxisGridLine(
            stroke: StrokeStyle(
              lineWidth: 1,
              dash: configuration.gridSettings.gridLineStyle == .dashed ? [3, 3] : []
            )
          )
          .foregroundStyle(
            configuration.gridSettings.gridColor.opacity(configuration.gridSettings.gridOpacity))
        }
      }
    }
    .chartYAxis {
      AxisMarks(values: .automatic) { _ in
        AxisValueLabel()
          .font(.caption)
        if configuration.gridSettings.showHorizontalGrid {
          AxisGridLine(
            stroke: StrokeStyle(
              lineWidth: 1,
              dash: configuration.gridSettings.gridLineStyle == .dashed ? [3, 3] : []
            )
          )
          .foregroundStyle(
            configuration.gridSettings.gridColor.opacity(configuration.gridSettings.gridOpacity))
        }
      }
    }
    .padding(.horizontal)
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("concentration-timeline-chart")
  }

  /// Grid background for the chart
  @ViewBuilder
  private func ChartGridBackground(proxy: ChartProxy) -> some View {
    Rectangle()
      .fill(configuration.theme.backgroundColor)
      .clipped()
  }

  /// Controls for chart interaction (time period selection, zoom, etc.)
  @ViewBuilder
  private func ChartControlsView() -> some View {
    HStack {
      TimePeriodSelector()
      Spacer()
      ChartActionButtons()
    }
    .padding(.horizontal)
  }

  /// Time period selection buttons
  @ViewBuilder
  private func TimePeriodSelector() -> some View {
    HStack(spacing: 8) {
      ForEach([TimeRange.lastWeek, .lastMonth, .lastQuarter, .lastYear], id: \.displayName) {
        timeRange in
        Button(timeRange.displayName) {
          currentConfiguration = currentConfiguration.withTimeRange(timeRange)
        }
        .font(.caption)
        .foregroundColor(currentConfiguration.timeRange == timeRange ? .primary : .secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(
              currentConfiguration.timeRange == timeRange
                ? Color.secondary.opacity(0.2) : Color.clear)
        )
        .accessibilityIdentifier("time-period-\(timeRange.displayName.lowercased())")
      }
    }
  }

  /// Action buttons for chart controls
  @ViewBuilder
  private func ChartActionButtons() -> some View {
    HStack(spacing: 12) {
      Button(action: {
        // Export functionality placeholder
      }) {
        Image(systemName: "square.and.arrow.up")
          .font(.caption)
      }
      .accessibilityLabel("Export chart")
      .accessibilityIdentifier("export-chart-button")

      Button(action: {
        // Reset zoom functionality placeholder
      }) {
        Image(systemName: "arrow.clockwise")
          .font(.caption)
      }
      .accessibilityLabel("Reset chart view")
      .accessibilityIdentifier("reset-chart-button")
    }
  }

  /// Empty state view when no data is available
  @ViewBuilder
  private func EmptyChartView() -> some View {
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
  mutating func updateTimePeriod(_ timeRange: TimeRange) {
    currentConfiguration = currentConfiguration.withTimeRange(timeRange)
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
