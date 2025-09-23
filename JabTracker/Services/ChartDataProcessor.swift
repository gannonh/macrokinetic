//
//  ChartDataProcessor.swift
//  JabTracker
//

import Foundation
import Observation

/// Data transformation service for converting SwiftData models to Swift Charts compatible structures
/// Handles concentration timeline data, dose markers, and time period filtering for chart visualizations
@Observable
final class ChartDataProcessor {

  // MARK: - Initialization

  init() {}

  // MARK: - Chart Data Structures

  /// Chart-compatible data point for concentration visualization
  struct ConcentrationChartPoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let concentration: Double

    init(date: Date, concentration: Double) {
      self.date = date
      self.concentration = concentration
    }

    // Convenience initializer from ConcentrationPoint
    init(from point: ConcentrationPoint) {
      self.date = point.date
      self.concentration = point.concentration
    }
  }

  /// Chart-compatible data point for dose markers
  struct DoseMarker: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let amount: Double
    let isSkipped: Bool

    init(date: Date, amount: Double, isSkipped: Bool = false) {
      self.date = date
      self.amount = amount
      self.isSkipped = isSkipped
    }

    // Convenience initializer from Dose
    init(from dose: Dose) {
      self.date = dose.timestamp
      self.amount = dose.amount
      self.isSkipped = dose.skipped
    }
  }

  /// Time period options for data filtering
  enum TimePeriod {
    case last7Days
    case last30Days
    case last90Days
    case lastYear
    case all

    var days: Int? {
      switch self {
      case .last7Days: return 7
      case .last30Days: return 30
      case .last90Days: return 90
      case .lastYear: return 365
      case .all: return nil
      }
    }
  }

  // MARK: - Concentration Data Transformation

  /// Transform ConcentrationPoint array to chart-compatible data structure
  /// - Parameter concentrationPoints: Array of concentration data points
  /// - Returns: Array of chart-compatible concentration points
  func transformConcentrationToChartData(_ concentrationPoints: [ConcentrationPoint])
    -> [ConcentrationChartPoint]
  {
    concentrationPoints.map { ConcentrationChartPoint(from: $0) }
  }

  /// Interpolate concentration data to fill gaps between data points
  /// - Parameters:
  ///   - points: Sparse concentration data points
  ///   - intervalHours: Desired interval between interpolated points in hours
  /// - Returns: Interpolated concentration data points
  func interpolateConcentrationData(_ points: [ConcentrationPoint], intervalHours: Double)
    -> [ConcentrationPoint]
  {
    guard points.count >= 2 else { return points }

    let sortedPoints = points.sorted { $0.date < $1.date }
    var interpolatedPoints: [ConcentrationPoint] = []

    for index in 0..<sortedPoints.count - 1 {
      let currentPoint = sortedPoints[index]
      let nextPoint = sortedPoints[index + 1]

      // Add current point
      interpolatedPoints.append(currentPoint)

      // Calculate interpolated points between current and next
      let timeInterval = nextPoint.date.timeIntervalSince(currentPoint.date)
      let numberOfInterpolations = Int(timeInterval / (intervalHours * 3600))

      for step in 1..<numberOfInterpolations {
        let interpolationRatio = Double(step) / Double(numberOfInterpolations)
        let interpolatedTime = currentPoint.date.addingTimeInterval(
          interpolationRatio * timeInterval
        )

        // Linear interpolation for concentration
        let interpolatedConcentration =
          currentPoint.concentration + (nextPoint.concentration - currentPoint.concentration)
          * interpolationRatio

        interpolatedPoints.append(
          ConcentrationPoint(
            date: interpolatedTime,
            concentration: interpolatedConcentration
          )
        )
      }
    }

    // Add the last point
    if let lastPoint = sortedPoints.last {
      interpolatedPoints.append(lastPoint)
    }

    return interpolatedPoints
  }

  // MARK: - Dose Marker Transformation

  /// Transform Dose array to chart marker data structure
  /// - Parameters:
  ///   - doses: Array of dose records
  ///   - includeSkipped: Whether to include skipped doses in markers (default: true)
  /// - Returns: Array of chart-compatible dose markers
  func transformDosesToMarkerData(_ doses: [Dose], includeSkipped: Bool = true) -> [DoseMarker] {
    let filteredDoses = includeSkipped ? doses : doses.filter { !$0.skipped }
    return filteredDoses.map { DoseMarker(from: $0) }
  }

  // MARK: - Time Period Filtering

  /// Filter data by predefined time period
  /// - Parameters:
  ///   - doses: Array of doses to filter
  ///   - period: Predefined time period
  /// - Returns: Filtered dose array
  func filterDataByTimePeriod(_ doses: [Dose], period: TimePeriod) -> [Dose] {
    guard let days = period.days else { return doses }

    let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 3600)
    return doses.filter { $0.timestamp >= cutoffDate }
  }

  /// Filter data by custom date range
  /// - Parameters:
  ///   - doses: Array of doses to filter
  ///   - startDate: Start of date range (inclusive)
  ///   - endDate: End of date range (inclusive)
  /// - Returns: Filtered dose array within date range
  func filterDataByDateRange(_ doses: [Dose], startDate: Date, endDate: Date) -> [Dose] {
    doses.filter { dose in
      dose.timestamp >= startDate && dose.timestamp <= endDate
    }
  }

  /// Filter concentration points by time period
  /// - Parameters:
  ///   - points: Array of concentration points to filter
  ///   - period: Predefined time period
  /// - Returns: Filtered concentration points array
  func filterConcentrationByTimePeriod(_ points: [ConcentrationPoint], period: TimePeriod)
    -> [ConcentrationPoint]
  {
    guard let days = period.days else { return points }

    let cutoffDate = Date().addingTimeInterval(-Double(days) * 24 * 3600)
    return points.filter { $0.date >= cutoffDate }
  }

  /// Filter concentration points by custom date range
  /// - Parameters:
  ///   - points: Array of concentration points to filter
  ///   - startDate: Start of date range (inclusive)
  ///   - endDate: End of date range (inclusive)
  /// - Returns: Filtered concentration points within date range
  func filterConcentrationByDateRange(
    _ points: [ConcentrationPoint], startDate: Date, endDate: Date
  ) -> [ConcentrationPoint] {
    points.filter { point in
      point.date >= startDate && point.date <= endDate
    }
  }

  // MARK: - Performance Optimization

  /// Optimize large datasets by reducing data density while preserving important features
  /// - Parameters:
  ///   - points: Array of concentration points to optimize
  ///   - maxPoints: Maximum number of points to retain
  /// - Returns: Optimized concentration points array
  func optimizeDataDensity(_ points: [ConcentrationPoint], maxPoints: Int = 100)
    -> [ConcentrationPoint]
  {
    guard points.count > maxPoints else { return points }

    let sortedPoints = points.sorted { $0.date < $1.date }
    let skipInterval = sortedPoints.count / maxPoints

    var optimizedPoints: [ConcentrationPoint] = []

    // Always include first point
    if let firstPoint = sortedPoints.first {
      optimizedPoints.append(firstPoint)
    }

    // Sample points at regular intervals
    for sampleIndex in stride(
      from: skipInterval, to: sortedPoints.count - skipInterval, by: skipInterval)
    {
      optimizedPoints.append(sortedPoints[sampleIndex])
    }

    // Always include last point
    if let lastPoint = sortedPoints.last, sortedPoints.count > 1 {
      optimizedPoints.append(lastPoint)
    }

    return optimizedPoints
  }

  /// Process large dose dataset efficiently with memory-conscious transformations
  /// - Parameters:
  ///   - doses: Large array of dose records
  ///   - maxMarkers: Maximum number of markers to generate
  /// - Returns: Optimized dose markers array
  func processLargeDatasetEfficiently(_ doses: [Dose], maxMarkers: Int = 100) -> [DoseMarker] {
    // For very large datasets, sample doses to stay within memory constraints
    let sampledDoses: [Dose]

    if doses.count > maxMarkers {
      let skipInterval = doses.count / maxMarkers
      let sortedDoses = doses.sorted { $0.timestamp > $1.timestamp }  // Most recent first

      sampledDoses = stride(from: 0, to: doses.count, by: skipInterval)
        .compactMap { index in
          index < sortedDoses.count ? sortedDoses[index] : nil
        }
    } else {
      sampledDoses = doses
    }

    return transformDosesToMarkerData(sampledDoses)
  }

  // MARK: - Data Validation and Error Handling

  /// Validate chart data for Swift Charts compatibility
  /// - Parameter points: Array of concentration chart points to validate
  /// - Returns: True if data is valid for charting, false otherwise
  func validateChartData(_ points: [ConcentrationChartPoint]) -> Bool {
    points.allSatisfy { point in
      point.concentration.isFinite && point.concentration >= 0
        && point.date <= Date().addingTimeInterval(86400)  // Not more than 1 day in future
    }
  }

  /// Sanitize concentration data for chart display
  /// - Parameter points: Array of potentially problematic concentration points
  /// - Returns: Sanitized concentration points safe for charting
  func sanitizeConcentrationData(_ points: [ConcentrationPoint]) -> [ConcentrationPoint] {
    points.compactMap { point in
      // Filter out invalid data points
      guard point.concentration.isFinite,
        point.concentration >= 0,
        point.date <= Date().addingTimeInterval(86400)
      else {
        return nil
      }

      // Cap extremely high concentrations to prevent chart scaling issues
      let cappedConcentration = min(point.concentration, 1000.0)

      return ConcentrationPoint(
        date: point.date,
        concentration: cappedConcentration
      )
    }
  }

  // MARK: - Chart Configuration Helpers

  /// Generate optimal chart time scale based on data range
  /// - Parameter points: Concentration points to analyze
  /// - Returns: Recommended time interval for chart axis
  func recommendedTimeScale(for points: [ConcentrationPoint]) -> TimeInterval {
    guard points.count >= 2 else { return 3600 }  // Default to 1 hour

    let sortedPoints = points.sorted { $0.date < $1.date }
    guard let earliest = sortedPoints.first?.date,
      let latest = sortedPoints.last?.date
    else {
      return 3600
    }

    let totalRange = latest.timeIntervalSince(earliest)
    let days = totalRange / (24 * 3600)

    // Recommend scale based on data range
    if days <= 1 {
      return 3600  // Hourly for 1 day or less
    } else if days <= 7 {
      return 6 * 3600  // 6-hourly for up to a week
    } else if days <= 30 {
      return 24 * 3600  // Daily for up to a month
    } else {
      return 7 * 24 * 3600  // Weekly for longer periods
    }
  }

  /// Calculate chart Y-axis range with appropriate padding
  /// - Parameter points: Concentration points to analyze
  /// - Returns: Tuple containing suggested min and max Y values
  func recommendedYAxisRange(for points: [ConcentrationPoint]) -> (min: Double, max: Double) {
    guard !points.isEmpty else { return (0, 10) }

    let concentrations = points.map { $0.concentration }
    let minValue = concentrations.min() ?? 0
    let maxValue = concentrations.max() ?? 10

    // Add 10% padding above and below
    let padding = (maxValue - minValue) * 0.1
    let paddedMin = max(0, minValue - padding)  // Don't go below 0
    let paddedMax = maxValue + padding

    return (paddedMin, paddedMax)
  }
}
