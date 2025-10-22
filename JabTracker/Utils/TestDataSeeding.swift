//
//  TestDataSeeding.swift
//  JabTracker
//
//  Comprehensive data seeding utilities for unit and E2E tests
//  Supports large dataset generation for performance testing
//
//  IMPORTANT: Only compiled when building for testing (DEBUG or testing environments)

#if DEBUG || TEST
    import Foundation
    import OSLog
    import SwiftData

    private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "TestDataSeeding")

    /// Configuration for generating test data
    struct TestDataSeedingConfig {
        /// Number of days of historical data to generate
        let daysOfHistory: Int

        /// Medication to use for seeding
        let medication: Medication

        /// Brand name for the medication
        let brandName: String

        /// Dose amount in mg
        let doseAmount: Double

        /// Injection sites to cycle through
        let injectionSites: [String]

        /// Adherence rate (0.0 to 1.0) - percentage of expected doses that are taken
        let adherenceRate: Double

        /// Whether to add variability in dose timing (±2 hours)
        let addTimingVariability: Bool

        /// Whether to include skipped doses
        let includeSkippedDoses: Bool

        // MARK: - Preset Configurations

        /// Small dataset for quick tests (7 days of data)
        static let small = TestDataSeedingConfig(
            daysOfHistory: 7,
            medication: .semaglutide,
            brandName: "Ozempic",
            doseAmount: 0.25,
            injectionSites: ["Abdomen", "Thigh"],
            adherenceRate: 1.0,
            addTimingVariability: false,
            includeSkippedDoses: false
        )

        /// Medium dataset for standard tests (30 days of data)
        static let medium = TestDataSeedingConfig(
            daysOfHistory: 30,
            medication: .semaglutide,
            brandName: "Ozempic",
            doseAmount: 0.5,
            injectionSites: ["Abdomen", "Thigh", "Upper Arm"],
            adherenceRate: 0.95,
            addTimingVariability: true,
            includeSkippedDoses: true
        )

        /// Large dataset for performance tests (365 days of data)
        static let large = TestDataSeedingConfig(
            daysOfHistory: 365,
            medication: .semaglutide,
            brandName: "Ozempic",
            doseAmount: 1.0,
            injectionSites: ["Abdomen", "Thigh", "Upper Arm", "Buttock"],
            adherenceRate: 0.92,
            addTimingVariability: true,
            includeSkippedDoses: true
        )

        /// Extra large dataset for stress tests (730 days / 2 years of data)
        static let extraLarge = TestDataSeedingConfig(
            daysOfHistory: 730,
            medication: .tirzepatide,
            brandName: "Mounjaro",
            doseAmount: 5.0,
            injectionSites: ["Abdomen", "Thigh", "Upper Arm", "Buttock"],
            adherenceRate: 0.90,
            addTimingVariability: true,
            includeSkippedDoses: true
        )

        /// Custom configuration
        init(
            daysOfHistory: Int,
            medication: Medication = .semaglutide,
            brandName: String = "Ozempic",
            doseAmount: Double = 1.0,
            injectionSites: [String] = ["Abdomen", "Thigh"],
            adherenceRate: Double = 1.0,
            addTimingVariability: Bool = false,
            includeSkippedDoses: Bool = false
        ) {
            self.daysOfHistory = daysOfHistory
            self.medication = medication
            self.brandName = brandName
            self.doseAmount = doseAmount
            self.injectionSites = injectionSites
            self.adherenceRate = min(max(adherenceRate, 0.0), 1.0)  // Clamp 0-1
            self.addTimingVariability = addTimingVariability
            self.includeSkippedDoses = includeSkippedDoses
        }
    }

    /// Result of data seeding operation
    struct TestDataSeedingResult {
        let user: User
        let medicationProfile: MedicationProfile
        let doses: [Dose]
        let skippedDoses: [Dose]
        let expectedDoseCount: Int
        let actualDoseCount: Int
        let adherenceRate: Double
    }

    /// Data seeding utilities for test data generation
    enum TestDataSeeding {

        // MARK: - Unit Test Data Seeding (SwiftData)

        /// Seed data into a SwiftData ModelContext for unit tests
        /// - Parameters:
        ///   - context: The ModelContext to seed data into
        ///   - config: Configuration for data generation
        ///   - existingUser: Optional existing user to seed data for (E2E tests). If nil, creates new user (unit tests)
        ///   - targetDoseCount: Optional exact number of doses to create (overrides daysOfHistory calculation)
        /// - Returns: Result containing created entities
        @MainActor
        // swiftlint:disable:next function_body_length
        static func seedData(
            into context: ModelContext,
            config: TestDataSeedingConfig = .medium,
            existingUser: User? = nil,
            targetDoseCount: Int? = nil
        ) throws -> TestDataSeedingResult {
            // Use existing user (E2E tests) or create new user (unit tests)
            let user: User
            if let existingUser = existingUser {
                user = existingUser
            } else {
                user = User(
                    email: "test@example.com",
                    name: "Test User",
                    weight: 80.0
                )
                context.insert(user)
            }

            // Create medication profile
            let profile = MedicationProfile(
                genericName: config.medication.rawValue,
                brandName: config.brandName,
                currentDose: config.doseAmount,
                medicationType: config.medication.rawValue
            )
            profile.user = user
            context.insert(profile)

            // Generate doses based on medication frequency
            let doseSchedule = generateDoseSchedule(
                for: config.medication,
                daysOfHistory: config.daysOfHistory,
                targetDoseCount: targetDoseCount
            )

            var createdDoses: [Dose] = []
            var skippedDoses: [Dose] = []

            for (index, scheduledDate) in doseSchedule.enumerated() {
                // Determine if this dose should be skipped based on adherence rate
                let shouldSkip = config.includeSkippedDoses && Double.random(in: 0...1) > config.adherenceRate

                // SKIP creating a logged Dose entity for skipped doses
                // They will only appear as scheduled doses that weren't fulfilled
                if shouldSkip {
                    continue  // Don't create a logged dose for skipped doses
                }

                // Add timing variability if configured
                var actualTimestamp = scheduledDate
                if config.addTimingVariability {
                    let variabilitySeconds = Double.random(in: -7200...7200)  // ±2 hours
                    actualTimestamp = scheduledDate.addingTimeInterval(variabilitySeconds)
                }

                // Select injection site (cycle through available sites)
                let siteIndex = index % config.injectionSites.count
                let injectionSite = config.injectionSites[siteIndex]

                // Create dose (only for actually logged doses)
                let dose = Dose(
                    amount: config.doseAmount,
                    timestamp: actualTimestamp,
                    site: injectionSite,
                    skipped: false  // Only logged doses are created, so skipped is always false
                )

                // Set analytics metadata
                dose.expectedTimestamp = scheduledDate
                dose.actualTimestamp = actualTimestamp

                let isOnTime = abs(actualTimestamp.timeIntervalSince(scheduledDate)) < 3600  // Within 1 hour
                dose.analyticsTags = isOnTime ? ["on_time"] : ["late"]

                // Set relationships
                dose.user = user
                dose.medication = profile

                context.insert(dose)
                createdDoses.append(dose)
            }

            // Create DoseSchedule entity for calendar scheduled dose display
            // Use the FIRST logged dose time to cover entire historical period
            if let firstDose = createdDoses.first {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: firstDose.timestamp)

                // Create schedule configuration
                let scheduleConfig = ScheduleConfiguration(
                    dayOfWeek: config.medication.frequency == .weekly
                        ? calendar.component(.weekday, from: firstDose.timestamp) : nil,
                    timeOfDay: TimeComponents(hour: components.hour ?? 9, minute: components.minute ?? 0),
                    interval: config.medication.frequency == .weekly ? 7 : 1,
                    doseAmount: config.doseAmount,
                    windowMinutesBefore: 120,  // 2 hours before
                    windowMinutesAfter: 120,  // 2 hours after
                    splitDoseCount: nil,
                    splitIntervalMinutes: nil,
                    customRecurrence: nil
                )

                // Encode configuration to Data
                let encoder = JSONEncoder()
                guard let scheduleData = try? encoder.encode(scheduleConfig) else {
                    // If encoding fails, skip schedule creation but continue with test data
                    logger.warning("Failed to encode schedule configuration for test data")
                    try context.save()
                    return TestDataSeedingResult(
                        user: user,
                        medicationProfile: profile,
                        doses: createdDoses,
                        skippedDoses: skippedDoses,
                        expectedDoseCount: doseSchedule.count,
                        actualDoseCount: createdDoses.count,
                        adherenceRate: Double(createdDoses.count) / Double(doseSchedule.count)
                    )
                }

                // Create DoseSchedule with encoded configuration
                let schedule = DoseSchedule(
                    medicationProfile: profile,
                    patternType: .weekly,
                    baseSchedule: scheduleData,
                    isActive: true
                )
                schedule.createdAt = firstDose.timestamp  // Set start date to FIRST dose for full historical coverage
                context.insert(schedule)
            }

            // Save context
            try context.save()

            return TestDataSeedingResult(
                user: user,
                medicationProfile: profile,
                doses: createdDoses,
                skippedDoses: skippedDoses,
                expectedDoseCount: doseSchedule.count,
                actualDoseCount: createdDoses.count,
                adherenceRate: Double(createdDoses.count) / Double(doseSchedule.count)
            )
        }

        /// Generate dose schedule based on medication frequency
        /// - Parameters:
        ///   - medication: The medication type (determines frequency)
        ///   - daysOfHistory: Number of days to generate
        ///   - targetDoseCount: Optional exact number of doses to create (overrides time-based calculation)
        /// - Returns: Array of scheduled dose dates
        static func generateDoseSchedule(
            for medication: Medication,
            daysOfHistory: Int,
            targetDoseCount: Int? = nil
        ) -> [Date] {
            var schedule: [Date] = []
            let now = Date()
            let calendar = Calendar.current

            // Get medication frequency
            let frequency = medication.frequency
            let intervalDays: Int

            switch frequency {
            case .daily:
                intervalDays = 1
            case .weekly:
                intervalDays = 7
            }

            // If targetDoseCount is specified, create exact number of doses
            if let targetCount = targetDoseCount {
                guard targetCount > 0 else {
                    return []  // Return empty array for 0 doses
                }

                // Create doses going backwards from now
                for index in 0..<targetCount {
                    let daysBack = index * intervalDays
                    let doseDate = calendar.date(byAdding: .day, value: -daysBack, to: now) ?? now
                    schedule.append(doseDate)
                }

                return schedule.reversed()  // Return chronological order
            }

            // Otherwise, generate doses based on daysOfHistory
            var currentDate = now
            let endDate = calendar.date(byAdding: .day, value: -daysOfHistory, to: now) ?? now

            while currentDate >= endDate {
                schedule.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: -intervalDays, to: currentDate) ?? currentDate
            }

            return schedule.reversed()  // Return chronological order
        }

        // MARK: - E2E Test Data Seeding (via App Launch)

        /// Generate data seeding configuration for E2E tests (passed via launch arguments)
        /// - Parameter config: Configuration for data generation
        /// - Returns: Dictionary of launch arguments/environment variables
        static func launchArgumentsForSeeding(config: TestDataSeedingConfig) -> [String: String] {
            [
                "TEST_DATA_SEED": "true",
                "TEST_DATA_DAYS": "\(config.daysOfHistory)",
                "TEST_DATA_MEDICATION": config.medication.rawValue,
                "TEST_DATA_BRAND": config.brandName,
                "TEST_DATA_DOSE": "\(config.doseAmount)",
                "TEST_DATA_ADHERENCE": "\(config.adherenceRate)",
                "TEST_DATA_VARIABILITY": config.addTimingVariability ? "true" : "false",
                "TEST_DATA_SKIPPED": config.includeSkippedDoses ? "true" : "false",
            ]
        }

        // MARK: - Quick Helpers

        /// Create a test user with default properties
        @MainActor
        static func createTestUser(
            email: String = "test@example.com",
            name: String = "Test User",
            weight: Double = 80.0
        ) -> User {
            User(email: email, name: name, weight: weight)
        }

        /// Create a test medication profile
        @MainActor
        static func createTestMedicationProfile(
            medication: Medication = .semaglutide,
            brandName: String = "Ozempic",
            currentDose: Double = 1.0
        ) -> MedicationProfile {
            MedicationProfile(
                genericName: medication.rawValue,
                brandName: brandName,
                currentDose: currentDose,
                medicationType: medication.rawValue
            )
        }

        /// Create a batch of test doses with consistent spacing
        @MainActor
        static func createTestDoses(
            count: Int,
            amount: Double = 1.0,
            daysApart: Int = 7,
            profile: MedicationProfile
        ) -> [Dose] {
            let now = Date()
            return (0..<count).map { index in
                let timestamp =
                    Calendar.current.date(
                        byAdding: .day,
                        value: -(index * daysApart),
                        to: now
                    ) ?? now

                let dose = Dose(
                    amount: amount,
                    timestamp: timestamp
                )
                dose.medication = profile
                return dose
            }.reversed()  // Return chronological order
        }
    }

    // MARK: - E2E Test Extensions

    extension TestDataSeeding {
        /// Create a test ModelContainer for unit tests
        @MainActor
        static func createTestContainer() throws -> ModelContainer {
            let config = ModelConfiguration(
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            return try ModelContainer(
                for: User.self, MedicationProfile.self, Dose.self, DoseSchedule.self, ScheduledDose.self,
                configurations: config
            )
        }
    }

#endif
