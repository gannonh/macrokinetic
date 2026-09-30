import SwiftData
import SwiftUI

@main
struct JabTrackerApp: App {
    @StateObject private var dataController: DataController
    @StateObject private var authManager: AuthenticationManager
    /// Biometric authentication manager (shared singleton)
    @StateObject private var biometricManager = BiometricAuthManager.shared
    @StateObject private var onboardingCoordinator: OnboardingCoordinator
    @Environment(\.scenePhase) var scenePhase
    @State private var showingOnboarding = false

    /// Track if app is locked by biometric authentication
    @State private var isAppLocked = false

    init() {
        let dataController = DataController.shared
        let authManager = AuthenticationManager(dataController: dataController)
        self._dataController = StateObject(wrappedValue: dataController)
        self._authManager = StateObject(wrappedValue: authManager)
        self._onboardingCoordinator = StateObject(
            wrappedValue: OnboardingCoordinator(
                authManager: authManager,
                dataController: dataController))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch dataController.storageState {
                case let .ready(container):
                    normalRoot(container: container)
                case let .failed(failure):
                    StorageRecoveryView(failure: failure, retry: dataController.retryStorage)
                }
            }
            .onOpenURL { url in
                guard case .ready = dataController.storageState else { return }
                DeeplinkHandler.handle(url: url)
            }
        }
    }

    // swiftlint:disable:next function_body_length
    private func normalRoot(container: ModelContainer) -> some View {
        ZStack {
            Group {
                switch self.authManager.authenticationState {
                case .authenticated:
                    if showingOnboarding {
                        OnboardingView(isPresented: self.$showingOnboarding, authManager: self.authManager)
                            .modelContainer(container)
                            .environmentObject(self.authManager)
                            .transition(.opacity)
                    } else {
                        ContentView()
                            .modelContainer(container)
                            .environmentObject(self.authManager)
                            .environmentObject(self.biometricManager)
                            .transition(.opacity)
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

                if self.authManager.authenticationState == .authenticated {
                    self.onboardingCoordinator.checkOnboardingStatus()
                    self.showingOnboarding = self.onboardingCoordinator.shouldShowOnboarding

                    isAppLocked = biometricManager.isBiometricEnabled

                    #if DEBUG || JABTRACKER_TEST_HARNESS
                    if ProcessInfo.processInfo.arguments.contains("--test-titration-data") {
                        self.dataController.seedTitrationTestData()
                    }

                    if ProcessInfo.processInfo.arguments.contains("--seed-calorie-user") {
                        self.dataController.seedCalorieExpenditureUser()
                    }

                    if let deeplinkURLString = ProcessInfo.processInfo.arguments.first(where: {
                        $0.hasPrefix("--deeplink-url=")
                    }) {
                        let urlString = String(deeplinkURLString.dropFirst("--deeplink-url=".count))
                        if let url = URL(string: urlString) {
                            DeeplinkHandler.handle(url: url)
                        }
                    }
                    #endif
                }
            }
        }
        .onChange(of: self.authManager.authenticationState) { _, newState in
            if newState == .authenticated {
                isAppLocked = biometricManager.isBiometricEnabled

                self.onboardingCoordinator.checkOnboardingStatus()
                self.showingOnboarding = self.onboardingCoordinator.shouldShowOnboarding
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if authManager.authenticationState == .authenticated
                && biometricManager.isBiometricEnabled
            {
                isAppLocked = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .restartOnboarding)) { _ in
            self.showingOnboarding = true
        }
    }
}
