//
//  ChartDataProcessor+Interpolation.swift
//  JabTracker
//

import Foundation

/// Advanced interpolation methods for ChartDataProcessor
/// Provides sophisticated pharmacokinetic-based interpolation and Swift Charts integration
extension ChartDataProcessor {

  // MARK: - Advanced Interpolation Methods

  /// Generate comprehensive concentration timeline using pharmacokinetic modeling
  /// Creates smooth concentration curves with exponential decay between doses
  /// - Parameters:
  ///   - doses: Array of dose records to model
  ///   - medication: Medication type for pharmacokinetic parameters
  ///   - startDate: Start of timeline range
  ///   - endDate: End of timeline range
  ///   - intervalHours: Time interval between generated points in hours
  /// - Returns: Array of concentration points with smooth interpolation
  func generateConcentrationTimeline(
    doses: [Dose],
    medication: Medication,
    startDate: Date,
    endDate: Date,
    intervalHours: Double
  ) -> [ConcentrationPoint] {
    guard !doses.isEmpty else { return [] }
    guard startDate < endDate else { return [] }
    guard intervalHours > 0 else { return [] }

    let engine = PharmacokineticsEngine()
    var timeline: [ConcentrationPoint] = []

    // Generate points at regular intervals
    let totalDuration = endDate.timeIntervalSince(startDate)
    let numberOfPoints = Int(totalDuration / (intervalHours * 3600))

    for pointIndex in 0...numberOfPoints {
      let currentTime = startDate.addingTimeInterval(Double(pointIndex) * intervalHours * 3600)

      // Only generate points up to the end date
      guard currentTime <= endDate else { break }

      let concentration = engine.calculateConcentration(
        from: doses,
        medication: medication,
        at: currentTime
      )

      timeline.append(
        ConcentrationPoint(
          date: currentTime,
          concentration: concentration
        ))
    }

    return timeline
  }

  /// Generate memory-optimized concentration timeline for large datasets
  /// Provides adaptive interpolation with density control for performance
  /// - Parameters:
  ///   - doses: Array of dose records (can be large)
  ///   - medication: Medication type for pharmacokinetic parameters
  ///   - startDate: Start of timeline range
  ///   - endDate: End of timeline range
  ///   - maxPoints: Maximum number of points to generate
  ///   - adaptiveIntervals: Whether to use adaptive interval sizing
  /// - Returns: Optimized concentration timeline with controlled density
  func generateConcentrationTimelineOptimized(
    doses: [Dose],
    medication: Medication,
    startDate: Date,
    endDate: Date,
    maxPoints: Int,
    adaptiveIntervals: Bool = true
  ) -> [ConcentrationPoint] {
    guard !doses.isEmpty else { return [] }
    guard startDate < endDate else { return [] }
    guard maxPoints > 0 else { return [] }

    let totalDuration = endDate.timeIntervalSince(startDate)
    let baseIntervalHours = totalDuration / (3600 * Double(maxPoints))

    if adaptiveIntervals {
      return generateAdaptiveConcentrationTimeline(
        doses: doses,
        medication: medication,
        startDate: startDate,
        endDate: endDate,
        maxPoints: maxPoints
      )
    } else {
      return generateConcentrationTimeline(
        doses: doses,
        medication: medication,
        startDate: startDate,
        endDate: endDate,
        intervalHours: baseIntervalHours
      )
    }
  }

  /// Generate adaptive concentration timeline with variable density
  /// Higher density around dose times, lower density during stable periods
  /// - Parameters:
  ///   - doses: Array of dose records
  ///   - medication: Medication type for pharmacokinetic parameters
  ///   - startDate: Start of timeline range
  ///   - endDate: End of timeline range
  ///   - maxPoints: Maximum number of points to generate
  /// - Returns: Adaptive concentration timeline with optimized point distribution
  private func generateAdaptiveConcentrationTimeline(
    doses: [Dose],
    medication: Medication,
    startDate: Date,
    endDate: Date,
    maxPoints: Int
  ) -> [ConcentrationPoint] {
    let engine = PharmacokineticsEngine()
    var timeline: [ConcentrationPoint] = []

    // Sort doses by timestamp for processing
    let sortedDoses = doses.sorted { $0.timestamp < $1.timestamp }

    // Calculate base interval
    let totalDuration = endDate.timeIntervalSince(startDate)
    let baseInterval = totalDuration / Double(maxPoints)

    var currentTime = startDate
    var pointsGenerated = 0

    while currentTime <= endDate && pointsGenerated < maxPoints {
      let concentration = engine.calculateConcentration(
        from: doses,
        medication: medication,
        at: currentTime
      )

      timeline.append(
        ConcentrationPoint(
          date: currentTime,
          concentration: concentration
        ))
      pointsGenerated += 1

      // Adaptive interval calculation
      let intervalMultiplier = calculateIntervalMultiplier(
        currentTime: currentTime,
        doses: sortedDoses,
        medication: medication
      )

      currentTime = currentTime.addingTimeInterval(baseInterval * intervalMultiplier)
    }

    return timeline
  }

  /// Calculate interval multiplier for adaptive sampling
  /// Smaller multiplier (denser points) near dose times and during rapid changes
  /// - Parameters:
  ///   - currentTime: Current point in timeline
  ///   - doses: Sorted dose array
  ///   - medication: Medication type for decay rate calculations
  /// - Returns: Multiplier for base interval (1.0 = normal, <1.0 = denser, >1.0 = sparser)
  private func calculateIntervalMultiplier(
    currentTime: Date,
    doses: [Dose],
    medication: Medication
  ) -> Double {
    // Find nearby doses (within 24 hours)
    let nearbyDoses = doses.filter { dose in
      abs(currentTime.timeIntervalSince(dose.timestamp)) <= 24 * 3600
    }

    if nearbyDoses.isEmpty {
      return 2.0  // Sparse sampling in areas without nearby doses
    }

    // Find closest dose time
    let closestDoseTime =
      nearbyDoses.min { dose1, dose2 in
        abs(currentTime.timeIntervalSince(dose1.timestamp))
          < abs(currentTime.timeIntervalSince(dose2.timestamp))
      }?.timestamp ?? currentTime

    let timeSinceDose = abs(currentTime.timeIntervalSince(closestDoseTime)) / 3600  // hours

    // Denser sampling in first few hours after dose (rapid concentration change)
    if timeSinceDose < 2 {
      return 0.3  // Very dense sampling
    } else if timeSinceDose < 6 {
      return 0.6  // Moderately dense sampling
    } else if timeSinceDose < 24 {
      return 1.0  // Normal sampling
    } else {
      return 1.5  // Sparse sampling during stable periods
    }
  }

  /// Transform advanced concentration timeline to enhanced chart data structure
  /// - Parameters:
  ///   - concentrationPoints: Array of concentration data points
  ///   - interpolationType: Type of interpolation used to generate points
  /// - Returns: Array of advanced chart-compatible concentration points
  func transformToAdvancedChartData(
    _ concentrationPoints: [ConcentrationPoint],
    interpolationType: InterpolationType = .pharmacokinetic
  ) -> [AdvancedConcentrationPoint] {
    concentrationPoints.map { point in
      AdvancedConcentrationPoint(
        from: point,
        interpolated: true
      )
    }
  }

  /// Generate enhanced dose markers with intelligent styling
  /// - Parameters:
  ///   - doses: Array of dose records
  ///   - includeSkipped: Whether to include skipped doses in markers
  ///   - enhancedStyling: Whether to apply intelligent styling based on dose properties
  /// - Returns: Array of enhanced dose markers with styling metadata
  func generateEnhancedDoseMarkers(
    _ doses: [Dose],
    includeSkipped: Bool = true,
    enhancedStyling: Bool = true
  ) -> [AdvancedDoseMarker] {
    let filteredDoses = includeSkipped ? doses : doses.filter { !$0.skipped }

    return filteredDoses.enumerated().map { index, dose in
      var marker = AdvancedDoseMarker(from: dose)

      if enhancedStyling {
        // Apply intelligent styling
        if index == 0 {
          marker = AdvancedDoseMarker(
            date: dose.timestamp,
            amount: dose.amount,
            isSkipped: dose.skipped,
            markerStyle: .firstDose,
            alertLevel: .info,
            metadata: marker.metadata
          )
        }

        // Mark milestone doses (every 10th dose)
        if (index + 1) % 10 == 0 {
          marker = AdvancedDoseMarker(
            date: dose.timestamp,
            amount: dose.amount,
            isSkipped: dose.skipped,
            markerStyle: .milestone,
            alertLevel: .info,
            metadata: marker.metadata
          )
        }
      }

      return marker
    }
  }

  /// Create complete chart dataset for concentration timeline visualization
  /// - Parameters:
  ///   - doses: Array of dose records
  ///   - medication: Medication type for modeling
  ///   - timeRange: Time range for chart display
  ///   - configuration: Chart configuration settings
  /// - Returns: Complete dataset ready for Swift Charts rendering
  func createConcentrationChartDataset(
    doses: [Dose],
    medication: Medication,
    timeRange: TimeRange = .lastWeek,
    configuration: ConcentrationChartConfiguration = .default
  ) -> ConcentrationChartDataset {
    let dateRange = timeRange.dateRange()

    // Generate concentration timeline
    let concentrationPoints = generateConcentrationTimeline(
      doses: doses,
      medication: medication,
      startDate: dateRange.start,
      endDate: dateRange.end,
      intervalHours: configuration.interpolationSettings.intervalHours
    )

    // Transform to advanced chart data
    let advancedPoints = transformToAdvancedChartData(
      concentrationPoints,
      interpolationType: configuration.interpolationSettings.type
    )

    // Create concentration curve
    let concentrationCurve = ConcentrationCurve(
      points: advancedPoints,
      medication: medication.displayName,
      curveStyle: .smooth
    )

    // Generate enhanced dose markers
    let doseMarkers = generateEnhancedDoseMarkers(doses, enhancedStyling: true)

    // Filter markers to time range
    let filteredMarkers = doseMarkers.filter { marker in
      marker.date >= dateRange.start && marker.date <= dateRange.end
    }

    return ConcentrationChartDataset(
      concentrationCurves: [concentrationCurve],
      doseMarkers: filteredMarkers,
      configuration: configuration,
      metadata: ChartMetadata(
        title: "\(medication.displayName) Concentration Timeline",
        subtitle: "\(timeRange)".capitalized
      )
    )
  }
}
