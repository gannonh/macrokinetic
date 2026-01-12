//
//  WeeklyNutritionHeroViewModel.swift
//  JabTracker
//
//  ViewModel for WeeklyNutritionHeroWidget - provides 7-day nutrition data.
//

import Foundation
import OSLog
import SwiftData

/// ViewModel providing 7-day nutrition data for WeeklyNutritionHeroWidget
@MainActor
@Observable
final class WeeklyNutritionHeroViewModel {

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "WeeklyNutritionHeroViewModel"
    )

    private let mealLogService: MealLogService
    private let context: ModelContext

    // MARK: - Published State

    /// Whether data is currently loading
    private(set) var isLoading: Bool = false

    /// Daily calories for each day of the week (0=Monday, 6=Sunday)
    private(set) var calories: [Double] = Array(repeating: 0, count: 7)

    /// Daily protein for each day of the week (0=Monday, 6=Sunday)
    private(set) var protein: [Double] = Array(repeating: 0, count: 7)

    /// Daily carbs for each day of the week (0=Monday, 6=Sunday)
    private(set) var carbs: [Double] = Array(repeating: 0, count: 7)

    /// Daily fat for each day of the week (0=Monday, 6=Sunday)
    private(set) var fat: [Double] = Array(repeating: 0, count: 7)

    /// Daily calorie target
    private(set) var caloriesTarget: Double = 2000

    /// Daily protein target in grams
    private(set) var proteinTarget: Double = 150

    /// Daily carbs target in grams
    private(set) var carbsTarget: Double = 200

    /// Daily fat target in grams
    private(set) var fatTarget: Double = 65

    /// Today's index in the week (0=Monday, 6=Sunday)
    private(set) var todayIndex: Int = 0

    /// Number of days that failed to load (data may be incomplete)
    private(set) var daysWithLoadingErrors: Int = 0

    // MARK: - Initialization

    /// Initialize with meal log service and model context
    /// - Parameters:
    ///   - mealLogService: Service for fetching meal log data
    ///   - context: ModelContext for fetching user data
    init(mealLogService: MealLogService, context: ModelContext) {
        self.mealLogService = mealLogService
        self.context = context
        self.todayIndex = Self.calculateTodayIndex()
    }

    // MARK: - Data Loading

    /// Load 7 days of nutrition data and user targets
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Calculate today's index in the week
        todayIndex = Self.calculateTodayIndex()

        // Load week's consumption data
        await loadWeekConsumption()

        // Load user targets
        loadUserTargets()

        Self.logger.debug(
            "Loaded weekly nutrition: today=\(self.todayIndex), totals=\(Int(self.calories.reduce(0, +))) kcal"
        )
    }

    /// Calculate today's index in the week (0=Monday, 6=Sunday)
    private static func calculateTodayIndex() -> Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Convert from Apple's 1=Sunday format to 0=Monday format
        return weekday == 1 ? 6 : weekday - 2
    }

    /// Get the start of the current week (Monday at 00:00)
    private func startOfWeek() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let daysFromMonday = Self.calculateTodayIndex()
        return calendar.date(
            byAdding: .day,
            value: -daysFromMonday,
            to: calendar.startOfDay(for: today)
        ) ?? calendar.startOfDay(for: today)
    }

    /// Load nutrition totals for each day of the current week
    private func loadWeekConsumption() async {
        let calendar = Calendar.current
        let weekStart = startOfWeek()

        // Reset arrays
        var newCalories = Array(repeating: 0.0, count: 7)
        var newProtein = Array(repeating: 0.0, count: 7)
        var newCarbs = Array(repeating: 0.0, count: 7)
        var newFat = Array(repeating: 0.0, count: 7)
        var failedDays = 0

        // Load data for each day up to and including today
        for dayIndex in 0...todayIndex {
            guard let dayDate = calendar.date(byAdding: .day, value: dayIndex, to: weekStart) else {
                continue
            }

            do {
                let totals = try await mealLogService.getDailyTotals(for: dayDate)
                newCalories[dayIndex] = totals.calories
                newProtein[dayIndex] = totals.protein
                newCarbs[dayIndex] = totals.carbs
                newFat[dayIndex] = totals.fat
            } catch {
                Self.logger.error("Failed to load totals for day \(dayIndex): \(error.localizedDescription)")
                failedDays += 1
                // Keep zeros for this day on error - tracked by daysWithLoadingErrors
            }
        }

        // Future days remain 0 (already initialized)

        calories = newCalories
        protein = newProtein
        carbs = newCarbs
        fat = newFat
        daysWithLoadingErrors = failedDays
    }

    /// Load macro targets from user's active NutritionGoal or fallback to User's direct goals
    private func loadUserTargets() {
        if let user = context.fetchCurrentUser(logger: Self.logger) {
            if let activeGoal = user.activeNutritionGoal {
                // Use active NutritionGoal targets
                // For weekly widget, use today's targets (simplification)
                let macros = activeGoal.macroTargetsForDate(Date())
                caloriesTarget = macros.calories
                proteinTarget = macros.proteinGrams
                carbsTarget = macros.carbsGrams
                fatTarget = macros.fatGrams
            } else {
                // Fallback to User's direct macro goals
                caloriesTarget = user.dailyCalorieGoal
                proteinTarget = user.dailyProteinGoal
                carbsTarget = user.dailyCarbGoal
                fatTarget = user.dailyFatGoal
            }
        }
        // If no user found, keep default values
    }

}

// MARK: - Preview Support

extension WeeklyNutritionHeroViewModel {
    /// Preview data for SwiftUI previews
    static var preview: WeeklyNutritionHeroViewModel {
        let context = PreviewHelpers.previewContext()
        let service = MealLogService(context: context)
        return WeeklyNutritionHeroViewModel(mealLogService: service, context: context)
    }
}
