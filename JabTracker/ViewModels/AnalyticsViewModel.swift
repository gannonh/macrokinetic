//
//  AnalyticsViewModel.swift
//  JabTracker
//
//  ViewModel for analytics view with chart data management and helper methods
//

import Foundation
import OSLog
import SwiftData

@Observable
class AnalyticsViewModel {

    // MARK: - Configuration

    /// Configuration for chart dataset refresh
    struct RefreshConfig {
        let user: User
        let profiles: [MedicationProfile]
        let doseService: DoseDataService
        let chartService: ChartDatasetService
        let context: ModelContext
        let selectedPeriod: ChartDataProcessor.TimePeriod
    }

    // MARK: - Properties

    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "AnalyticsViewModel")

    /// Disk cache for chart dataset persistence
    private let cache = ChartDatasetCache()

    /// Full chart dataset (all time) - generated once and cached in memory + disk
    var fullChartDataset: ConcentrationChartDataset?

    /// Filtered chart dataset for current time period
    var chartDataset: ConcentrationChartDataset?

    // MARK: - Chart Data Management

    /// Try to load cached dataset from disk (instant vs 80s generation)
    /// - Parameter selectedPeriod: Initial time period to filter to
    /// - Returns: true if loaded from cache, false if cache miss or corrupted
    func loadFromCache(selectedPeriod: ChartDataProcessor.TimePeriod) -> Bool {
        switch cache.load() {
        case .success(let cached):
            fullChartDataset = cached
            filterChartDataset(to: selectedPeriod)
            Self.logger.info("✅ Loaded from cache - instant startup")
            return true

        case .notFound:
            Self.logger.info("📭 No cached dataset - will need to generate")
            return false

        case .corrupted(let error):
            Self.logger.warning(
                """
                ⚠️  Cached dataset is corrupted - will regenerate
                   Error: \(error.localizedDescription)
                """
            )
            // Clear corrupted cache so it doesn't interfere with next save
            cache.clear()
            return false
        }
    }

    /// Refresh full chart dataset (all time) - only happens once per session
    /// - Parameter config: Configuration containing user, profiles, services, context, and selected period
    func refreshChartDataset(config: RefreshConfig) async {
        Self.logger.info("🔄 Generating FULL chart dataset (all time)...")
        let refreshStartTime = Date()

        let profilesWithDoses = await fetchAllDoses(config: config)
        guard !profilesWithDoses.isEmpty else {
            await MainActor.run {
                self.fullChartDataset = nil
                self.chartDataset = nil
            }
            return
        }

        let fullDataset = await generateFullDataset(
            user: config.user,
            profilesWithDoses: profilesWithDoses,
            chartService: config.chartService
        )

        await updateAndPersistDataset(
            fullDataset,
            selectedPeriod: config.selectedPeriod,
            totalTime: Date().timeIntervalSince(refreshStartTime)
        )
    }

    /// Fetch all doses for medication profiles
    /// - Parameter config: Configuration containing profiles, dose service, and context
    /// - Returns: Array of tuples containing medication profiles and their doses
    private func fetchAllDoses(config: RefreshConfig) async -> [(MedicationProfile, [Dose])] {
        let doseFetchStart = Date()
        var profilesWithDoses: [(MedicationProfile, [Dose])] = []

        for profile in config.profiles {
            // Note: Swift 6 concurrency warning expected - SwiftData models are designed for MainActor use
            // Will be addressed during Swift 6 migration
            let doses = await config.doseService.fetchDoses(for: profile, within: .all, context: config.context)
            guard !doses.isEmpty else { continue }
            profilesWithDoses.append((profile, doses))
        }

        let doseFetchTime = Date().timeIntervalSince(doseFetchStart) * 1000
        let totalDoses = profilesWithDoses.reduce(0) { $0 + $1.1.count }
        Self.logger.info("  ⏱️  Dose fetching: \(String(format: "%.1f", doseFetchTime))ms (\(totalDoses) doses)")

        return profilesWithDoses
    }

    /// Generate full chart dataset using chart service
    /// - Parameters:
    ///   - user: User for the dataset
    ///   - profilesWithDoses: Medication profiles with their doses
    ///   - chartService: Chart service for dataset generation
    /// - Returns: Generated concentration chart dataset
    private func generateFullDataset(
        user: User,
        profilesWithDoses: [(MedicationProfile, [Dose])],
        chartService: ChartDatasetService
    ) async -> ConcentrationChartDataset? {
        let chartGenStart = Date()
        let fullDataset = chartService.generateChartDataset(
            for: user,
            profilesWithDoses: profilesWithDoses,
            timePeriod: .all
        )
        let chartGenTime = Date().timeIntervalSince(chartGenStart) * 1000
        Self.logger.info("  ⏱️  Chart generation: \(String(format: "%.1f", chartGenTime))ms")

        return fullDataset
    }

    /// Update chart dataset properties and persist to disk cache
    /// - Parameters:
    ///   - dataset: Full chart dataset to persist
    ///   - selectedPeriod: Time period to filter to
    ///   - totalTime: Total refresh time interval for logging
    private func updateAndPersistDataset(
        _ dataset: ConcentrationChartDataset?,
        selectedPeriod: ChartDataProcessor.TimePeriod,
        totalTime: TimeInterval
    ) async {
        await MainActor.run {
            self.fullChartDataset = dataset
            self.filterChartDataset(to: selectedPeriod)

            let totalTimeMs = totalTime * 1000
            Self.logger.info("  ⏱️  Total refresh: \(String(format: "%.1f", totalTimeMs))ms")
            Self.logger.info("✅ Full dataset generated and cached in memory")

            // Save to disk for instant startup next time
            if let dataset = self.fullChartDataset {
                do {
                    try self.cache.save(dataset)
                } catch let error as CacheError {
                    Self.logger.error("❌ Cache save failed: \(error.localizedDescription)")
                } catch {
                    Self.logger.error("❌ Unexpected error saving to cache: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Filter full dataset to selected time period (INSTANT - <10ms)
    /// - Parameter period: Time period to filter to
    func filterChartDataset(to period: ChartDataProcessor.TimePeriod) {
        guard let full = fullChartDataset else {
            chartDataset = nil
            return
        }

        let filterStart = Date()

        // Map ChartDataProcessor.TimePeriod to TimeRange
        let timeRange: TimeRange = {
            switch period {
            case .last7Days: return .lastWeek
            case .last30Days: return .lastMonth
            case .last90Days: return .lastQuarter
            case .lastYear: return .lastYear
            case .all: return .all
            }
        }()

        // INSTANT: Just filter arrays (no regeneration)
        chartDataset = full.filtered(to: timeRange)

        let filterTime = Date().timeIntervalSince(filterStart) * 1000
        Self.logger.info("  ⚡ Filtered to \(timeRange.displayName): \(String(format: "%.1f", filterTime))ms")
    }

    /// Async version of filterChartDataset for responsive UI during time period changes
    /// - Parameter period: Time period to filter to
    func filterChartDatasetAsync(to period: ChartDataProcessor.TimePeriod) async {
        guard let full = fullChartDataset else {
            await MainActor.run {
                chartDataset = nil
            }
            return
        }

        let filterStart = Date()

        // Map ChartDataProcessor.TimePeriod to TimeRange
        let timeRange: TimeRange = {
            switch period {
            case .last7Days: return .lastWeek
            case .last30Days: return .lastMonth
            case .last90Days: return .lastQuarter
            case .lastYear: return .lastYear
            case .all: return .all
            }
        }()

        // Filter on background thread (though it's fast, keeps UI responsive)
        let filtered = full.filtered(to: timeRange)

        let filterTime = Date().timeIntervalSince(filterStart) * 1000

        await MainActor.run {
            self.chartDataset = filtered
            Self.logger.info("  ⚡ Filtered to \(timeRange.displayName): \(String(format: "%.1f", filterTime))ms")
        }
    }

    // MARK: - Sample Data Generation

    /// Generate sample trend data for adherence visualization
    /// - Parameter user: User to generate trend data for
    /// - Returns: Array of adherence trend points for the last 4 weeks
    func generateTrendData(for user: User) -> [AdherenceTrendPoint] {
        let calendar = Calendar.current
        let now = Date()
        var trendData: [AdherenceTrendPoint] = []

        for weekOffset in 0..<4 {
            if let weekDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) {
                let adherenceRate = Double.random(in: 0.6...0.95)
                trendData.append(
                    AdherenceTrendPoint(
                        date: weekDate,
                        adherenceRate: adherenceRate,
                        period: "Week \(4 - weekOffset)"
                    ))
            }
        }

        return trendData.sorted { $0.date < $1.date }
    }

    /// Generate sample missed dose patterns for visualization
    /// - Parameter user: User to generate missed dose patterns for
    /// - Returns: Array of missed dose patterns
    func generateMissedDosePatterns(for user: User) -> [MissedDosePattern] {
        let calendar = Calendar.current
        let now = Date()

        return [
            MissedDosePattern(
                date: calendar.date(byAdding: .day, value: -6, to: now) ?? now,
                dayOfWeek: "Saturday",
                missedCount: 2
            ),
            MissedDosePattern(
                date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                dayOfWeek: "Sunday",
                missedCount: 3
            ),
        ]
    }
}
