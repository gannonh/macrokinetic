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
}
