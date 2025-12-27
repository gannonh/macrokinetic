// swiftlint:disable file_length
import AuthenticationServices
import Foundation
import OSLog
import SwiftData
import SwiftUI

enum AuthenticationState: String, CaseIterable {
    case notDetermined
    case authenticated
    case notAuthenticated
    case restricted
    case expired
}

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "JabTracker",
        category: "AuthenticationManager")

    @Published var authenticationState: AuthenticationState = .notDetermined {
        didSet {
            Self.logger.info(
                """
                🔄 AuthenticationManager: State changed from \
                \(oldValue.rawValue, privacy: .public) to \(self.authenticationState.rawValue, privacy: .public)
                """
            )
        }
    }

    @Published var currentUser: User?

    private let dataController: DataController

    /// Detects if code is running in a unit test context (not UI tests)
    private var isUnitTestEnvironment: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil
    }

    init(dataController: DataController? = nil) {
        self.dataController = dataController ?? DataController.shared
        super.init()
    }

    func checkAuthenticationStatus() async {
        Self.logger.info("🔍 AuthenticationManager: checkAuthenticationStatus() called")

        // Reset app data if requested (for UI testing)
        if ProcessInfo.processInfo.arguments.contains("--reset-app-data") {
            await self.resetAppData()
        }

        // UI testing mode bypasses auth - but not during unit tests
        let isUITesting =
            (ProcessInfo.processInfo.environment["UI_TESTING"] == "true"
                || ProcessInfo.processInfo.arguments.contains("--ui-testing"))
            && !isUnitTestEnvironment

        // Check if we're in manual UI testing mode (shows auth UI but mocks Apple ID response)
        let isManualUITesting = ProcessInfo.processInfo.arguments.contains("--manual-ui-testing")

        if isUITesting {
            await self.setupUITestingUser()
            return
        }

        // For manual UI testing, we don't setup a user immediately - let the auth UI show
        // But when signInWithApple() is called, we'll mock the response
        if isManualUITesting {
            Self.logger.info(
                "🎭 AuthenticationManager: Manual UI testing mode - showing auth UI with mocked Apple ID response"
            )
        }

        // Check if user is already authenticated by looking for existing user data
        let context = self.dataController.container.mainContext

        do {
            let fetchDescriptor = FetchDescriptor<User>()
            let users = try context.fetch(fetchDescriptor)

            Self.logger.info(
                "🔍 AuthenticationManager: Found \(users.count, privacy: .public) users in database")
            if let user = users.first {
                Self.logger.info(
                    """
                    🔍 AuthenticationManager: First user - ID: \(user.id, privacy: .public), \
                    Email: \(user.displayEmail, privacy: .public)
                    """
                )
            }

            await MainActor.run {
                if let user = users.first {
                    self.currentUser = user
                    self.authenticationState = .authenticated
                    Self.logger.info("✅ AuthenticationManager: Set state to authenticated")
                } else {
                    self.authenticationState = .notAuthenticated
                    Self.logger.info(
                        "❌ AuthenticationManager: Set state to notAuthenticated - no users found")
                }
            }
        } catch {
            Self.logger.error("❌ AuthenticationManager: Fetch error: \(error, privacy: .public)")
            await MainActor.run {
                self.authenticationState = .notAuthenticated
            }
        }
    }

    /// Clear chart dataset cache from Application Support directory
    /// Used during test data reset to ensure clean state
    private func clearChartDatasetCache() {
        let fileManager = FileManager.default
        guard
            let appSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first
        else {
            return
        }

        let cacheDirectory = appSupport.appendingPathComponent("ChartCache", isDirectory: true)
        let cacheFile = cacheDirectory.appendingPathComponent("concentrationDataset.json")

        if fileManager.fileExists(atPath: cacheFile.path) {
            do {
                try fileManager.removeItem(at: cacheFile)
                Self.logger.info("🗑️  Cleared chart dataset cache for clean test state")
            } catch {
                Self.logger.error("❌ Failed to clear chart dataset cache: \(error.localizedDescription)")
            }
        }
    }

    private func resetAppData() async {
        let context = self.dataController.container.mainContext

        do {
            try deleteAllSwiftDataEntities(context: context)
        } catch {
            Self.logger.error("Failed to reset app data: \(error, privacy: .public)")
        }

        clearUserDefaultsForReset()
        clearNotificationsForReset()
        clearChartDatasetCache()

        await MainActor.run {
            self.currentUser = nil
            self.authenticationState = .notAuthenticated
        }
    }

    /// Deletes all SwiftData entities for a clean test state
    private func deleteAllSwiftDataEntities(context: ModelContext) throws {
        // Delete counts for logging
        let userCount = try deleteAll(User.self, from: context)
        let profileCount = try deleteAll(MedicationProfile.self, from: context)
        let doseCount = try deleteAll(Dose.self, from: context)
        let titrationCount = try deleteAll(DoseTitration.self, from: context)
        let foodCount = try deleteAll(Food.self, from: context)
        let foodEntryCount = try deleteAll(FoodEntry.self, from: context)
        let weightEntryCount = try deleteAll(WeightEntry.self, from: context)
        let metricsEntryCount = try deleteAll(MetricsEntry.self, from: context)
        let progressPhotoCount = try deleteAll(ProgressPhoto.self, from: context)

        try context.save()
        Self.logger.info(
            """
            ✅ AuthenticationManager: App data reset successfully - \
            Deleted \(userCount) users, \(profileCount) profiles, \(doseCount) doses, \
            \(titrationCount) titrations, \(foodCount) foods, \(foodEntryCount) food entries, \
            \(weightEntryCount) weight entries, \(metricsEntryCount) metrics entries, \
            \(progressPhotoCount) progress photos
            """)
    }

    /// Generic helper to delete all entities of a given type
    private func deleteAll<T: PersistentModel>(_ type: T.Type, from context: ModelContext) throws -> Int {
        let fetchDescriptor = FetchDescriptor<T>()
        let entities = try context.fetch(fetchDescriptor)
        for entity in entities {
            context.delete(entity)
        }
        return entities.count
    }

    private func clearUserDefaultsForReset() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        UserDefaults.standard.removeObject(forKey: "onboardingCompletedAt")
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "reminderMinutesBefore")
    }

    private func clearNotificationsForReset() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        Self.logger.info("✅ AuthenticationManager: Cleared all pending and delivered notifications")
    }

    private func setupUITestingUser() async {
        let context = self.dataController.container.mainContext

        // Check if a user already exists from a previous session
        let fetchDescriptor = FetchDescriptor<User>()
        let existingUsers = try? context.fetch(fetchDescriptor)

        let mockUser: User
        let isNewUser: Bool

        if let existingUser = existingUsers?.first {
            // Use existing user from previous session (preserves seeded data)
            mockUser = existingUser
            isNewUser = false
            Self.logger.info("✅ AuthenticationManager: Found existing UI testing user, reusing with persisted data")
        } else {
            // Create new user on first launch
            mockUser = User(
                email: "test@uitesting.com",
                name: "UI Test User",
                weight: 70.0,
                weightUnit: "kg")
            context.insert(mockUser)
            isNewUser = true
            Self.logger.info("✅ AuthenticationManager: Creating new UI testing mock user")
        }

        do {
            try context.save()
            await MainActor.run {
                self.currentUser = mockUser
                self.authenticationState = .authenticated
            }

            // Mark onboarding as complete if bypass flag is set
            if ProcessInfo.processInfo.arguments.contains("--bypass-onboarding") {
                mockUser.hasCompletedOnboarding = true
                mockUser.onboardingCompletedAt = Date()
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                UserDefaults.standard.set(Date(), forKey: "onboardingCompletedAt")
                try? context.save()
                Self.logger.info("✅ AuthenticationManager: Marked onboarding as complete (bypass enabled)")
            }

            // Only seed test data on first launch
            if isNewUser {
                await self.seedTestDataIfRequested(for: mockUser, context: context)
            } else {
                Self.logger.info("📊 Skipping test data seeding - using persisted data from previous session")
            }
        } catch {
            Self.logger.error("❌ AuthenticationManager: Failed to persist UI testing user: \(error)")
            await MainActor.run {
                self.authenticationState = .notAuthenticated
            }
        }
    }

    // swiftlint:disable:next orphaned_doc_comment
    /// Seed test data for UI testing if TEST_DATA_SEED environment variable or time period launch arguments are set
    /// Enables fast E2E performance testing with large datasets and manual testing with realistic data
    // swiftlint:disable:next function_body_length
    private func seedTestDataIfRequested(for user: User, context: ModelContext) async {
        #if DEBUG || TEST
            let environment = ProcessInfo.processInfo.environment
            let arguments = ProcessInfo.processInfo.arguments

            // Determine which seeding period was requested
            var daysOfHistory = 0
            if environment["TEST_DATA_SEED"] == "true" {
                // Legacy environment variable approach (for UI tests)
                daysOfHistory = Int(environment["TEST_DATA_DAYS"] ?? "30") ?? 30
            } else if arguments.contains("--seed-test-7d") {
                daysOfHistory = 7
            } else if arguments.contains("--seed-test-30d") {
                daysOfHistory = 30
            } else if arguments.contains("--seed-test-90d") {
                daysOfHistory = 90
            } else if arguments.contains("--seed-test-1y") {
                daysOfHistory = 365
            } else {
                return  // No seeding requested
            }

            Self.logger.info("🌱 Test data seeding requested for \(daysOfHistory) days")

            // Parse seeding configuration from environment (or use defaults)
            let medicationRaw = environment["TEST_DATA_MEDICATION"] ?? "semaglutide"
            let brandName = environment["TEST_DATA_BRAND"] ?? "Ozempic"
            let doseAmount = Double(environment["TEST_DATA_DOSE"] ?? "1.0") ?? 1.0
            let adherenceRate = Double(environment["TEST_DATA_ADHERENCE"] ?? "0.95") ?? 0.95
            let addVariability = environment["TEST_DATA_VARIABILITY"] ?? "true" == "true"
            let includeSkipped = environment["TEST_DATA_SKIPPED"] ?? "true" == "true"
            let medicationProfileCount = Int(environment["TEST_DATA_PROFILES"] ?? "1") ?? 1
            let doseCount = Int(environment["TEST_DATA_DOSE_COUNT"] ?? "\(daysOfHistory / 7)") ?? (daysOfHistory / 7)

            // Create medication enum from string
            guard let medication = Medication(rawValue: medicationRaw) else {
                Self.logger.warning("⚠️  Invalid medication: \(medicationRaw), skipping seeding")
                return
            }

            Self.logger.info(
                """
                🌱 Seeding configuration:
                   - Days: \(daysOfHistory)
                   - Dose count: \(doseCount)
                   - Medication profiles: \(medicationProfileCount)
                   - Primary medication: \(medicationRaw)
                   - Brand: \(brandName)
                   - Dose: \(doseAmount)mg
                   - Adherence: \(String(format: "%.1f%%", adherenceRate * 100))
                """)

            // Create configuration
            let config = TestDataSeedingConfig(
                daysOfHistory: daysOfHistory,
                medication: medication,
                brandName: brandName,
                doseAmount: doseAmount,
                adherenceRate: adherenceRate,
                addTimingVariability: addVariability,
                includeSkippedDoses: includeSkipped
            )

            // Perform seeding on main actor
            await MainActor.run {
                do {
                    let startTime = Date()

                    // Seed primary profile and its doses
                    let result = try TestDataSeeding.seedData(
                        into: context,
                        config: config,
                        existingUser: user,  // Seed data for the authenticated mock user
                        targetDoseCount: doseCount  // Use exact dose count from launch arguments
                    )

                    // Create additional medication profiles if requested
                    if medicationProfileCount > 1 {
                        try self.seedAdditionalMedicationProfiles(
                            count: medicationProfileCount - 1,
                            user: user,
                            context: context
                        )
                    }

                    let seedingTime = Date().timeIntervalSince(startTime) * 1000

                    Self.logger.info(
                        """
                        ✅ Test data seeding complete:
                           - Medication profiles: \(medicationProfileCount)
                           - Doses created: \(result.actualDoseCount)
                           - Skipped doses: \(result.skippedDoses.count)
                           - Adherence: \(String(format: "%.1f%%", result.adherenceRate * 100))
                           - Seeding time: \(String(format: "%.1f", seedingTime))ms
                        """)
                } catch {
                    Self.logger.error("❌ Test data seeding failed: \(error)")
                }
            }
        #endif
    }

    // MARK: - Private Helper Methods

    private func processAppleIDCredential(_ appleIDCredential: ASAuthorizationAppleIDCredential)
        async throws -> User
    {
        // Consolidated credential processing logic
        let context = self.dataController.container.mainContext

        let user = User(
            email: appleIDCredential.email,  // Pass nil if Apple doesn't provide email
            name: appleIDCredential.fullName?.formatted())

        context.insert(user)
        Self.logger.info(
            "📝 AuthenticationManager: User inserted into context - ID: \(user.id, privacy: .public)")

        try context.save()
        Self.logger.info("💾 AuthenticationManager: Context saved successfully")

        // Verify the user was actually saved
        let fetchDescriptor = FetchDescriptor<User>()
        let savedUsers = try context.fetch(fetchDescriptor)
        Self.logger.info(
            """
            🔍 AuthenticationManager: After save, found \(savedUsers.count, privacy: .public) users in database
            """
        )

        Self.logger.info(
            """
            ✅ AuthenticationManager: User created successfully - ID: \(user.id, privacy: .public), \
            Email: \(user.displayEmail, privacy: .public)
            """
        )

        return user
    }

    // MARK: - Public Methods

    func signInWithApple() async throws -> User {
        // Check if we're in manual UI testing mode
        let isManualUITesting = ProcessInfo.processInfo.arguments.contains("--manual-ui-testing")

        if isManualUITesting {
            Self.logger.info(
                "🎭 AuthenticationManager: Manual UI testing - mocking Apple ID response after delay")

            // Add a small delay to simulate the Apple ID flow (gives user time to see the Apple ID sheet)
            try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds

            // Create mock user for manual testing
            let context = self.dataController.container.mainContext
            let mockUser = User(
                email: "manual@uitesting.com",
                name: "Manual UI Test User",
                weight: 75.0,
                weightUnit: "kg")

            context.insert(mockUser)

            do {
                try context.save()
                await MainActor.run {
                    self.currentUser = mockUser
                    self.authenticationState = .authenticated
                }
                Self.logger.info("✅ AuthenticationManager: Manual UI testing user created successfully")
                return mockUser
            } catch {
                Self.logger.error(
                    "❌ AuthenticationManager: Failed to create manual UI testing user: \(error)")
                throw AuthenticationError.authorizationDenied
            }
        }

        // Regular Apple ID flow (not yet fully implemented)
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        // This is a minimal implementation to make tests pass
        // Full implementation would handle the authorization flow
        throw AuthenticationError.notImplemented
    }

    func handleSignInWithAppleResult(_ authorization: ASAuthorization) async throws -> User {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
        else {
            throw AuthenticationError.authorizationDenied
        }

        let user = try await processAppleIDCredential(appleIDCredential)

        await MainActor.run {
            self.currentUser = user
            self.authenticationState = .authenticated
        }

        return user
    }

    func signOut() async throws {
        // Clear user data from SwiftData
        let context = self.dataController.container.mainContext

        if let user = currentUser {
            context.delete(user)
            try context.save()
        }

        await MainActor.run {
            self.authenticationState = .notAuthenticated
            self.currentUser = nil
        }
    }
}

enum AuthenticationError: Error, LocalizedError {
    case notImplemented
    case authorizationDenied
    case credentialsNotFound
    case keychainError

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Authentication not fully implemented"
        case .authorizationDenied:
            return "User denied authorization"
        case .credentialsNotFound:
            return "No stored credentials found"
        case .keychainError:
            return "Error accessing Keychain"
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task {
            await self.handleSignInResult(authorization)
        }
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError _: Error
    ) {
        Task { @MainActor in
            self.authenticationState = .notAuthenticated
        }
    }

    private func handleSignInResult(_ authorization: ASAuthorization) async {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
        else {
            await MainActor.run {
                self.authenticationState = .notAuthenticated
            }
            return
        }

        do {
            let user = try await processAppleIDCredential(appleIDCredential)

            await MainActor.run {
                self.currentUser = user
                self.authenticationState = .authenticated
            }
        } catch {
            Self.logger.error(
                """
                ❌ AuthenticationManager: Failed to process Apple ID credential: \
                \(error.localizedDescription, privacy: .public)
                """
            )
            await MainActor.run {
                self.authenticationState = .notAuthenticated
            }
        }
    }
}

// MARK: - Test Data Seeding Extension

extension AuthenticationManager {
    /// Configuration for additional medication profiles
    private struct MedicationConfig {
        let medication: Medication
        let brand: String
        let dose: Double
    }

    /// Seeds additional medication profiles for multi-profile testing
    /// - Parameters:
    ///   - count: Number of additional profiles to create (beyond the primary profile)
    ///   - user: The user to associate profiles with
    ///   - context: The model context for persistence
    func seedAdditionalMedicationProfiles(
        count: Int,
        user: User,
        context: ModelContext
    ) throws {
        // Define additional medications to create (in order)
        let additionalMedications: [MedicationConfig] = [
            MedicationConfig(medication: .tirzepatide, brand: "Mounjaro", dose: 5.0),
            MedicationConfig(medication: .liraglutide, brand: "Victoza", dose: 1.2),
            MedicationConfig(medication: .dulaglutide, brand: "Trulicity", dose: 1.5),
        ]

        for index in 0..<min(count, additionalMedications.count) {
            let config = additionalMedications[index]

            let profile = MedicationProfile(
                genericName: config.medication.displayName,
                brandName: config.brand,
                currentDose: config.dose
            )
            profile.user = user
            context.insert(profile)

            Self.logger.info(
                "✅ Created additional medication profile: \(config.medication.displayName) (\(config.brand))")
        }

        try context.save()
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        else {
            fatalError("No window available for Sign in with Apple")
        }
        return window
    }
}
