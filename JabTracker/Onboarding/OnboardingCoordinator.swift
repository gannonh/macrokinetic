import Foundation
import OSLog
import SwiftData

@MainActor
class OnboardingCoordinator: ObservableObject {
    @Published var shouldShowOnboarding: Bool = false

    private let authManager: AuthenticationManager
    private let dataController: DataController
    private let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "OnboardingCoordinator"
    )

    init(authManager: AuthenticationManager, dataController: DataController? = nil) {
        self.authManager = authManager
        self.dataController = dataController ?? DataController.shared
    }

    func checkOnboardingStatus() {
        // Check if user should see onboarding
        self.shouldShowOnboarding = self.needsOnboarding()
    }

    private func needsOnboarding() -> Bool {
        // IMPORTANT: Only apply testing flags when running the actual app (not unit tests)
        // Unit tests run in-process and have XCTestConfigurationFilePath set
        let isUnitTestEnvironment =
            ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil

        // Check if we're forcing onboarding (for testing) - only apply in non-unit-test context
        if !isUnitTestEnvironment && ProcessInfo.processInfo.arguments.contains("--force-onboarding") {
            logger.debug("Force onboarding enabled - showing onboarding")
            return true
        }

        // Check if we're bypassing onboarding (for real auth testing) - only apply in non-unit-test context
        if !isUnitTestEnvironment && ProcessInfo.processInfo.arguments.contains("--bypass-onboarding") {
            logger.debug("Bypass onboarding enabled - skipping onboarding")
            return false
        }

        // Check if we're in UI testing mode - should bypass onboarding unless forcing
        // Only apply in non-unit-test context
        let isUITesting =
            !isUnitTestEnvironment
            && (ProcessInfo.processInfo.environment["UI_TESTING"] == "true"
                || ProcessInfo.processInfo.arguments.contains("--ui-testing"))
        if isUITesting {
            logger.debug("UI testing mode detected - bypassing onboarding")
            return false
        }

        // Check if user exists and has completed onboarding
        guard let user = authManager.currentUser else {
            logger.debug("No current user found - not showing onboarding")
            return false  // No user means not authenticated, shouldn't show onboarding
        }

        logger.debug(
            "Found user \(user.id, privacy: .private) - hasCompletedOnboarding: \(user.hasCompletedOnboarding)")

        // Check user's onboarding status
        if user.hasCompletedOnboarding {
            logger.debug("User has completed onboarding - not showing")
            return false
        }

        // Check if user skipped onboarding (will complete goal setup later via Strategy)
        if user.onboardingSkippedAt != nil {
            logger.debug("User skipped onboarding - not showing")
            return false
        }

        // Check UserDefaults for skipped state
        let userDefaultsSkipped = UserDefaults.standard.bool(forKey: "hasSkippedOnboarding")
        if userDefaultsSkipped {
            logger.debug("UserDefaults says skipped - syncing to model")
            user.onboardingSkippedAt =
                UserDefaults.standard.object(forKey: "onboardingSkippedAt") as? Date ?? Date()
            do {
                try self.dataController.container.mainContext.save()
            } catch {
                logger.error("Failed to sync skipped state to model: \(error.localizedDescription)")
            }
            return false
        }

        // Check UserDefaults as backup
        let userDefaultsCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        logger.debug("UserDefaults hasCompletedOnboarding: \(userDefaultsCompleted)")

        if userDefaultsCompleted {
            logger.debug("UserDefaults says completed - syncing to model")
            // Sync the model if UserDefaults says completed but model doesn't
            user.hasCompletedOnboarding = true
            user.onboardingCompletedAt =
                UserDefaults.standard.object(
                    forKey: "onboardingCompletedAt"
                ) as? Date ?? Date()
            do {
                try self.dataController.container.mainContext.save()
            } catch {
                logger.error("Failed to sync completed state to model: \(error.localizedDescription)")
            }
            return false
        }

        logger.debug("User needs onboarding - showing onboarding flow")
        return true
    }

    func markOnboardingComplete() {
        self.shouldShowOnboarding = false
        self.checkOnboardingStatus()  // Re-evaluate in case something changed
    }
}
