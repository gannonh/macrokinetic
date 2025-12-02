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
    /// Shared instance for app-wide access
    static let shared = AppServices()

    /// Schedule service for dose schedule management
    @Published private(set) var scheduleService: ScheduleService?

    /// Notification service for dose reminder notifications
    @Published private(set) var notificationService: NotificationService?

    private init() {
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
    }

    /// Reset services (useful for testing or sign-out)
    func reset() {
        scheduleService = nil
        notificationService = nil
    }
}

/// SwiftUI Environment key for AppServices
struct AppServicesKey: EnvironmentKey {
    @MainActor
    static let defaultValue: AppServices = AppServices.shared
}

extension EnvironmentValues {
    var appServices: AppServices {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }
}
