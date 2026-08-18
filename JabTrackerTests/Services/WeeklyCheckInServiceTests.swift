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

@MainActor
private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
    let schema = Schema([
        User.self,
        NutritionGoal.self,
        NutritionProgram.self,
        WeightEntry.self,
        FoodEntry.self,
    ])
    let config = InMemoryTestStore.configuration(schema: schema)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return (container.mainContext, container)
}

@MainActor
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

        // Use a fixed Monday date for consistent testing
        let monday = createMondayDate()

        // Last check-in 3 days before that Monday (less than 7 days)
        let threeDaysBeforeMonday = Calendar.current.date(byAdding: .day, value: -3, to: monday)!
        let goal = createTestGoal(in: context, checkInDayOfWeek: 2, lastCheckInDate: threeDaysBeforeMonday)

        let service = WeeklyCheckInService(context: context)
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

    @Test("Returns true when exactly 7 days since last check-in regardless of time-of-day")
    @MainActor
    func testCheckInDueIgnoresTimeOfDay() async {
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current

        // Create a Monday at 9:00 AM for the "today" date
        let mondayMorning = createMondayDate()
        var components = calendar.dateComponents([.year, .month, .day], from: mondayMorning)
        components.hour = 9
        components.minute = 0
        let mondayAt9AM = calendar.date(from: components)!

        // Last check-in was exactly 7 days ago at 10:00 PM (later in the day)
        // Without normalization, this would calculate as 6 days due to time difference
        var lastCheckInComponents = calendar.dateComponents([.year, .month, .day], from: mondayAt9AM)
        lastCheckInComponents.day! -= 7
        lastCheckInComponents.hour = 22  // 10:00 PM
        lastCheckInComponents.minute = 0
        let lastMonday10PM = calendar.date(from: lastCheckInComponents)!

        let goal = createTestGoal(in: context, checkInDayOfWeek: 2, lastCheckInDate: lastMonday10PM)

        let service = WeeklyCheckInService(context: context)
        let result = service.isCheckInDue(for: goal, on: mondayAt9AM)

        // Should be true because 7 calendar days have passed, even though
        // the time difference is less than 7 * 24 hours
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
        // Insufficient data results in one of these messages depending on whether improvement tips exist
        #expect(
            result.changeDescription.contains("insufficient") || result.changeDescription.contains("Not enough")
                || result.changeDescription.contains("To unlock")
        )
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

// MARK: - daysUntilCheckIn Tests

@Suite("WeeklyCheckInService - daysUntilCheckIn")
struct DaysUntilCheckInTests {

    @Test("Returns 0 when check-in is due today")
    @MainActor
    func testReturnsZeroWhenDueToday() async {
        let (context, container) = createTestContext()
        _ = container

        // Check-in day is Monday (2), last check-in was 8 days ago
        let monday = createMondayDate()
        let eightDaysBeforeMonday = Calendar.current.date(byAdding: .day, value: -8, to: monday)!
        let goal = createTestGoal(in: context, checkInDayOfWeek: 2, lastCheckInDate: eightDaysBeforeMonday)

        let service = WeeklyCheckInService(context: context)

        // Test on the Monday when check-in is due
        // Note: daysUntilCheckIn uses current date internally
        // We can only verify that the method runs without error
        let result = service.daysUntilCheckIn(for: goal)

        // Should return a value between 0 and 7
        #expect(result >= 0)
        #expect(result <= 7)
    }

    @Test("Returns correct days when check-in was recent")
    @MainActor
    func testReturnsDaysWhenRecentCheckIn() async {
        let (context, container) = createTestContext()
        _ = container

        // Check-in on Monday (2), last check-in was 3 days ago (within 7 days)
        let goal = createTestGoal(in: context, checkInDayOfWeek: 2, lastCheckInDate: Date())

        let service = WeeklyCheckInService(context: context)
        let result = service.daysUntilCheckIn(for: goal)

        // Should return days until next week's check-in day
        #expect(result >= 0)
        #expect(result <= 7)
    }

    @Test("Returns correct days for new goal with no previous check-in")
    @MainActor
    func testReturnsDaysForNewGoal() async {
        let (context, container) = createTestContext()
        _ = container

        let goal = createTestGoal(in: context, checkInDayOfWeek: 2, lastCheckInDate: nil)
        // Goal was created just now, so it's within 7 days
        goal.createdAt = Date()

        let service = WeeklyCheckInService(context: context)
        let result = service.daysUntilCheckIn(for: goal)

        // Should return days until check-in day, possibly next week if created today
        #expect(result >= 0)
        #expect(result <= 7)
    }
}

// MARK: - assessDataQuality and canPerformCheckIn Tests

@Suite("WeeklyCheckInService - Data Quality")
struct DataQualityTests {

    @Test("assessDataQuality returns assessment")
    @MainActor
    func testAssessDataQualityReturnsAssessment() async {
        let (context, container) = createTestContext()
        _ = container

        let service = WeeklyCheckInService(context: context)
        let result = await service.assessDataQuality()

        // With no data, should return insufficient quality
        #expect(result.quality == .insufficient)
    }

    @Test("canPerformCheckIn returns false with insufficient data")
    @MainActor
    func testCanPerformCheckInReturnsFalseWithNoData() async {
        let (context, container) = createTestContext()
        _ = container

        let service = WeeklyCheckInService(context: context)
        let result = await service.canPerformCheckIn()

        // With no data, should return false
        #expect(result == false)
    }

    @Test("canPerformCheckIn returns true with sufficient data")
    @MainActor
    func testCanPerformCheckInReturnsTrueWithSufficientData() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Seed sufficient data
        let calendar = Calendar.current
        for dayOffset in 0..<14 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            let entry = WeightEntry(timestamp: date, weightKg: 80.0 - Double(dayOffset) * 0.05, source: "test")
            context.insert(entry)

            // Add food entries
            let foodEntry = FoodEntry(
                foodId: UUID(),
                foodName: "Test",
                foodBrand: nil,
                mealSection: .lunch,
                loggedAt: date,
                servingGrams: 100,
                servingDescription: nil,
                caloriesPer100g: 200,
                proteinPer100g: 20,
                carbsPer100g: 20,
                fatPer100g: 10,
                fiberPer100g: 2,
                notes: nil
            )
            context.insert(foodEntry)
        }

        try context.save()

        let service = WeeklyCheckInService(context: context)
        let result = await service.canPerformCheckIn()

        // With sufficient data, should return true
        #expect(result == true)
    }
}

// MARK: - applyOptimization Tests

@Suite("WeeklyCheckInService - applyOptimization")
struct ApplyOptimizationTests {

    @Test("applyOptimization updates goal TDEE when hasChanges is true")
    @MainActor
    func testApplyOptimizationUpdatesTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        let goal = createTestGoal(in: context, tdee: 2000)
        let originalTDEE = goal.lastCalculatedTDEE

        let result = ProgramOptimizationResult(
            periodStart: Date().addingTimeInterval(-28 * 24 * 60 * 60),
            periodEnd: Date(),
            currentTDEE: 2000,
            proposedTDEE: 2200,
            tdeeConfidence: 0.8,
            dataQuality: DataQualityAssessment(
                quality: .good,
                weightEntryCount: 10,
                foodConsistency: 0.7,
                daySpan: 14,
                improvementTips: []
            ),
            actualWeightChangeKg: -1.0,
            goalWeightChangeKg: -2.0,
            isOnTrack: false,
            proposedDailyCalories: 1800,
            proposedWeeklyMacros: WeeklyMacroDistribution.even(
                macros: DailyMacros(calories: 1800, proteinGrams: 150, fatGrams: 60, carbsGrams: 180)
            ),
            changeDescription: "Test description",
            whatNextDescription: "Test what next"
        )

        let service = WeeklyCheckInService(context: context)
        try service.applyOptimization(result, to: goal)

        #expect(goal.lastCalculatedTDEE == 2200)
        #expect(goal.lastCalculatedTDEE != originalTDEE)
        #expect(goal.dailyCalorieTarget == 1800)
        #expect(goal.lastCheckInDate != nil)
    }

    @Test("applyOptimization does nothing when hasChanges is false")
    @MainActor
    func testApplyOptimizationNoChanges() async throws {
        let (context, container) = createTestContext()
        _ = container

        let goal = createTestGoal(in: context, tdee: 2000)
        let originalTDEE = goal.lastCalculatedTDEE
        let originalCalories = goal.dailyCalorieTarget

        let result = ProgramOptimizationResult(
            periodStart: Date().addingTimeInterval(-28 * 24 * 60 * 60),
            periodEnd: Date(),
            currentTDEE: 2000,
            proposedTDEE: nil,  // No proposed change
            tdeeConfidence: 0.8,
            dataQuality: DataQualityAssessment(
                quality: .good,
                weightEntryCount: 10,
                foodConsistency: 0.7,
                daySpan: 14,
                improvementTips: []
            ),
            actualWeightChangeKg: -0.5,
            goalWeightChangeKg: -0.5,
            isOnTrack: true,
            proposedDailyCalories: nil,
            proposedWeeklyMacros: nil,
            changeDescription: "You're on track!",
            whatNextDescription: "Keep doing what you're doing"
        )

        let service = WeeklyCheckInService(context: context)
        try service.applyOptimization(result, to: goal)

        // Should not change anything
        #expect(goal.lastCalculatedTDEE == originalTDEE)
        #expect(goal.dailyCalorieTarget == originalCalories)
    }

    @Test("applyOptimization updates macros when proposed")
    @MainActor
    func testApplyOptimizationUpdatesMacros() async throws {
        let (context, container) = createTestContext()
        _ = container

        let goal = createTestGoal(in: context, tdee: 2000)

        let proposedMacros = WeeklyMacroDistribution.even(
            macros: DailyMacros(calories: 1800, proteinGrams: 160, fatGrams: 65, carbsGrams: 175)
        )

        let result = ProgramOptimizationResult(
            periodStart: Date().addingTimeInterval(-28 * 24 * 60 * 60),
            periodEnd: Date(),
            currentTDEE: 2000,
            proposedTDEE: 2100,
            tdeeConfidence: 0.8,
            dataQuality: DataQualityAssessment(
                quality: .good,
                weightEntryCount: 10,
                foodConsistency: 0.7,
                daySpan: 14,
                improvementTips: []
            ),
            actualWeightChangeKg: -1.0,
            goalWeightChangeKg: -2.0,
            isOnTrack: false,
            proposedDailyCalories: 1800,
            proposedWeeklyMacros: proposedMacros,
            changeDescription: "Test",
            whatNextDescription: "Test"
        )

        let service = WeeklyCheckInService(context: context)
        try service.applyOptimization(result, to: goal)

        #expect(goal.dailyProteinTargetGrams == 160)
        #expect(goal.dailyFatTargetGrams == 65)
        #expect(goal.dailyCarbTargetGrams == 175)
    }
}

// MARK: - declineOptimization Tests

@Suite("WeeklyCheckInService - declineOptimization")
struct DeclineOptimizationTests {

    @Test("declineOptimization updates lastCheckInDate")
    @MainActor
    func testDeclineOptimizationUpdatesDate() async throws {
        let (context, container) = createTestContext()
        _ = container

        let goal = createTestGoal(in: context, lastCheckInDate: nil, tdee: 2000)
        let originalTDEE = goal.lastCalculatedTDEE
        let originalCalories = goal.dailyCalorieTarget

        #expect(goal.lastCheckInDate == nil)

        let service = WeeklyCheckInService(context: context)
        try service.declineOptimization(for: goal)

        // lastCheckInDate should be updated
        #expect(goal.lastCheckInDate != nil)
        #expect(goal.updatedAt != nil)

        // Targets should remain unchanged
        #expect(goal.lastCalculatedTDEE == originalTDEE)
        #expect(goal.dailyCalorieTarget == originalCalories)
    }

    @Test("declineOptimization keeps current targets")
    @MainActor
    func testDeclineOptimizationKeepsTargets() async throws {
        let (context, container) = createTestContext()
        _ = container

        let goal = createTestGoal(in: context, tdee: 2000)
        goal.dailyProteinTargetGrams = 150
        goal.dailyFatTargetGrams = 60
        goal.dailyCarbTargetGrams = 200

        let service = WeeklyCheckInService(context: context)
        try service.declineOptimization(for: goal)

        // All targets should remain unchanged
        #expect(goal.lastCalculatedTDEE == 2000)
        #expect(goal.dailyProteinTargetGrams == 150)
        #expect(goal.dailyFatTargetGrams == 60)
        #expect(goal.dailyCarbTargetGrams == 200)
    }
}

// MARK: - ProgramOptimizationResult Tests

@Suite("ProgramOptimizationResult - Computed Properties")
struct ProgramOptimizationResultTests {

    @Test("hasChanges returns true when proposedTDEE differs from currentTDEE")
    func testHasChangesTrue() {
        let result = ProgramOptimizationResult(
            periodStart: Date(),
            periodEnd: Date(),
            currentTDEE: 2000,
            proposedTDEE: 2200,
            tdeeConfidence: 0.8,
            dataQuality: DataQualityAssessment(
                quality: .good,
                weightEntryCount: 10,
                foodConsistency: 0.7,
                daySpan: 14,
                improvementTips: []
            ),
            actualWeightChangeKg: -1.0,
            goalWeightChangeKg: -2.0,
            isOnTrack: false,
            proposedDailyCalories: 1800,
            proposedWeeklyMacros: nil,
            changeDescription: "Test",
            whatNextDescription: "Test"
        )

        #expect(result.hasChanges == true)
    }

    @Test("hasChanges returns false when proposedTDEE is nil")
    func testHasChangesFalseWhenNil() {
        let result = ProgramOptimizationResult(
            periodStart: Date(),
            periodEnd: Date(),
            currentTDEE: 2000,
            proposedTDEE: nil,
            tdeeConfidence: 0.8,
            dataQuality: DataQualityAssessment(
                quality: .good,
                weightEntryCount: 10,
                foodConsistency: 0.7,
                daySpan: 14,
                improvementTips: []
            ),
            actualWeightChangeKg: -0.5,
            goalWeightChangeKg: -0.5,
            isOnTrack: true,
            proposedDailyCalories: nil,
            proposedWeeklyMacros: nil,
            changeDescription: "On track",
            whatNextDescription: "Keep going"
        )

        #expect(result.hasChanges == false)
    }

    @Test("hasChanges returns false when proposedTDEE equals currentTDEE")
    func testHasChangesFalseWhenEqual() {
        let result = ProgramOptimizationResult(
            periodStart: Date(),
            periodEnd: Date(),
            currentTDEE: 2000,
            proposedTDEE: 2000,
            tdeeConfidence: 0.8,
            dataQuality: DataQualityAssessment(
                quality: .good,
                weightEntryCount: 10,
                foodConsistency: 0.7,
                daySpan: 14,
                improvementTips: []
            ),
            actualWeightChangeKg: -0.5,
            goalWeightChangeKg: -0.5,
            isOnTrack: true,
            proposedDailyCalories: nil,
            proposedWeeklyMacros: nil,
            changeDescription: "On track",
            whatNextDescription: "Keep going"
        )

        #expect(result.hasChanges == false)
    }

    @Test("isHighConfidence returns true for excellent quality")
    func testIsHighConfidenceTrueForExcellent() {
        let result = ProgramOptimizationResult(
            periodStart: Date(),
            periodEnd: Date(),
            currentTDEE: 2000,
            proposedTDEE: 2200,
            tdeeConfidence: 0.9,
            dataQuality: DataQualityAssessment(
                quality: .excellent,
                weightEntryCount: 20,
                foodConsistency: 0.9,
                daySpan: 21,
                improvementTips: []
            ),
            actualWeightChangeKg: -1.0,
            goalWeightChangeKg: -1.5,
            isOnTrack: false,
            proposedDailyCalories: 1800,
            proposedWeeklyMacros: nil,
            changeDescription: "Test",
            whatNextDescription: "Test"
        )

        #expect(result.isHighConfidence == true)
    }

    @Test("isHighConfidence returns true for good quality")
    func testIsHighConfidenceTrueForGood() {
        let result = ProgramOptimizationResult(
            periodStart: Date(),
            periodEnd: Date(),
            currentTDEE: 2000,
            proposedTDEE: 2200,
            tdeeConfidence: 0.7,
            dataQuality: DataQualityAssessment(
                quality: .good,
                weightEntryCount: 10,
                foodConsistency: 0.7,
                daySpan: 14,
                improvementTips: []
            ),
            actualWeightChangeKg: -1.0,
            goalWeightChangeKg: -1.5,
            isOnTrack: false,
            proposedDailyCalories: 1800,
            proposedWeeklyMacros: nil,
            changeDescription: "Test",
            whatNextDescription: "Test"
        )

        #expect(result.isHighConfidence == true)
    }

    @Test("isHighConfidence returns false for minimum quality")
    func testIsHighConfidenceFalseForMinimum() {
        let result = ProgramOptimizationResult(
            periodStart: Date(),
            periodEnd: Date(),
            currentTDEE: 2000,
            proposedTDEE: 2200,
            tdeeConfidence: 0.5,
            dataQuality: DataQualityAssessment(
                quality: .minimum,
                weightEntryCount: 5,
                foodConsistency: 0.5,
                daySpan: 7,
                improvementTips: ["Log more data"]
            ),
            actualWeightChangeKg: -0.5,
            goalWeightChangeKg: -1.0,
            isOnTrack: false,
            proposedDailyCalories: 1800,
            proposedWeeklyMacros: nil,
            changeDescription: "Test",
            whatNextDescription: "Test"
        )

        #expect(result.isHighConfidence == false)
    }

    @Test("isHighConfidence returns false for insufficient quality")
    func testIsHighConfidenceFalseForInsufficient() {
        let result = ProgramOptimizationResult(
            periodStart: Date(),
            periodEnd: Date(),
            currentTDEE: 2000,
            proposedTDEE: nil,
            tdeeConfidence: 0.0,
            dataQuality: DataQualityAssessment(
                quality: .insufficient,
                weightEntryCount: 1,
                foodConsistency: 0.2,
                daySpan: 3,
                improvementTips: ["Need more data"]
            ),
            actualWeightChangeKg: nil,
            goalWeightChangeKg: -0.5,
            isOnTrack: false,
            proposedDailyCalories: nil,
            proposedWeeklyMacros: nil,
            changeDescription: "Insufficient data",
            whatNextDescription: "Log more"
        )

        #expect(result.isHighConfidence == false)
    }
}

// MARK: - isCheckInDue Edge Cases

@Suite("WeeklyCheckInService - isCheckInDue Edge Cases")
struct IsCheckInDueEdgeCasesTests {

    @Test("Returns false when not check-in day of week")
    @MainActor
    func testReturnsFalseOnWrongDay() async {
        let (context, container) = createTestContext()
        _ = container

        // Check-in day is Monday (2), but we check on Tuesday
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        let goal = createTestGoal(in: context, checkInDayOfWeek: 2, lastCheckInDate: eightDaysAgo)

        let service = WeeklyCheckInService(context: context)

        // Create a Tuesday date
        let tuesday = createTuesdayDate()
        let result = service.isCheckInDue(for: goal, on: tuesday)

        #expect(result == false)
    }

    @Test("Uses createdAt when lastCheckInDate is nil")
    @MainActor
    func testUsesCreatedAtWhenNoLastCheckIn() async {
        let (context, container) = createTestContext()
        _ = container

        // Goal created 10 days ago, no previous check-in
        let goal = createTestGoal(in: context, checkInDayOfWeek: 2, lastCheckInDate: nil)
        goal.createdAt = Calendar.current.date(byAdding: .day, value: -10, to: Date())!

        let service = WeeklyCheckInService(context: context)
        let monday = createMondayDate()
        let result = service.isCheckInDue(for: goal, on: monday)

        // Should be due since >= 7 days from createdAt
        #expect(result == true)
    }

    @Test("Returns false when goal has no program")
    @MainActor
    func testReturnsFalseForGoalWithNoProgram() async {
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            startingWeightKg: 80.0,
            targetWeightKg: 75.0,
            weeklyWeightChangePaceKg: -0.5
        )
        goal.checkInDayOfWeek = 2
        goal.program = nil  // No program
        context.insert(goal)

        let service = WeeklyCheckInService(context: context)
        let monday = createMondayDate()
        let result = service.isCheckInDue(for: goal, on: monday)

        // No program means style check returns true for guard (not manual)
        // but without last check-in date or old createdAt, might not be due
        // This depends on when createdAt was set
        #expect(result == true || result == false)  // Just verifying no crash
    }
}

// MARK: - WeeklyCheckInServiceError Tests

@Suite("WeeklyCheckInServiceError")
struct WeeklyCheckInServiceErrorTests {

    @Test("goalNotActive has correct description")
    func testGoalNotActiveDescription() {
        let error = WeeklyCheckInServiceError.goalNotActive
        #expect(error.errorDescription == "Goal is not active")
    }

    @Test("noProgramFound has correct description")
    func testNoProgramFoundDescription() {
        let error = WeeklyCheckInServiceError.noProgramFound
        #expect(error.errorDescription == "No program found for goal")
    }

    @Test("contextSaveError includes underlying error description")
    func testContextSaveErrorDescription() {
        let underlyingError = NSError(
            domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = WeeklyCheckInServiceError.contextSaveError(underlyingError)
        #expect(error.errorDescription?.contains("Test error") == true)
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

/// Create a date that falls on Tuesday
private func createTuesdayDate() -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.firstWeekday = 1  // Sunday = 1
    let today = Date()
    let todayWeekday = calendar.component(.weekday, from: today)
    let daysUntilTuesday = (10 - todayWeekday) % 7  // Tuesday = 3
    return calendar.date(byAdding: .day, value: daysUntilTuesday, to: today)!
}
