//
//  ChartDataProcessor+Filtering.swift
//  JabTracker
//

import Foundation

/// Advanced filtering, aggregation, and dose marker overlay functionality for ChartDataProcessor
/// Provides time period filtering, content-based filtering, and efficient aggregation for large datasets
extension ChartDataProcessor {

  // MARK: - Advanced Time Period Filtering

  /// Filter doses by custom date range with enhanced boundary handling
  /// - Parameters:
  ///   - doses: Array of dose records to filter
  ///   - startDate: Start of date range (inclusive)
  ///   - endDate: End of date range (inclusive)
  /// - Returns: Filtered dose array within the specified date range
  func filterDosesByCustomDateRange(_ doses: [Dose], startDate: Date, endDate: Date) -> [Dose] {
    doses.filter { dose in
      dose.timestamp >= startDate && dose.timestamp <= endDate
    }
  }

  /// Filter concentration points by rolling time window
  /// - Parameters:
  ///   - points: Array of concentration points to filter
  ///   - windowHours: Size of rolling window in hours
  ///   - referenceDate: Reference date for window calculation (default: current date)
  /// - Returns: Filtered concentration points within the rolling window
  func filterConcentrationByRollingTimeWindow(
    _ points: [ConcentrationPoint],
    windowHours: Double,
    referenceDate: Date = Date()
  ) -> [ConcentrationPoint] {
    let cutoffDate = referenceDate.addingTimeInterval(-windowHours * 3600)
    return points.filter { point in
      point.date >= cutoffDate && point.date <= referenceDate
    }
  }

  // MARK: - Content-Based Filtering

  /// Filter doses by medication type
  /// - Parameters:
  ///   - doses: Array of dose records to filter
  ///   - medicationType: Target medication type to filter by
  /// - Returns: Filtered dose array matching the specified medication type
  func filterDosesByMedicationType(_ doses: [Dose], medicationType: Medication) -> [Dose] {
    doses.filter { dose in
      dose.medication?.medicationType == medicationType.rawValue
    }
  }

  /// Filter doses by injection site pattern matching
  /// - Parameters:
  ///   - doses: Array of dose records to filter
  ///   - sitePattern: Pattern to match against injection sites (case-insensitive)
  /// - Returns: Filtered dose array where injection site contains the pattern
  func filterDosesByInjectionSitePattern(_ doses: [Dose], sitePattern: String) -> [Dose] {
    doses.filter { dose in
      guard let site = dose.site else { return false }
      return site.localizedCaseInsensitiveContains(sitePattern)
    }
  }

  /// Filter doses by specific injection sites
  /// - Parameters:
  ///   - doses: Array of dose records to filter
  ///   - sites: Specific injection sites to match
  /// - Returns: Filtered dose array matching any of the specified sites
  func filterDosesBySpecificInjectionSites(_ doses: [Dose], sites: [String]) -> [Dose] {
    doses.filter { dose in
      guard let site = dose.site else { return false }
      return sites.contains(site)
    }
  }

  // MARK: - Dose Marker Overlay Logic

  /// Enhanced dose marker with concentration context
  struct DoseMarkerWithConcentration: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    let isSkipped: Bool
    let concentrationAtDose: Double?
    let site: String?

    init(from dose: Dose, concentrationAtDose: Double? = nil) {
      self.date = dose.timestamp
      self.amount = dose.amount
      self.isSkipped = dose.skipped
      self.concentrationAtDose = concentrationAtDose
      self.site = dose.site
    }
  }

  /// Create dose markers overlaid on concentration curves with timing alignment
  /// - Parameters:
  ///   - doses: Array of dose records
  ///   - concentrationPoints: Array of concentration points for overlay
  ///   - timeToleranceMinutes: Time tolerance for matching doses to concentration points
  /// - Returns: Array of dose markers with concentration context
  func createDoseMarkersOverlaidOnConcentrationCurve(
    doses: [Dose],
    concentrationPoints: [ConcentrationPoint],
    timeToleranceMinutes: Double = 30
  ) -> [DoseMarkerWithConcentration] {
    let tolerance = timeToleranceMinutes * 60  // Convert to seconds

    return doses.map { dose in
      // Find closest concentration point within tolerance
      let closestPoint = concentrationPoints.min { point1, point2 in
        abs(dose.timestamp.timeIntervalSince(point1.date))
          < abs(dose.timestamp.timeIntervalSince(point2.date))
      }

      let concentrationAtDose: Double?
      if let closestPoint = closestPoint,
        abs(dose.timestamp.timeIntervalSince(closestPoint.date)) <= tolerance
      {
        concentrationAtDose = closestPoint.concentration
      } else {
        concentrationAtDose = nil
      }

      return DoseMarkerWithConcentration(from: dose, concentrationAtDose: concentrationAtDose)
    }
  }

  /// Generate enhanced dose markers with concentration context from timeline
  /// - Parameters:
  ///   - doses: Array of dose records
  ///   - concentrationTimeline: Complete concentration timeline
  /// - Returns: Array of dose markers with concentration context
  func generateEnhancedDoseMarkersWithConcentrationContext(
    doses: [Dose],
    concentrationTimeline: [ConcentrationPoint]
  ) -> [DoseMarkerWithConcentration] {
    doses.map { dose in
      // Find exact match or closest concentration point
      let exactMatch = concentrationTimeline.first { $0.date == dose.timestamp }
      let concentrationAtDose = exactMatch?.concentration

      return DoseMarkerWithConcentration(from: dose, concentrationAtDose: concentrationAtDose)
    }
  }

  // MARK: - Aggregation and Performance

  /// Aggregation period options for time-based grouping
  enum AggregationPeriod {
    case hourly
    case daily
    case weekly
    case monthly

    var timeInterval: TimeInterval {
      switch self {
      case .hourly: return 3600
      case .daily: return 24 * 3600
      case .weekly: return 7 * 24 * 3600
      case .monthly: return 30 * 24 * 3600  // Approximate
      }
    }
  }

  /// Aggregated dose data point for efficient chart display
  struct AggregatedDosePoint: Identifiable {
    let id = UUID()
    let periodStart: Date
    let periodEnd: Date
    let totalAmount: Double
    let doseCount: Int
    let averageAmount: Double
    let sites: [String]

    init(periodStart: Date, periodEnd: Date, doses: [Dose]) {
      self.periodStart = periodStart
      self.periodEnd = periodEnd
      self.totalAmount = doses.reduce(0) { $0 + $1.amount }
      self.doseCount = doses.count
      self.averageAmount = doseCount > 0 ? totalAmount / Double(doseCount) : 0
      self.sites = Array(Set(doses.compactMap { $0.site }))
    }
  }

  // swiftlint:disable:next orphaned_doc_comment
  /// Aggregate doses by time period for efficient chart display
  /// - Parameters:
  ///   - doses: Array of dose records to aggregate
  ///   - aggregationPeriod: Time period for aggregation
  ///   - maxDataPoints: Maximum number of aggregated data points to return
  /// - Returns: Array of aggregated dose points
  // swiftlint:disable:next function_body_length
  func aggregateDosesByTimePeriod(
    _ doses: [Dose],
    aggregationPeriod: AggregationPeriod,
    maxDataPoints: Int
  ) -> [AggregatedDosePoint] {
    guard !doses.isEmpty else { return [] }

    let sortedDoses = doses.sorted { $0.timestamp < $1.timestamp }
    guard let earliestDate = sortedDoses.first?.timestamp,
      let latestDate = sortedDoses.last?.timestamp
    else {
      return []
    }

    // If we have fewer time periods than maxDataPoints, use original period
    let totalTimeSpan = latestDate.timeIntervalSince(earliestDate)
    let originalInterval = aggregationPeriod.timeInterval
    let numberOfPeriods = Int(ceil(totalTimeSpan / originalInterval))

    let effectiveInterval: TimeInterval
    if numberOfPeriods <= maxDataPoints {
      effectiveInterval = originalInterval
    } else {
      // Scale up the interval to fit within maxDataPoints
      effectiveInterval = totalTimeSpan / Double(maxDataPoints)
    }

    var aggregatedPoints: [AggregatedDosePoint] = []
    var processedDoses: Set<UUID> = []
    var currentDate = earliestDate

    // Create time-based buckets ensuring we don't exceed maxDataPoints
    while currentDate <= latestDate && aggregatedPoints.count < maxDataPoints {
      let periodEnd = min(
        latestDate.addingTimeInterval(1), currentDate.addingTimeInterval(effectiveInterval))
      let dosesInPeriod = sortedDoses.filter { dose in
        dose.timestamp >= currentDate && dose.timestamp <= periodEnd
          && !processedDoses.contains(dose.id)
      }

      if !dosesInPeriod.isEmpty {
        let aggregatedPoint = AggregatedDosePoint(
          periodStart: currentDate,
          periodEnd: periodEnd,
          doses: dosesInPeriod
        )
        aggregatedPoints.append(aggregatedPoint)

        // Mark these doses as processed
        for dose in dosesInPeriod {
          processedDoses.insert(dose.id)
        }
      }

      currentDate = periodEnd

      // Break if we've reached the end
      if currentDate >= latestDate {
        break
      }
    }

    // Ensure we capture any remaining doses that might have been missed
    let missedDoses = sortedDoses.filter { !processedDoses.contains($0.id) }

    if !missedDoses.isEmpty && aggregatedPoints.count < maxDataPoints {
      // Create a catch-all period for missed doses
      let catchAllPeriod = AggregatedDosePoint(
        periodStart: earliestDate,
        periodEnd: latestDate.addingTimeInterval(1),
        doses: missedDoses
      )
      aggregatedPoints.append(catchAllPeriod)
    }

    return aggregatedPoints
  }

  /// Apply adaptive density control for optimal chart performance
  /// - Parameters:
  ///   - points: Array of concentration points to optimize
  ///   - targetDataPoints: Target number of data points for chart
  ///   - preserveExtremes: Whether to preserve minimum and maximum values
  /// - Returns: Optimized concentration points array
  func applyAdaptiveDensityControl(
    _ points: [ConcentrationPoint],
    targetDataPoints: Int,
    preserveExtremes: Bool = true
  ) -> [ConcentrationPoint] {
    guard points.count > targetDataPoints else { return points }

    let sortedPoints = points.sorted { $0.date < $1.date }
    var optimizedPoints: [ConcentrationPoint] = []

    // Calculate how many points we can allocate for sampling
    let extremePointsCount = preserveExtremes ? 4 : 0  // first, last, min concentration, max concentration
    let availableForSampling = max(1, targetDataPoints - extremePointsCount)

    // Calculate sampling interval to ensure we don't exceed target
    let skipInterval = max(1, sortedPoints.count / availableForSampling)

    // Always include first point if preserving extremes
    if preserveExtremes, let firstPoint = sortedPoints.first {
      optimizedPoints.append(firstPoint)
    }

    // Sample points at regular intervals
    let startIndex = preserveExtremes ? skipInterval : 0
    let endIndex = preserveExtremes ? sortedPoints.count - skipInterval : sortedPoints.count

    for sampleIndex in stride(from: startIndex, to: endIndex, by: skipInterval) {
      if sampleIndex < sortedPoints.count
        && optimizedPoints.count < targetDataPoints - (preserveExtremes ? 3 : 0)
      {
        optimizedPoints.append(sortedPoints[sampleIndex])
      }
    }

    // Always include last point if preserving extremes
    if preserveExtremes, let lastPoint = sortedPoints.last,
      sortedPoints.count > 1,
      optimizedPoints.count < targetDataPoints - 2
    {
      optimizedPoints.append(lastPoint)
    }

    // Preserve extreme concentration values if requested and we have room
    if preserveExtremes && optimizedPoints.count < targetDataPoints {
      let minConcentrationPoint = sortedPoints.min { $0.concentration < $1.concentration }
      let maxConcentrationPoint = sortedPoints.max(by: { $0.concentration < $1.concentration })

      if let minPoint = minConcentrationPoint,
        !optimizedPoints.contains(where: { $0.id == minPoint.id }),
        optimizedPoints.count < targetDataPoints
      {
        optimizedPoints.append(minPoint)
      }
      if let maxPoint = maxConcentrationPoint,
        !optimizedPoints.contains(where: { $0.id == maxPoint.id }),
        optimizedPoints.count < targetDataPoints
      {
        optimizedPoints.append(maxPoint)
      }
    }

    // Sort final result by date and ensure we don't exceed target
    let finalResult = optimizedPoints.sorted { $0.date < $1.date }
    return Array(finalResult.prefix(targetDataPoints))
  }
}
