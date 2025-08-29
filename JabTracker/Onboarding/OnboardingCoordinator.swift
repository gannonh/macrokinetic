import Foundation
import SwiftData

@MainActor
class OnboardingCoordinator: ObservableObject {
    @Published var shouldShowOnboarding: Bool = false
    
    private let authManager: AuthenticationManager
    private let dataController: DataController
    
    init(authManager: AuthenticationManager, dataController: DataController? = nil) {
        self.authManager = authManager
        self.dataController = dataController ?? DataController.shared
    }
    
    func checkOnboardingStatus() {
        // Check if user should see onboarding
        shouldShowOnboarding = needsOnboarding()
    }
    
    private func needsOnboarding() -> Bool {
        // Check if we're forcing onboarding (for testing)
        if ProcessInfo.processInfo.arguments.contains("--force-onboarding") {
            return true
        }
        
        // Check if user exists and has completed onboarding
        guard let user = authManager.currentUser else {
            return false // No user means not authenticated, shouldn't show onboarding
        }
        
        // Check user's onboarding status
        if user.hasCompletedOnboarding {
            return false
        }
        
        // Check UserDefaults as backup
        let userDefaultsCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if userDefaultsCompleted {
            // Sync the model if UserDefaults says completed but model doesn't
            user.hasCompletedOnboarding = true
            user.onboardingCompletedAt = UserDefaults.standard.object(forKey: "onboardingCompletedAt") as? Date ?? Date()
            try? dataController.container.mainContext.save()
            return false
        }
        
        return true
    }
    
    func markOnboardingComplete() {
        shouldShowOnboarding = false
        checkOnboardingStatus() // Re-evaluate in case something changed
    }
}