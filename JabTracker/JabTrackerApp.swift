import SwiftData
import SwiftUI
import UserNotifications

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
    @State private var isAppLocked: Bool

    init() {
        UNUserNotificationCenter.current().delegate = LaunchNotificationDelegate.shared
        Task {
            await NotificationService.cancelUnavailableTitrationNotifications()
        }
        let dataController = DataController.shared
        let authManager = AuthenticationManager(dataController: dataController)
        self._dataController = StateObject(wrappedValue: dataController)
        self._authManager = StateObject(wrappedValue: authManager)
        // Start locked when the lock is on so ContentView never renders unlocked before the first check completes.
        self._isAppLocked = State(initialValue: BiometricAuthManager.shared.isBiometricEnabled)
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
                // No sign-in in 1.0: the app is either loading the local profile or showing it.
                if self.authManager.authenticationState == .authenticated {
                    // Show onboarding fullscreen if needed, otherwise ContentView
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
                } else {
                    SplashView()
                        .environmentObject(self.authManager)
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

                    #if DEBUG || JABTRACKER_TEST_HARNESS
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
                    #endif

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
        .onReceive(NotificationCenter.default.publisher(for: .restartOnboarding)) { _ in
            // Show onboarding immediately when user restarts from settings
            self.showingOnboarding = true
        }
    }
}
