import SwiftData
import SwiftUI

@main
struct JabTrackerApp: App {
    let dataController = DataController.shared
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var biometricManager = BiometricAuthManager()
    @Environment(\.scenePhase) var scenePhase
    @State private var hasJustSignedIn = false
    @State private var hasRecentBiometricAuth = false

    var body: some Scene {
        WindowGroup {
            Group {
                switch authManager.authenticationState {
                case .authenticated:
                    ContentView()
                        .modelContainer(dataController.container)
                        .environmentObject(authManager)
                        .environmentObject(biometricManager)
                case .notAuthenticated:
                    AuthenticationView()
                        .environmentObject(authManager)
                        .environmentObject(biometricManager)
                case .notDetermined:
                    SplashView()
                        .environmentObject(authManager)
                case .restricted, .expired:
                    AuthenticationView()
                        .environmentObject(authManager)
                        .environmentObject(biometricManager)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
            .onChange(of: authManager.authenticationState) { _, newState in
                if newState == .authenticated {
                    hasJustSignedIn = true
                    // Reset the flag after a short delay
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        hasJustSignedIn = false
                    }
                }
            }
            .onAppear {
                Task {
                    await authManager.checkAuthenticationStatus()
                }
            }
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("📱 JabTrackerApp: Scene became active")
            print("📱 JabTrackerApp: Auth state = \(authManager.authenticationState), Biometric enabled = \(biometricManager.isBiometricEnabled), Just signed in = \(hasJustSignedIn), Recent biometric = \(hasRecentBiometricAuth)")
            // Check for biometric authentication when app becomes active (but not right after sign-in or recent biometric auth)
            if authManager.authenticationState == .authenticated && biometricManager.isBiometricEnabled && !hasJustSignedIn && !hasRecentBiometricAuth {
                print("📱 JabTrackerApp: Triggering biometric authentication")
                Task {
                    await handleBiometricAuthentication()
                }
            } else if hasJustSignedIn {
                print("📱 JabTrackerApp: Skipping biometric auth - user just signed in")
            } else if hasRecentBiometricAuth {
                print("📱 JabTrackerApp: Skipping biometric auth - recent authentication")
            }
        case .background, .inactive:
            // Reset biometric auth flag when app goes to background
            hasRecentBiometricAuth = false
            break
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
                hasRecentBiometricAuth = true
                // Reset the flag after a reasonable delay
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    hasRecentBiometricAuth = false
                }
            } else {
                print("🔐 JabTrackerApp: Biometric auth failed, signing out user")
                // If biometric authentication fails, sign out the user
                try? await authManager.signOut()
            }
        } catch {
            print("🔐 JabTrackerApp: Biometric auth error: \(error), signing out user")
            // If biometric authentication encounters an error, sign out for security
            try? await authManager.signOut()
        }
    }
}
