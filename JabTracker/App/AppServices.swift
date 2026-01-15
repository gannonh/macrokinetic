import Foundation
import SwiftData
import SwiftUI

/// Centralized service coordinator for app-wide service access.
///
/// Provides singleton access to core services that require dependency injection and ModelContext.
/// This pattern ensures services are initialized once with proper dependencies and accessible
/// throughout the app without prop drilling.
@MainActor
final class AppServices: ObservableObject {
    /// Shared instance for app-wide access.
    /// nonisolated allows access from any context while instance methods remain MainActor isolated.
    nonisolated static let shared = AppServices()

    /// Schedule service for dose schedule management
    @Published private(set) var scheduleService: ScheduleService?

    /// Notification service for dose reminder notifications
    @Published private(set) var notificationService: NotificationService?

    /// Food service for food search across local database and API
    @Published private(set) var foodService: FoodService?

    /// Meal log service for food entry CRUD operations
    @Published private(set) var mealLogService: MealLogService?

    /// Custom food service for user-created food CRUD operations
    @Published private(set) var customFoodService: CustomFoodService?

    /// Metrics service for ALL body metrics (weight, height, body fat, circumferences) and HealthKit sync
    @Published private(set) var metricsService: MetricsService?

    /// Progress photo service for photo tracking
    @Published private(set) var progressPhotoService: ProgressPhotoService?

    /// Calorie adjustment service for burned calories and rollover calculations
    @Published private(set) var calorieAdjustmentService: CalorieAdjustmentService?

    /// TDEE service for TDEE snapshots and adaptive calculations
    @Published private(set) var tdeeService: TDEEService?

    /// Day status service for fasting day tracking
    @Published private(set) var dayStatusService: DayStatusService?

    private nonisolated init() {
        // Services will be initialized when ModelContext becomes available
    }

    /// Initialize services with ModelContext from the app's SwiftData container.
    ///
    /// This should be called once when the authenticated view appears and ModelContext is available.
    ///
    /// - Parameter modelContext: The ModelContext from the app's container
    func initialize(with modelContext: ModelContext) {
        // Only initialize once
        guard scheduleService == nil else { return }

        // Create ScheduleService with ModelContext
        let scheduleService = ScheduleService(context: modelContext)
        self.scheduleService = scheduleService

        // Create NotificationService with ScheduleService dependency
        let notificationService = NotificationService(scheduleService: scheduleService)
        self.notificationService = notificationService

        // Load persisted notification state
        notificationService.loadState()

        // Create CustomFoodService for user-created foods
        let customFoodService = CustomFoodService(context: modelContext)
        self.customFoodService = customFoodService

        // Create FoodService for food search (with CustomFoodService for categorized search)
        let foodService = FoodService(context: modelContext, customFoodService: customFoodService)
        self.foodService = foodService

        // Create MealLogService for meal logging
        let mealLogService = MealLogService(context: modelContext)
        self.mealLogService = mealLogService

        // Create CalorieAdjustmentService and configure providers
        let calorieAdjustmentService = CalorieAdjustmentService()
        calorieAdjustmentService.configureRolloverProvider(mealLogService: mealLogService)
        calorieAdjustmentService.configurePredictiveProvider(
            activeEnergyDataSource: HealthKitActiveEnergyDataSource()
        )
        self.calorieAdjustmentService = calorieAdjustmentService

        // Create MetricsService for ALL body metrics (weight, height, body fat, circumferences)
        let metricsService = MetricsService(context: modelContext)
        self.metricsService = metricsService

        // Create ProgressPhotoService for photo tracking
        let progressPhotoService = ProgressPhotoService(context: modelContext)
        self.progressPhotoService = progressPhotoService

        // Create DayStatusService for fasting day tracking (before TDEEService for dependency injection)
        let dayStatusService = DayStatusService(context: modelContext)
        self.dayStatusService = dayStatusService

        // Create TDEEService for TDEE snapshots and adaptive calculations
        // Inject DayStatusService so TDEE calculations can exclude fasting days
        let tdeeService = TDEEService(context: modelContext, dayStatusService: dayStatusService)
        self.tdeeService = tdeeService
    }

    /// Reset services (useful for testing or sign-out)
    func reset() {
        scheduleService = nil
        notificationService = nil
        foodService = nil
        mealLogService = nil
        customFoodService = nil
        metricsService = nil
        progressPhotoService = nil
        calorieAdjustmentService = nil
        tdeeService = nil
        dayStatusService = nil
    }
}

/// SwiftUI Environment key for AppServices
struct AppServicesKey: EnvironmentKey {
    static let defaultValue: AppServices = AppServices.shared
}

extension EnvironmentValues {
    var appServices: AppServices {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }
}
