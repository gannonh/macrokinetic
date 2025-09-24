//
//  ConcentrationTimelineChart.swift
//  JabTracker
//

import Charts
import SwiftUI

// swiftlint:disable type_body_length file_length
/// Interactive concentration timeline chart displaying medication concentration over time
/// Integrates with ChartDataProcessor for data transformation and Swift Charts for native iOS visualization
struct ConcentrationTimelineChart: View {

  // MARK: - Properties

  /// Chart dataset containing concentration curves, dose markers, and configuration
  let dataset: ConcentrationChartDataset

  /// Current chart configuration for appearance and behavior
  var configuration: ConcentrationChartConfiguration {
    currentConfiguration
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
    let timeRange = configuration.timeRange.displayName
    let zoomInfo = currentZoomLevel != 1.0 ? ", zoomed to \(Int(currentZoomLevel * 100))%" : ""
    return
      "Chart contains \(pointCount) concentration points and \(markerCount) dose markers for \(timeRange)\(zoomInfo)"
  }

  /// Detailed accessibility description for VoiceOver users
  var accessibilityHint: String? {
    if processedConcentrationPoints.isEmpty {
      return
        "No concentration data available. Start tracking doses to see your medication timeline."
    }

    let latestPoint = processedConcentrationPoints.max(by: { $0.date < $1.date })
    let currentLevel = latestPoint?.concentration ?? 0.0
    let levelDescription = formatConcentrationForAccessibility(currentLevel)

    return
      "Current concentration level: \(levelDescription). Use pinch to zoom, drag to pan, or double tap to reset view."
  }

  // MARK: - State

  @State private var currentConfiguration: ConcentrationChartConfiguration
  @State private var zoomLevel: Double = 1.0
  @State private var panOffset: CGSize = .zero
  @State private var isDragging: Bool = false
  @State private var showingExportSheet = false

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
        emptyChartView()
      } else {
        chartHeaderView()
        concentrationChartView()
        chartControlsView()
      }
    }
    .background(configuration.theme.backgroundColor)
    .sheet(isPresented: $showingExportSheet) {
      NavigationStack {
        ChartExportView(dataset: dataset) { result in
          showingExportSheet = false
          // Handle export result
          switch result {
          case .success(let url):
            print("✅ Chart exported successfully to: \(url)")
          case .failure(let error):
            print("❌ Chart export failed: \(error)")
          }
        }
      }
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
      .scaleEffect(zoomLevel)
      .offset(panOffset)
      .gesture(chartZoomGesture)
      .gesture(chartPanGesture)
      .accessibilityElement(children: .contain)
      .accessibilityIdentifier("concentration-timeline-chart")
      .accessibilityLabel(accessibilityLabel ?? "")
      .accessibilityValue(accessibilityValue ?? "")
      .accessibilityHint(accessibilityHint ?? "")
      .accessibilityAction(named: "Reset zoom") {
        // Reset zoom and pan on accessibility action
        withAnimation(.easeInOut(duration: 0.5)) {
          zoomLevel = 1.0
          panOffset = .zero
        }
      }
      .accessibilityAction(named: "Describe trend") {
        // Announce chart trend for VoiceOver users
        // This would trigger a spoken description in a real implementation
      }
      .accessibilityAddTraits(.allowsDirectInteraction)
  }

  /// Core chart content without gestures
  @ViewBuilder
  private var chartContent: some View {
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
      chartGridBackground(proxy: proxy)
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
  }

  /// Grid background for the chart
  @ViewBuilder
  private func chartGridBackground(proxy: ChartProxy) -> some View {
    Rectangle()
      .fill(configuration.theme.backgroundColor)
      .clipped()
  }

  /// Controls for chart interaction (time period selection, zoom, etc.)
  @ViewBuilder
  private func chartControlsView() -> some View {
    HStack {
      timePeriodSelector()
      Spacer()
      chartActionButtons()
    }
    .padding(.horizontal)
  }

  /// Time period selection buttons
  @ViewBuilder
  private func timePeriodSelector() -> some View {
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
        action: {
          withAnimation(.easeInOut(duration: 0.5)) {
            zoomLevel = 1.0
            panOffset = .zero
            currentConfiguration = dataset.configuration
          }
        },
        label: {
          Image(systemName: "arrow.clockwise")
            .font(.caption)
        }
      )
      .accessibilityLabel("Reset chart view")
      .accessibilityIdentifier("reset-chart-button")
    }
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
  mutating func updateTimePeriod(_ timeRange: TimeRange) {
    currentConfiguration = currentConfiguration.withTimeRange(timeRange)
  }

  /// Resets zoom and pan to default state
  func resetZoomAndPan() {
    withAnimation(.easeInOut(duration: 0.5)) {
      zoomLevel = 1.0
      panOffset = .zero
    }
  }

  /// Sets zoom level programmatically
  /// - Parameter level: Zoom level (0.5 to 3.0)
  func setZoomLevel(_ level: Double) {
    let clampedLevel = max(0.5, min(3.0, level))
    withAnimation(.easeInOut(duration: 0.3)) {
      zoomLevel = clampedLevel
    }
  }

  /// Sets pan offset programmatically
  /// - Parameter offset: Pan offset in points
  func setPanOffset(_ offset: CGSize) {
    let maxOffset: CGFloat = 100
    let clampedOffset = CGSize(
      width: max(-maxOffset, min(maxOffset, offset.width)),
      height: max(-maxOffset, min(maxOffset, offset.height))
    )
    withAnimation(.easeInOut(duration: 0.3)) {
      panOffset = clampedOffset
    }
  }

  // MARK: - Gesture State Access

  /// Current zoom level (read-only)
  var currentZoomLevel: Double {
    zoomLevel
  }

  /// Current pan offset (read-only)
  var currentPanOffset: CGSize {
    panOffset
  }

  /// Whether user is currently dragging (read-only)
  var isCurrentlyDragging: Bool {
    isDragging
  }

  // MARK: - Gesture Definitions

  /// Zoom gesture for chart interaction
  private var chartZoomGesture: some Gesture {
    MagnificationGesture()
      .onChanged { value in
        zoomLevel = max(0.5, min(3.0, value))
      }
      .onEnded { _ in
        withAnimation(.easeInOut(duration: 0.3)) {
          if zoomLevel < 0.8 {
            zoomLevel = 1.0
            panOffset = .zero
          }
        }
      }
  }

  /// Pan gesture for chart interaction
  private var chartPanGesture: some Gesture {
    DragGesture()
      .onChanged { value in
        isDragging = true
        panOffset = CGSize(
          width: value.translation.width / zoomLevel,
          height: value.translation.height / zoomLevel
        )
      }
      .onEnded { _ in
        isDragging = false
        withAnimation(.easeInOut(duration: 0.3)) {
          // Snap back if dragged too far
          let maxOffset: CGFloat = 100
          panOffset = CGSize(
            width: max(-maxOffset, min(maxOffset, panOffset.width)),
            height: max(-maxOffset, min(maxOffset, panOffset.height))
          )
        }
      }
  }

  // MARK: - Accessibility Helper Methods

  /// Formats concentration value for accessibility with descriptive text
  /// - Parameter concentration: Concentration value to format
  /// - Returns: Human-readable description of concentration level
  private func formatConcentrationForAccessibility(_ concentration: Double) -> String {
    let formattedValue = String(format: "%.1f", concentration)
    let level: String

    switch concentration {
    case 0...1:
      level = "low"
    case 1...3:
      level = "moderate"
    case 3...5:
      level = "high"
    default:
      level = "very high"
    }

    return "\(formattedValue) units, \(level) level"
  }

  /// Formats dose amount for accessibility
  /// - Parameter amount: Dose amount to format
  /// - Returns: Formatted dose amount with units
  private func formatDoseAmount(_ amount: Double) -> String {
    String(format: "%.1f mg", amount)
  }

  /// Provides spoken description of chart trend for VoiceOver
  var chartTrendDescription: String {
    guard processedConcentrationPoints.count >= 2 else {
      return "Insufficient data for trend analysis"
    }

    let sortedPoints = processedConcentrationPoints.sorted { $0.date < $1.date }
    let firstHalf = sortedPoints.prefix(sortedPoints.count / 2)
    let secondHalf = sortedPoints.suffix(sortedPoints.count / 2)

    let firstAverage = firstHalf.map(\.concentration).reduce(0, +) / Double(firstHalf.count)
    let secondAverage = secondHalf.map(\.concentration).reduce(0, +) / Double(secondHalf.count)

    let difference = secondAverage - firstAverage
    let percentChange = abs(difference / firstAverage) * 100

    if abs(difference) < 0.1 {
      return "Concentration levels are stable"
    } else if difference > 0 {
      return "Concentration levels are increasing by \(Int(percentChange))%"
    } else {
      return "Concentration levels are decreasing by \(Int(percentChange))%"
    }
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
// swiftlint:enable type_body_length file_length
