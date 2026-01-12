//
//  ChartDataProcessor.swift
//  JabTracker
//

import Foundation
import OSLog
import Observation
import SwiftData

/// Data transformation service for converting SwiftData models to Swift Charts compatible structures
/// Handles concentration timeline data, dose markers, and time period filtering for chart visualizations
@Observable
// swiftlint:disable:next type_body_length
final class ChartDataProcessor {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "JabTracker",
        category: "ChartDataProcessor")

    // MARK: - Concentration Sampling Configuration

    /// Standard sampling interval for concentration timeline (hours)
    /// Balances chart smoothness with performance for large datasets
    private static let standardSamplingInterval: TimeInterval = 0.5 * 3600  // 30 minutes

    /// Multiplier for denser sampling near dose events
    /// Provides smoother curves during rapid concentration changes
    private static let doseSamplingMultiplier: Double = 4.0

    /// Time window around doses requiring denser sampling (hours)
    /// Captures concentration spikes and decay curves accurately
    private static let denseSamplingWindow: TimeInterval = 24 * 3600  // ±24 hours

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
            // Sanitize concentration to prevent infinite/NaN values that could crash charts
            self.concentration = concentration.isFinite ? max(0, concentration) : 0
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
            // Sanitize amount to prevent invalid dose values
            self.amount = amount.isFinite ? max(0, amount) : 0
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

    /// Analytics-optimized chart data structure
    struct AnalyticsChartData {
        let concentrationTimeline: [ConcentrationPoint]
        let doseMarkers: [DoseMarker]
        let analyticsInsights: [AnalyticsInsight]
    }

    /// Analytics insight for chart display
    struct AnalyticsInsight {
        let title: String
        let description: String
        let recommendation: String
        let priority: AnalyticsInsightPriority
    }

    /// Priority levels for analytics insights
    enum AnalyticsInsightPriority {
        case high
        case medium
        case low

        var description: String {
            switch self {
            case .high: return "High Priority"
            case .medium: return "Medium Priority"
            case .low: return "Low Priority"
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
        // Input validation to prevent crashes
        guard points.count >= 2 else { return points }
        guard intervalHours > 0 && intervalHours.isFinite else { return points }

        let sortedPoints = points.sorted { $0.date < $1.date }
        var interpolatedPoints: [ConcentrationPoint] = []

        for index in 0..<sortedPoints.count - 1 {
            let currentPoint = sortedPoints[index]
            let nextPoint = sortedPoints[index + 1]

            // Add current point
            interpolatedPoints.append(currentPoint)

            // Calculate interpolated points between current and next
            let timeInterval = nextPoint.date.timeIntervalSince(currentPoint.date)

            // Skip if time interval is invalid or negative
            guard timeInterval > 0 && timeInterval.isFinite else { continue }

            let intervalSeconds = intervalHours * 3600
            let numberOfInterpolations = max(0, Int(timeInterval / intervalSeconds))

            // Only interpolate if we need at least one interpolation point
            // AND if the gap is larger than the desired interval
            guard numberOfInterpolations > 0 && timeInterval > intervalSeconds else { continue }

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

        // Use more efficient sampling that guarantees maxPoints limit
        if maxPoints <= 2 {
            // Edge case: return first and last points only
            return [sortedPoints.first, sortedPoints.last].compactMap { $0 }
        }

        var optimizedPoints: [ConcentrationPoint] = []

        // Always include first point
        if let firstPoint = sortedPoints.first {
            optimizedPoints.append(firstPoint)
        }

        // Calculate step size to distribute remaining points evenly
        let remainingPoints = maxPoints - 2  // Reserve slots for first and last
        let step = max(1, (sortedPoints.count - 2) / remainingPoints)

        // Sample points at calculated intervals
        for index in stride(from: step, to: sortedPoints.count - 1, by: step)
        where optimizedPoints.count < maxPoints - 1 {  // Reserve last slot
            optimizedPoints.append(sortedPoints[index])
        }

        // Always include last point (if different from first)
        if sortedPoints.count > 1, let lastPoint = sortedPoints.last {
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
            let sortedDoses = doses.sorted { $0.timestamp > $1.timestamp }  // Most recent first

            // Ensure we don't exceed maxMarkers by taking exact count
            sampledDoses = Array(sortedDoses.prefix(maxMarkers))
        } else {
            sampledDoses = doses
        }

        return transformDosesToMarkerData(sampledDoses)
    }

    /// Memory-efficient batch processing for very large datasets
    /// - Parameters:
    ///   - points: Large concentration dataset
    ///   - batchSize: Size of processing batches (default: 1000)
    ///   - maxFinalPoints: Maximum points in final result (default: 200)
    /// - Returns: Optimized concentration points processed in batches
    func processBatchedConcentrationData(
        _ points: [ConcentrationPoint],
        batchSize: Int = 1000,
        maxFinalPoints: Int = 200
    ) -> [ConcentrationPoint] {
        guard points.count > batchSize else {
            return optimizeDataDensity(points, maxPoints: maxFinalPoints)
        }

        let sortedPoints = points.sorted { $0.date < $1.date }
        var batchedResults: [ConcentrationPoint] = []

        // Process in batches to reduce memory pressure
        for batchStart in stride(from: 0, to: sortedPoints.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, sortedPoints.count)
            let batch = Array(sortedPoints[batchStart..<batchEnd])

            // Optimize each batch individually to reduce memory usage
            let optimizedBatch = optimizeDataDensity(batch, maxPoints: batchSize / 5)
            batchedResults.append(contentsOf: optimizedBatch)
        }

        // Final optimization to meet target point count
        return optimizeDataDensity(batchedResults, maxPoints: maxFinalPoints)
    }

    /// Lazy processing for concentration calculations to reduce memory footprint
    /// - Parameters:
    ///   - timeRange: Date range for calculations
    ///   - intervalHours: Time interval between calculated points
    ///   - doses: Dose data for calculations
    ///   - medication: Medication for pharmacokinetic parameters
    /// - Returns: Generator function that yields concentration points on demand
    func lazyConcentrationCalculation(
        timeRange: ClosedRange<Date>,
        intervalHours: Double,
        doses: [Dose],
        medication: Medication
    ) -> AnySequence<ConcentrationPoint> {
        // Initialize PharmacokineticsEngine for real concentration calculations
        let pharmacokineticsEngine = PharmacokineticsEngine()

        return AnySequence { () -> AnyIterator<ConcentrationPoint> in
            var currentTime = timeRange.lowerBound
            let endTime = timeRange.upperBound
            let intervalSeconds = intervalHours * 3600

            return AnyIterator {
                guard currentTime <= endTime else { return nil }

                // Use PharmacokineticsEngine for real concentration calculation
                let concentration = pharmacokineticsEngine.calculateConcentrationOptimized(
                    from: doses,
                    medication: medication,
                    at: currentTime
                )
                let point = ConcentrationPoint(date: currentTime, concentration: concentration)

                currentTime = currentTime.addingTimeInterval(intervalSeconds)
                return point
            }
        }
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

    // MARK: - Integration with PharmacokineticsEngine

    /// Generate comprehensive concentration timeline using PharmacokineticsEngine
    /// - Parameters:
    ///   - medicationProfile: The medication profile to analyze
    ///   - timeRange: Date range for timeline generation
    ///   - intervalHours: Time interval between calculated points (defaults to 6 hours for performance)
    /// - Returns: Array of concentration points calculated using pharmacokinetic models
    func generateConcentrationTimeline(
        for medicationProfile: MedicationProfile,
        timeRange: ClosedRange<Date>,
        intervalHours: Double = 6.0  // 6 hours provides smooth curves with ~12x better performance
    ) -> [ConcentrationPoint] {
        guard medicationProfile.medication != nil,
            let doses = medicationProfile.doses
        else {
            return []
        }

        return generateConcentrationTimeline(
            for: medicationProfile,
            doses: doses,
            timeRange: timeRange,
            intervalHours: intervalHours
        )
    }

    /// Generate concentration timeline with explicit dose array (avoids SwiftData relationship access)
    func generateConcentrationTimeline(
        for medicationProfile: MedicationProfile,
        doses: [Dose],
        timeRange: ClosedRange<Date>,
        intervalHours: Double = 6.0
    ) -> [ConcentrationPoint] {
        Self.logger.debug(
            """
            🧮 generateConcentrationTimeline(): explicit=\(doses.count, privacy: .public), \
            relationship=\(medicationProfile.doses?.count ?? 0, privacy: .public)
            """
        )

        guard let medication = medicationProfile.medication else {
            Self.logger.error("❌ No medication for profile '\(medicationProfile.genericName, privacy: .public)'")
            return []
        }

        let pharmacokineticsEngine = PharmacokineticsEngine()
        var concentrationPoints: [ConcentrationPoint] = []

        // Get dose timestamps for adaptive sampling (extra dense around doses)
        let doseTimestamps =
            doses
            .filter { !$0.skipped && $0.timestamp >= timeRange.lowerBound && $0.timestamp <= timeRange.upperBound }
            .map { $0.timestamp }
            .sorted()

        Self.logger.debug("  📊 Using \(doseTimestamps.count, privacy: .public) doses in time range")

        var currentTime = timeRange.lowerBound
        let endTime = timeRange.upperBound
        let baseIntervalSeconds = intervalHours * 3600

        while currentTime <= endTime {
            // Use denser sampling within dose sampling window for clear spikes
            let nearDose = doseTimestamps.contains { abs($0.timeIntervalSince(currentTime)) < Self.denseSamplingWindow }
            let actualInterval = nearDose ? baseIntervalSeconds / Self.doseSamplingMultiplier : baseIntervalSeconds

            let concentration = pharmacokineticsEngine.calculateConcentrationOptimized(
                from: doses,
                medication: medication,
                at: currentTime
            )

            concentrationPoints.append(
                ConcentrationPoint(date: currentTime, concentration: concentration)
            )

            currentTime = currentTime.addingTimeInterval(actualInterval)
        }

        Self.logger.info("✅ Generated \(concentrationPoints.count, privacy: .public) points")
        return concentrationPoints
    }

    /// Comprehensive concentration timeline with peak and trough markers
    struct ConcentrationTimelineWithLevels {
        let timeline: [ConcentrationPoint]
        let peakLevels: [ConcentrationPoint]
        let troughLevels: [ConcentrationPoint]
    }

    /// Generate chart data with peak and trough level markers
    /// - Parameters:
    ///   - medicationProfile: The medication profile to analyze
    ///   - timeRange: Date range for analysis
    /// - Returns: Comprehensive timeline data including special level markers
    func generateConcentrationTimelineWithLevels(
        for medicationProfile: MedicationProfile,
        timeRange: ClosedRange<Date>
    ) -> ConcentrationTimelineWithLevels {
        guard let doses = medicationProfile.doses else {
            return ConcentrationTimelineWithLevels(timeline: [], peakLevels: [], troughLevels: [])
        }

        let pharmacokineticsEngine = PharmacokineticsEngine()
        let timeline = generateConcentrationTimeline(for: medicationProfile, timeRange: timeRange)

        var peakLevels: [ConcentrationPoint] = []
        var troughLevels: [ConcentrationPoint] = []

        // Calculate peak and trough levels for each dose
        for dose in doses where !dose.skipped {
            let (peakLevel, peakTime) = pharmacokineticsEngine.calculatePeakLevel(
                for: dose,
                medication: medicationProfile
            )

            if timeRange.contains(peakTime) {
                peakLevels.append(ConcentrationPoint(date: peakTime, concentration: peakLevel))
            }
        }

        // Calculate overall trough level for the medication profile
        let (troughLevel, troughTime) = pharmacokineticsEngine.calculateTroughLevel(
            for: medicationProfile)
        if timeRange.contains(troughTime) {
            troughLevels.append(ConcentrationPoint(date: troughTime, concentration: troughLevel))
        }

        return ConcentrationTimelineWithLevels(
            timeline: timeline,
            peakLevels: peakLevels,
            troughLevels: troughLevels
        )
    }

    // MARK: - Integration with AnalyticsService

    /// Generate chart data optimized for analytics display
    /// - Parameters:
    ///   - user: User for analytics calculation
    ///   - analyticsService: AnalyticsService instance for coordination
    ///   - timePeriod: Time period for chart display
    /// - Returns: Chart data structure optimized for analytics visualization
    func generateAnalyticsOptimizedChartData(
        for user: User,
        analyticsService: AnalyticsService,
        timePeriod: TimePeriod,
        context: ModelContext
    ) -> AnalyticsChartData {
        guard let medicationProfiles = user.medicationProfiles else {
            return AnalyticsChartData(concentrationTimeline: [], doseMarkers: [], analyticsInsights: [])
        }

        let analyticsSummary = analyticsService.calculateUserAnalytics(user: user, context: context)
        let timeRange = calculateTimeRange(for: timePeriod, medicationProfiles: medicationProfiles)
        let chartData = generateChartDataForProfiles(medicationProfiles, timeRange: timeRange)
        let optimizedData = optimizeAnalyticsChartData(chartData)

        return AnalyticsChartData(
            concentrationTimeline: optimizedData.concentrationPoints,
            doseMarkers: optimizedData.doseMarkers,
            analyticsInsights: mapAnalyticsInsights(analyticsSummary.adherenceInsights)
        )
    }

    // MARK: - Helper Methods for Analytics Integration

    /// Map AnalyticsService insight type to display title
    private func mapInsightTypeToTitle(_ type: AnalyticsService.AdherenceInsightType) -> String {
        switch type {
        case .excellentAdherence:
            return "Excellent Adherence"
        case .missedDosesPattern:
            return "Missed Doses Pattern"
        case .timingInconsistency:
            return "Timing Inconsistency"
        case .medicationInteraction:
            return "Medication Interaction"
        case .doseEscalationOpportunity:
            return "Dose Escalation Opportunity"
        }
    }

    /// Map AnalyticsService priority to ChartDataProcessor priority
    private func mapInsightPriority(_ priority: AnalyticsService.InsightPriority)
        -> AnalyticsInsightPriority
    {
        switch priority {
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
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

    // MARK: - Analytics Helper Methods

    /// Calculate time range based on time period and medication profiles
    /// - Parameters:
    ///   - timePeriod: The time period for chart display
    ///   - medicationProfiles: Medication profiles for determining date bounds
    /// - Returns: Date range for chart data generation
    private func calculateTimeRange(
        for timePeriod: TimePeriod,
        medicationProfiles: [MedicationProfile]
    ) -> ClosedRange<Date> {
        let endDate = Date()
        let startDate: Date

        switch timePeriod {
        case .last7Days:
            startDate = endDate.addingTimeInterval(-7 * 24 * 3600)
        case .last30Days:
            startDate = endDate.addingTimeInterval(-30 * 24 * 3600)
        case .last90Days:
            startDate = endDate.addingTimeInterval(-90 * 24 * 3600)
        case .lastYear:
            startDate = endDate.addingTimeInterval(-365 * 24 * 3600)
        case .all:
            // Find earliest dose from all medication profiles
            let earliestDoses = medicationProfiles.compactMap { profile in
                profile.doses?.min { $0.timestamp < $1.timestamp }
            }
            let earliestDose = earliestDoses.min { $0.timestamp < $1.timestamp }
            startDate = earliestDose?.timestamp ?? endDate.addingTimeInterval(-365 * 24 * 3600)
        }

        return startDate...endDate
    }

    /// Chart data for multiple medication profiles
    private struct ProfileChartData {
        let concentrationPoints: [ConcentrationPoint]
        let doseMarkers: [DoseMarker]
    }

    /// Generate chart data for medication profiles within time range
    /// - Parameters:
    ///   - medicationProfiles: Profiles to generate chart data for
    ///   - timeRange: Time range for data generation
    /// - Returns: Combined chart data for all profiles
    private func generateChartDataForProfiles(
        _ medicationProfiles: [MedicationProfile],
        timeRange: ClosedRange<Date>
    ) -> ProfileChartData {
        var allConcentrationPoints: [ConcentrationPoint] = []
        var allDoseMarkers: [DoseMarker] = []

        for profile in medicationProfiles {
            // Generate concentration timeline for this profile
            let concentrationPoints = generateConcentrationTimeline(
                for: profile,
                timeRange: timeRange,
                intervalHours: 2.0
            )
            allConcentrationPoints.append(contentsOf: concentrationPoints)

            // Generate dose markers for this profile
            if let doses = profile.doses {
                let filteredDoses = filterDosesByCustomDateRange(
                    doses,
                    startDate: timeRange.lowerBound,
                    endDate: timeRange.upperBound
                )
                let doseMarkers = transformDosesToMarkerData(filteredDoses)
                allDoseMarkers.append(contentsOf: doseMarkers)
            }
        }

        return ProfileChartData(
            concentrationPoints: allConcentrationPoints,
            doseMarkers: allDoseMarkers
        )
    }

    /// Optimize chart data for analytics visualization
    /// - Parameter chartData: Raw chart data to optimize
    /// - Returns: Optimized chart data suitable for analytics display
    private func optimizeAnalyticsChartData(_ chartData: ProfileChartData) -> ProfileChartData {
        // Optimize concentration data density for chart performance
        let optimizedConcentration = optimizeDataDensity(
            chartData.concentrationPoints,
            maxPoints: 200
        )

        // Ensure dose markers are within reasonable limits
        let optimizedDoseMarkers = Array(chartData.doseMarkers.prefix(100))

        return ProfileChartData(
            concentrationPoints: optimizedConcentration,
            doseMarkers: optimizedDoseMarkers
        )
    }

    /// Map analytics insights to chart insights
    /// - Parameter insights: Analytics service insights
    /// - Returns: Chart-compatible analytics insights
    private func mapAnalyticsInsights(
        _ insights: [AnalyticsService.AdherenceInsight]
    ) -> [AnalyticsInsight] {
        insights.map { insight in
            AnalyticsInsight(
                title: mapInsightTypeToTitle(insight.type),
                description: insight.description,
                recommendation: insight.actionableRecommendation,
                priority: mapInsightPriority(insight.priority)
            )
        }
    }
}
