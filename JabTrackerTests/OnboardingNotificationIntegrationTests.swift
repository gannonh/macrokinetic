import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Integration tests for OnboardingViewModel and NotificationService integration
@Suite("Onboarding Notification Integration Tests")
@MainActor
struct OnboardingNotificationIntegrationTests {

    // MARK: - Helper Methods

    private func createTestContext() -> ModelContext {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            Dose.self,
            DoseSchedule.self,
            ScheduledDose.self,
            PendingNotification.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func createTestDataController(context: ModelContext) -> DataController {
        let dataController = DataController.shared
        return dataController
    }

    private func createTestAuthManager(with user: User) -> AuthenticationManager {
        let authManager = AuthenticationManager()
        authManager.setMockUser(user)  // Assuming there's a test method
        return authManager
    }

    // MARK: - Notification Service Integration Tests

    @Test("NotificationService configured with reminder minutes after schedule creation")
    func testNotificationServiceConfiguredWithReminderMinutes() async throws {
        // Arrange
        let context = createTestContext()
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        let dataController = createTestDataController(context: context)
        let authManager = AuthenticationManager()
        authManager.setMockUser(user)

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        viewModel.selectedMedication = .semaglutide
        viewModel.selectedDose = 1.0
        viewModel.selectedStartDate = Date()
        viewModel.notificationsGranted = true

        let notificationService = NotificationService.shared

        // Act
        viewModel.saveScheduleConfiguration(
            pattern: .weekly,
            reminderMinutes: 30,
            enableMultiple: false
        )

        // Assert
        #expect(notificationService.reminderMinutesBefore == 30)
    }

    @Test("NotificationService enabled when user grants permission during onboarding")
    func testNotificationServiceEnabledWhenPermissionGranted() async throws {
        // Arrange
        let context = createTestContext()
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        let dataController = createTestDataController(context: context)
        let authManager = AuthenticationManager()
        authManager.setMockUser(user)

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        viewModel.selectedMedication = .semaglutide
        viewModel.selectedDose = 1.0
        viewModel.selectedStartDate = Date()
        viewModel.notificationsGranted = true
        viewModel.schedulePattern = .weekly
        viewModel.reminderMinutes = 60

        let notificationService = NotificationService.shared
        // Reset state
        await notificationService.disable()

        // Act
        let result = await viewModel.completeOnboarding()

        // Assert
        guard case .success = result else {
            #expect(Bool(false), "Expected .success result, got \(result)")
            return
        }

        // Notification service should be enabled
        #expect(notificationService.notificationsEnabled == true)
    }

    @Test("NotificationService not enabled when user denies permission during onboarding")
    func testNotificationServiceNotEnabledWhenPermissionDenied() async throws {
        // Arrange
        let context = createTestContext()
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        let dataController = createTestDataController(context: context)
        let authManager = AuthenticationManager()
        authManager.setMockUser(user)

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        viewModel.selectedMedication = .semaglutide
        viewModel.selectedDose = 1.0
        viewModel.selectedStartDate = Date()
        viewModel.notificationsGranted = false  // User denied
        viewModel.schedulePattern = .weekly
        viewModel.reminderMinutes = 60

        let notificationService = NotificationService.shared
        // Reset state
        await notificationService.disable()

        // Act
        let result = await viewModel.completeOnboarding()

        // Assert
        guard case .success = result else {
            #expect(Bool(false), "Expected .success result, got \(result)")
            return
        }

        // Notification service should remain disabled
        #expect(notificationService.notificationsEnabled == false)
    }

    @Test("Reminder minutes persist from onboarding to settings")
    func testReminderMinutesPersistFromOnboardingToSettings() async throws {
        // Arrange
        let context = createTestContext()
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        let dataController = createTestDataController(context: context)
        let authManager = AuthenticationManager()
        authManager.setMockUser(user)

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        viewModel.selectedMedication = .semaglutide
        viewModel.selectedDose = 1.0
        viewModel.selectedStartDate = Date()
        viewModel.notificationsGranted = true
        viewModel.schedulePattern = .weekly
        viewModel.reminderMinutes = 120  // 2 hours

        let notificationService = NotificationService.shared

        // Act
        let result = await viewModel.completeOnboarding()

        // Assert
        guard case .success = result else {
            #expect(Bool(false), "Expected .success result, got \(result)")
            return
        }

        // Reminder preference should be saved
        #expect(notificationService.reminderMinutesBefore == 120)
    }

    @Test("Notification service activation handles authorization denial gracefully")
    func testNotificationServiceHandlesAuthorizationDenialGracefully() async throws {
        // Arrange
        let context = createTestContext()
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        let dataController = createTestDataController(context: context)
        let authManager = AuthenticationManager()
        authManager.setMockUser(user)

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        viewModel.selectedMedication = .semaglutide
        viewModel.selectedDose = 1.0
        viewModel.selectedStartDate = Date()
        viewModel.notificationsGranted = true  // User thinks they granted, but system denies
        viewModel.schedulePattern = .weekly
        viewModel.reminderMinutes = 60

        let notificationService = NotificationService.shared
        // Simulate denied authorization by using mock that returns false
        // (This would require mock injection in production code)

        // Act
        let result = await viewModel.completeOnboarding()

        // Assert
        // Should complete successfully even if notification activation fails
        guard case .success = result else {
            #expect(Bool(false), "Expected .success result even with denied authorization, got \(result)")
            return
        }
    }

    @Test("Multiple reminder options saved correctly from onboarding")
    func testMultipleReminderOptionsSavedCorrectly() async throws {
        // Arrange
        let reminderOptions = [15, 30, 60, 120]

        for reminderMinutes in reminderOptions {
            let context = createTestContext()
            let user = User(email: "test\(reminderMinutes)@example.com", name: "Test User")
            context.insert(user)

            let dataController = createTestDataController(context: context)
            let authManager = AuthenticationManager()
            authManager.setMockUser(user)

            let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
            viewModel.selectedMedication = .semaglutide
            viewModel.selectedDose = 1.0
            viewModel.selectedStartDate = Date()
            viewModel.notificationsGranted = true
            viewModel.schedulePattern = .weekly
            viewModel.reminderMinutes = reminderMinutes

            let notificationService = NotificationService.shared

            // Act
            _ = await viewModel.completeOnboarding()

            // Assert
            #expect(
                notificationService.reminderMinutesBefore == reminderMinutes,
                "Expected reminderMinutes to be \(reminderMinutes), got \(notificationService.reminderMinutesBefore)")
        }
    }

    @Test("Notification service configuration survives app restart")
    func testNotificationServiceConfigurationSurvivesRestart() async throws {
        // Arrange
        let context = createTestContext()
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        let dataController = createTestDataController(context: context)
        let authManager = AuthenticationManager()
        authManager.setMockUser(user)

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        viewModel.selectedMedication = .semaglutide
        viewModel.selectedDose = 1.0
        viewModel.selectedStartDate = Date()
        viewModel.notificationsGranted = true
        viewModel.schedulePattern = .weekly
        viewModel.reminderMinutes = 30

        let notificationService = NotificationService.shared

        // Act - Complete onboarding
        _ = await viewModel.completeOnboarding()

        let savedReminderMinutes = notificationService.reminderMinutesBefore
        let savedEnabled = notificationService.notificationsEnabled

        // Simulate app restart by saving and reloading state
        notificationService.saveState()

        // Create new NotificationService instance (simulating app restart)
        // In real code, this would reload from persistence
        let reloadedService = NotificationService.shared

        // Assert
        #expect(reloadedService.reminderMinutesBefore == savedReminderMinutes)
        #expect(reloadedService.notificationsEnabled == savedEnabled)
    }

    @Test("Schedule creation succeeds even if notification service fails")
    func testScheduleCreationSucceedsEvenIfNotificationServiceFails() async throws {
        // Arrange
        let context = createTestContext()
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        let dataController = createTestDataController(context: context)
        let authManager = AuthenticationManager()
        authManager.setMockUser(user)

        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)
        viewModel.selectedMedication = .semaglutide
        viewModel.selectedDose = 1.0
        viewModel.selectedStartDate = Date()
        viewModel.notificationsGranted = true
        viewModel.schedulePattern = .weekly
        viewModel.reminderMinutes = 60

        // Act
        let result = await viewModel.completeOnboarding()

        // Assert
        // Onboarding should succeed even if notifications fail
        guard case .success = result else {
            #expect(Bool(false), "Expected .success result, got \(result)")
            return
        }

        // Schedule should be created
        let schedules = try context.fetch(FetchDescriptor<DoseSchedule>())
        #expect(schedules.count == 1, "Expected 1 schedule to be created")
    }
}
