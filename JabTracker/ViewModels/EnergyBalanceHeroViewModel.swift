//
//  EnergyBalanceHeroViewModel.swift
//  JabTracker
//
//  ViewModel for EnergyBalanceHeroWidget - provides 30-day energy balance data.
//

import Foundation
import OSLog
import SwiftData

/// Data point for daily calorie chart
struct DayCalories: Identifiable {
    /// Use date as stable identifier for animation continuity
    var id: Date { date }
    let date: Date
    let value: Double
}

/// ViewModel providing 30-day energy balance data for EnergyBalanceHeroWidget
@MainActor
@Observable
final class EnergyBalanceHeroViewModel {

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "EnergyBalanceHeroViewModel"
    )

    private let mealLogService: MealLogService
    private let context: ModelContext

    /// Number of days to display
    private let dayCount = 30

    // MARK: - Published State

    /// Whether data is currently loading
    private(set) var isLoading: Bool = false

    /// Daily calories for each of the last 30 days
    private(set) var dailyCalories: [DayCalories] = []

    /// Average daily expenditure (TDEE)
    private(set) var averageExpenditure: Double = 2000

    /// Average daily calorie target
    private(set) var averageTargets: Double = 1800

    /// Total nutrition (sum of all daily calories)
    private(set) var totalNutrition: Int = 0

    // MARK: - Initialization

    /// Initialize with meal log service and model context
    /// - Parameters:
    ///   - mealLogService: Service for fetching meal log data
    ///   - context: ModelContext for fetching user data
    init(mealLogService: MealLogService, context: ModelContext) {
        self.mealLogService = mealLogService
        self.context = context

        // Initialize with empty daily calories
        dailyCalories = createEmptyDailyCalories()
    }

    // MARK: - Data Loading

    /// Load 30 days of energy balance data
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Load daily calorie data
        await loadDailyCalories()

        // Load user targets and expenditure
        loadUserData()

        Self.logger.debug(
            """
            Loaded energy balance: total=\(self.totalNutrition), \
            exp=\(Int(self.averageExpenditure)), target=\(Int(self.averageTargets))
            """
        )
    }

    /// Create empty daily calories array with dates
    private func createEmptyDailyCalories() -> [DayCalories] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<dayCount).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            return DayCalories(date: date, value: 0)
        }
    }

    /// Load daily calorie totals for the last 30 days
    private func loadDailyCalories() async {
        let calendar = Calendar.current
        let today = Date()

        var newDailyCalories: [DayCalories] = []
        var newTotalNutrition = 0

        // Load data for each day (oldest to newest)
        for daysAgo in (0..<dayCount).reversed() {
            guard let dayDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                continue
            }

            do {
                let totals = try await mealLogService.getDailyTotals(for: dayDate)
                let calories = totals.calories
                newDailyCalories.append(DayCalories(date: dayDate, value: calories))
                newTotalNutrition += Int(calories)
            } catch {
                Self.logger.error("Failed to load totals for day \(-daysAgo): \(error)")
                // Add zero for this day on error
                newDailyCalories.append(DayCalories(date: dayDate, value: 0))
            }
        }

        dailyCalories = newDailyCalories
        totalNutrition = newTotalNutrition
    }

    /// Load expenditure and target data from user's NutritionGoal or User defaults
    private func loadUserData() {
        if let user = fetchUser() {
            if let activeGoal = user.activeNutritionGoal {
                // Use TDEE from active NutritionGoal for expenditure
                if let tdee = activeGoal.initialEstimatedTDEE ?? activeGoal.lastCalculatedTDEE {
                    averageExpenditure = tdee
                }

                // Use daily calorie target for targets
                averageTargets = activeGoal.dailyCalorieTarget
            } else {
                // Fallback to User's direct calorie goal for targets
                averageTargets = user.dailyCalorieGoal
                // Use a reasonable default for expenditure if no TDEE available
                // Expenditure defaults to targets + 500 (typical deficit)
                averageExpenditure = user.dailyCalorieGoal + 500
            }
        }
        // If no user found, keep default values
    }

    /// Fetch the current user from context
    private func fetchUser() -> User? {
        let descriptor = FetchDescriptor<User>()
        do {
            let users = try context.fetch(descriptor)
            return users.first
        } catch {
            Self.logger.error("Failed to fetch user: \(error)")
            return nil
        }
    }
}

// MARK: - Preview Support

extension EnergyBalanceHeroViewModel {
    /// Preview data for SwiftUI previews
    static var preview: EnergyBalanceHeroViewModel {
        let schema = Schema([User.self, FoodEntry.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        let service = MealLogService(context: context)
        return EnergyBalanceHeroViewModel(mealLogService: service, context: context)
    }
}
