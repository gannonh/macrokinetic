//
//  WeightTrendDetailViewModel.swift
//  JabTracker
//
//  ViewModel for WeightTrendDetailView - provides weight history with trend analysis.
//

import Foundation
import OSLog
import SwiftData

/// ViewModel providing weight history data with trend analysis for WeightTrendDetailView
@MainActor
@Observable
final class WeightTrendDetailViewModel {

    // MARK: - Types

    /// Data point for weight chart (matches WeightTrendDetailData.WeightPoint)
    struct WeightPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
        let isTrendLine: Bool  // true for smoothed trend, false for actual weight
    }

    /// Weight change at a specific interval
    struct WeightChange: Identifiable {
        let id = UUID()
        let period: String  // "3-day", "7-day", etc.
        let change: Double
        let trend: String  // "Decrease", "Increase", "No Change"
    }

    /// Historical entry for data sources section
    struct HistoricalEntry: Identifiable {
        let id = UUID()
        let weight: Double
        let date: Date
        let changeLabel: String?  // "No Change", "+0.2", "-0.3", etc.
    }

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "WeightTrendDetailViewModel"
    )

    private let metricsService: MetricsService
    private let context: ModelContext

    /// EWMA smoothing factor (higher = more weight to recent values)
    private let ewmaAlpha: Double = 0.2

    // MARK: - Published State

    /// Whether data is currently loading
    private(set) var isLoading: Bool = false

    /// All data points for chart (both actual and trend)
    private(set) var dataPoints: [WeightPoint] = []

    /// Weight changes at various intervals
    private(set) var weightChanges: [WeightChange] = []

    /// Historical entries for data sources section
    private(set) var historicalEntries: [HistoricalEntry] = []

    /// Current/average weight
    private(set) var currentWeight: Double?

    /// Difference from start of period
    private(set) var difference: Double?

    /// Date range string for display
    private(set) var dateRange: String = ""

    /// Smoothed (trend) weight via EWMA
    private(set) var smoothedWeight: Double?

    /// Weekly weight change rate
    private(set) var weeklyChange: Double?

    /// Estimated daily energy deficit/surplus in kcal
    private(set) var energyDeficit: Int?

    /// Projected weight in 30 days
    private(set) var projectedWeight: Double?

    /// Weight unit (lbs or kg)
    private(set) var weightUnit: String = "lbs"

    /// Selected time period for filtering
    var selectedPeriod: DetailTimePeriod = .oneYear

    /// Whether any weight data exists
    var hasData: Bool {
        !dataPoints.filter { !$0.isTrendLine }.isEmpty
    }

    // MARK: - Initialization

    /// Initialize with metrics service and model context
    /// - Parameters:
    ///   - metricsService: Service for fetching weight data
    ///   - context: ModelContext for fetching user data
    init(metricsService: MetricsService, context: ModelContext) {
        self.metricsService = metricsService
        self.context = context
    }

    // MARK: - Data Loading

    /// Load weight data and calculate all metrics
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Load user preferences
        loadUserPreferences()

        // Load weight entries for selected period
        let entries = await loadWeightEntries()
        guard !entries.isEmpty else {
            clearAllData()
            return
        }

        // Sort entries by date (oldest to newest)
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }

        // Generate data points (actual weights)
        generateDataPoints(from: sortedEntries)

        // Calculate EWMA trend
        calculateEWMATrend(from: sortedEntries)

        // Calculate weight changes at intervals
        calculateWeightChanges(from: sortedEntries)

        // Calculate energy balance
        calculateEnergyBalance(from: sortedEntries)

        // Calculate 30-day projection
        calculate30DayProjection()

        // Calculate current weight and difference
        calculateCurrentAndDifference(from: sortedEntries)

        // Generate date range string
        generateDateRange(from: sortedEntries)

        // Generate historical entries
        generateHistoricalEntries(from: sortedEntries)

        Self.logger.debug(
            "Loaded \(sortedEntries.count) weight entries, smoothed=\(self.smoothedWeight ?? 0)"
        )
    }

    // MARK: - Private Methods

    /// Load user preferences (weight unit)
    private func loadUserPreferences() {
        if let user = context.fetchCurrentUser(logger: Self.logger) {
            weightUnit = user.weightUnit
        }
    }

    /// Load weight entries for selected time period
    private func loadWeightEntries() async -> [WeightEntry] {
        let endDate = Date()

        do {
            if let startDate = selectedPeriod.startDate {
                return try await metricsService.getWeightEntries(from: startDate, to: endDate)
            } else {
                // All time
                return try await metricsService.getAllWeightEntries()
            }
        } catch {
            Self.logger.error("Failed to load weight entries: \(error)")
            return []
        }
    }

    /// Clear all data when no entries exist
    private func clearAllData() {
        dataPoints = []
        weightChanges = []
        historicalEntries = []
        currentWeight = nil
        difference = nil
        dateRange = ""
        smoothedWeight = nil
        weeklyChange = nil
        energyDeficit = nil
        projectedWeight = nil
    }

    /// Generate actual weight data points
    private func generateDataPoints(from entries: [WeightEntry]) {
        let actualPoints = entries.map { entry in
            let weight = weightUnit == "lbs" ? entry.weightInLbs : entry.weightKg
            return WeightPoint(date: entry.timestamp, weight: weight, isTrendLine: false)
        }
        dataPoints = actualPoints
    }

    /// Calculate EWMA trend and add trend points
    private func calculateEWMATrend(from entries: [WeightEntry]) {
        guard !entries.isEmpty else {
            smoothedWeight = nil
            return
        }

        // Convert to weights in user's preferred unit
        let weights: [(date: Date, weight: Double)] = entries.map { entry in
            let weight = weightUnit == "lbs" ? entry.weightInLbs : entry.weightKg
            return (entry.timestamp, weight)
        }

        // Calculate EWMA
        var ewmaWeights: [(date: Date, weight: Double)] = []
        var smoothed = weights[0].weight

        for (date, weight) in weights {
            smoothed = ewmaAlpha * weight + (1 - ewmaAlpha) * smoothed
            ewmaWeights.append((date, smoothed))
        }

        // Set smoothed weight to latest EWMA value
        smoothedWeight = ewmaWeights.last?.weight

        // Generate trend line points
        let trendPoints = ewmaWeights.map { (date, weight) in
            WeightPoint(date: date, weight: weight, isTrendLine: true)
        }

        // Combine actual and trend points
        dataPoints += trendPoints
    }

    /// Calculate weight changes at various intervals
    private func calculateWeightChanges(from entries: [WeightEntry]) {
        guard entries.count >= 2 else {
            weightChanges = []
            return
        }

        // Calculate EWMA values for comparison
        let ewmaValues = calculateEWMAValues(from: entries)
        guard !ewmaValues.isEmpty else {
            weightChanges = []
            return
        }

        let intervals = [(3, "3-day"), (7, "7-day"), (14, "14-day"), (30, "30-day"), (90, "90-day")]
        var changes: [WeightChange] = []

        let latestDate = ewmaValues.last!.date
        let latestWeight = ewmaValues.last!.weight

        for (days, label) in intervals {
            // Find entry closest to N days ago
            guard let targetDate = Calendar.current.date(byAdding: .day, value: -days, to: latestDate) else {
                continue
            }

            // Find closest EWMA value to target date
            if let closest = findClosestEntry(to: targetDate, in: ewmaValues, maxDaysDistance: days / 2 + 1) {
                let change = latestWeight - closest.weight
                let trend: String
                if change < -0.05 {
                    trend = "Decrease"
                } else if change > 0.05 {
                    trend = "Increase"
                } else {
                    trend = "No Change"
                }

                changes.append(WeightChange(period: label, change: change, trend: trend))
            }
        }

        weightChanges = changes
    }

    /// Calculate EWMA values from entries
    private func calculateEWMAValues(from entries: [WeightEntry]) -> [(date: Date, weight: Double)] {
        guard !entries.isEmpty else { return [] }

        var ewmaValues: [(date: Date, weight: Double)] = []
        var smoothed = weightUnit == "lbs" ? entries[0].weightInLbs : entries[0].weightKg

        for entry in entries {
            let weight = weightUnit == "lbs" ? entry.weightInLbs : entry.weightKg
            smoothed = ewmaAlpha * weight + (1 - ewmaAlpha) * smoothed
            ewmaValues.append((entry.timestamp, smoothed))
        }

        return ewmaValues
    }

    /// Find closest entry to a target date
    private func findClosestEntry(
        to targetDate: Date,
        in entries: [(date: Date, weight: Double)],
        maxDaysDistance: Int
    ) -> (date: Date, weight: Double)? {
        var closest: (date: Date, weight: Double)?
        var closestDistance: TimeInterval = .infinity

        for entry in entries {
            let distance = abs(entry.date.timeIntervalSince(targetDate))
            if distance < closestDistance {
                closestDistance = distance
                closest = entry
            }
        }

        // Check if closest is within acceptable range
        let maxSeconds = TimeInterval(maxDaysDistance * 24 * 60 * 60)
        if closestDistance <= maxSeconds {
            return closest
        }

        return nil
    }

    /// Calculate energy balance from weight change rate
    private func calculateEnergyBalance(from entries: [WeightEntry]) {
        guard entries.count >= 2 else {
            weeklyChange = nil
            energyDeficit = nil
            return
        }

        // Calculate EWMA values
        let ewmaValues = calculateEWMAValues(from: entries)
        guard ewmaValues.count >= 2 else {
            weeklyChange = nil
            energyDeficit = nil
            return
        }

        // Calculate over 3 weeks (21 days) if available
        let latestDate = ewmaValues.last!.date
        let latestWeight = ewmaValues.last!.weight

        // Find entry from ~3 weeks ago
        guard let targetDate = Calendar.current.date(byAdding: .day, value: -21, to: latestDate),
            let threeWeeksAgo = findClosestEntry(to: targetDate, in: ewmaValues, maxDaysDistance: 10)
        else {
            // Fall back to total period if 3 weeks not available
            let oldest = ewmaValues.first!
            let weeks = latestDate.timeIntervalSince(oldest.date) / (7 * 24 * 60 * 60)
            if weeks > 0 {
                // Convert weight change from lbs to kg if needed for calculation
                let weightChangeKg: Double
                if weightUnit == "lbs" {
                    weightChangeKg = (latestWeight - oldest.weight) / WeightEntry.kgToLbsConversion
                } else {
                    weightChangeKg = latestWeight - oldest.weight
                }

                let kgPerWeek = weightChangeKg / weeks
                weeklyChange = weightUnit == "lbs" ? kgPerWeek * WeightEntry.kgToLbsConversion : kgPerWeek

                // 1 kg = 7700 kcal, so daily deficit = kg/week * 7700 / 7 = kg/week * 1100
                let dailyDeficit = abs(kgPerWeek) * 1100
                energyDeficit = Int(dailyDeficit)
            }
            return
        }

        // Calculate weekly change over 3 weeks
        let weeks = latestDate.timeIntervalSince(threeWeeksAgo.date) / (7 * 24 * 60 * 60)
        guard weeks > 0 else {
            weeklyChange = nil
            energyDeficit = nil
            return
        }

        // Convert weight change from lbs to kg if needed
        let weightChangeKg: Double
        if weightUnit == "lbs" {
            weightChangeKg = (latestWeight - threeWeeksAgo.weight) / WeightEntry.kgToLbsConversion
        } else {
            weightChangeKg = latestWeight - threeWeeksAgo.weight
        }

        let kgPerWeek = weightChangeKg / weeks
        weeklyChange = weightUnit == "lbs" ? kgPerWeek * WeightEntry.kgToLbsConversion : kgPerWeek

        // Energy formula: kg/week * 1100 = daily deficit
        let dailyDeficit = abs(kgPerWeek) * 1100
        energyDeficit = Int(dailyDeficit)
    }

    /// Calculate 30-day weight projection based on current trend
    private func calculate30DayProjection() {
        guard let smoothed = smoothedWeight, let weekly = weeklyChange else {
            projectedWeight = nil
            return
        }

        // 30 days = ~4.3 weeks
        let weeks = 30.0 / 7.0
        projectedWeight = smoothed + (weekly * weeks)
    }

    /// Calculate current weight (average for period) and difference from period start
    private func calculateCurrentAndDifference(from entries: [WeightEntry]) {
        guard !entries.isEmpty else {
            currentWeight = nil
            difference = nil
            return
        }

        // Average weight for the entire selected period
        let allWeights = entries.map { weightUnit == "lbs" ? $0.weightInLbs : $0.weightKg }
        currentWeight = allWeights.reduce(0, +) / Double(allWeights.count)

        // Difference: compare latest weight to first weight in period
        if entries.count >= 2 {
            let firstWeight = weightUnit == "lbs" ? entries.first!.weightInLbs : entries.first!.weightKg
            let lastWeight = weightUnit == "lbs" ? entries.last!.weightInLbs : entries.last!.weightKg
            difference = lastWeight - firstWeight
        } else {
            difference = nil
        }
    }

    /// Generate date range string
    private func generateDateRange(from entries: [WeightEntry]) {
        guard !entries.isEmpty else {
            dateRange = ""
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"

        if entries.count == 1 {
            dateRange = formatter.string(from: entries.first!.timestamp)
        } else {
            let start = formatter.string(from: entries.first!.timestamp)
            let end = formatter.string(from: entries.last!.timestamp)
            dateRange = "\(start) - \(end)"
        }
    }

    /// Generate historical entries for display
    private func generateHistoricalEntries(from entries: [WeightEntry]) {
        // Take last 10 entries, most recent first
        let recentEntries = Array(entries.suffix(10).reversed())

        historicalEntries = recentEntries.enumerated().map { index, entry in
            let weight = weightUnit == "lbs" ? entry.weightInLbs : entry.weightKg

            // Calculate change label (comparing to previous entry)
            var changeLabel: String?
            if index < recentEntries.count - 1 {
                let previousEntry = recentEntries[index + 1]
                let previousWeight = weightUnit == "lbs" ? previousEntry.weightInLbs : previousEntry.weightKg
                let change = weight - previousWeight

                if abs(change) < 0.1 {
                    changeLabel = "No Change"
                } else if change > 0 {
                    changeLabel = String(format: "+%.1f", change)
                } else {
                    changeLabel = String(format: "%.1f", change)
                }
            }

            return HistoricalEntry(
                weight: weight,
                date: entry.timestamp,
                changeLabel: changeLabel
            )
        }
    }
}

// MARK: - Preview Support

extension WeightTrendDetailViewModel {
    /// Preview data for SwiftUI previews
    static var preview: WeightTrendDetailViewModel {
        let context = PreviewHelpers.previewContext()
        let service = MetricsService(context: context)
        return WeightTrendDetailViewModel(metricsService: service, context: context)
    }
}
