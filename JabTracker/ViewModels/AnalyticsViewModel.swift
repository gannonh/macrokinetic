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

    /// Clears the disk cache and in-memory dataset, forcing regeneration
    func clearCache() {
        Self.logger.info("🗑️ Clearing chart cache (user requested refresh)")
        cache.clear()
        fullChartDataset = nil
        chartDataset = nil
    }

    /// Filtered chart dataset for current time period
    var chartDataset: ConcentrationChartDataset?

    // MARK: - Chart Data Management

    /// Try to load cached dataset from disk (instant vs 80s generation)
    /// - Parameters:
    ///   - selectedPeriod: Initial time period to filter to
    ///   - expectedDoseCount: Expected number of doses (for staleness check)
    /// - Returns: true if loaded from cache, false if cache miss, corrupted, or stale
    func loadFromCache(selectedPeriod: ChartDataProcessor.TimePeriod, expectedDoseCount: Int = 0) -> Bool {
        Self.logger.debug("🔍 loadFromCache: expectedDoseCount=\(expectedDoseCount)")

        switch cache.load() {
        case .success(let cached):
            Self.logger.debug(
                """
                🔍 Staleness check: cache markers=\(cached.doseMarkers.count), expected doses=\(expectedDoseCount)
                """
            )

            // Staleness check: if cache has fewer markers than expected doses, regenerate
            if expectedDoseCount > 0 && cached.doseMarkers.count < expectedDoseCount {
                Self.logger.info(
                    """
                    📅 Cache is stale (markers: \(cached.doseMarkers.count), expected: \(expectedDoseCount)) - \
                    will regenerate
                    """
                )
                cache.clear()
                return false
            }

            // Also check if cache has no data but we expect some
            if cached.doseMarkers.isEmpty && expectedDoseCount > 0 {
                Self.logger.info("📅 Cache is empty but doses exist - will regenerate")
                cache.clear()
                return false
            }

            fullChartDataset = cached
            logCachedDatasetDetails(cached)
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

    /// Log cached dataset details for debugging
    private func logCachedDatasetDetails(_ cached: ConcentrationChartDataset) {
        let totalCachedPoints = cached.concentrationCurves.reduce(0) { $0 + $1.points.count }
        Self.logger.debug(
            """
            📦 Cached dataset details:
               - Curves: \(cached.concentrationCurves.count)
               - Total points: \(totalCachedPoints)
               - Markers: \(cached.doseMarkers.count)
            """
        )
        for (index, curve) in cached.concentrationCurves.enumerated() {
            if let firstPoint = curve.points.first, let lastPoint = curve.points.last {
                Self.logger.debug(
                    """
                       - Curve \(index) '\(curve.medication)': \(curve.points.count) pts
                          First: \(firstPoint.date.formatted()), conc: \(String(format: "%.3f", firstPoint.concentration))
                          Last: \(lastPoint.date.formatted()), conc: \(String(format: "%.3f", lastPoint.concentration))
                    """
                )
            }
        }
        for marker in cached.doseMarkers {
            Self.logger.debug("   - Marker: \(marker.date.formatted()), amount: \(marker.amount)")
        }
    }

    /// Refresh full chart dataset (all time) - only happens once per session
    /// - Parameter config: Configuration containing user, profiles, services, context, and selected period
    @MainActor
    func refreshChartDataset(config: RefreshConfig) async {
        Self.logger.info("🔄 Generating FULL chart dataset (all time)...")
        Self.logger.debug("  📋 Profiles count: \(config.profiles.count)")
        let refreshStartTime = Date()

        let profilesWithDoses = await fetchAllDoses(config: config)
        Self.logger.debug("  📊 profilesWithDoses count: \(profilesWithDoses.count)")

        guard !profilesWithDoses.isEmpty else {
            Self.logger.warning("  ⚠️ No profiles with doses found - chart will be empty")
            await MainActor.run {
                self.fullChartDataset = nil
                self.chartDataset = nil
            }
            return
        }

        for (profile, doses) in profilesWithDoses {
            Self.logger.debug(
                """
                  📍 Profile '\(profile.genericName)': \(doses.count) doses
                     - medicationType: '\(profile.medicationType)'
                     - medication: \(profile.medication?.displayName ?? "nil")
                """
            )
        }

        let fullDataset = await generateFullDataset(
            user: config.user,
            profilesWithDoses: profilesWithDoses,
            chartService: config.chartService
        )

        Self.logger.debug("  📈 Generated dataset: \(fullDataset != nil ? "success" : "nil")")
        if let dataset = fullDataset {
            Self.logger.debug("    - Curves: \(dataset.concentrationCurves.count)")
            Self.logger.debug("    - Markers: \(dataset.doseMarkers.count)")
            Self.logger.debug("    - Total points: \(dataset.concentrationCurves.reduce(0) { $0 + $1.points.count })")
        }

        await updateAndPersistDataset(
            fullDataset,
            selectedPeriod: config.selectedPeriod,
            totalTime: Date().timeIntervalSince(refreshStartTime)
        )
    }

    /// Fetch all doses for medication profiles
    /// - Parameter config: Configuration containing profiles, dose service, and context
    /// - Returns: Array of tuples containing medication profiles and their doses
    @MainActor
    private func fetchAllDoses(config: RefreshConfig) async -> [(MedicationProfile, [Dose])] {
        let doseFetchStart = Date()
        var profilesWithDoses: [(MedicationProfile, [Dose])] = []

        for profile in config.profiles {
            let doses = config.doseService.fetchDoses(for: profile, within: .all, context: config.context)
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
    @MainActor
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

        // Debug: Log filtered data details
        if let filtered = chartDataset {
            let totalPoints = filtered.concentrationCurves.reduce(0) { $0 + $1.points.count }
            Self.logger.debug(
                """
                  📊 Filtered dataset:
                     - Curves: \(filtered.concentrationCurves.count)
                     - Total points: \(totalPoints)
                     - Markers: \(filtered.doseMarkers.count)
                """
            )
            // Log curve details
            for (index, curve) in filtered.concentrationCurves.enumerated() {
                if let firstPoint = curve.points.first, let lastPoint = curve.points.last {
                    Self.logger.debug(
                        """
                           - Curve \(index): \(curve.points.count) pts, \
                        \(firstPoint.date.formatted()) to \(lastPoint.date.formatted())
                        """
                    )
                } else {
                    Self.logger.debug("     - Curve \(index): 0 points (empty after filter)")
                }
            }
            // Log marker details
            for marker in filtered.doseMarkers {
                Self.logger.debug("     - Marker: \(marker.date.formatted()), amount: \(marker.amount)")
            }
        }
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

    // MARK: - Real Adherence Calculations

    /// Calculate real adherence trend data using ScheduleService
    /// - Parameters:
    ///   - user: User to generate trend data for
    ///   - profiles: Medication profiles to analyze
    ///   - context: ModelContext for fetching schedules
    /// - Returns: Array of adherence trend points for the last 4 weeks
    func generateTrendData(
        for user: User,
        profiles: [MedicationProfile],
        context: ModelContext
    ) -> [AdherenceTrendPoint] {
        let calendar = Calendar.current
        let now = Date()
        var trendData: [AdherenceTrendPoint] = []

        // Get all dose schedules for the user's profiles
        let schedules = profiles.compactMap { $0.schedules?.first }

        // Create ScheduleService with the provided context (even if no schedules yet)
        let scheduleService = ScheduleService(context: context)

        // Calculate adherence for each of the last 4 weeks
        for weekOffset in 0..<4 {
            guard let weekEndDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now),
                let weekStartDate = calendar.date(byAdding: .day, value: -6, to: weekEndDate)
            else { continue }

            // Calculate combined adherence across all schedules for this week
            var totalTaken = 0
            var totalMissed = 0

            for schedule in schedules {
                let metrics = scheduleService.calculateAdherence(
                    for: schedule,
                    from: weekStartDate,
                    to: weekEndDate
                )
                totalTaken += metrics.totalTaken
                totalMissed += metrics.totalMissed
            }

            // Calculate overall adherence for the week
            let adherenceRate: Double
            if totalTaken + totalMissed > 0 {
                adherenceRate = Double(totalTaken) / Double(totalTaken + totalMissed)
            } else {
                adherenceRate = 0.0
            }

            trendData.append(
                AdherenceTrendPoint(
                    date: weekEndDate,
                    adherenceRate: adherenceRate,
                    period: "Week \(4 - weekOffset)"
                ))
        }

        return trendData.sorted { $0.date < $1.date }
    }

    /// Calculate real missed dose patterns using ScheduleService
    /// - Parameters:
    ///   - user: User to generate missed dose patterns for
    ///   - profiles: Medication profiles to analyze
    ///   - context: ModelContext for fetching schedules
    /// - Returns: Array of missed dose patterns grouped by day of week
    func generateMissedDosePatterns(
        for user: User,
        profiles: [MedicationProfile],
        context: ModelContext
    ) -> [MissedDosePattern] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: now) ?? now

        // Get all dose schedules
        let schedules = profiles.compactMap { $0.schedules?.first }
        guard !schedules.isEmpty else {
            return []  // No schedules = no missed dose data
        }

        // Collect all missed doses from all schedules
        var missedDosesByDay: [String: (date: Date, count: Int)] = [:]

        for schedule in schedules {
            // Get missed scheduled doses in the time period
            let allScheduledDoses = schedule.scheduledDoses ?? []
            let scheduledDoses = allScheduledDoses.filter { dose in
                dose.scheduledTime >= startDate
                    && dose.scheduledTime <= now
                    && dose.status == .missed
            }

            for dose in scheduledDoses {
                let dayOfWeek = calendar.weekdaySymbols[calendar.component(.weekday, from: dose.scheduledTime) - 1]

                if var existing = missedDosesByDay[dayOfWeek] {
                    existing.count += 1
                    missedDosesByDay[dayOfWeek] = existing
                } else {
                    missedDosesByDay[dayOfWeek] = (date: dose.scheduledTime, count: 1)
                }
            }
        }

        // Convert to MissedDosePattern array and sort by count (descending)
        return missedDosesByDay.map { dayOfWeek, value in
            MissedDosePattern(
                date: value.date,
                dayOfWeek: dayOfWeek,
                missedCount: value.count
            )
        }.sorted { $0.missedCount > $1.missedCount }
    }
}
