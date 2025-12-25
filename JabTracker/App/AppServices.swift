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

    /// Weight service for weight tracking and HealthKit sync
    @Published private(set) var weightService: WeightService?

    /// Metrics service for body measurements and HealthKit sync
    @Published private(set) var metricsService: MetricsService?

    /// Progress photo service for photo tracking
    @Published private(set) var progressPhotoService: ProgressPhotoService?

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

        // Create WeightService for weight tracking
        let weightService = WeightService(context: modelContext)
        self.weightService = weightService

        // Create MetricsService for body measurements
        let metricsService = MetricsService(context: modelContext)
        self.metricsService = metricsService

        // Create ProgressPhotoService for photo tracking
        let progressPhotoService = ProgressPhotoService(context: modelContext)
        self.progressPhotoService = progressPhotoService
    }

    /// Reset services (useful for testing or sign-out)
    func reset() {
        scheduleService = nil
        notificationService = nil
        foodService = nil
        mealLogService = nil
        customFoodService = nil
        weightService = nil
        metricsService = nil
        progressPhotoService = nil
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
