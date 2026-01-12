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
    private let context: ModelContext

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
    ///   - context: ModelContext for fetching user data
    init(mealLogService: MealLogService, context: ModelContext) {
        self.mealLogService = mealLogService
        self.context = context
    }

    // MARK: - Data Loading

    /// Load 7-day energy balance data
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Get user and TDEE
        guard let user = context.fetchCurrentUser(logger: Self.logger),
            let activeGoal = user.activeNutritionGoal,
            let userTdee = activeGoal.lastCalculatedTDEE ?? activeGoal.initialEstimatedTDEE
        else {
            // Cannot calculate balance without TDEE
            dailyIntake = []
            dailyBalances = []
            tdee = 0
            averageDailyBalance = 0
            isDeficit = true
            Self.logger.debug("No TDEE available for energy balance calculation")
            return
        }

        // Store TDEE for reference line
        tdee = userTdee

        // Calculate balance for each of the last 7 days
        var intake: [Double] = []
        var balances: [Double] = []
        var totalBalance: Double = 0
        var failedDays = 0

        for daysAgo in stride(from: 6, through: 0, by: -1) {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            do {
                let totals = try await mealLogService.getDailyTotals(for: date)
                let consumed = totals.calories
                intake.append(consumed)
                let balance = consumed - userTdee  // Negative = deficit, positive = surplus
                balances.append(balance)
                totalBalance += balance
            } catch {
                // Distinguish between "no data" and "fetch error"
                // SwiftData throws when no matching records exist, but we should still log at error level
                // to ensure actual DB errors are visible in production logs
                Self.logger.error("Failed to load meal data for \(date): \(error.localizedDescription)")
                failedDays += 1
                intake.append(0)
                let balance = 0 - userTdee
                balances.append(balance)
                totalBalance += balance
            }
        }

        dailyIntake = intake
        dailyBalances = balances
        daysWithLoadingErrors = failedDays
        // Calculate average daily balance (signed: negative for deficit)
        let averageBalance = totalBalance / Double(balances.count)
        averageDailyBalance = Int(averageBalance)  // Keep sign for display
        isDeficit = totalBalance < 0

        Self.logger.debug(
            "Loaded energy balance: avgDaily=\(self.averageDailyBalance), deficit=\(self.isDeficit), failedDays=\(failedDays)"
        )
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
