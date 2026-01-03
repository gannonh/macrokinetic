//
//  TDEEServiceTests.swift
//  JabTrackerTests
//
//  Unit tests for TDEEService orchestration layer.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("TDEEService Tests")
struct TDEEServiceTests {

    // MARK: - Test Helpers

    @MainActor
    func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([
            User.self, NutritionGoal.self, NutritionProgram.self,
            WeightEntry.self, FoodEntry.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        return (container.mainContext, container)
    }

    @MainActor
    func createTestUser(in context: ModelContext) -> User {
        let user = User()
        user.heightCm = 175.0
        user.gender = "male"
        user.dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date())
        context.insert(user)
        return user
    }

    @MainActor
    func createTestGoal(for user: User, in context: ModelContext) -> NutritionGoal {
        let goal = NutritionGoal()
        goal.user = user

        let program = NutritionProgram()
        program.trainingLevelRaw = TrainingLevel.cardio.rawValue
        program.goal = goal
        goal.program = program

        context.insert(goal)
        context.insert(program)
        return goal
    }

    // MARK: - Initial TDEE Tests

    @Test("calculateInitialTDEE updates NutritionGoal.initialEstimatedTDEE")
    @MainActor
    func testCalculateInitialTDEEUpdatesInitialEstimatedTDEE() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)

        // Add weight entry
        let weightEntry = WeightEntry(timestamp: Date(), weightKg: 80.0)
        context.insert(weightEntry)
        try context.save()

        let service = TDEEService(context: context)

        // When
        try await service.calculateInitialTDEE(for: user, goal: goal)

        // Then
        #expect(goal.initialEstimatedTDEE != nil)
        #expect(goal.initialEstimatedTDEE! > 0)
    }

    @Test("calculateInitialTDEE updates NutritionGoal.lastCalculatedTDEE")
    @MainActor
    func testCalculateInitialTDEEUpdatesLastCalculatedTDEE() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)

        let weightEntry = WeightEntry(timestamp: Date(), weightKg: 80.0)
        context.insert(weightEntry)
        try context.save()

        let service = TDEEService(context: context)

        // When
        try await service.calculateInitialTDEE(for: user, goal: goal)

        // Then
        #expect(goal.lastCalculatedTDEE != nil)
        #expect(goal.lastCalculatedTDEE == goal.initialEstimatedTDEE)
    }

    @Test("calculateInitialTDEE sets lastTDEECalculationDate to now")
    @MainActor
    func testCalculateInitialTDEESetsLastTDEECalculationDate() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)

        let weightEntry = WeightEntry(timestamp: Date(), weightKg: 80.0)
        context.insert(weightEntry)
        try context.save()

        let service = TDEEService(context: context)
        let beforeCalculation = Date()

        // When
        try await service.calculateInitialTDEE(for: user, goal: goal)

        // Then
        #expect(goal.lastTDEECalculationDate != nil)
        #expect(goal.lastTDEECalculationDate! >= beforeCalculation)
    }

    @Test("calculateInitialTDEE throws if user missing height")
    @MainActor
    func testCalculateInitialTDEEThrowsIfMissingHeight() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = User()
        user.heightCm = nil  // Missing height
        user.gender = "male"
        user.dateOfBirth = Calendar.current.date(byAdding: .year, value: -30, to: Date())
        context.insert(user)

        let goal = createTestGoal(for: user, in: context)

        let weightEntry = WeightEntry(timestamp: Date(), weightKg: 80.0)
        context.insert(weightEntry)
        try context.save()

        let service = TDEEService(context: context)

        // When/Then
        await #expect(throws: TDEEServiceError.self) {
            try await service.calculateInitialTDEE(for: user, goal: goal)
        }
    }

    @Test("calculateInitialTDEE throws if user missing dateOfBirth")
    @MainActor
    func testCalculateInitialTDEEThrowsIfMissingDateOfBirth() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = User()
        user.heightCm = 175.0
        user.gender = "male"
        user.dateOfBirth = nil  // Missing date of birth
        context.insert(user)

        let goal = createTestGoal(for: user, in: context)

        let weightEntry = WeightEntry(timestamp: Date(), weightKg: 80.0)
        context.insert(weightEntry)
        try context.save()

        let service = TDEEService(context: context)

        // When/Then
        await #expect(throws: TDEEServiceError.self) {
            try await service.calculateInitialTDEE(for: user, goal: goal)
        }
    }

    @Test("calculateInitialTDEE throws if no weight entries exist")
    @MainActor
    func testCalculateInitialTDEEThrowsIfNoWeightEntries() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        // No weight entries added
        try context.save()

        let service = TDEEService(context: context)

        // When/Then
        await #expect(throws: TDEEServiceError.self) {
            try await service.calculateInitialTDEE(for: user, goal: goal)
        }
    }

    @Test("calculateInitialTDEE produces reasonable TDEE for 80kg male 175cm 30yo cardio")
    @MainActor
    func testCalculateInitialTDEEProducesReasonableValue() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)

        let weightEntry = WeightEntry(timestamp: Date(), weightKg: 80.0)
        context.insert(weightEntry)
        try context.save()

        let service = TDEEService(context: context)

        // When
        try await service.calculateInitialTDEE(for: user, goal: goal)

        // Then
        // Expected: BMR = (10 * 80) + (6.25 * 175) - (5 * 30) + 5 = 800 + 1093.75 - 150 + 5 = 1748.75
        // TDEE = 1748.75 * 1.55 (cardio) = 2710.56
        #expect(goal.initialEstimatedTDEE! > 2500)
        #expect(goal.initialEstimatedTDEE! < 3000)
    }

    // MARK: - Adaptive TDEE Tests

    @MainActor
    func seedWeightData(days: Int, startWeight: Double, weeklyChange: Double, in context: ModelContext) {
        let dailyChange = weeklyChange / 7.0
        for day in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -days + day + 1, to: Date())!
            let weight = startWeight + (Double(day) * dailyChange)
            let entry = WeightEntry(timestamp: date, weightKg: weight)
            context.insert(entry)
        }
    }

    @MainActor
    func seedFoodData(days: Int, dailyCalories: Double, in context: ModelContext) {
        // Note: caloriesPer100g = dailyCalories with servingGrams = 100
        // means each entry has dailyCalories total (100g * dailyCalories/100g)
        for day in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -days + day + 1, to: Date())!
            let entry = FoodEntry(
                foodName: "Test Food",
                mealSection: .breakfast,
                loggedAt: date,
                servingGrams: 100.0,
                caloriesPer100g: dailyCalories,
                proteinPer100g: 20.0,
                carbsPer100g: 50.0,
                fatPer100g: 10.0
            )
            context.insert(entry)
        }
    }

    @Test("calculateAdaptiveTDEE returns AdaptiveTDEEResult with TDEE value")
    @MainActor
    func testCalculateAdaptiveTDEEReturnsResult() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.initialEstimatedTDEE = 2500.0

        // Seed 28 days of data: losing 0.5 kg/week eating 2000 kcal/day
        seedWeightData(days: 28, startWeight: 82.0, weeklyChange: -0.5, in: context)
        seedFoodData(days: 28, dailyCalories: 2000.0, in: context)
        try context.save()

        let service = TDEEService(context: context)

        // When
        let result = try await service.calculateAdaptiveTDEE(goal: goal)

        // Then
        #expect(result.tdee > 0)
        #expect(result.daysWithData == 28)
    }

    @Test("calculateAdaptiveTDEE throws if insufficient weight data")
    @MainActor
    func testCalculateAdaptiveTDEEThrowsIfInsufficientWeightData() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)

        // Only seed 7 days of data (less than 14 day minimum)
        seedWeightData(days: 7, startWeight: 80.0, weeklyChange: -0.5, in: context)
        seedFoodData(days: 7, dailyCalories: 2000.0, in: context)
        try context.save()

        let service = TDEEService(context: context)

        // When/Then
        await #expect(throws: TDEEServiceError.self) {
            _ = try await service.calculateAdaptiveTDEE(goal: goal)
        }
    }

    @Test("calculateAdaptiveTDEE throws if insufficient food logging")
    @MainActor
    func testCalculateAdaptiveTDEEThrowsIfInsufficientFoodData() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)

        // Seed 28 days of weight data but only 10 days of food data (< 70% consistency)
        seedWeightData(days: 28, startWeight: 80.0, weeklyChange: -0.5, in: context)
        seedFoodData(days: 10, dailyCalories: 2000.0, in: context)
        try context.save()

        let service = TDEEService(context: context)

        // When/Then
        await #expect(throws: TDEEServiceError.self) {
            _ = try await service.calculateAdaptiveTDEE(goal: goal)
        }
    }

    @Test("updateGoalWithAdaptiveTDEE updates lastCalculatedTDEE")
    @MainActor
    func testUpdateGoalWithAdaptiveTDEE() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.initialEstimatedTDEE = 2500.0

        seedWeightData(days: 28, startWeight: 82.0, weeklyChange: -0.5, in: context)
        seedFoodData(days: 28, dailyCalories: 2000.0, in: context)
        try context.save()

        let service = TDEEService(context: context)
        let result = try await service.calculateAdaptiveTDEE(goal: goal)

        // When
        try service.updateGoalWithAdaptiveTDEE(goal: goal, result: result)

        // Then
        #expect(goal.lastCalculatedTDEE == result.tdee)
        #expect(goal.lastTDEECalculationDate != nil)
    }

    @Test("shouldRecalculateTDEE returns true if never calculated")
    @MainActor
    func testShouldRecalculateTDEEReturnsTrueIfNeverCalculated() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        // lastTDEECalculationDate is nil (never calculated)

        let service = TDEEService(context: context)

        // When/Then
        #expect(service.shouldRecalculateTDEE(goal: goal))
    }

    @Test("shouldRecalculateTDEE returns true if more than 7 days since last calculation")
    @MainActor
    func testShouldRecalculateTDEEReturnsTrueIfMoreThan7Days() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.lastTDEECalculationDate = Calendar.current.date(byAdding: .day, value: -8, to: Date())

        let service = TDEEService(context: context)

        // When/Then
        #expect(service.shouldRecalculateTDEE(goal: goal))
    }

    @Test("shouldRecalculateTDEE returns false if less than 7 days since last calculation")
    @MainActor
    func testShouldRecalculateTDEEReturnsFalseIfLessThan7Days() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.lastTDEECalculationDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())

        let service = TDEEService(context: context)

        // When/Then
        #expect(!service.shouldRecalculateTDEE(goal: goal))
    }

    // MARK: - Calorie & Macro Calculation Tests

    @Test("applyTDEEToGoal calculates correct deficit for 1 lb/week weight loss")
    @MainActor
    func testApplyTDEEToGoalCalculatesCorrectDeficit() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.initialEstimatedTDEE = 2700.0
        // 1 lb/week = 0.4536 kg/week, weeklyWeightChangePaceKg is negative for weight loss
        goal.weeklyWeightChangePaceKg = -0.4536

        let service = TDEEService(context: context)

        // When
        service.applyTDEEToGoal(goal)

        // Then
        // Daily deficit = 0.4536 * 1100 = 499 kcal
        // Daily target = 2700 - 499 = 2201 kcal
        let expectedTarget = 2700.0 - (0.4536 * 1100)
        #expect(abs(goal.dailyCalorieTarget - expectedTarget) < 1.0)
    }

    @Test("applyTDEEToGoal calculates correct surplus for weight gain")
    @MainActor
    func testApplyTDEEToGoalCalculatesCorrectSurplus() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.initialEstimatedTDEE = 2500.0
        // 1 lb/week gain = +0.4536 kg/week
        goal.weeklyWeightChangePaceKg = 0.4536

        let service = TDEEService(context: context)

        // When
        service.applyTDEEToGoal(goal)

        // Then
        // Daily surplus = 0.4536 * 1100 = 499 kcal
        // Daily target = 2500 + 499 = 2999 kcal
        let expectedTarget = 2500.0 + (0.4536 * 1100)
        #expect(abs(goal.dailyCalorieTarget - expectedTarget) < 1.0)
    }

    @Test("applyTDEEToGoal respects calorie floor")
    @MainActor
    func testApplyTDEEToGoalRespectsCalorieFloor() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.initialEstimatedTDEE = 1500.0
        goal.weeklyWeightChangePaceKg = -0.9  // Aggressive deficit

        // Set calorie floor to 1200
        goal.program?.calorieFloorTypeRaw = CalorieFloorType.standard.rawValue

        let service = TDEEService(context: context)

        // When
        service.applyTDEEToGoal(goal)

        // Then
        // Calculated would be 1500 - (0.9 * 1100) = 510 kcal (below floor)
        // Should be clamped to 1200
        #expect(goal.dailyCalorieTarget >= 1200.0)
    }

    @Test("calculateMacros returns correct protein based on weight and protein level")
    @MainActor
    func testCalculateMacrosReturnsCorrectProtein() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)

        // Set protein level to moderate (1.6 g/kg)
        goal.program?.proteinLevelRaw = ProteinLevel.moderate.rawValue

        let service = TDEEService(context: context)

        // When
        let macros = service.calculateMacros(
            calories: 2000.0,
            program: goal.program!,
            weightKg: 80.0
        )

        // Then
        // Protein = 1.6 g/kg * 80 kg = 128g
        let expectedProtein = ProteinLevel.moderate.gramsPerKg * 80.0
        #expect(abs(macros.protein - expectedProtein) < 1.0)
    }

    @Test("calculateMacros distributes remaining calories to fat and carbs")
    @MainActor
    func testCalculateMacrosDistributesRemainingCalories() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)

        // Set diet to balanced (30% P, 40% C, 30% F)
        goal.program?.dietPreferenceRaw = DietPreference.balanced.rawValue
        goal.program?.proteinLevelRaw = ProteinLevel.moderate.rawValue

        let service = TDEEService(context: context)

        // When
        let macros = service.calculateMacros(
            calories: 2000.0,
            program: goal.program!,
            weightKg: 80.0
        )

        // Then
        // Verify macros add up to approximately total calories
        let proteinCals = macros.protein * 4
        let fatCals = macros.fat * 9
        let carbCals = macros.carbs * 4
        let totalCals = proteinCals + fatCals + carbCals

        #expect(abs(totalCals - 2000.0) < 10.0)  // Within 10 kcal tolerance
    }

    @Test("calculateAndApplyMacros updates goal with calculated values")
    @MainActor
    func testCalculateAndApplyMacrosUpdatesGoal() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.dailyCalorieTarget = 2000.0
        goal.startingWeightKg = 80.0
        goal.program?.proteinLevelRaw = ProteinLevel.moderate.rawValue
        goal.program?.dietPreferenceRaw = DietPreference.balanced.rawValue

        let service = TDEEService(context: context)

        // When
        service.calculateAndApplyMacros(for: goal)

        // Then
        #expect(goal.dailyProteinTargetGrams > 0)
        #expect(goal.dailyFatTargetGrams > 0)
        #expect(goal.dailyCarbTargetGrams > 0)
    }

    @Test("calculateAndApplyFullTDEE orchestrates complete calculation flow")
    @MainActor
    func testCalculateAndApplyFullTDEEOrchestration() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.weeklyWeightChangePaceKg = -0.4536  // 1 lb/week loss
        goal.startingWeightKg = 80.0

        // Add weight entry for TDEE calculation
        let weightEntry = WeightEntry(timestamp: Date(), weightKg: 80.0)
        context.insert(weightEntry)
        try context.save()

        let service = TDEEService(context: context)

        // When
        try await service.calculateAndApplyFullTDEE(for: user, goal: goal)

        // Then
        // Verify all values are set
        #expect(goal.initialEstimatedTDEE != nil)
        #expect(goal.dailyCalorieTarget > 0)
        #expect(goal.dailyProteinTargetGrams > 0)
        #expect(goal.dailyFatTargetGrams > 0)
        #expect(goal.dailyCarbTargetGrams > 0)

        // Verify calorie target is less than TDEE (for weight loss)
        #expect(goal.dailyCalorieTarget < goal.initialEstimatedTDEE!)
    }

    // MARK: - Data Quality Assessment Tests

    // MARK: Service Configuration

    @Test("TDEEService has correct default thresholds")
    @MainActor
    func testServiceDefaultThresholds() throws {
        let (context, container) = createTestContext()
        _ = container
        let service = TDEEService(context: context)

        // Verify absolute minimum thresholds
        #expect(service.absoluteMinimumWeightEntries == 3)
        #expect(service.absoluteMinimumFoodConsistency == 0.5)
        #expect(service.absoluteMinimumDaySpan == 7)

        // Verify optimal thresholds
        #expect(service.optimalWeightEntries == 14)
        #expect(service.optimalFoodConsistency == 0.75)
        #expect(service.lookbackDays == 28)
    }

    // MARK: Data Quality Tier Constants

    @Test("DataQuality confidence ceilings are correct")
    func testDataQualityConfidenceCeilings() {
        #expect(DataQuality.insufficient.confidenceCeiling == 0.0)
        #expect(DataQuality.minimum.confidenceCeiling == 0.5)
        #expect(DataQuality.good.confidenceCeiling == 0.7)
        #expect(DataQuality.excellent.confidenceCeiling == 1.0)
    }

    @Test("DataQuality allowsCheckIn is correct")
    func testDataQualityAllowsCheckIn() {
        #expect(DataQuality.insufficient.allowsCheckIn == false)
        #expect(DataQuality.minimum.allowsCheckIn == true)
        #expect(DataQuality.good.allowsCheckIn == true)
        #expect(DataQuality.excellent.allowsCheckIn == true)
    }

    // MARK: Day Span Calculation

    @Test("Calendar.dateComponents calculates exact day differences correctly")
    func testCalendarDateComponentsDayCalculation() {
        let calendar = Calendar.current
        let now = Date()

        // Test 8-day span
        let day8Ago = calendar.date(byAdding: .day, value: -8, to: now)!
        #expect(calendar.dateComponents([.day], from: day8Ago, to: now).day == 8)

        // Test 7-day span (threshold)
        let day7Ago = calendar.date(byAdding: .day, value: -7, to: now)!
        #expect(calendar.dateComponents([.day], from: day7Ago, to: now).day == 7)

        // Test 6-day span (below threshold)
        let day6Ago = calendar.date(byAdding: .day, value: -6, to: now)!
        #expect(calendar.dateComponents([.day], from: day6Ago, to: now).day == 6)

        // Test 0-day span (same day)
        #expect(calendar.dateComponents([.day], from: now, to: now).day == 0)
    }

    @Test("assessDataQuality returns daySpan=1 for single weight entry")
    @MainActor
    func testSingleWeightEntryDaySpan() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Single weight entry
        let entry = WeightEntry(timestamp: Date(), weightKg: 80.0)
        context.insert(entry)
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        // Single entry should give daySpan of 1 (from max(1, 0))
        #expect(assessment.daySpan == 1)
        #expect(assessment.weightEntryCount == 1)
    }

    @Test("assessDataQuality calculates correct daySpan for entries at [0, 3, 5, 8]")
    @MainActor
    func testDaySpanCalculationMinimumTierPattern() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        // Weight entries at days [0, 3, 5, 8]
        for dayOffset in [0, 3, 5, 8] {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        #expect(assessment.daySpan == 8)
        #expect(assessment.weightEntryCount == 4)
    }

    // MARK: Food Consistency Calculation

    @Test("assessDataQuality calculates foodConsistency as uniqueDays/daySpan")
    @MainActor
    func testFoodConsistencyCalculation() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        // 10 days of weight entries (daySpan = 10)
        for day in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }

        // 7 days of food entries (food consistency = 7/10 = 70%)
        for day in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(
                FoodEntry(
                    foodName: "Test",
                    mealSection: .breakfast,
                    loggedAt: date,
                    servingGrams: 100.0,
                    caloriesPer100g: 400.0,
                    proteinPer100g: 25.0,
                    carbsPer100g: 50.0,
                    fatPer100g: 15.0
                ))
        }
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        #expect(assessment.daySpan == 9)  // Day 0 to day 9 = 9 days span
        #expect(assessment.foodConsistency > 0.7)  // 7/9 ≈ 77.8%
    }

    @Test("assessDataQuality returns 0 foodConsistency when no food entries")
    @MainActor
    func testNoFoodEntriesConsistency() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        // Weight entries but no food
        for day in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        #expect(assessment.foodConsistency == 0.0)
    }

    // MARK: INSUFFICIENT Tier Tests

    @Test("assessDataQuality returns INSUFFICIENT when weight count below threshold")
    @MainActor
    func testInsufficientWeightCount() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        // Only 2 weight entries (threshold is 3)
        for day in [0, 7] {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }

        // Plenty of food entries
        for day in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(
                FoodEntry(
                    foodName: "Test", mealSection: .breakfast, loggedAt: date,
                    servingGrams: 100.0, caloriesPer100g: 400.0,
                    proteinPer100g: 25.0, carbsPer100g: 50.0, fatPer100g: 15.0
                ))
        }
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        #expect(assessment.quality == .insufficient)
        #expect(assessment.weightEntryCount == 2)
    }

    @Test("assessDataQuality returns INSUFFICIENT when food consistency below threshold")
    @MainActor
    func testInsufficientFoodConsistency() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        // 10 weight entries spanning 10 days
        for day in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }

        // Only 4 food entries (4/9 = 44% < 50%)
        for day in 0..<4 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(
                FoodEntry(
                    foodName: "Test", mealSection: .breakfast, loggedAt: date,
                    servingGrams: 100.0, caloriesPer100g: 400.0,
                    proteinPer100g: 25.0, carbsPer100g: 50.0, fatPer100g: 15.0
                ))
        }
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        #expect(assessment.quality == .insufficient)
        #expect(assessment.foodConsistency < 0.5)
    }

    @Test("assessDataQuality returns INSUFFICIENT when day span below threshold")
    @MainActor
    func testInsufficientDaySpan() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        // 5 weight entries but only spanning 6 days (threshold is 7)
        for day in [0, 1, 3, 4, 6] {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }

        // Food on all 6 days
        for day in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(
                FoodEntry(
                    foodName: "Test", mealSection: .breakfast, loggedAt: date,
                    servingGrams: 100.0, caloriesPer100g: 400.0,
                    proteinPer100g: 25.0, carbsPer100g: 50.0, fatPer100g: 15.0
                ))
        }
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        #expect(assessment.quality == .insufficient)
        #expect(assessment.daySpan == 6)
    }

    // MARK: MINIMUM Tier Tests

    @Test("assessDataQuality returns MINIMUM for data just meeting thresholds")
    @MainActor
    func testMinimumTierJustMeetingThresholds() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        // Exactly 3 weight entries spanning exactly 7 days
        for day in [0, 3, 7] {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }

        // 4 food days out of 7 = 57% (just above 50%)
        for day in [0, 2, 4, 6] {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(
                FoodEntry(
                    foodName: "Test", mealSection: .breakfast, loggedAt: date,
                    servingGrams: 100.0, caloriesPer100g: 400.0,
                    proteinPer100g: 25.0, carbsPer100g: 50.0, fatPer100g: 15.0
                ))
        }
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        #expect(assessment.quality == .minimum)
        #expect(assessment.weightEntryCount >= 3)
        #expect(assessment.daySpan >= 7)
        #expect(assessment.foodConsistency >= 0.5)
    }

    // MARK: GOOD Tier Tests

    @Test("assessDataQuality returns GOOD when weight count >= 7")
    @MainActor
    func testGoodTierByWeightCount() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        // 8 weight entries spanning 8 days
        for day in 0..<8 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }

        // 4 food days (57%, below 60% but doesn't matter for GOOD)
        for day in [0, 2, 4, 6] {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(
                FoodEntry(
                    foodName: "Test", mealSection: .breakfast, loggedAt: date,
                    servingGrams: 100.0, caloriesPer100g: 400.0,
                    proteinPer100g: 25.0, carbsPer100g: 50.0, fatPer100g: 15.0
                ))
        }
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        #expect(assessment.quality == .good)
        #expect(assessment.weightEntryCount >= 7)
    }

    @Test("assessDataQuality returns GOOD when food consistency >= 60%")
    @MainActor
    func testGoodTierByFoodConsistency() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        // 4 weight entries (below 7 threshold)
        for day in [0, 3, 5, 8] {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }

        // 5 food days out of 8 = 62.5% (above 60%)
        for day in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(
                FoodEntry(
                    foodName: "Test", mealSection: .breakfast, loggedAt: date,
                    servingGrams: 100.0, caloriesPer100g: 400.0,
                    proteinPer100g: 25.0, carbsPer100g: 50.0, fatPer100g: 15.0
                ))
        }
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        #expect(assessment.quality == .good)
        #expect(assessment.foodConsistency >= 0.6)
    }

    // MARK: EXCELLENT Tier Tests

    @Test("assessDataQuality returns EXCELLENT for optimal data")
    @MainActor
    func testExcellentTier() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        // 21 weight entries spanning 21 days (>= 14 entries, >= 14 day span)
        for day in 0..<21 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }

        // 16 food days out of 20 = 80% (>= 75%)
        for day in 0..<16 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(
                FoodEntry(
                    foodName: "Test", mealSection: .breakfast, loggedAt: date,
                    servingGrams: 100.0, caloriesPer100g: 400.0,
                    proteinPer100g: 25.0, carbsPer100g: 50.0, fatPer100g: 15.0
                ))
        }
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        #expect(assessment.quality == .excellent)
        #expect(assessment.weightEntryCount >= 14)
        #expect(assessment.daySpan >= 14)
        #expect(assessment.foodConsistency >= 0.75)
    }

    // MARK: Improvement Tips Tests

    @Test("INSUFFICIENT tier generates correct improvement tips")
    @MainActor
    func testInsufficientTierImprovementTips() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        // 2 weight entries spanning 5 days
        for day in [0, 5] {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }

        // 2 food days out of 5 = 40%
        for day in [0, 2] {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(
                FoodEntry(
                    foodName: "Test", mealSection: .breakfast, loggedAt: date,
                    servingGrams: 100.0, caloriesPer100g: 400.0,
                    proteinPer100g: 25.0, carbsPer100g: 50.0, fatPer100g: 15.0
                ))
        }
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        #expect(assessment.quality == .insufficient)
        #expect(assessment.improvementTips.count >= 1)

        // Should include tip about weight entries (need 1 more)
        let hasWeightTip = assessment.improvementTips.contains { $0.contains("weight") }
        #expect(hasWeightTip)

        // Should include tip about day span (need 2 more days: 7 - 5 = 2)
        let hasDaysTip = assessment.improvementTips.contains { $0.contains("day") }
        #expect(hasDaysTip)
    }

    // MARK: Adaptive TDEE Confidence Ceiling Tests

    @Test("calculateAdaptiveTDEE caps confidence at MINIMUM tier ceiling")
    @MainActor
    func testAdaptiveTDEEMinimumConfidenceCeiling() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.initialEstimatedTDEE = 2500.0

        // Create MINIMUM tier data
        for day in [0, 3, 7] {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0 - Double(day) * 0.05))
        }

        // 4 food days (57%)
        for day in [0, 2, 4, 6] {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(
                FoodEntry(
                    foodName: "Test", mealSection: .breakfast, loggedAt: date,
                    servingGrams: 100.0, caloriesPer100g: 2000.0,
                    proteinPer100g: 50.0, carbsPer100g: 200.0, fatPer100g: 80.0
                ))
        }
        try context.save()

        let service = TDEEService(context: context)
        let result = try await service.calculateAdaptiveTDEE(goal: goal)

        // Confidence should be capped at 0.5 for MINIMUM tier
        #expect(result.confidence <= DataQuality.minimum.confidenceCeiling)
        #expect(result.dataQuality.quality == .minimum)
    }

    @Test("calculateAdaptiveTDEE throws for INSUFFICIENT data")
    @MainActor
    func testAdaptiveTDEEThrowsForInsufficientData() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.initialEstimatedTDEE = 2500.0

        // Only 2 weight entries
        for day in [0, 3] {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }
        try context.save()

        let service = TDEEService(context: context)

        await #expect(throws: TDEEServiceError.self) {
            _ = try await service.calculateAdaptiveTDEE(goal: goal)
        }
    }

    // MARK: Edge Cases

    @Test("assessDataQuality handles empty database gracefully")
    @MainActor
    func testEmptyDatabaseAssessment() async throws {
        let (context, container) = createTestContext()
        _ = container

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        #expect(assessment.quality == .insufficient)
        #expect(assessment.weightEntryCount == 0)
        #expect(assessment.daySpan == 0)
        #expect(assessment.foodConsistency == 0.0)
    }

    @Test("assessDataQuality handles multiple food entries on same day correctly")
    @MainActor
    func testMultipleFoodEntriesSameDay() async throws {
        let (context, container) = createTestContext()
        _ = container
        let calendar = Calendar.current
        let now = Date()

        // 10 weight entries
        for day in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            context.insert(WeightEntry(timestamp: date, weightKg: 80.0))
        }

        // 3 meals per day for 7 days = 21 entries but only 7 unique days
        for day in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            for meal in [MealSection.breakfast, .lunch, .dinner] {
                context.insert(
                    FoodEntry(
                        foodName: "Test", mealSection: meal, loggedAt: date,
                        servingGrams: 100.0, caloriesPer100g: 400.0,
                        proteinPer100g: 25.0, carbsPer100g: 50.0, fatPer100g: 15.0
                    ))
            }
        }
        try context.save()

        let service = TDEEService(context: context)
        let assessment = await service.assessDataQuality()

        // Should count unique days, not total entries
        // 7 unique days / 9 day span ≈ 77.8%
        #expect(assessment.foodConsistency > 0.7)
        #expect(assessment.foodConsistency < 1.0)
    }
}
