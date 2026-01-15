//
//  EnergyBalanceWidgetViewModel.swift
//  JabTracker
//
//  ViewModel for EnergyBalanceWidget - provides 7-day energy balance data.
//

import Foundation
import OSLog
import SwiftData

/// ViewModel providing 7-day energy balance data for EnergyBalanceWidget
@MainActor
@Observable
final class EnergyBalanceWidgetViewModel {

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "EnergyBalanceWidgetViewModel"
    )

    private let mealLogService: MealLogService
    private let dayStatusService: DayStatusService?
    private let context: ModelContext

    /// Number of days to look back (excludes today)
    private let dayCount = 7

    // MARK: - Published State

    /// Whether data is currently loading
    private(set) var isLoading: Bool = false

    /// Daily intake values for 7 days (calories consumed)
    private(set) var dailyIntake: [Double] = []

    /// Daily balance values for 7 days (negative = deficit, positive = surplus)
    private(set) var dailyBalances: [Double] = []

    /// TDEE used for balance calculation (reference line value)
    private(set) var tdee: Double = 0

    /// Average daily balance over 7 days (signed: negative for deficit)
    private(set) var averageDailyBalance: Int = 0

    /// Whether the net balance is a deficit
    private(set) var isDeficit: Bool = true

    /// Number of days that failed to load (data may be incomplete)
    private(set) var daysWithLoadingErrors: Int = 0

    /// Whether valid data exists (TDEE is required)
    var hasData: Bool {
        !dailyBalances.isEmpty
    }

    // MARK: - Initialization

    /// Initialize with meal log service and model context
    /// - Parameters:
    ///   - mealLogService: Service for fetching meal log data
    ///   - dayStatusService: Service for fasting status (optional for backward compat)
    ///   - context: ModelContext for fetching user data
    init(mealLogService: MealLogService, dayStatusService: DayStatusService? = nil, context: ModelContext) {
        self.mealLogService = mealLogService
        self.dayStatusService = dayStatusService
        self.context = context
    }

    // MARK: - Data Loading

    /// Load 7-day energy balance data
    /// - Note: Excludes today (partial data) and days without food entries or fasting status
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Get user and TDEE
        guard let user = context.fetchCurrentUser(logger: Self.logger),
            let activeGoal = user.activeNutritionGoal,
            let userTdee = activeGoal.lastCalculatedTDEE ?? activeGoal.initialEstimatedTDEE
        else {
            clearData()
            return
        }

        // Store TDEE for reference line
        tdee = userTdee

        // Load daily balance data
        await loadDailyBalances(userTdee: userTdee)
    }

    /// Clear all data when requirements not met
    private func clearData() {
        dailyIntake = []
        dailyBalances = []
        tdee = 0
        averageDailyBalance = 0
        isDeficit = true
        Self.logger.debug("No TDEE available for energy balance calculation")
    }

    /// Load daily balance data for the lookback period
    private func loadDailyBalances(userTdee: Double) async {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        // Calculate date range: dayCount days ago up to (but not including) today
        guard let startDate = calendar.date(byAdding: .day, value: -dayCount, to: todayStart) else {
            return
        }

        // Get dates with meaningful data (food logged or marked as fasting)
        let meaningfulDates: Set<Date>
        do {
            meaningfulDates = try await getMeaningfulDates(from: startDate, to: todayStart)
        } catch {
            Self.logger.error("Failed to get meaningful dates: \(error.localizedDescription)")
            // Surface error state rather than silently showing empty data
            updateResults(intake: [], balances: [], totalBalance: 0, failedDays: dayCount)
            return
        }

        // Calculate balance for each day (excluding today)
        var intake: [Double] = []
        var balances: [Double] = []
        var totalBalance: Double = 0
        var failedDays = 0

        for daysAgo in (1...dayCount).reversed() {
            guard let dayDate = calendar.date(byAdding: .day, value: -daysAgo, to: todayStart) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: dayDate)

            // Skip days without meaningful data (no food entries and not fasting)
            guard meaningfulDates.contains(dayStart) else { continue }

            do {
                let totals = try await mealLogService.getDailyTotals(for: dayDate)
                let consumed = totals.calories
                intake.append(consumed)
                let balance = consumed - userTdee
                balances.append(balance)
                totalBalance += balance
            } catch {
                Self.logger.error("Failed to load meal data for \(dayDate): \(error.localizedDescription)")
                failedDays += 1
            }
        }

        updateResults(intake: intake, balances: balances, totalBalance: totalBalance, failedDays: failedDays)
    }

    /// Get dates with meaningful data from the service
    /// - Throws: Error if the underlying service call fails
    private func getMeaningfulDates(from startDate: Date, to endDate: Date) async throws -> Set<Date> {
        try await mealLogService.getDatesWithMeaningfulData(
            from: startDate, to: endDate, dayStatusService: dayStatusService
        )
    }

    /// Update published results from calculated values
    private func updateResults(intake: [Double], balances: [Double], totalBalance: Double, failedDays: Int) {
        dailyIntake = intake
        dailyBalances = balances
        daysWithLoadingErrors = failedDays

        if !balances.isEmpty {
            averageDailyBalance = Int(totalBalance / Double(balances.count))
        } else {
            averageDailyBalance = 0
        }
        isDeficit = totalBalance < 0

        Self.logger.debug("Loaded \(balances.count)/\(self.dayCount) days, avgDaily=\(self.averageDailyBalance)")
    }
}

// MARK: - Preview Support

extension EnergyBalanceWidgetViewModel {
    /// Preview data for SwiftUI previews
    static var preview: EnergyBalanceWidgetViewModel {
        let context = PreviewHelpers.previewContext()
        let service = MealLogService(context: context)
        return EnergyBalanceWidgetViewModel(mealLogService: service, context: context)
    }
}
