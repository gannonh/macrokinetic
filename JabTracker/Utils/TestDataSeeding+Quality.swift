//
//  TestDataSeeding+Quality.swift
//  JabTracker
//
//  Data quality seeding extension for generating realistic test data scenarios
//  with varying levels of data completeness (high/medium/low/new user).
//

#if DEBUG || TEST
    import Foundation
    import OSLog
    import SwiftData

    // MARK: - Data Quality Variants

    /// Data quality levels for seeding realistic user data scenarios
    enum DataQualityLevel: String, CaseIterable {
        case high = "high"  // Complete daily logging and weigh-ins
        case medium = "medium"  // 4-5 days/week logging, every 2-3 days weigh-ins
        case low = "low"  // 1-2 days/week logging, weekly weigh-ins
        case newUser = "new"  // Today only - fresh start scenario

        /// Expected food logging days per week
        var foodLoggingDaysPerWeek: Double {
            switch self {
            case .high: return 7.0
            case .medium: return 4.5
            case .low: return 1.5
            case .newUser: return 1.0
            }
        }

        /// Expected weigh-ins per week
        var weighInsPerWeek: Double {
            switch self {
            case .high: return 7.0
            case .medium: return 3.0
            case .low: return 1.0
            case .newUser: return 1.0
            }
        }

        /// Number of days of history to generate
        var daysOfHistory: Int {
            switch self {
            case .high, .medium, .low: return 365
            case .newUser: return 1
            }
        }
    }

    /// Configuration for data quality seeding
    struct DataQualitySeedingConfig {
        let qualityLevel: DataQualityLevel
        let startingWeightKg: Double
        let targetWeightKg: Double
        let dailyCalorieTarget: Double

        static let `default` = DataQualitySeedingConfig(
            qualityLevel: .high,
            startingWeightKg: 90.0,
            targetWeightKg: 80.0,
            dailyCalorieTarget: 2000.0
        )
    }

    /// Result of data quality seeding operation
    struct DataQualitySeedingResult {
        let user: User
        let goal: NutritionGoal
        let foodEntryCount: Int
        let weightEntryCount: Int
        let tdeeSnapshotCount: Int
        let expectedFoodLogDays: Int
        let expectedWeighIns: Int
    }

    // MARK: - Data Quality Seeding Extension

    extension TestDataSeeding {
        private static let qualityLogger = Logger(
            subsystem: "com.gannonhall.JabTracker",
            category: "TestDataSeeding+Quality"
        )

        /// Seed data with specified quality level for realistic user scenarios
        /// - Parameters:
        ///   - context: The ModelContext to seed data into
        ///   - qualityLevel: The data quality tier (high/medium/low/newUser)
        ///   - existingUser: Optional existing user to seed data for
        ///   - seed: Random seed for reproducible data generation
        /// - Returns: Result containing created entities and counts
        @MainActor
        // swiftlint:disable:next function_body_length
        static func seedDataWithQuality(
            into context: ModelContext,
            qualityLevel: DataQualityLevel,
            existingUser: User? = nil,
            seed: UInt64 = 789
        ) throws -> DataQualitySeedingResult {
            var rng = SeededRNG(seed: seed)
            let calendar = Calendar.current
            let today = Date()

            // Use existing user or create new user
            let user: User
            if let existingUser = existingUser {
                user = existingUser
            } else {
                user = User(
                    email: "test@example.com",
                    name: "Test User",
                    weight: 90.0
                )
                user.heightCm = 175.0
                user.gender = "male"
                user.dateOfBirth = calendar.date(byAdding: .year, value: -30, to: today)
                context.insert(user)
            }

            // Create nutrition goal
            let goal = NutritionGoal(
                goalType: .weightLoss,
                isActive: true,
                startingWeightKg: 90.0,
                targetWeightKg: 80.0,
                targetDate: calendar.date(byAdding: .month, value: 6, to: today) ?? today,
                weeklyWeightChangePaceKg: -0.5,
                dailyCalorieTarget: 2000.0,
                dailyProteinTargetGrams: 150.0,
                dailyCarbTargetGrams: 200.0,
                dailyFatTargetGrams: 65.0
            )
            goal.initialEstimatedTDEE = 2400.0
            goal.lastCalculatedTDEE = 2350.0
            goal.lastTDEECalculationDate = calendar.date(byAdding: .day, value: -7, to: today)
            goal.lastCheckInDate = calendar.date(byAdding: .day, value: -10, to: today)
            goal.checkInDayOfWeek = calendar.component(.weekday, from: today)
            goal.user = user
            context.insert(goal)

            // Create program
            let program = NutritionProgram(
                style: .coached,
                diet: .balanced,
                calorieFloor: .standard,
                trainingLevel: .lifting,
                distributionMode: .even,
                proteinLevel: .moderate
            )
            program.goal = goal
            context.insert(program)

            // Generate data based on quality level
            let daysToGenerate = qualityLevel.daysOfHistory
            var foodEntryCount = 0
            var weightEntryCount = 0
            var tdeeSnapshotCount = 0

            // Calculate expected counts
            let weeks = Double(daysToGenerate) / 7.0
            let expectedFoodLogDays = Int(weeks * qualityLevel.foodLoggingDaysPerWeek)
            let expectedWeighIns = Int(weeks * qualityLevel.weighInsPerWeek)

            // Generate weight entries
            weightEntryCount = seedWeightEntries(
                into: context,
                qualityLevel: qualityLevel,
                daysOfHistory: daysToGenerate,
                rng: &rng
            )

            // Generate food entries
            foodEntryCount = seedFoodEntries(
                into: context,
                qualityLevel: qualityLevel,
                daysOfHistory: daysToGenerate,
                rng: &rng
            )

            // Generate TDEE snapshots
            tdeeSnapshotCount = seedTDEESnapshots(
                into: context,
                qualityLevel: qualityLevel,
                daysOfHistory: daysToGenerate,
                rng: &rng
            )

            try context.save()

            qualityLogger.info(
                """
                ✅ Data quality seeding complete (\(qualityLevel.rawValue)):
                   - Food entries: \(foodEntryCount)
                   - Weight entries: \(weightEntryCount)
                   - TDEE snapshots: \(tdeeSnapshotCount)
                """)

            return DataQualitySeedingResult(
                user: user,
                goal: goal,
                foodEntryCount: foodEntryCount,
                weightEntryCount: weightEntryCount,
                tdeeSnapshotCount: tdeeSnapshotCount,
                expectedFoodLogDays: expectedFoodLogDays,
                expectedWeighIns: expectedWeighIns
            )
        }

        /// Seed weight entries based on quality level
        @MainActor
        private static func seedWeightEntries(
            into context: ModelContext,
            qualityLevel: DataQualityLevel,
            daysOfHistory: Int,
            rng: inout SeededRNG
        ) -> Int {
            let calendar = Calendar.current
            let today = Date()
            var count = 0

            // Starting and ending weights for trend
            let startWeight = 92.0  // kg
            let endWeight = 88.0  // kg

            for dayOffset in 0..<daysOfHistory {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

                // Determine if we should log weight on this day based on quality
                let shouldLog: Bool
                switch qualityLevel {
                case .high:
                    // Daily logging
                    shouldLog = true
                case .medium:
                    // Every 2-3 days (roughly 40% of days)
                    shouldLog = Double.random(in: 0...1, using: &rng) < 0.4
                case .low:
                    // Weekly only (roughly 14% of days)
                    shouldLog = Double.random(in: 0...1, using: &rng) < 0.14
                case .newUser:
                    // Only today
                    shouldLog = dayOffset == 0
                }

                guard shouldLog else { continue }

                // Calculate weight with trend and noise
                let progress = Double(daysOfHistory - dayOffset) / Double(daysOfHistory)
                let baseWeight = startWeight - ((startWeight - endWeight) * progress)
                let noise = Double.random(in: -0.4...0.4, using: &rng)
                let weightKg = baseWeight + noise

                let entry = WeightEntry(timestamp: date, weightKg: weightKg)
                context.insert(entry)
                count += 1
            }

            return count
        }

        /// Seed food entries based on quality level
        @MainActor
        private static func seedFoodEntries(
            into context: ModelContext,
            qualityLevel: DataQualityLevel,
            daysOfHistory: Int,
            rng: inout SeededRNG
        ) -> Int {
            let calendar = Calendar.current
            let today = Date()
            var count = 0

            for dayOffset in 0..<daysOfHistory {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

                // Determine if we should log food on this day based on quality
                let shouldLogDay = shouldLogFoodOnDay(
                    qualityLevel: qualityLevel,
                    dayOffset: dayOffset,
                    rng: &rng
                )

                guard shouldLogDay else { continue }

                // Determine meal completeness based on quality
                let isPartialDay = isPartialFoodDay(
                    qualityLevel: qualityLevel,
                    dayOffset: dayOffset,
                    rng: &rng
                )

                // Add daily variance
                let dayMultiplier = Double.random(in: 0.85...1.15, using: &rng)

                // Log meals
                count += logMealsForDay(
                    into: context,
                    date: date,
                    isPartialDay: isPartialDay,
                    dayMultiplier: dayMultiplier,
                    qualityLevel: qualityLevel,
                    rng: &rng
                )
            }

            return count
        }

        private static func shouldLogFoodOnDay(
            qualityLevel: DataQualityLevel,
            dayOffset: Int,
            rng: inout SeededRNG
        ) -> Bool {
            switch qualityLevel {
            case .high:
                return true
            case .medium:
                return Double.random(in: 0...1, using: &rng) < 0.65
            case .low:
                return Double.random(in: 0...1, using: &rng) < 0.21
            case .newUser:
                return dayOffset == 0
            }
        }

        private static func isPartialFoodDay(
            qualityLevel: DataQualityLevel,
            dayOffset: Int,
            rng: inout SeededRNG
        ) -> Bool {
            switch qualityLevel {
            case .high:
                return Double.random(in: 0...1, using: &rng) < 0.05
            case .medium:
                return Double.random(in: 0...1, using: &rng) < 0.30
            case .low:
                return Double.random(in: 0...1, using: &rng) < 0.50
            case .newUser:
                return dayOffset == 0
            }
        }

        @MainActor
        // swiftlint:disable:next function_parameter_count
        private static func logMealsForDay(
            into context: ModelContext,
            date: Date,
            isPartialDay: Bool,
            dayMultiplier: Double,
            qualityLevel: DataQualityLevel,
            rng: inout SeededRNG
        ) -> Int {
            var count = 0

            // Meal configurations
            let mealsToLog: [(MealSection, Double, Double, Double, Double)]
            if isPartialDay {
                mealsToLog = [
                    (.breakfast, 400, 25, 50, 15),
                    (.lunch, 700, 45, 60, 30),
                ]
            } else {
                mealsToLog = [
                    (.breakfast, 400, 25, 50, 15),
                    (.lunch, 700, 45, 60, 30),
                    (.dinner, 800, 55, 70, 35),
                ]
            }

            for (section, baseCal, protein, carbs, fat) in mealsToLog {
                let mealMult = Double.random(in: 0.9...1.1, using: &rng) * dayMultiplier

                let entry = FoodEntry(
                    foodName: "Test \(section.rawValue)",
                    mealSection: section,
                    loggedAt: date,
                    servingGrams: 100.0 * mealMult,
                    caloriesPer100g: baseCal,
                    proteinPer100g: protein,
                    carbsPer100g: carbs,
                    fatPer100g: fat
                )
                context.insert(entry)
                count += 1
            }

            // Sometimes add snacks (except for new users on day 0)
            if !isPartialDay && qualityLevel != .newUser {
                let hasSnack = Double.random(in: 0...1, using: &rng) < 0.4
                if hasSnack {
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

        /// Seed TDEE snapshots based on quality level
        @MainActor
        private static func seedTDEESnapshots(
            into context: ModelContext,
            qualityLevel: DataQualityLevel,
            daysOfHistory: Int,
            rng: inout SeededRNG
        ) -> Int {
            let calendar = Calendar.current
            let today = Date()
            var count = 0

            let initialTDEE = 2400.0
            let currentTDEE = 2350.0
            let tdeeRange = initialTDEE - currentTDEE

            for dayOffset in 0..<daysOfHistory {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

                // Calculate TDEE with trend and noise
                let progress = Double(daysOfHistory - dayOffset) / Double(daysOfHistory)
                let baseTDEE = initialTDEE - (tdeeRange * progress)
                let noise = Double.random(in: -8...8, using: &rng)
                let tdeeValue = baseTDEE + noise

                // Determine source type and confidence based on quality
                let (sourceType, confidence) = determineTDEESourceAndConfidence(
                    qualityLevel: qualityLevel,
                    dayOffset: dayOffset,
                    daysOfHistory: daysOfHistory,
                    progress: progress,
                    rng: &rng
                )

                let snapshot = TDEESnapshot(
                    timestamp: date,
                    tdeeValue: tdeeValue,
                    confidence: confidence,
                    source: sourceType
                )
                context.insert(snapshot)
                count += 1
            }

            return count
        }

        private static func determineTDEESourceAndConfidence(
            qualityLevel: DataQualityLevel,
            dayOffset: Int,
            daysOfHistory: Int,
            progress: Double,
            rng: inout SeededRNG
        ) -> (TDEESourceType, Double) {
            switch qualityLevel {
            case .high:
                if dayOffset > daysOfHistory - 7 {
                    return (.initial, 0.5 + (0.35 * progress))
                } else {
                    let sourceType: TDEESourceType = Double.random(in: 0...1, using: &rng) < 0.9 ? .adaptive : .holding
                    return (sourceType, 0.65 + (0.2 * progress))
                }
            case .medium:
                if dayOffset > daysOfHistory - 14 {
                    return (.initial, 0.4 + (0.25 * progress))
                } else {
                    let sourceType: TDEESourceType = Double.random(in: 0...1, using: &rng) < 0.7 ? .adaptive : .holding
                    return (sourceType, 0.5 + (0.2 * progress))
                }
            case .low:
                if dayOffset > daysOfHistory - 21 {
                    return (.initial, 0.3 + (0.15 * progress))
                } else {
                    let sourceType: TDEESourceType = Double.random(in: 0...1, using: &rng) < 0.4 ? .adaptive : .holding
                    return (sourceType, 0.35 + (0.15 * progress))
                }
            case .newUser:
                return (.initial, 0.3)
            }
        }
    }

#endif
