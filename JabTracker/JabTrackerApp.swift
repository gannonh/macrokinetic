import SwiftData
import SwiftUI

@main
struct JabTrackerApp: App {
    let dataController = DataController.shared
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var biometricManager = BiometricAuthManager()
    @Environment(\.scenePhase) var scenePhase

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
            .onAppear {
                print("JabTrackerApp onAppear - authState: \(authManager.authenticationState)")
                Task {
                    await authManager.checkAuthenticationStatus()
                    print("JabTrackerApp after checkAuthenticationStatus - authState: \(authManager.authenticationState)")
                }
            }
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            // Check for biometric authentication when app becomes active
            if authManager.authenticationState == .authenticated && biometricManager.isBiometricEnabled {
                Task {
                    await handleBiometricAuthentication()
                }
            }
        case .background, .inactive:
            // Clear sensitive data when app goes to background if needed
            break
        @unknown default:
            break
        }
    }
    
    @MainActor
    private func handleBiometricAuthentication() async {
        do {
            let success = try await biometricManager.authenticateWithBiometrics(reason: "Unlock JabTracker")
            if !success {
                // If biometric authentication fails, sign out the user
                try? await authManager.signOut()
            }
        } catch {
            // If biometric authentication encounters an error, sign out for security
            try? await authManager.signOut()
        }
    }
}
