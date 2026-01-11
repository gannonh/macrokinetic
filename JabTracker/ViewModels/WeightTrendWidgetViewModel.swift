//
//  WeightTrendWidgetViewModel.swift
//  JabTracker
//
//  ViewModel for WeightTrendWidget - provides 7-day weight data.
//

import Foundation
import OSLog
import SwiftData

/// ViewModel providing 7-day weight data for WeightTrendWidget
@MainActor
@Observable
final class WeightTrendWidgetViewModel {

    // MARK: - Types

    /// Data point for weight trend chart
    struct DataPoint: Identifiable {
        let id = UUID()
        let day: Int  // 0-6 representing days (oldest to newest)
        let weight: Double
    }

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "WeightTrendWidgetViewModel"
    )

    private let metricsService: MetricsService
    private let context: ModelContext

    // MARK: - Published State

    /// Whether data is currently loading
    private(set) var isLoading: Bool = false

    /// Weight data points for chart (oldest to newest)
    private(set) var dataPoints: [DataPoint] = []

    /// Latest weight value (in user's preferred unit)
    private(set) var latestWeight: Double?

    /// Weight unit (lbs or kg)
    private(set) var unit: String = "lbs"

    /// Whether any weight data exists
    var hasData: Bool {
        !dataPoints.isEmpty
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

    /// Load 7-day weight data and user preferences
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Get user's weight unit preference
        loadUserPreferences()

        // Load weight entries for last 7 days
        await loadWeightEntries()

        Self.logger.debug(
            "Loaded weight data: \(self.dataPoints.count) points, latest=\(self.latestWeight ?? 0)"
        )
    }

    /// Load user preferences (weight unit)
    private func loadUserPreferences() {
        if let user = context.fetchCurrentUser(logger: Self.logger) {
            unit = user.weightUnit
        }
    }

    /// Load weight entries from the last 7 days
    private func loadWeightEntries() async {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) else {
            return
        }

        do {
            let entries = try await metricsService.getWeightEntries(from: startDate, to: endDate)

            // Sort entries oldest to newest
            let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }

            // Map to data points with day indices
            dataPoints = sortedEntries.enumerated().map { index, entry in
                let weight = unit == "lbs" ? entry.weightInLbs : entry.weightKg
                return DataPoint(day: index, weight: weight)
            }

            // Set latest weight (most recent entry)
            if let latest = sortedEntries.last {
                latestWeight = unit == "lbs" ? latest.weightInLbs : latest.weightKg
            }
        } catch {
            Self.logger.error("Failed to load weight entries: \(error)")
            dataPoints = []
            latestWeight = nil
        }
    }
}

// MARK: - Preview Support

extension WeightTrendWidgetViewModel {
    /// Preview data for SwiftUI previews
    static var preview: WeightTrendWidgetViewModel {
        let context = PreviewHelpers.previewContext()
        let service = MetricsService(context: context)
        return WeightTrendWidgetViewModel(metricsService: service, context: context)
    }
}
