import SwiftData
import SwiftUI

@main
struct JabTrackerApp: App {
    let dataController = DataController.shared
    @StateObject private var authManager = AuthenticationManager()
    /// Biometric authentication manager (shared singleton)
    @StateObject private var biometricManager = BiometricAuthManager.shared
    @StateObject private var onboardingCoordinator: OnboardingCoordinator
    @Environment(\.scenePhase) var scenePhase
    @State private var showingOnboarding = false

    /// Track if app is locked by biometric authentication
    @State private var isAppLocked = false

    init() {
        let authManager = AuthenticationManager()
        let dataController = DataController.shared
        self._authManager = StateObject(wrappedValue: authManager)
        self._onboardingCoordinator = StateObject(
            wrappedValue: OnboardingCoordinator(
                authManager: authManager,
                dataController: dataController))
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    switch self.authManager.authenticationState {
                    case .authenticated:
                        ContentView()
                            .modelContainer(self.dataController.container)
                            .environmentObject(self.authManager)
                            .environmentObject(self.biometricManager)
                            .sheet(isPresented: self.$showingOnboarding) {
                                OnboardingView(isPresented: self.$showingOnboarding, authManager: self.authManager)
                                    .environmentObject(self.authManager)
                            }
                    case .notAuthenticated:
                        AuthenticationView()
                            .environmentObject(self.authManager)
                            .environmentObject(self.biometricManager)
                    case .notDetermined:
                        SplashView()
                            .environmentObject(self.authManager)
                    case .restricted, .expired:
                        AuthenticationView()
                            .environmentObject(self.authManager)
                            .environmentObject(self.biometricManager)
                    }
                }

                // Biometric lock overlay (appears on top when locked)
                if isAppLocked && authManager.authenticationState == .authenticated {
                    LockScreenView(isLocked: $isAppLocked)
                        .environmentObject(self.biometricManager)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                Task {
                    await self.authManager.checkAuthenticationStatus()

                    // Check onboarding status after auth check
                    if self.authManager.authenticationState == .authenticated {
                        self.onboardingCoordinator.checkOnboardingStatus()
                        self.showingOnboarding = self.onboardingCoordinator.shouldShowOnboarding

                        // After auth check, determine if biometric lock should be shown
                        isAppLocked = biometricManager.isBiometricEnabled

                        // Seed test data if launch argument is present
                        if ProcessInfo.processInfo.arguments.contains("--test-titration-data") {
                            self.dataController.seedTitrationTestData()
                        }

                        if ProcessInfo.processInfo.arguments.contains("--seed-calorie-user") {
                            self.dataController.seedCalorieExpenditureUser()
                        }

                        // Handle deeplink from launch arguments (for UI testing)
                        if let deeplinkURLString = ProcessInfo.processInfo.arguments.first(where: {
                            $0.hasPrefix("--deeplink-url=")
                        }) {
                            let urlString = String(deeplinkURLString.dropFirst("--deeplink-url=".count))
                            if let url = URL(string: urlString) {
                                DeeplinkHandler.handle(url: url)
                            }
                        }
                    }
                }
            }
            .onChange(of: self.authManager.authenticationState) { _, newState in
                if newState == .authenticated {
                    // Lock app when authentication state changes to authenticated
                    // and biometric is enabled
                    isAppLocked = biometricManager.isBiometricEnabled

                    // Check if user needs onboarding
                    self.onboardingCoordinator.checkOnboardingStatus()
                    self.showingOnboarding = self.onboardingCoordinator.shouldShowOnboarding
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Re-lock app when returning from background
                if authManager.authenticationState == .authenticated
                    && biometricManager.isBiometricEnabled
                {
                    isAppLocked = true
                }
            }
            .onOpenURL { url in
                DeeplinkHandler.handle(url: url)
            }
        }
    }
}
