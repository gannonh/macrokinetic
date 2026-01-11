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

    /// Daily balance values for 7 days (negative = deficit, positive = surplus)
    private(set) var dailyBalances: [Double] = []

    /// Net balance over 7 days (absolute value)
    private(set) var netBalance: Int = 0

    /// Whether the net balance is a deficit
    private(set) var isDeficit: Bool = true

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
            let tdee = activeGoal.lastCalculatedTDEE ?? activeGoal.initialEstimatedTDEE
        else {
            // Cannot calculate balance without TDEE
            dailyBalances = []
            netBalance = 0
            isDeficit = true
            Self.logger.debug("No TDEE available for energy balance calculation")
            return
        }

        // Calculate balance for each of the last 7 days
        var balances: [Double] = []
        var totalBalance: Double = 0

        for daysAgo in stride(from: 6, through: 0, by: -1) {
            let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
            do {
                let totals = try await mealLogService.getDailyTotals(for: date)
                let consumed = totals.calories
                let balance = consumed - tdee  // Negative = deficit, positive = surplus
                balances.append(balance)
                totalBalance += balance
            } catch {
                // No food logged = 0 calories consumed = full TDEE deficit
                let balance = 0 - tdee
                balances.append(balance)
                totalBalance += balance
            }
        }

        dailyBalances = balances
        netBalance = Int(abs(totalBalance))
        isDeficit = totalBalance < 0

        Self.logger.debug(
            "Loaded energy balance: net=\(self.netBalance), deficit=\(self.isDeficit)"
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
