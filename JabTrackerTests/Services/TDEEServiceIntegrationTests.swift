//
//  TDEEServiceIntegrationTests.swift
//  JabTrackerTests
//
//  Integration tests for TDEEService with full data flows.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("TDEEService Integration Tests")
struct TDEEServiceIntegrationTests {

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

    // Note: This helper creates one FoodEntry per day with caloriesPer100g = dailyCalories
    // and servingGrams = 100, so each entry's calories = dailyCalories (100g * dailyCalories/100g)
    @MainActor
    func seedFoodData(days: Int, dailyCalories: Double, in context: ModelContext) {
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

    // MARK: - Integration Tests

    @Test("Full initial TDEE calculation flow")
    @MainActor
    func testInitialTDEEFlow() async throws {
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)

        // Add weight entry
        let weightEntry = WeightEntry(timestamp: Date(), weightKg: 80.0)
        context.insert(weightEntry)
        try context.save()

        // Calculate initial TDEE
        let service = TDEEService(context: context)
        try await service.calculateInitialTDEE(for: user, goal: goal)

        // Verify goal updated
        #expect(goal.initialEstimatedTDEE != nil)
        #expect(goal.lastCalculatedTDEE != nil)
        #expect(goal.lastTDEECalculationDate != nil)

        // Verify TDEE is reasonable for 80kg male, 175cm, 30yo, cardio
        // Expected: BMR = (10 * 80) + (6.25 * 175) - (5 * 30) + 5 = 1748.75
        // TDEE = 1748.75 * 1.55 (cardio) = 2710.56
        #expect(goal.initialEstimatedTDEE! > 2500)
        #expect(goal.initialEstimatedTDEE! < 3000)
    }

    @Test("Adaptive TDEE with weight loss scenario")
    @MainActor
    func testAdaptiveTDEEWeightLoss() async throws {
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.initialEstimatedTDEE = 2500.0

        // Seed 28 days of data: losing 0.5 kg/week while eating 2000 kcal/day
        seedWeightData(days: 28, startWeight: 82.0, weeklyChange: -0.5, in: context)
        seedFoodData(days: 28, dailyCalories: 2000.0, in: context)
        try context.save()

        // Calculate adaptive TDEE
        let service = TDEEService(context: context)
        let result = try await service.calculateAdaptiveTDEE(goal: goal)

        // Expected: TDEE = 2000 - (weightChange * 7700 / days)
        // weightChange = -2.0 kg (0.5 kg/week * 4 weeks)
        // TDEE = 2000 - (-2.0 * 7700 / 28) = 2000 + 550 = 2550
        #expect(result.tdee > 2400)
        #expect(result.tdee < 2700)
        #expect(result.weightChangeRateKgPerWeek < 0)
        #expect(result.confidence > 0.5)
        #expect(!result.hasMetabolicAdaptation)
    }

    @Test("Adaptive TDEE with weight gain scenario")
    @MainActor
    func testAdaptiveTDEEWeightGain() async throws {
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.initialEstimatedTDEE = 2500.0

        // Seed 28 days of data: gaining 0.25 kg/week while eating 2800 kcal/day
        seedWeightData(days: 28, startWeight: 80.0, weeklyChange: 0.25, in: context)
        seedFoodData(days: 28, dailyCalories: 2800.0, in: context)
        try context.save()

        // Calculate adaptive TDEE
        let service = TDEEService(context: context)
        let result = try await service.calculateAdaptiveTDEE(goal: goal)

        // Expected: TDEE = 2800 - (weightChange * 7700 / days)
        // weightChange = +1.0 kg (0.25 kg/week * 4 weeks)
        // TDEE = 2800 - (1.0 * 7700 / 28) = 2800 - 275 = 2525
        #expect(result.tdee > 2400)
        #expect(result.tdee < 2700)
        #expect(result.weightChangeRateKgPerWeek > 0)
    }

    @Test("Metabolic adaptation detection")
    @MainActor
    func testMetabolicAdaptationDetection() async throws {
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.initialEstimatedTDEE = 2500.0  // Expected TDEE

        // Seed data showing much lower actual TDEE (eating 1800, not losing weight)
        // This means actual TDEE = 1800, which is 28% below expected 2500
        seedWeightData(days: 28, startWeight: 80.0, weeklyChange: 0.0, in: context)
        seedFoodData(days: 28, dailyCalories: 1800.0, in: context)
        try context.save()

        let service = TDEEService(context: context)
        let result = try await service.calculateAdaptiveTDEE(goal: goal)

        // Should detect metabolic adaptation (actual TDEE ~1800 vs expected 2500)
        #expect(result.hasMetabolicAdaptation)
        #expect(result.tdee < 2000)  // Actual TDEE should be around 1800
    }

    @Test("Should recalculate after 7 days")
    @MainActor
    func testShouldRecalculateAfter7Days() throws {
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)

        let service = TDEEService(context: context)

        // Never calculated
        #expect(service.shouldRecalculateTDEE(goal: goal))

        // Just calculated
        goal.lastTDEECalculationDate = Date()
        #expect(!service.shouldRecalculateTDEE(goal: goal))

        // 6 days ago
        goal.lastTDEECalculationDate = Calendar.current.date(byAdding: .day, value: -6, to: Date())
        #expect(!service.shouldRecalculateTDEE(goal: goal))

        // 7 days ago
        goal.lastTDEECalculationDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        #expect(service.shouldRecalculateTDEE(goal: goal))

        // 14 days ago
        goal.lastTDEECalculationDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())
        #expect(service.shouldRecalculateTDEE(goal: goal))
    }

    @Test("Full TDEE recalculation workflow")
    @MainActor
    func testFullRecalculationWorkflow() async throws {
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)

        // Step 1: Add initial weight and calculate initial TDEE
        let weightEntry = WeightEntry(timestamp: Date(), weightKg: 80.0)
        context.insert(weightEntry)
        try context.save()

        let service = TDEEService(context: context)
        try await service.calculateInitialTDEE(for: user, goal: goal)

        let initialTDEE = goal.initialEstimatedTDEE!
        #expect(initialTDEE > 0)

        // Step 2: Simulate 28 days passing with food/weight data
        // Reset lastTDEECalculationDate to 28 days ago
        goal.lastTDEECalculationDate = Calendar.current.date(byAdding: .day, value: -28, to: Date())

        // Clear existing weight entry and seed new data
        context.delete(weightEntry)
        seedWeightData(days: 28, startWeight: 80.0, weeklyChange: -0.5, in: context)
        seedFoodData(days: 28, dailyCalories: 2000.0, in: context)
        try context.save()

        // Step 3: Check if recalculation is needed
        #expect(service.shouldRecalculateTDEE(goal: goal))

        // Step 4: Calculate adaptive TDEE
        let result = try await service.calculateAdaptiveTDEE(goal: goal)
        #expect(result.tdee > 0)
        #expect(result.daysWithData == 28)

        // Step 5: Update goal
        try service.updateGoalWithAdaptiveTDEE(goal: goal, result: result)
        #expect(goal.lastCalculatedTDEE == result.tdee)
        #expect(goal.lastTDEECalculationDate != nil)

        // Step 6: Verify no immediate recalculation needed
        #expect(!service.shouldRecalculateTDEE(goal: goal))
    }

    @Test("High confidence with consistent logging")
    @MainActor
    func testHighConfidenceWithConsistentLogging() async throws {
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(in: context)
        let goal = createTestGoal(for: user, in: context)
        goal.initialEstimatedTDEE = 2500.0

        // Seed 28 days with complete data and clear weight trend
        seedWeightData(days: 28, startWeight: 82.0, weeklyChange: -0.5, in: context)
        seedFoodData(days: 28, dailyCalories: 2000.0, in: context)
        try context.save()

        let service = TDEEService(context: context)
        let result = try await service.calculateAdaptiveTDEE(goal: goal)

        // Should have high confidence with 28 days and 100% consistency
        #expect(result.confidence > 0.7)
        #expect(result.isHighConfidence)
        #expect(result.daysWithData == 28)
    }
}
