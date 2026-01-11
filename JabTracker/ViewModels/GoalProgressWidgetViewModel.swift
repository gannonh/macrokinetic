//
//  GoalProgressWidgetViewModel.swift
//  JabTracker
//
//  ViewModel for GoalProgressWidget - provides daily nutrition progress data.
//

import Foundation
import OSLog
import SwiftData

/// ViewModel providing daily nutrition progress for GoalProgressWidget
@MainActor
@Observable
final class GoalProgressWidgetViewModel {

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "GoalProgressWidgetViewModel"
    )

    private let mealLogService: MealLogService
    private let context: ModelContext

    // MARK: - Published State

    /// Whether data is currently loading
    private(set) var isLoading: Bool = false

    /// Progress percentage (0.0 to 1.0+)
    private(set) var progressPercentage: Double = 0

    /// Target percentage (usually 1.0)
    private(set) var targetPercentage: Double = 1.0

    /// Whether valid data exists
    var hasData: Bool {
        // We always have some form of data once loaded
        true
    }

    /// Display percentage as integer
    var displayPercentage: Int {
        Int(progressPercentage * 100)
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

    /// Load today's nutrition progress
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Get user's calorie target
        var calorieTarget: Double = 2000  // Default

        if let user = context.fetchCurrentUser(logger: Self.logger) {
            if let activeGoal = user.activeNutritionGoal {
                calorieTarget = activeGoal.dailyCalorieTarget
            } else {
                calorieTarget = user.dailyCalorieGoal
            }
        }

        // Get today's consumed calories
        do {
            let totals = try await mealLogService.getDailyTotals(for: Date())
            let consumed = totals.calories

            // Calculate progress percentage
            if calorieTarget > 0 {
                progressPercentage = consumed / calorieTarget
            } else {
                progressPercentage = 0
            }
        } catch {
            Self.logger.error("Failed to load daily totals: \(error)")
            progressPercentage = 0
        }

        Self.logger.debug("Loaded goal progress: \(self.displayPercentage)%")
    }
}

// MARK: - Preview Support

extension GoalProgressWidgetViewModel {
    /// Preview data for SwiftUI previews
    static var preview: GoalProgressWidgetViewModel {
        let context = PreviewHelpers.previewContext()
        let service = MealLogService(context: context)
        return GoalProgressWidgetViewModel(mealLogService: service, context: context)
    }
}
