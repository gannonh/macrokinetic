//
//  TestDataSeeding+ActiveUser.swift
//  JabTracker
//
//  Active user seeding extension for generating realistic test data scenarios
//  with specific durations of food logging, weight entries, and medication doses.
//

#if DEBUG || TEST
    import Foundation
    import OSLog
    import SwiftData

    // MARK: - Active User Configuration

    /// Configuration for active user seeding scenarios
    enum ActiveUserScenario: String, CaseIterable {
        case threeDay = "3-day"
        case fiveDay = "5-day"
        case twoWeek = "2-week"
        case oneMonth = "1-month"
        case ninetyDay = "90-day"

        /// Number of days of food logging
        var foodLoggingDays: Int {
            switch self {
            case .threeDay: return 3
            case .fiveDay: return 5
            case .twoWeek: return 14
            case .oneMonth: return 30
            case .ninetyDay: return 90
            }
        }

        /// Number of days of weigh-ins
        var weighInDays: Int {
            switch self {
            case .threeDay: return 3
            case .fiveDay: return 5
            case .twoWeek: return 14
            case .oneMonth: return 30
            case .ninetyDay: return 90
            }
        }

        /// Number of medication doses
        var doseCount: Int {
            switch self {
            case .threeDay: return 0
            case .fiveDay: return 1
            case .twoWeek: return 2
            case .oneMonth: return 4
            case .ninetyDay: return 13
            }
        }

        /// Base TDEE for the scenario (varies slightly for realism)
        var baseTDEE: Double {
            2200  // Moderate TDEE for 185 lb male
        }
    }

    /// Result of active user seeding operation
    struct ActiveUserSeedingResult {
        let user: User
        let medicationProfile: MedicationProfile?
        let foodEntryCount: Int
        let weightEntryCount: Int
        let doseCount: Int
    }

    // MARK: - Active User Seeding Extension

    extension TestDataSeeding {
        private static let activeUserLogger = Logger(
            subsystem: "com.gannonhall.JabTracker",
            category: "TestDataSeeding+ActiveUser"
        )

        /// Seed data for an active user scenario with specific days of food/weight and dose count
        @MainActor
        static func seedActiveUserData(
            into context: ModelContext,
            scenario: ActiveUserScenario,
            existingUser: User? = nil,
            seed: UInt64 = 456
        ) throws -> ActiveUserSeedingResult {
            var rng = SeededRNG(seed: seed)
            let calendar = Calendar.current
            let today = Date()

            let user = setupUser(context: context, existingUser: existingUser)
            setupNutritionGoal(context: context, user: user, scenario: scenario)
            seedTDEESnapshots(context: context, scenario: scenario, today: today, rng: &rng)

            let weightEntryCount = seedWeightEntries(
                context: context, scenario: scenario, calendar: calendar, today: today, rng: &rng
            )
            let foodEntryCount = seedFoodEntries(
                context: context, scenario: scenario, calendar: calendar, today: today, rng: &rng
            )

            let medicationProfile = try seedMedicationIfNeeded(
                context: context, user: user, scenario: scenario
            )

            try context.save()

            activeUserLogger.info(
                """
                Active user seeding complete (\(scenario.rawValue)):
                   - NutritionGoal: created with TDEE \(Int(scenario.baseTDEE))
                   - TDEE snapshots: \(scenario.foodLoggingDays) days
                   - Food entries: \(foodEntryCount) (\(scenario.foodLoggingDays) days)
                   - Weight entries: \(weightEntryCount) (\(scenario.weighInDays) days)
                   - Doses: \(scenario.doseCount)
                """)

            return ActiveUserSeedingResult(
                user: user,
                medicationProfile: medicationProfile,
                foodEntryCount: foodEntryCount,
                weightEntryCount: weightEntryCount,
                doseCount: scenario.doseCount
            )
        }

        // MARK: - Private Helpers

        @MainActor
        private static func setupUser(context: ModelContext, existingUser: User?) -> User {
            var birthComponents = DateComponents()
            birthComponents.year = 1970
            birthComponents.month = 3
            birthComponents.day = 12
            let birthDate = Calendar.current.date(from: birthComponents)

            if let existingUser = existingUser {
                if existingUser.heightCm == nil { existingUser.heightCm = 188.0 }
                if existingUser.gender.isEmpty { existingUser.gender = "male" }
                if existingUser.dateOfBirth == nil { existingUser.dateOfBirth = birthDate }
                return existingUser
            }

            let user = User(
                email: "test@example.com",
                name: "Test User",
                dateOfBirth: birthDate,
                heightCm: 188.0,
                gender: "male",
                weight: 185.0,
                weightUnit: "lbs"
            )
            context.insert(user)
            return user
        }

        @MainActor
        private static func setupNutritionGoal(
            context: ModelContext, user: User, scenario: ActiveUserScenario
        ) {
            let goal = NutritionGoal(
                goalType: .weightLoss,
                startingWeightKg: 84.0,  // ~185 lbs
                targetWeightKg: 77.0,  // ~170 lbs
                weeklyWeightChangePaceKg: -0.5,
                dailyCalorieTarget: 1800,
                dailyProteinTargetGrams: 150,
                dailyCarbTargetGrams: 180,
                dailyFatTargetGrams: 60
            )
            goal.initialEstimatedTDEE = scenario.baseTDEE
            goal.lastCalculatedTDEE = scenario.baseTDEE
            goal.user = user
            context.insert(goal)

            let program = NutritionProgram()
            program.goal = goal
            context.insert(program)
        }

        @MainActor
        private static func seedTDEESnapshots(
            context: ModelContext,
            scenario: ActiveUserScenario,
            today: Date,
            rng: inout SeededRNG
        ) {
            let calendar = Calendar.current
            for dayOffset in 0..<scenario.foodLoggingDays {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
                let dailyTDEE = scenario.baseTDEE + Double.random(in: -100...100, using: &rng)
                let snapshot = TDEESnapshot(timestamp: date, tdeeValue: dailyTDEE)
                context.insert(snapshot)
            }
        }

        @MainActor
        private static func seedWeightEntries(
            context: ModelContext,
            scenario: ActiveUserScenario,
            calendar: Calendar,
            today: Date,
            rng: inout SeededRNG
        ) -> Int {
            var count = 0
            for dayOffset in 0..<scenario.weighInDays {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
                let baseWeight = 84.0 - (Double(scenario.weighInDays - dayOffset) * 0.03)
                let noise = Double.random(in: -0.3...0.3, using: &rng)
                let entry = WeightEntry(timestamp: date, weightKg: baseWeight + noise)
                context.insert(entry)
                count += 1
            }
            return count
        }

        @MainActor
        private static func seedFoodEntries(
            context: ModelContext,
            scenario: ActiveUserScenario,
            calendar: Calendar,
            today: Date,
            rng: inout SeededRNG
        ) -> Int {
            var count = 0
            let meals: [(MealSection, Double, Double, Double, Double)] = [
                (.breakfast, 400, 25, 50, 15),
                (.lunch, 700, 45, 60, 30),
                (.dinner, 800, 55, 70, 35),
            ]

            for dayOffset in 0..<scenario.foodLoggingDays {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
                let dayMultiplier = Double.random(in: 0.9...1.1, using: &rng)

                for (section, cal, protein, carbs, fat) in meals {
                    let mealMult = Double.random(in: 0.9...1.1, using: &rng) * dayMultiplier
                    let entry = FoodEntry(
                        foodName: "Test \(section.rawValue)",
                        mealSection: section,
                        loggedAt: date,
                        servingGrams: 100.0 * mealMult,
                        caloriesPer100g: cal,
                        proteinPer100g: protein,
                        carbsPer100g: carbs,
                        fatPer100g: fat
                    )
                    context.insert(entry)
                    count += 1
                }

                if Double.random(in: 0...1, using: &rng) < 0.3 {
                    let snackEntry = FoodEntry(
                        foodName: "Test snack",
                        mealSection: .snacks,
                        loggedAt: date,
                        servingGrams: 100.0 * Double.random(in: 0.8...1.2, using: &rng),
                        caloriesPer100g: 200,
                        proteinPer100g: 10,
                        carbsPer100g: 25,
                        fatPer100g: 8
                    )
                    context.insert(snackEntry)
                    count += 1
                }
            }
            return count
        }

        @MainActor
        private static func seedMedicationIfNeeded(
            context: ModelContext,
            user: User,
            scenario: ActiveUserScenario
        ) throws -> MedicationProfile? {
            guard scenario.doseCount > 0 else { return nil }

            let daysOfHistory = scenario.doseCount * 7
            let config = TestDataSeedingConfig(
                daysOfHistory: daysOfHistory,
                medication: .semaglutide,
                brandName: "Ozempic",
                doseAmount: 0.5,
                adherenceRate: 1.0,
                addTimingVariability: true,
                includeSkippedDoses: false
            )

            let result = try TestDataSeeding.seedData(
                into: context,
                config: config,
                existingUser: user,
                targetDoseCount: scenario.doseCount
            )
            return result.medicationProfile
        }
    }

#endif
