import SwiftData
import SwiftUI

@main
struct JabTrackerApp: App {
    let dataController = DataController.shared
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var biometricManager = BiometricAuthManager()
    @StateObject private var onboardingCoordinator: OnboardingCoordinator
    @Environment(\.scenePhase) var scenePhase
    @State private var hasJustSignedIn = false
    @State private var hasRecentBiometricAuth = false
    @State private var showingOnboarding = false

    init() {
        let authManager = AuthenticationManager()
        let dataController = DataController.shared
        self._authManager = StateObject(wrappedValue: authManager)
        self._biometricManager = StateObject(wrappedValue: BiometricAuthManager())
        self._onboardingCoordinator = StateObject(wrappedValue: OnboardingCoordinator(
            authManager: authManager,
            dataController: dataController))
    }

    var body: some Scene {
        WindowGroup {
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
            .onChange(of: self.scenePhase) { _, newPhase in
                self.handleScenePhaseChange(newPhase)
            }
            .onChange(of: self.authManager.authenticationState) { _, newState in
                if newState == .authenticated {
                    self.hasJustSignedIn = true
                    // Check if user needs onboarding
                    self.onboardingCoordinator.checkOnboardingStatus()
                    self.showingOnboarding = self.onboardingCoordinator.shouldShowOnboarding

                    // Reset the flag after a short delay
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        self.hasJustSignedIn = false
                    }
                }
            }
            .onAppear {
                Task {
                    await self.authManager.checkAuthenticationStatus()
                    // Check onboarding status after auth check
                    if self.authManager.authenticationState == .authenticated {
                        self.onboardingCoordinator.checkOnboardingStatus()
                        self.showingOnboarding = self.onboardingCoordinator.shouldShowOnboarding
                    }
                }
            }
        }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("📱 JabTrackerApp: Scene became active")
            print("📱 JabTrackerApp: Auth state = \(self.authManager.authenticationState), " +
                "Biometric enabled = \(self.biometricManager.isBiometricEnabled), " +
                "Just signed in = \(self.hasJustSignedIn), Recent biometric = \(self.hasRecentBiometricAuth)")
            // Check for biometric authentication when app becomes active
            // (but not right after sign-in or recent biometric auth)
            if self.authManager.authenticationState == .authenticated,
               self.biometricManager.isBiometricEnabled,
               !self.hasJustSignedIn,
               !self.hasRecentBiometricAuth
            {
                print("📱 JabTrackerApp: Triggering biometric authentication")
                Task {
                    await self.handleBiometricAuthentication()
                }
            } else if self.hasJustSignedIn {
                print("📱 JabTrackerApp: Skipping biometric auth - user just signed in")
            } else if self.hasRecentBiometricAuth {
                print("📱 JabTrackerApp: Skipping biometric auth - recent authentication")
            }
        case .background, .inactive:
            // Reset biometric auth flag when app goes to background
            self.hasRecentBiometricAuth = false
        @unknown default:
            break
        }
    }

    @MainActor
    private func handleBiometricAuthentication() async {
        print("🔐 JabTrackerApp: Starting biometric authentication")
        do {
            let success = try await biometricManager.authenticateWithBiometrics(reason: "Unlock JabTracker")
            print("🔐 JabTrackerApp: Biometric authentication result = \(success)")
            if success {
                // Set flag to prevent immediate re-authentication
                self.hasRecentBiometricAuth = true
                // Reset the flag after a reasonable delay
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    self.hasRecentBiometricAuth = false
                }
            } else {
                print("🔐 JabTrackerApp: Biometric auth failed, continuing without biometric auth")
                // Authentication failed but user stays signed in - set flag to prevent retry loops
                self.hasRecentBiometricAuth = true
            }
        } catch {
            print("🔐 JabTrackerApp: Biometric auth error: \(error)")

            // Handle different biometric errors appropriately
            if let biometricError = error as? BiometricError {
                switch biometricError {
                case .notAvailable, .disabled:
                    // Biometrics not available/disabled - user stays signed in
                    print("🔐 JabTrackerApp: Biometrics not available, continuing without biometric auth")
                    self.hasRecentBiometricAuth = true // Prevent retry loops

                case .userCancel, .userFallback:
                    // User cancelled or chose fallback - user stays signed in
                    print("🔐 JabTrackerApp: User cancelled biometric auth, continuing without biometric auth")
                    self.hasRecentBiometricAuth = true // Prevent retry loops

                case .lockout:
                    // User is locked out from too many attempts - sign out for security
                    print("🔐 JabTrackerApp: Biometric lockout detected, signing out for security")
                    try? await self.authManager.signOut()

                case .authenticationFailed:
                    // Authentication failed - could be temporary, don't sign out immediately
                    print("🔐 JabTrackerApp: Biometric auth failed, continuing without biometric auth")
                    self.hasRecentBiometricAuth = true // Prevent retry loops

                default:
                    print("🔐 JabTrackerApp: Unknown biometric error, continuing without biometric auth")
                    self.hasRecentBiometricAuth = true // Prevent retry loops
                }
            } else {
                // Unknown error type - be conservative but don't sign out
                print("🔐 JabTrackerApp: Unknown biometric error type, continuing without biometric auth")
                self.hasRecentBiometricAuth = true // Prevent retry loops
            }
        }
    }
}
