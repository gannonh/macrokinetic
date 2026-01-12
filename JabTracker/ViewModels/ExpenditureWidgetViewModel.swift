//
//  ExpenditureWidgetViewModel.swift
//  JabTracker
//
//  ViewModel for ExpenditureWidget - provides TDEE expenditure data.
//

import Foundation
import OSLog
import SwiftData

/// Data point for daily TDEE chart
struct ExpenditureDayData: Identifiable {
    let id = UUID()
    let day: Int  // 0-6 representing days
    let value: Double  // TDEE value
}

/// ViewModel providing TDEE expenditure data for ExpenditureWidget
@MainActor
@Observable
final class ExpenditureWidgetViewModel {

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "ExpenditureWidgetViewModel"
    )

    private let context: ModelContext

    // MARK: - Published State

    /// Whether data is currently loading
    private(set) var isLoading: Bool = false

    /// Current TDEE value (nil if not calculated)
    private(set) var tdee: Double?

    /// Daily TDEE values for last 7 days (for sparkline chart)
    private(set) var dailyValues: [ExpenditureDayData] = []

    /// Whether TDEE data exists
    var hasData: Bool {
        tdee != nil
    }

    // MARK: - Initialization

    /// Initialize with model context
    /// - Parameter context: ModelContext for fetching user data
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Data Loading

    /// Load TDEE data from user's active NutritionGoal and TDEESnapshots
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Get user and active nutrition goal
        guard let user = context.fetchCurrentUser(logger: Self.logger),
            let activeGoal = user.activeNutritionGoal
        else {
            tdee = nil
            dailyValues = []
            Self.logger.debug("No user or active nutrition goal found")
            return
        }

        // Get current TDEE: prefer lastCalculatedTDEE, fall back to initialEstimatedTDEE
        if let lastCalculated = activeGoal.lastCalculatedTDEE {
            tdee = lastCalculated
        } else if let initial = activeGoal.initialEstimatedTDEE {
            tdee = initial
        } else {
            tdee = nil
        }

        // Load 7 days of TDEE snapshots for sparkline
        await loadDailyValues(for: activeGoal)

        Self.logger.debug("Loaded TDEE: \(self.tdee ?? 0), dailyValues: \(self.dailyValues.count)")
    }

    private func loadDailyValues(for goal: NutritionGoal) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Calculate date range for last 7 days
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: today) else {
            Self.logger.error("Unexpected: Failed to calculate start date for 7-day range")
            dailyValues = []
            return
        }

        // Fetch TDEESnapshots for the date range
        let descriptor = FetchDescriptor<TDEESnapshot>(
            predicate: #Predicate { snapshot in
                snapshot.timestamp >= startDate
            },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )

        do {
            let snapshots = try context.fetch(descriptor)

            // Build daily values array
            var values: [ExpenditureDayData] = []
            let fallbackTdee = tdee ?? 2000

            for dayIndex in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: dayIndex - 6, to: today) else {
                    continue
                }
                let dayStart = calendar.startOfDay(for: date)

                // Find snapshot for this day
                if let snapshot = snapshots.first(where: {
                    calendar.isDate($0.timestamp, inSameDayAs: dayStart)
                }) {
                    values.append(ExpenditureDayData(day: dayIndex, value: snapshot.tdeeValue))
                } else {
                    // Use fallback TDEE if no snapshot
                    values.append(ExpenditureDayData(day: dayIndex, value: fallbackTdee))
                }
            }

            dailyValues = values
        } catch {
            Self.logger.error("Failed to fetch TDEE snapshots: \(error.localizedDescription)")
            // Create fallback with constant TDEE
            let fallbackTdee = tdee ?? 2000
            dailyValues = (0..<7).map { ExpenditureDayData(day: $0, value: fallbackTdee) }
        }
    }
}

// MARK: - Preview Support

extension ExpenditureWidgetViewModel {
    /// Preview data for SwiftUI previews
    static var preview: ExpenditureWidgetViewModel {
        let context = PreviewHelpers.previewContext()
        return ExpenditureWidgetViewModel(context: context)
    }
}
