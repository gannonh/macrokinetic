//
//  WeeklyCheckInServiceTests.swift
//  JabTrackerTests
//
//  Tests for WeeklyCheckInService - weekly check-in logic and optimization.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - Test Helpers

private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
    let schema = Schema([
        User.self,
        NutritionGoal.self,
        NutritionProgram.self,
        WeightEntry.self,
        FoodEntry.self,
    ])
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    let container = try! ModelContainer(for: schema, configurations: [config])
    return (container.mainContext, container)
}

private func createTestGoal(
    in context: ModelContext,
    style: ProgramStyle = .coached,
    checkInDayOfWeek: Int = 2,
    lastCheckInDate: Date? = nil,
    tdee: Double = 2000
) -> NutritionGoal {
    let goal = NutritionGoal(
        goalType: .weightLoss,
        isActive: true,
        startingWeightKg: 80.0,
        targetWeightKg: 75.0,
        weeklyWeightChangePaceKg: -0.5
    )
    goal.checkInDayOfWeek = checkInDayOfWeek
    goal.lastCheckInDate = lastCheckInDate
    goal.initialEstimatedTDEE = tdee
    goal.lastCalculatedTDEE = tdee
    goal.dailyCalorieTarget = 1500

    let program = NutritionProgram(style: style)
    context.insert(program)
    goal.program = program

    context.insert(goal)
    return goal
}

// MARK: - isCheckInDue Tests

@Suite("WeeklyCheckInService - isCheckInDue")
struct IsCheckInDueTests {

    @Test("Returns true on check-in day when >= 7 days since last")
    @MainActor
    func testCheckInDueOnCorrectDay() async {
        let (context, container) = createTestContext()
        _ = container

        // Create goal with check-in on Monday (2), last check-in 8 days ago
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        let goal = createTestGoal(in: context, checkInDayOfWeek: 2, lastCheckInDate: eightDaysAgo)

        let service = WeeklyCheckInService(context: context)

        // Simulate today being Monday
        let monday = createMondayDate()
        let result = service.isCheckInDue(for: goal, on: monday)

        #expect(result == true)
    }

    @Test("Returns false before 7 days since last check-in")
    @MainActor
    func testNotDueBeforeSevenDays() async {
        let (context, container) = createTestContext()
        _ = container

        // Last check-in 3 days ago
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let goal = createTestGoal(in: context, checkInDayOfWeek: 2, lastCheckInDate: threeDaysAgo)

        let service = WeeklyCheckInService(context: context)
        let monday = createMondayDate()
        let result = service.isCheckInDue(for: goal, on: monday)

        #expect(result == false)
    }

    @Test("Returns false for Manual program style")
    @MainActor
    func testManualStyleExcluded() async {
        let (context, container) = createTestContext()
        _ = container

        // Manual programs skip check-ins entirely
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        let goal = createTestGoal(in: context, style: .manual, checkInDayOfWeek: 2, lastCheckInDate: eightDaysAgo)

        let service = WeeklyCheckInService(context: context)
        let monday = createMondayDate()
        let result = service.isCheckInDue(for: goal, on: monday)

        #expect(result == false)
    }

    @Test("Returns true for first check-in when lastCheckInDate is nil")
    @MainActor
    func testFirstCheckInDue() async {
        let (context, container) = createTestContext()
        _ = container

        // New goal with no previous check-in, but created 7+ days ago
        let goal = createTestGoal(in: context, checkInDayOfWeek: 2, lastCheckInDate: nil)
        goal.createdAt = Calendar.current.date(byAdding: .day, value: -10, to: Date())!

        let service = WeeklyCheckInService(context: context)
        let monday = createMondayDate()
        let result = service.isCheckInDue(for: goal, on: monday)

        #expect(result == true)
    }
}

// MARK: - generateOptimization Tests

@Suite("WeeklyCheckInService - generateOptimization")
struct GenerateOptimizationTests {

    @Test("Returns unchanged program when insufficient data")
    @MainActor
    func testInsufficientData() async throws {
        let (context, container) = createTestContext()
        _ = container

        let goal = createTestGoal(in: context, tdee: 2000)

        // No weight or food data logged
        let service = WeeklyCheckInService(context: context)
        let result = try await service.generateOptimization(for: goal)

        #expect(result.hasChanges == false)
        #expect(result.proposedTDEE == nil)
        #expect(result.changeDescription.contains("insufficient") || result.changeDescription.contains("Not enough"))
    }

    @Test("Calculates new TDEE from weight trend and food logs")
    @MainActor
    func testCalculatesAdaptiveTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        let goal = createTestGoal(in: context, tdee: 2000)

        // Seed 14+ days of weight data with declining trend
        let calendar = Calendar.current
        for dayOffset in 0..<21 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let weight = 80.0 - Double(dayOffset) * 0.05  // Losing ~0.35 kg/week
            let entry = WeightEntry(timestamp: date, weightKg: weight, source: "test")
            context.insert(entry)
        }

        // Seed food logs for 70%+ days with ~1500 cal average
        for dayOffset in 0..<21 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            if dayOffset % 3 != 2 {  // Skip every 3rd day (~67% consistency, need to hit 70%+)
                let entry = FoodEntry(
                    foodId: UUID(),
                    foodName: "Test Food",
                    foodBrand: nil,
                    mealSection: .lunch,
                    loggedAt: date,
                    servingGrams: 500,
                    servingDescription: nil,
                    caloriesPer100g: 300,
                    proteinPer100g: 25,
                    carbsPer100g: 40,
                    fatPer100g: 10,
                    fiberPer100g: 5,
                    notes: nil
                )
                context.insert(entry)
            }
        }

        try context.save()

        let service = WeeklyCheckInService(context: context)
        let result = try await service.generateOptimization(for: goal)

        // Should have calculated a new TDEE from actual data
        #expect(result.proposedTDEE != nil)
        #expect(result.tdeeConfidence > 0)
        #expect(result.actualWeightChangeKg != nil)
    }

    @Test("Returns correct macro adjustments based on new TDEE")
    @MainActor
    func testMacroAdjustments() async throws {
        let (context, container) = createTestContext()
        _ = container

        let goal = createTestGoal(in: context, tdee: 2000)

        // Seed enough data to trigger optimization
        let calendar = Calendar.current
        for dayOffset in 0..<21 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let weight = 80.0 - Double(dayOffset) * 0.02  // Slower weight loss than expected
            let entry = WeightEntry(timestamp: date, weightKg: weight, source: "test")
            context.insert(entry)
        }

        // Seed food logs
        for dayOffset in 0..<21 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let entry = FoodEntry(
                foodId: UUID(),
                foodName: "Test Food",
                foodBrand: nil,
                mealSection: .lunch,
                loggedAt: date,
                servingGrams: 600,
                servingDescription: nil,
                caloriesPer100g: 300,
                proteinPer100g: 25,
                carbsPer100g: 40,
                fatPer100g: 10,
                fiberPer100g: 5,
                notes: nil
            )
            context.insert(entry)
        }

        try context.save()

        let service = WeeklyCheckInService(context: context)
        let result = try await service.generateOptimization(for: goal)

        // If TDEE changed significantly, should have proposed new calories/macros
        if result.hasChanges {
            #expect(result.proposedDailyCalories != nil)
            #expect(result.proposedWeeklyMacros != nil)
        }
    }
}

// MARK: - Test Helpers

/// Create a date that falls on Monday
private func createMondayDate() -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 1  // Sunday = 1
    let today = Date()
    let todayWeekday = calendar.component(.weekday, from: today)
    let daysUntilMonday = (9 - todayWeekday) % 7  // Monday = 2
    return calendar.date(byAdding: .day, value: daysUntilMonday, to: today)!
}
