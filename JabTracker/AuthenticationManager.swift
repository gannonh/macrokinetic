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

            if let user = users.first {
                // Validate Apple credential and handle revoked state
                if await self.validateAndHandleAppleCredential(for: user, context: context) == false {
                    return
                }
                self.currentUser = user
                self.authenticationState = .authenticated
                Self.logger.info("✅ AuthenticationManager: Set state to authenticated")
            } else {
                self.authenticationState = .notAuthenticated
                Self.logger.info(
                    "❌ AuthenticationManager: Set state to notAuthenticated - no users found")
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
    /// Must delete ALL entity types from DataController.modelTypes to ensure complete reset
    private func deleteAllSwiftDataEntities(context: ModelContext) throws {
        // Delete counts for logging - must match DataController.modelTypes
        let userCount = try deleteAll(User.self, from: context)
        let profileCount = try deleteAll(MedicationProfile.self, from: context)
        let doseCount = try deleteAll(Dose.self, from: context)
        let titrationCount = try deleteAll(DoseTitration.self, from: context)
        let doseScheduleCount = try deleteAll(DoseSchedule.self, from: context)
        let scheduledDoseCount = try deleteAll(ScheduledDose.self, from: context)
        let foodCount = try deleteAll(Food.self, from: context)
        let foodEntryCount = try deleteAll(FoodEntry.self, from: context)
        let weightEntryCount = try deleteAll(WeightEntry.self, from: context)
        let metricsEntryCount = try deleteAll(MetricsEntry.self, from: context)
        let progressPhotoCount = try deleteAll(ProgressPhoto.self, from: context)
        let nutritionGoalCount = try deleteAll(NutritionGoal.self, from: context)
        let nutritionProgramCount = try deleteAll(NutritionProgram.self, from: context)
        let tdeeSnapshotCount = try deleteAll(TDEESnapshot.self, from: context)

        try context.save()
        Self.logger.info(
            """
            ✅ AuthenticationManager: App data reset successfully - \
            Deleted \(userCount) users, \(profileCount) profiles, \(doseCount) doses, \
            \(titrationCount) titrations, \(doseScheduleCount) schedules, \(scheduledDoseCount) scheduled doses, \
            \(foodCount) foods, \(foodEntryCount) food entries, \(weightEntryCount) weight entries, \
            \(metricsEntryCount) metrics entries, \(progressPhotoCount) progress photos, \
            \(nutritionGoalCount) goals, \(nutritionProgramCount) programs, \(tdeeSnapshotCount) TDEE snapshots
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
            // Uses realistic biometrics for TDEE calculation testing
            var birthComponents = DateComponents()
            birthComponents.year = 1970
            birthComponents.month = 3
            birthComponents.day = 12
            let birthDate = Calendar.current.date(from: birthComponents)

            mockUser = User(
                email: "test@uitesting.com",
                name: "UI Test User",
                dateOfBirth: birthDate,
                heightCm: 188.0,  // 6'2"
                gender: "male",
                weight: 185.0,
                weightUnit: "lbs")
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

            // Mark onboarding as complete for UI testing (unless --force-onboarding is set)
            // This prevents issues with existing CloudKit users that have medication profiles
            // but hasCompletedOnboarding=false
            let shouldBypassOnboarding =
                ProcessInfo.processInfo.arguments.contains("--bypass-onboarding")
                || !ProcessInfo.processInfo.arguments.contains("--force-onboarding")

            if shouldBypassOnboarding && !mockUser.hasCompletedOnboarding {
                mockUser.hasCompletedOnboarding = true
                mockUser.onboardingCompletedAt = Date()
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                UserDefaults.standard.set(Date(), forKey: "onboardingCompletedAt")
                try? context.save()
                Self.logger.info("✅ AuthenticationManager: Marked onboarding as complete (UI testing mode)")
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
    // swiftlint:disable:next function_body_length cyclomatic_complexity
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
            }

            // Check for check-in seeding flags (different data quality tiers)
            let shouldSeedCheckInReady = arguments.contains("--seed-check-in-ready")
            let shouldSeedCheckInGood = arguments.contains("--seed-check-in-good")
            let shouldSeedCheckInMinimum = arguments.contains("--seed-check-in-minimum")
            let shouldSeedCheckInInsufficient = arguments.contains("--seed-check-in-insufficient")

            // Check for data quality seeding flags (1-year data with different densities)
            let shouldSeedHighQuality = arguments.contains("--seed-test-1y-high")
            let shouldSeedMediumQuality = arguments.contains("--seed-test-1y-medium")
            let shouldSeedLowQuality = arguments.contains("--seed-test-1y-low")
            let shouldSeedNewUser = arguments.contains("--seed-test-new-user")

            // Program style modifier (default: Coached, with flag: Collaborative)
            let useCollaborative = arguments.contains("--seed-collaborative")
            let programStyle: ProgramStyle = useCollaborative ? .collaborative : .coached

            let hasCheckInSeeding =
                shouldSeedCheckInReady || shouldSeedCheckInGood
                || shouldSeedCheckInMinimum || shouldSeedCheckInInsufficient

            let hasDataQualitySeeding =
                shouldSeedHighQuality || shouldSeedMediumQuality
                || shouldSeedLowQuality || shouldSeedNewUser

            // Check for active user seeding flags
            let shouldSeed3DayActive = arguments.contains("--seed-3-day-active")
            let shouldSeed5DayActive = arguments.contains("--seed-5-day-active")
            let shouldSeed2WeekActive = arguments.contains("--seed-2-week-active")
            let shouldSeed1MonthActive = arguments.contains("--seed-1-month-active")
            let shouldSeed90DayActive = arguments.contains("--seed-90-day-active")

            let hasActiveUserSeeding =
                shouldSeed3DayActive || shouldSeed5DayActive || shouldSeed2WeekActive
                || shouldSeed1MonthActive || shouldSeed90DayActive

            // If neither flag is present, skip seeding
            if daysOfHistory == 0 && !hasCheckInSeeding && !hasDataQualitySeeding && !hasActiveUserSeeding {
                return  // No seeding requested
            }

            // Seed data quality variants (1-year with different densities)
            if hasDataQualitySeeding {
                let qualityLevel: DataQualityLevel
                if shouldSeedHighQuality {
                    qualityLevel = .high
                } else if shouldSeedMediumQuality {
                    qualityLevel = .medium
                } else if shouldSeedLowQuality {
                    qualityLevel = .low
                } else {
                    qualityLevel = .newUser
                }

                Self.logger.info("🎯 Seeding data quality level: \(qualityLevel.rawValue)")
                await MainActor.run {
                    do {
                        _ = try TestDataSeeding.seedDataWithQuality(
                            into: context,
                            qualityLevel: qualityLevel,
                            existingUser: user
                        )
                    } catch {
                        Self.logger.error("❌ Data quality seeding failed: \(error)")
                    }
                }
                // Continue to medication seeding if requested (don't return early)
            }

            // Seed active user scenarios (specific days of food/weight + doses)
            if hasActiveUserSeeding {
                let scenario: ActiveUserScenario
                if shouldSeed3DayActive {
                    scenario = .threeDay
                } else if shouldSeed5DayActive {
                    scenario = .fiveDay
                } else if shouldSeed2WeekActive {
                    scenario = .twoWeek
                } else if shouldSeed1MonthActive {
                    scenario = .oneMonth
                } else {
                    scenario = .ninetyDay
                }

                Self.logger.info("🎯 Seeding active user scenario: \(scenario.rawValue)")
                await MainActor.run {
                    do {
                        _ = try TestDataSeeding.seedActiveUserData(
                            into: context,
                            scenario: scenario,
                            existingUser: user
                        )
                    } catch {
                        Self.logger.error("❌ Active user seeding failed: \(error)")
                    }
                }
                return  // Active user seeding includes doses, so return early
            }

            // Seed check-in data based on requested tier (only one tier at a time)
            // Skip if data quality seeding already created goals/programs
            if !hasDataQualitySeeding {
                if shouldSeedCheckInReady {
                    await seedCheckInReadyData(for: user, context: context, programStyle: programStyle)
                } else if shouldSeedCheckInGood {
                    await seedCheckInGoodData(for: user, context: context, programStyle: programStyle)
                } else if shouldSeedCheckInMinimum {
                    await seedCheckInMinimumData(for: user, context: context, programStyle: programStyle)
                } else if shouldSeedCheckInInsufficient {
                    await seedCheckInInsufficientData(for: user, context: context, programStyle: programStyle)
                }
            }

            // Skip dose seeding if only check-in-ready was requested
            guard daysOfHistory > 0 else { return }

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

    /// Seed nutrition goal and program with check-in ready state for UI testing
    /// Creates a weight loss goal with specified program style, sets lastCheckInDate to 10 days ago
    // swiftlint:disable:next function_body_length
    private func seedCheckInReadyData(
        for user: User,
        context: ModelContext,
        programStyle: ProgramStyle = .coached
    ) async {
        #if DEBUG || TEST
            Self.logger.info("🎯 Seeding check-in ready data (\(programStyle.rawValue)) for UI testing")

            await MainActor.run {
                do {
                    let calendar = Calendar.current

                    // Set user biometrics for TDEE calculation
                    user.heightCm = 175.0
                    user.gender = "male"
                    user.dateOfBirth = calendar.date(byAdding: .year, value: -30, to: Date())

                    // Create weight loss goal
                    let goal = NutritionGoal(
                        goalType: .weightLoss,
                        isActive: true,
                        startingWeightKg: 90.0,
                        targetWeightKg: 80.0,
                        targetDate: calendar.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
                        weeklyWeightChangePaceKg: -0.5,
                        dailyCalorieTarget: 2000.0,
                        dailyProteinTargetGrams: 150.0,
                        dailyCarbTargetGrams: 200.0,
                        dailyFatTargetGrams: 65.0
                    )

                    // Set TDEE values
                    goal.initialEstimatedTDEE = 2400.0
                    goal.lastCalculatedTDEE = 2350.0
                    goal.lastTDEECalculationDate = calendar.date(byAdding: .day, value: -7, to: Date())

                    // Set check-in as due: today is check-in day + 10 days since last
                    goal.lastCheckInDate = calendar.date(byAdding: .day, value: -10, to: Date())
                    goal.checkInDayOfWeek = calendar.component(.weekday, from: Date())  // Today's weekday

                    goal.user = user
                    context.insert(goal)

                    // Create program with specified style
                    let program = NutritionProgram(
                        style: programStyle,
                        diet: .balanced,
                        calorieFloor: .standard,
                        trainingLevel: .lifting,
                        distributionMode: .even,
                        proteinLevel: .moderate
                    )
                    program.goal = goal
                    context.insert(program)

                    // Seed 90 days of weight history (matches TDEE snapshot history)
                    // Starting weight ~92kg, ending ~88kg (gradual 4kg loss over 90 days)
                    for dayOffset in 0..<90 {
                        let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
                        // Gradual downward trend: 92kg -> 88kg over 90 days with daily noise
                        let progress = Double(90 - dayOffset) / 90.0  // 0 at day -90, 1 at today
                        let baseWeight = 92.0 - (4.0 * progress)  // 92kg to 88kg
                        let noise = Double.random(in: -0.4...0.4)
                        let weightKg = baseWeight + noise
                        let weightEntry = WeightEntry(timestamp: date, weightKg: weightKg)
                        context.insert(weightEntry)
                    }

                    // Seed 90 days of food entries (matches weight and TDEE snapshot history)
                    for dayOffset in 0..<90 {
                        let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()

                        // Today (dayOffset == 0): only breakfast + lunch to show partial progress (~50%)
                        let isToday = dayOffset == 0

                        // Add daily variance: some days higher, some lower (±15%)
                        let dayMultiplier = Double.random(in: 0.85...1.15)

                        // Occasionally skip breakfast (~20% of days, but not today)
                        let skipBreakfast = !isToday && Double.random(in: 0...1) < 0.2

                        // Base meals with per-meal variance (±10%)
                        let breakfastMult = skipBreakfast ? 0.0 : Double.random(in: 0.9...1.1)
                        let lunchMult = Double.random(in: 0.9...1.1)
                        // Skip dinner today to show partial day progress
                        let dinnerMult = isToday ? 0.0 : Double.random(in: 0.9...1.1)

                        // Sometimes add snacks (~40% of days, but not today)
                        let hasSnack = !isToday && Double.random(in: 0...1) < 0.4

                        // Create meals with variance applied via serving size
                        let mealConfigs: [(MealSection, Double)] = [
                            (.breakfast, breakfastMult * dayMultiplier),
                            (.lunch, lunchMult * dayMultiplier),
                            (.dinner, dinnerMult * dayMultiplier),
                        ]

                        for (section, mult) in mealConfigs {
                            guard mult > 0 else { continue }  // Skip if multiplier is 0

                            // Base macros per meal type
                            let (baseCal, protein, carbs, fat): (Double, Double, Double, Double) = {
                                switch section {
                                case .breakfast: return (400, 25, 50, 15)
                                case .lunch: return (700, 45, 60, 30)
                                case .dinner: return (800, 55, 70, 35)
                                default: return (500, 30, 50, 20)
                                }
                            }()

                            let entry = FoodEntry(
                                foodName: "Test \(section.rawValue)",
                                mealSection: section,
                                loggedAt: date,
                                servingGrams: 100.0 * mult,
                                caloriesPer100g: baseCal,
                                proteinPer100g: protein,
                                carbsPer100g: carbs,
                                fatPer100g: fat
                            )
                            context.insert(entry)
                        }

                        // Add snack on some days
                        if hasSnack {
                            let snackEntry = FoodEntry(
                                foodName: "Test snack",
                                mealSection: .snacks,
                                loggedAt: date,
                                servingGrams: 100.0 * Double.random(in: 0.8...1.2),
                                caloriesPer100g: 200,
                                proteinPer100g: 10,
                                carbsPer100g: 25,
                                fatPer100g: 8
                            )
                            context.insert(snackEntry)
                        }
                    }

                    // Seed 90 days of TDEE history snapshots
                    // Shows gradual decrease from initial (2400) to current (2350)
                    let initialTDEE = 2400.0
                    let currentTDEE = 2350.0
                    let tdeeRange = initialTDEE - currentTDEE  // 50 kcal decrease over 90 days

                    Self.logger.debug("🔄 Seeding 90 TDEESnapshot entries...")
                    var snapshotCount = 0
                    for dayOffset in 0..<90 {
                        guard let snapshotDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                            continue
                        }

                        // Calculate TDEE: gradual decrease with daily noise
                        let progress = Double(90 - dayOffset) / 90.0  // 0 at day -90, 1 at today
                        let baseTDEE = initialTDEE - (tdeeRange * progress)
                        let noise = Double.random(in: -8...8)
                        let tdeeValue = baseTDEE + noise

                        // Source: initial for first week, then mix of adaptive/holding
                        // Days 1-7 (dayOffset 83-89): initial
                        // Days 8-60 (dayOffset 30-82): 70% adaptive, 30% holding
                        // Days 61-90 (dayOffset 0-29): 90% adaptive, 10% holding
                        let sourceType: TDEESourceType
                        if dayOffset > 83 {
                            sourceType = .initial
                        } else if dayOffset >= 30 {
                            // Days 8-60: 70% adaptive, 30% holding
                            sourceType = Double.random(in: 0...1) < 0.7 ? .adaptive : .holding
                        } else {
                            // Days 61-90: 90% adaptive, 10% holding
                            sourceType = Double.random(in: 0...1) < 0.9 ? .adaptive : .holding
                        }

                        // Confidence increases over time (more data = more confidence)
                        // Holding snapshots get lower confidence
                        // Day -90: 0.3, Day 0: 0.85, holding snapshots reduced by 20%
                        var confidence = 0.3 + (0.55 * progress)
                        if sourceType == .holding {
                            confidence *= 0.8
                        }

                        let snapshot = TDEESnapshot(
                            timestamp: snapshotDate,
                            tdeeValue: tdeeValue,
                            confidence: confidence,
                            source: sourceType
                        )
                        context.insert(snapshot)
                        snapshotCount += 1
                    }
                    Self.logger.debug("✅ Created \(snapshotCount) TDEESnapshot entries")

                    try context.save()

                    Self.logger.info(
                        """
                        ✅ Check-in ready data seeded:
                           - Goal: Weight loss (90kg → 80kg)
                           - Program: Coached/Balanced
                           - TDEE: 2350 kcal (from 2400 initial)
                           - TDEE snapshots: 90 days (mixed sources: initial/adaptive/holding)
                           - Last check-in: 10 days ago (due for check-in)
                           - Weight entries: 90 days (92kg → 88kg with ±0.4kg noise)
                           - Food entries: 90 days (with variance: ±15% daily, ±10% per meal)
                           - Breakfast skipped ~20% of days, snacks added ~40% of days
                        """)
                } catch {
                    Self.logger.error("❌ Check-in ready data seeding failed: \(error)")
                }
            }
        #endif
    }

    /// Seed check-in data with GOOD tier quality (10 weights, 65% food, 10 days)
    /// - Allows check-in with good confidence (ceiling 0.7)
    // swiftlint:disable:next function_body_length
    private func seedCheckInGoodData(
        for user: User,
        context: ModelContext,
        programStyle: ProgramStyle = .coached
    ) async {
        #if DEBUG || TEST
            Self.logger.info("🎯 Seeding GOOD tier check-in data (\(programStyle.rawValue)) for UI testing")

            await MainActor.run {
                do {
                    let calendar = Calendar.current

                    // Set user biometrics for TDEE calculation
                    user.heightCm = 175.0
                    user.gender = "male"
                    user.dateOfBirth = calendar.date(byAdding: .year, value: -30, to: Date())

                    // Create weight loss goal
                    let goal = NutritionGoal(
                        goalType: .weightLoss,
                        isActive: true,
                        startingWeightKg: 90.0,
                        targetWeightKg: 80.0,
                        targetDate: calendar.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
                        weeklyWeightChangePaceKg: -0.5,
                        dailyCalorieTarget: 2000.0,
                        dailyProteinTargetGrams: 150.0,
                        dailyCarbTargetGrams: 200.0,
                        dailyFatTargetGrams: 65.0
                    )

                    // Set TDEE values
                    goal.initialEstimatedTDEE = 2400.0
                    goal.lastCalculatedTDEE = 2350.0
                    goal.lastTDEECalculationDate = calendar.date(byAdding: .day, value: -7, to: Date())

                    // Set check-in as due: today is check-in day + 10 days since last
                    goal.lastCheckInDate = calendar.date(byAdding: .day, value: -10, to: Date())
                    goal.checkInDayOfWeek = calendar.component(.weekday, from: Date())

                    goal.user = user
                    context.insert(goal)

                    // Create program with specified style
                    let program = NutritionProgram(
                        style: programStyle,
                        diet: .balanced,
                        calorieFloor: .standard,
                        trainingLevel: .lifting,
                        distributionMode: .even,
                        proteinLevel: .moderate
                    )
                    program.goal = goal
                    context.insert(program)

                    // Seed 10 weight entries across 10 days (just above minimum)
                    for dayOffset in 0..<10 {
                        let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
                        let weightKg = 89.0 - (Double(5 - dayOffset) * 0.03) + Double.random(in: -0.2...0.2)
                        let weightEntry = WeightEntry(timestamp: date, weightKg: weightKg)
                        context.insert(weightEntry)
                    }

                    // Seed 7 days of food entries (65% of 10-day span, > 60% threshold)
                    for dayOffset in 0..<7 {
                        let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
                        let meals: [(MealSection, Double, Double, Double, Double)] = [
                            (.breakfast, 400, 25, 50, 15),
                            (.lunch, 700, 45, 60, 30),
                            (.dinner, 800, 55, 70, 35),
                        ]
                        for (section, cal, protein, carbs, fat) in meals {
                            let entry = FoodEntry(
                                foodName: "Test \(section.rawValue)",
                                mealSection: section,
                                loggedAt: date,
                                servingGrams: 100.0,
                                caloriesPer100g: cal,
                                proteinPer100g: protein,
                                carbsPer100g: carbs,
                                fatPer100g: fat
                            )
                            context.insert(entry)
                        }
                    }

                    try context.save()

                    Self.logger.info(
                        """
                        ✅ GOOD tier check-in data seeded:
                           - Goal: Weight loss (90kg → 80kg)
                           - Program: Coached/Balanced
                           - TDEE: 2350 kcal
                           - Weight entries: 10 (tier threshold: 7+)
                           - Food consistency: 65% (tier threshold: 60%+)
                           - Day span: 10 days (tier threshold: 7+)
                           - Data quality: GOOD (confidence ceiling: 0.7)
                        """)
                } catch {
                    Self.logger.error("❌ GOOD tier check-in data seeding failed: \(error)")
                }
            }
        #endif
    }

    /// Seed check-in data with MINIMUM tier quality (4 weights, 55% food, 7 days)
    /// - Allows check-in with low confidence (ceiling 0.5)
    // swiftlint:disable:next function_body_length
    private func seedCheckInMinimumData(
        for user: User,
        context: ModelContext,
        programStyle: ProgramStyle = .coached
    ) async {
        #if DEBUG || TEST
            Self.logger.info("🎯 Seeding MINIMUM tier check-in data (\(programStyle.rawValue)) for UI testing")

            await MainActor.run {
                do {
                    let calendar = Calendar.current

                    // Set user biometrics for TDEE calculation
                    user.heightCm = 175.0
                    user.gender = "male"
                    user.dateOfBirth = calendar.date(byAdding: .year, value: -30, to: Date())

                    // Create weight loss goal
                    let goal = NutritionGoal(
                        goalType: .weightLoss,
                        isActive: true,
                        startingWeightKg: 90.0,
                        targetWeightKg: 80.0,
                        targetDate: calendar.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
                        weeklyWeightChangePaceKg: -0.5,
                        dailyCalorieTarget: 2000.0,
                        dailyProteinTargetGrams: 150.0,
                        dailyCarbTargetGrams: 200.0,
                        dailyFatTargetGrams: 65.0
                    )

                    // Set TDEE values
                    goal.initialEstimatedTDEE = 2400.0
                    goal.lastCalculatedTDEE = 2350.0
                    goal.lastTDEECalculationDate = calendar.date(byAdding: .day, value: -7, to: Date())

                    // Set check-in as due: today is check-in day + 10 days since last
                    goal.lastCheckInDate = calendar.date(byAdding: .day, value: -10, to: Date())
                    goal.checkInDayOfWeek = calendar.component(.weekday, from: Date())

                    goal.user = user
                    context.insert(goal)

                    // Create program with specified style
                    let program = NutritionProgram(
                        style: programStyle,
                        diet: .balanced,
                        calorieFloor: .standard,
                        trainingLevel: .lifting,
                        distributionMode: .even,
                        proteinLevel: .moderate
                    )
                    program.goal = goal
                    context.insert(program)

                    // Seed 4 weight entries spanning 8 days (safely above 7-day minimum)
                    let weightDays = [0, 3, 5, 8]  // 4 entries, span = 8 days
                    for dayOffset in weightDays {
                        let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
                        let weightKg = 89.5 - (Double(3 - dayOffset) * 0.02) + Double.random(in: -0.2...0.2)
                        let weightEntry = WeightEntry(timestamp: date, weightKg: weightKg)
                        context.insert(weightEntry)
                    }

                    // Seed 5 days of food entries (5/8 = 62.5%, above 50% threshold)
                    for dayOffset in 0..<5 {
                        let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
                        let meals: [(MealSection, Double, Double, Double, Double)] = [
                            (.breakfast, 400, 25, 50, 15),
                            (.lunch, 700, 45, 60, 30),
                            (.dinner, 800, 55, 70, 35),
                        ]
                        for (section, cal, protein, carbs, fat) in meals {
                            let entry = FoodEntry(
                                foodName: "Test \(section.rawValue)",
                                mealSection: section,
                                loggedAt: date,
                                servingGrams: 100.0,
                                caloriesPer100g: cal,
                                proteinPer100g: protein,
                                carbsPer100g: carbs,
                                fatPer100g: fat
                            )
                            context.insert(entry)
                        }
                    }

                    try context.save()

                    Self.logger.info(
                        """
                        ✅ MINIMUM tier check-in data seeded:
                           - Goal: Weight loss (90kg → 80kg)
                           - Program: \(programStyle.rawValue)
                           - TDEE: 2350 kcal
                           - Weight entries: 4 (tier threshold: 3+)
                           - Food consistency: 62.5% (tier threshold: 50%+)
                           - Day span: 8 days (tier threshold: 7+)
                           - Data quality: MINIMUM (confidence ceiling: 0.5)
                        """)
                } catch {
                    Self.logger.error("❌ MINIMUM tier check-in data seeding failed: \(error)")
                }
            }
        #endif
    }

    /// Seed check-in data with INSUFFICIENT tier quality (2 weights, 40% food, 5 days)
    /// - Does NOT allow check-in (shows "not enough data" message)
    // swiftlint:disable:next function_body_length
    private func seedCheckInInsufficientData(
        for user: User,
        context: ModelContext,
        programStyle: ProgramStyle = .coached
    ) async {
        #if DEBUG || TEST
            Self.logger.info("🎯 Seeding INSUFFICIENT tier check-in data (\(programStyle.rawValue)) for UI testing")

            await MainActor.run {
                do {
                    let calendar = Calendar.current

                    // Set user biometrics for TDEE calculation
                    user.heightCm = 175.0
                    user.gender = "male"
                    user.dateOfBirth = calendar.date(byAdding: .year, value: -30, to: Date())

                    // Create weight loss goal
                    let goal = NutritionGoal(
                        goalType: .weightLoss,
                        isActive: true,
                        startingWeightKg: 90.0,
                        targetWeightKg: 80.0,
                        targetDate: calendar.date(byAdding: .month, value: 3, to: Date()) ?? Date(),
                        weeklyWeightChangePaceKg: -0.5,
                        dailyCalorieTarget: 2000.0,
                        dailyProteinTargetGrams: 150.0,
                        dailyCarbTargetGrams: 200.0,
                        dailyFatTargetGrams: 65.0
                    )

                    // Set TDEE values
                    goal.initialEstimatedTDEE = 2400.0
                    goal.lastCalculatedTDEE = 2350.0
                    goal.lastTDEECalculationDate = calendar.date(byAdding: .day, value: -3, to: Date())

                    // Set check-in as due: today is check-in day + 10 days since last
                    goal.lastCheckInDate = calendar.date(byAdding: .day, value: -10, to: Date())
                    goal.checkInDayOfWeek = calendar.component(.weekday, from: Date())

                    goal.user = user
                    context.insert(goal)

                    // Create program with specified style
                    let program = NutritionProgram(
                        style: programStyle,
                        diet: .balanced,
                        calorieFloor: .standard,
                        trainingLevel: .lifting,
                        distributionMode: .even,
                        proteinLevel: .moderate
                    )
                    program.goal = goal
                    context.insert(program)

                    // Seed only 2 weight entries across 5 days (below minimum)
                    let weightDays = [0, 4]  // Just 2 entries
                    for dayOffset in weightDays {
                        let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
                        let weightKg = 89.7 + Double.random(in: -0.2...0.2)
                        let weightEntry = WeightEntry(timestamp: date, weightKg: weightKg)
                        context.insert(weightEntry)
                    }

                    // Seed only 2 days of food entries (40% of 5-day span, below 50% threshold)
                    for dayOffset in 0..<2 {
                        let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
                        let meals: [(MealSection, Double, Double, Double, Double)] = [
                            (.breakfast, 400, 25, 50, 15),
                            (.lunch, 700, 45, 60, 30),
                            (.dinner, 800, 55, 70, 35),
                        ]
                        for (section, cal, protein, carbs, fat) in meals {
                            let entry = FoodEntry(
                                foodName: "Test \(section.rawValue)",
                                mealSection: section,
                                loggedAt: date,
                                servingGrams: 100.0,
                                caloriesPer100g: cal,
                                proteinPer100g: protein,
                                carbsPer100g: carbs,
                                fatPer100g: fat
                            )
                            context.insert(entry)
                        }
                    }

                    try context.save()

                    Self.logger.info(
                        """
                        ✅ INSUFFICIENT tier check-in data seeded:
                           - Goal: Weight loss (90kg → 80kg)
                           - Program: Coached/Balanced
                           - TDEE: 2350 kcal
                           - Weight entries: 2 (tier threshold: 3+)
                           - Food consistency: 40% (tier threshold: 50%+)
                           - Day span: 5 days (tier threshold: 7+)
                           - Data quality: INSUFFICIENT (check-in blocked)
                        """)
                } catch {
                    Self.logger.error("❌ INSUFFICIENT tier check-in data seeding failed: \(error)")
                }
            }
        #endif
    }

    // MARK: - Private Helper Methods

    /// Validates the user's Apple credential and handles revoked state.
    /// Returns true if credential is valid or not present, false if revoked (and sets auth state).
    private func validateAndHandleAppleCredential(for user: User, context: ModelContext) async -> Bool {
        guard let appleUserId = user.appleUserId else {
            return true  // No Apple ID stored, skip validation
        }

        let credentialState = await self.checkAppleCredentialState(userId: appleUserId)
        if credentialState != .authorized {
            let stateDesc = String(describing: credentialState)
            Self.logger.warning(
                "⚠️ AuthenticationManager: Apple credential invalid (state: \(stateDesc))"
            )
            // Clear the invalid Apple ID but keep user data
            user.appleUserId = nil
            try? context.save()
            self.authenticationState = .notAuthenticated
            Self.logger.info(
                "❌ AuthenticationManager: Set state to notAuthenticated - credential revoked"
            )
            return false
        }
        return true
    }

    /// Check if an Apple ID credential is still valid
    private func checkAppleCredentialState(userId: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        let provider = ASAuthorizationAppleIDProvider()
        do {
            return try await provider.credentialState(forUserID: userId)
        } catch {
            Self.logger.error("❌ AuthenticationManager: Failed to check credential state: \(error, privacy: .public)")
            return .notFound
        }
    }

    private func processAppleIDCredential(_ appleIDCredential: ASAuthorizationAppleIDCredential)
        async throws -> User
    {
        // Consolidated credential processing logic
        let context = self.dataController.container.mainContext

        // Find existing user or create new one (single-user app)
        let fetchDescriptor = FetchDescriptor<User>()
        let existingUsers = try context.fetch(fetchDescriptor)

        let user: User
        if let existingUser = existingUsers.first {
            // Update existing user with Apple ID credentials
            existingUser.appleUserId = appleIDCredential.user
            if let name = appleIDCredential.fullName?.formatted(), !name.isEmpty {
                existingUser.name = name
            }
            // Email only provided on first auth, update if available
            if let email = appleIDCredential.email {
                existingUser.email = email
            }
            user = existingUser
            Self.logger.info(
                "📝 AuthenticationManager: Updated existing user with Apple ID - ID: \(user.id, privacy: .public)")
        } else {
            // Create new user
            user = User(
                email: appleIDCredential.email,
                name: appleIDCredential.fullName?.formatted())
            user.appleUserId = appleIDCredential.user
            context.insert(user)
            Self.logger.info(
                "📝 AuthenticationManager: Created new user - ID: \(user.id, privacy: .public)")
        }

        try context.save()
        Self.logger.info("💾 AuthenticationManager: Context saved successfully")

        // Verify the user was actually saved
        let verifyDescriptor = FetchDescriptor<User>()
        let savedUsers = try context.fetch(verifyDescriptor)
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
            // Uses realistic biometrics for TDEE calculation testing
            let context = self.dataController.container.mainContext
            var birthComponents = DateComponents()
            birthComponents.year = 1970
            birthComponents.month = 3
            birthComponents.day = 12
            let birthDate = Calendar.current.date(from: birthComponents)

            let mockUser = User(
                email: "manual@uitesting.com",
                name: "Manual UI Test User",
                dateOfBirth: birthDate,
                heightCm: 188.0,  // 6'2"
                gender: "male",
                weight: 185.0,
                weightUnit: "lbs")

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
                currentDose: config.dose,
                medicationType: config.medication.rawValue
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
