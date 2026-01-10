//
//  DailyNutritionHeroViewModel.swift
//  JabTracker
//
//  ViewModel for DailyNutritionHeroWidget - provides today's nutrition data.
//

import Foundation
import OSLog
import SwiftData

/// ViewModel providing today's nutrition consumption and targets for DailyNutritionHeroWidget
@MainActor
@Observable
final class DailyNutritionHeroViewModel {

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "DailyNutritionHeroViewModel"
    )

    private let mealLogService: MealLogService
    private let context: ModelContext

    // MARK: - Published State

    /// Whether data is currently loading
    private(set) var isLoading: Bool = false

    /// Today's consumed calories
    private(set) var caloriesConsumed: Int = 0

    /// Today's consumed protein in grams
    private(set) var proteinConsumed: Int = 0

    /// Today's consumed carbs in grams
    private(set) var carbsConsumed: Int = 0

    /// Today's consumed fat in grams
    private(set) var fatConsumed: Int = 0

    /// Daily calorie target
    private(set) var caloriesTarget: Int = 2000

    /// Daily protein target in grams
    private(set) var proteinTarget: Int = 150

    /// Daily carbs target in grams
    private(set) var carbsTarget: Int = 200

    /// Daily fat target in grams
    private(set) var fatTarget: Int = 65

    /// Remaining calories (target - consumed, minimum 0)
    var caloriesRemaining: Int {
        max(0, caloriesTarget - caloriesConsumed)
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

    /// Load today's nutrition data and user targets
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Load today's consumption
        await loadTodayConsumption()

        // Load user targets
        loadUserTargets()

        Self.logger.debug(
            "Loaded daily nutrition: \(self.caloriesConsumed)/\(self.caloriesTarget) kcal"
        )
    }

    /// Load today's nutrition totals from meal log service
    private func loadTodayConsumption() async {
        do {
            let totals = try await mealLogService.getDailyTotals(for: Date())
            caloriesConsumed = Int(totals.calories)
            proteinConsumed = Int(totals.protein)
            carbsConsumed = Int(totals.carbs)
            fatConsumed = Int(totals.fat)
        } catch {
            Self.logger.error("Failed to load daily totals: \(error)")
            // Keep zeros on error
        }
    }

    /// Load macro targets from user's active NutritionGoal or fallback to User's direct goals
    private func loadUserTargets() {
        // First try to find active NutritionGoal via User
        if let user = fetchUser() {
            if let activeGoal = user.activeNutritionGoal {
                // Use active NutritionGoal targets (may include per-day macros)
                let macros = activeGoal.macroTargetsForDate(Date())
                caloriesTarget = Int(macros.calories)
                proteinTarget = Int(macros.proteinGrams)
                carbsTarget = Int(macros.carbsGrams)
                fatTarget = Int(macros.fatGrams)
            } else {
                // Fallback to User's direct macro goals
                caloriesTarget = Int(user.dailyCalorieGoal)
                proteinTarget = Int(user.dailyProteinGoal)
                carbsTarget = Int(user.dailyCarbGoal)
                fatTarget = Int(user.dailyFatGoal)
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

extension DailyNutritionHeroViewModel {
    /// Preview data for SwiftUI previews
    static var preview: DailyNutritionHeroViewModel {
        // Create a minimal mock for preview purposes
        // In production, DailyMockData.sample is used directly by the widget for previews
        let schema = Schema([User.self, FoodEntry.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        let service = MealLogService(context: context)
        return DailyNutritionHeroViewModel(mealLogService: service, context: context)
    }
}
