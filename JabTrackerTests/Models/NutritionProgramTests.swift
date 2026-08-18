//
//  NutritionProgramTests.swift
//  JabTrackerTests
//
//  Tests for NutritionProgram SwiftData model
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - Test Utilities

/// Creates an in-memory SwiftData context for testing
/// Returns both context and container - container must be kept alive for context to remain valid
@MainActor
private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
    let schema = Schema([
        User.self,
        Dose.self,
        MedicationProfile.self,
        DoseTitration.self,
        DoseSchedule.self,
        ScheduledDose.self,
        Food.self,
        FoodEntry.self,
        WeightEntry.self,
        MetricsEntry.self,
        ProgressPhoto.self,
        NutritionGoal.self,
        NutritionProgram.self,
    ])
    let config = InMemoryTestStore.configuration(schema: schema)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return (container.mainContext, container)
}

// MARK: - NutritionProgramTests

@Suite("NutritionProgram Tests")
struct NutritionProgramTests {

    // MARK: - Initialization Tests

    @Test("Default initialization creates valid program with expected defaults")
    @MainActor
    func testDefaultInitialization() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let program = NutritionProgram()
        context.insert(program)
        try context.save()

        // Then
        // ID is auto-generated - verify program was saved and can be queried
        let saved = try context.fetch(FetchDescriptor<NutritionProgram>()).first
        #expect(saved?.id == program.id)
        #expect(program.programStyleRaw == "coached")
        #expect(program.dietPreferenceRaw == "balanced")
        #expect(program.calorieFloorTypeRaw == "standard")
        #expect(program.weeklyDistributionModeRaw == "even")
        #expect(program.proteinLevelRaw == "moderate")
        #expect(program.createdAt <= Date())
        #expect(program.updatedAt <= Date())
    }

    @Test("Initialization with custom values")
    @MainActor
    func testCustomInitialization() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let program = NutritionProgram(
            style: .manual,
            diet: .keto,
            calorieFloor: .low,
            distributionMode: .shifted,
            proteinLevel: .high
        )
        context.insert(program)
        try context.save()

        // Then
        #expect(program.style == .manual)
        #expect(program.diet == .keto)
        #expect(program.calorieFloor == .low)
        #expect(program.distributionMode == .shifted)
        #expect(program.protein == .high)
    }

    // MARK: - Style Accessor Tests

    @Test("Style accessor converts to/from ProgramStyle enum")
    @MainActor
    func testStyleAccessor() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // Then - default is coached
        #expect(program.style == .coached)

        // When - change to collaborative
        program.style = .collaborative
        #expect(program.programStyleRaw == "collaborative")
        #expect(program.style == .collaborative)

        // When - change to manual
        program.style = .manual
        #expect(program.programStyleRaw == "manual")
        #expect(program.style == .manual)
    }

    @Test("Style with invalid raw value defaults to coached")
    @MainActor
    func testStyleInvalidRawValue() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let program = NutritionProgram()
        program.programStyleRaw = "invalid_style"
        context.insert(program)

        // Then
        #expect(program.style == .coached)
    }

    // MARK: - Diet Accessor Tests

    @Test("Diet accessor converts to/from DietPreference enum")
    @MainActor
    func testDietAccessor() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // Then - default is balanced
        #expect(program.diet == .balanced)

        // When - change to low fat
        program.diet = .lowFat
        #expect(program.dietPreferenceRaw == "low_fat")
        #expect(program.diet == .lowFat)

        // When - change to keto
        program.diet = .keto
        #expect(program.dietPreferenceRaw == "keto")
        #expect(program.diet == .keto)
    }

    @Test("Diet with invalid raw value defaults to balanced")
    @MainActor
    func testDietInvalidRawValue() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let program = NutritionProgram()
        program.dietPreferenceRaw = "invalid_diet"
        context.insert(program)

        // Then
        #expect(program.diet == .balanced)
    }

    // MARK: - Configuration Encoding/Decoding Tests

    @Test("Configuration encoding/decoding roundtrip preserves values")
    @MainActor
    func testConfigurationEncodingRoundtrip() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram(
            style: .collaborative,
            diet: .lowCarb,
            calorieFloor: .low,
            distributionMode: .even,
            proteinLevel: .extraHigh
        )
        context.insert(program)
        try context.save()

        // When
        let decoded = program.configuration

        // Then
        #expect(decoded != nil)
        #expect(decoded?.programStyle == .collaborative)
        #expect(decoded?.dietPreference == .lowCarb)
        #expect(decoded?.calorieFloorType == .low)
        #expect(decoded?.weeklyDistributionMode == .even)
        #expect(decoded?.proteinLevel == .extraHigh)
    }

    @Test("Configuration updates when style changes")
    @MainActor
    func testConfigurationUpdatesOnStyleChange() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // When
        program.style = .manual

        // Then
        let decoded = program.configuration
        #expect(decoded?.programStyle == .manual)
    }

    @Test("Configuration updates when diet changes")
    @MainActor
    func testConfigurationUpdatesOnDietChange() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // When
        program.diet = .keto

        // Then
        let decoded = program.configuration
        #expect(decoded?.dietPreference == .keto)
    }

    // MARK: - Calorie Target for Day Tests

    @Test("calorieTargetForDay returns base for even distribution")
    @MainActor
    func testCalorieTargetForDayEvenDistribution() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.dailyCalorieTarget = 2000.0
        context.insert(goal)

        let program = NutritionProgram()
        program.distributionMode = .even
        context.insert(program)

        // Link program to goal
        program.goal = goal

        try context.save()

        // When/Then - all days should return same value
        for day in 1...7 {
            let target = program.calorieTargetForDay(day)
            #expect(target == 2000.0, "Day \(day) should return base calories")
        }
    }

    @Test("calorieTargetForDay applies multiplier for shifted distribution")
    @MainActor
    func testCalorieTargetForDayShiftedDistribution() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.dailyCalorieTarget = 2000.0
        context.insert(goal)

        let program = NutritionProgram()
        context.insert(program)

        // Link program to goal
        program.goal = goal

        // Set shifted distribution with weekend boost
        let distribution = WeeklyCalorieDistribution(dayMultipliers: [
            1: 1.2,  // Sunday - 20% more
            7: 1.2,  // Saturday - 20% more
            2: 0.92,  // Monday through Friday - less to compensate
            3: 0.92,
            4: 0.92,
            5: 0.92,
            6: 0.92,
        ])

        let didSet = program.setWeeklyDistribution(distribution)
        #expect(didSet == true)

        try context.save()

        // Then
        #expect(program.distributionMode == .shifted)

        // Weekend gets 2400 (2000 * 1.2)
        #expect(program.calorieTargetForDay(1) == 2400.0)
        #expect(program.calorieTargetForDay(7) == 2400.0)

        // Weekdays get 1840 (2000 * 0.92)
        #expect(program.calorieTargetForDay(2) == 1840.0)
        #expect(program.calorieTargetForDay(3) == 1840.0)
    }

    @Test("calorieTargetForDay returns nil for invalid weekday")
    @MainActor
    func testCalorieTargetForDayInvalidWeekday() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.dailyCalorieTarget = 2000.0
        context.insert(goal)

        let program = NutritionProgram()
        program.goal = goal
        context.insert(program)

        // Then
        #expect(program.calorieTargetForDay(0) == nil)
        #expect(program.calorieTargetForDay(8) == nil)
        #expect(program.calorieTargetForDay(-1) == nil)
    }

    @Test("calorieTargetForDay returns nil when goal is not set")
    @MainActor
    func testCalorieTargetForDayNoGoal() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)
        // No goal set

        // Then
        #expect(program.calorieTargetForDay(1) == nil)
    }

    // MARK: - Minimum Calories Tests

    @Test("minimumCalories returns correct floor for standard")
    @MainActor
    func testMinimumCaloriesStandard() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        program.calorieFloor = .standard
        context.insert(program)

        // Then
        #expect(program.minimumCalories == 1538.0)
    }

    @Test("minimumCalories returns correct floor for low")
    @MainActor
    func testMinimumCaloriesLow() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        program.calorieFloor = .low
        context.insert(program)

        // Then
        #expect(program.minimumCalories == 1025.0)
    }

    // MARK: - Computed Properties Tests

    @Test("usesCoachedMacros returns true for coached")
    @MainActor
    func testUsesCoachedMacrosCoached() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram(style: .coached)
        context.insert(program)

        // Then
        #expect(program.usesCoachedMacros == true)
    }

    @Test("usesCoachedMacros returns false for collaborative")
    @MainActor
    func testUsesCoachedMacrosCollaborative() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram(style: .collaborative)
        context.insert(program)

        // Then
        #expect(program.usesCoachedMacros == false)
    }

    @Test("usesCoachedMacros returns false for manual")
    @MainActor
    func testUsesCoachedMacrosManual() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram(style: .manual)
        context.insert(program)

        // Then
        #expect(program.usesCoachedMacros == false)
    }

    @Test("adjustsCaloriesWithProgress returns true for coached and collaborative")
    @MainActor
    func testAdjustsCaloriesWithProgress() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // Coached adjusts
        let coached = NutritionProgram(style: .coached)
        context.insert(coached)
        #expect(coached.adjustsCaloriesWithProgress == true)

        // Collaborative adjusts
        let collaborative = NutritionProgram(style: .collaborative)
        context.insert(collaborative)
        #expect(collaborative.adjustsCaloriesWithProgress == true)

        // Manual does not adjust
        let manual = NutritionProgram(style: .manual)
        context.insert(manual)
        #expect(manual.adjustsCaloriesWithProgress == false)
    }

    // MARK: - Weekly Distribution Tests

    @Test("setWeeklyDistribution validates distribution sums to 7")
    @MainActor
    func testSetWeeklyDistributionValidation() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // Invalid distribution (doesn't sum to 7)
        let invalidDistribution = WeeklyCalorieDistribution(dayMultipliers: [
            1: 2.0  // Way too high
        ])
        #expect(invalidDistribution.isValid == false)

        let didSet = program.setWeeklyDistribution(invalidDistribution)
        #expect(didSet == false)
        #expect(program.distributionMode == .even)  // Should not change
    }

    @Test("setWeeklyDistribution sets mode to shifted when valid")
    @MainActor
    func testSetWeeklyDistributionSetsShiftedMode() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        program.distributionMode = .even
        context.insert(program)

        // Valid distribution (sums to 7)
        let validDistribution = WeeklyCalorieDistribution.even

        let didSet = program.setWeeklyDistribution(validDistribution)
        #expect(didSet == true)
        #expect(program.distributionMode == .shifted)
    }

    @Test("weeklyDistribution returns nil when not set")
    @MainActor
    func testWeeklyDistributionNil() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // Then
        #expect(program.weeklyDistribution == nil)
    }

    // MARK: - Goal Relationship Tests

    @Test("Program can be linked to goal")
    @MainActor
    func testGoalRelationship() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        context.insert(goal)

        let program = NutritionProgram()
        context.insert(program)

        // When
        program.goal = goal
        try context.save()

        // Then
        #expect(program.goal != nil)
        #expect(goal.program == program)
    }

    // MARK: - UpdatedAt Tests

    @Test("updatedAt changes when configuration is updated")
    @MainActor
    func testUpdatedAtChanges() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)
        try context.save()

        let originalUpdatedAt = program.updatedAt

        // Wait a tiny bit to ensure time difference
        try await Task.sleep(for: .milliseconds(10))

        // When
        program.style = .manual

        // Then
        #expect(program.updatedAt > originalUpdatedAt)
    }

    // MARK: - WeeklyMacros Tests

    @Test("weeklyMacros returns nil when weeklyMacroDistributionData is nil")
    @MainActor
    func testWeeklyMacrosNil() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // Then
        #expect(program.weeklyMacros == nil)
    }

    @Test("weeklyMacros returns decoded WeeklyMacroDistribution")
    @MainActor
    func testWeeklyMacrosDecoded() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        let defaultMacros = DailyMacros(calories: 2000, proteinGrams: 150, fatGrams: 80, carbsGrams: 200)
        let distribution = WeeklyMacroDistribution.even(macros: defaultMacros)

        // When
        let didSet = program.setWeeklyMacros(distribution)

        // Then
        #expect(didSet == true)
        #expect(program.weeklyMacros != nil)
        #expect(program.weeklyMacros?.defaultMacros == defaultMacros)
    }

    @Test("setWeeklyMacros returns false for invalid distribution")
    @MainActor
    func testSetWeeklyMacrosInvalid() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // Invalid: zero calories
        let invalidMacros = DailyMacros(calories: 0, proteinGrams: 150, fatGrams: 80, carbsGrams: 200)
        let invalidDistribution = WeeklyMacroDistribution.even(macros: invalidMacros)

        // When
        let didSet = program.setWeeklyMacros(invalidDistribution)

        // Then
        #expect(didSet == false)
        #expect(program.weeklyMacros == nil)
    }

    @Test("macrosForDay returns correct values for even distribution")
    @MainActor
    func testMacrosForDayEven() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.dailyCalorieTarget = 2000
        goal.dailyProteinTargetGrams = 150
        goal.dailyFatTargetGrams = 80
        goal.dailyCarbTargetGrams = 200
        context.insert(goal)

        let program = NutritionProgram()
        context.insert(program)
        program.goal = goal

        let defaultMacros = DailyMacros(calories: 2000, proteinGrams: 150, fatGrams: 80, carbsGrams: 200)
        let distribution = WeeklyMacroDistribution.even(macros: defaultMacros)
        _ = program.setWeeklyMacros(distribution)

        try context.save()

        // Then - all days should return the same macros
        for weekday in 1...7 {
            let macros = program.macrosForDay(weekday, goal: goal)
            #expect(macros != nil, "Day \(weekday) should return macros")
            #expect(macros?.calories == 2000, "Day \(weekday) should have 2000 calories")
            #expect(macros?.proteinGrams == 150, "Day \(weekday) should have 150g protein")
            #expect(macros?.fatGrams == 80, "Day \(weekday) should have 80g fat")
            #expect(macros?.carbsGrams == 200, "Day \(weekday) should have 200g carbs")
        }
    }

    @Test("macrosForDay returns correct values for shifted distribution")
    @MainActor
    func testMacrosForDayShifted() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.dailyCalorieTarget = 2000
        goal.dailyProteinTargetGrams = 150
        goal.dailyFatTargetGrams = 80
        goal.dailyCarbTargetGrams = 200
        context.insert(goal)

        let program = NutritionProgram()
        context.insert(program)
        program.goal = goal

        let defaultMacros = DailyMacros(calories: 2000, proteinGrams: 150, fatGrams: 80, carbsGrams: 200)
        let sundayMacros = DailyMacros(calories: 2400, proteinGrams: 180, fatGrams: 96, carbsGrams: 240)

        let distribution = WeeklyMacroDistribution(
            dayMacros: [1: sundayMacros],  // Sunday has higher macros
            defaultMacros: defaultMacros
        )
        _ = program.setWeeklyMacros(distribution)

        try context.save()

        // Then
        // Sunday (1) should have higher macros
        let sundayResult = program.macrosForDay(1, goal: goal)
        #expect(sundayResult?.calories == 2400)
        #expect(sundayResult?.proteinGrams == 180)
        #expect(sundayResult?.fatGrams == 96)
        #expect(sundayResult?.carbsGrams == 240)

        // Other days should have default macros
        let mondayResult = program.macrosForDay(2, goal: goal)
        #expect(mondayResult?.calories == 2000)
        #expect(mondayResult?.proteinGrams == 150)
    }

    @Test("macrosForDay falls back to goal defaults when no per-day config")
    @MainActor
    func testMacrosForDayFallbackToGoal() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.dailyCalorieTarget = 1800
        goal.dailyProteinTargetGrams = 135
        goal.dailyFatTargetGrams = 72
        goal.dailyCarbTargetGrams = 180
        context.insert(goal)

        let program = NutritionProgram()
        context.insert(program)
        program.goal = goal
        // Don't set weeklyMacros - should fall back to goal

        try context.save()

        // Then - should return goal values
        let result = program.macrosForDay(1, goal: goal)
        #expect(result != nil)
        #expect(result?.calories == 1800)
        #expect(result?.proteinGrams == 135)
        #expect(result?.fatGrams == 72)
        #expect(result?.carbsGrams == 180)
    }

    @Test("macrosForDay returns nil for invalid weekday")
    @MainActor
    func testMacrosForDayInvalidWeekday() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.dailyCalorieTarget = 2000
        context.insert(goal)

        let program = NutritionProgram()
        context.insert(program)
        program.goal = goal

        // Then
        #expect(program.macrosForDay(0, goal: goal) == nil)
        #expect(program.macrosForDay(8, goal: goal) == nil)
        #expect(program.macrosForDay(-1, goal: goal) == nil)
    }

    @Test("macrosForDay returns nil when goal is nil")
    @MainActor
    func testMacrosForDayNoGoal() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)
        // No goal set, no weeklyMacros set

        // Then
        #expect(program.macrosForDay(1, goal: nil) == nil)
    }

    // MARK: - CalorieFloor Accessor Tests

    @Test("CalorieFloor accessor converts to/from CalorieFloorType enum")
    @MainActor
    func testCalorieFloorAccessor() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // Then - default is standard
        #expect(program.calorieFloor == .standard)

        // When - change to low
        program.calorieFloor = .low
        #expect(program.calorieFloorTypeRaw == "low")
        #expect(program.calorieFloor == .low)

        // When - change back to standard
        program.calorieFloor = .standard
        #expect(program.calorieFloorTypeRaw == "standard")
        #expect(program.calorieFloor == .standard)
    }

    @Test("CalorieFloor with invalid raw value defaults to standard")
    @MainActor
    func testCalorieFloorInvalidRawValue() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let program = NutritionProgram()
        program.calorieFloorTypeRaw = "invalid_floor"
        context.insert(program)

        // Then
        #expect(program.calorieFloor == .standard)
    }

    // MARK: - Protein Accessor Tests

    @Test("Protein accessor converts to/from ProteinLevel enum")
    @MainActor
    func testProteinAccessor() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // Then - default is moderate
        #expect(program.protein == .moderate)

        // When - change to high
        program.protein = .high
        #expect(program.proteinLevelRaw == "high")
        #expect(program.protein == .high)

        // When - change to extraHigh
        program.protein = .extraHigh
        #expect(program.proteinLevelRaw == "extra_high")
        #expect(program.protein == .extraHigh)

        // When - change to low
        program.protein = .low
        #expect(program.proteinLevelRaw == "low")
        #expect(program.protein == .low)
    }

    @Test("Protein with invalid raw value defaults to moderate")
    @MainActor
    func testProteinInvalidRawValue() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let program = NutritionProgram()
        program.proteinLevelRaw = "invalid_protein"
        context.insert(program)

        // Then
        #expect(program.protein == .moderate)
    }

    // MARK: - Training Accessor Tests

    @Test("Training accessor converts to/from TrainingLevel enum")
    @MainActor
    func testTrainingAccessor() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // Then - default is none
        #expect(program.training == .none)

        // When - change to lifting
        program.training = .lifting
        #expect(program.trainingLevelRaw == "lifting")
        #expect(program.training == .lifting)

        // When - change to cardio
        program.training = .cardio
        #expect(program.trainingLevelRaw == "cardio")
        #expect(program.training == .cardio)

        // When - change to cardioAndLifting
        program.training = .cardioAndLifting
        #expect(program.trainingLevelRaw == "cardio_and_lifting")
        #expect(program.training == .cardioAndLifting)

        // When - change back to none
        program.training = .none
        #expect(program.trainingLevelRaw == "none")
        #expect(program.training == .none)
    }

    @Test("Training with invalid raw value defaults to none")
    @MainActor
    func testTrainingInvalidRawValue() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let program = NutritionProgram()
        program.trainingLevelRaw = "invalid_training"
        context.insert(program)

        // Then
        #expect(program.training == .none)
    }

    // MARK: - DistributionMode Accessor Tests

    @Test("DistributionMode accessor converts to/from WeeklyDistributionMode enum")
    @MainActor
    func testDistributionModeAccessor() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // Then - default is even
        #expect(program.distributionMode == .even)

        // When - change to shifted
        program.distributionMode = .shifted
        #expect(program.weeklyDistributionModeRaw == "shifted")
        #expect(program.distributionMode == .shifted)

        // When - change back to even
        program.distributionMode = .even
        #expect(program.weeklyDistributionModeRaw == "even")
        #expect(program.distributionMode == .even)
    }

    @Test("DistributionMode with invalid raw value defaults to even")
    @MainActor
    func testDistributionModeInvalidRawValue() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let program = NutritionProgram()
        program.weeklyDistributionModeRaw = "invalid_mode"
        context.insert(program)

        // Then
        #expect(program.distributionMode == .even)
    }

    // MARK: - Configuration Edge Cases

    @Test("Configuration returns nil for empty configurationData")
    @MainActor
    func testConfigurationNilForEmptyData() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // When - explicitly set empty data
        program.configurationData = Data()

        // Then
        #expect(program.configuration == nil)
    }

    @Test("Configuration returns nil for invalid JSON data")
    @MainActor
    func testConfigurationNilForInvalidData() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // When - set invalid JSON data
        program.configurationData = Data("not valid json".utf8)

        // Then
        #expect(program.configuration == nil)
    }

    // MARK: - WeeklyDistribution Edge Cases

    @Test("WeeklyDistribution returns nil for invalid JSON data")
    @MainActor
    func testWeeklyDistributionNilForInvalidData() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // When - set invalid JSON data
        program.weeklyDistributionData = Data("not valid json".utf8)

        // Then
        #expect(program.weeklyDistribution == nil)
    }

    // MARK: - WeeklyMacros Edge Cases

    @Test("WeeklyMacros returns nil for invalid JSON data")
    @MainActor
    func testWeeklyMacrosNilForInvalidData() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // When - set invalid JSON data
        program.weeklyMacroDistributionData = Data("not valid json".utf8)

        // Then
        #expect(program.weeklyMacros == nil)
    }

    // MARK: - Collaborative Config Tests

    @Test("setCollaborativeConfig saves configuration successfully")
    @MainActor
    func testSetCollaborativeConfigSuccess() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        let dayConfigs: [Int: CollaborativeDayConfigStorage] = [
            1: CollaborativeDayConfigStorage(
                calories: 2400, proteinGramsPerLb: 0.8, carbFatRatio: 0.5, isLocked: false),
            2: CollaborativeDayConfigStorage(calories: 1800, proteinGramsPerLb: 0.8, carbFatRatio: 0.5, isLocked: true),
        ]

        // When
        let result = program.setCollaborativeConfig(dayConfigs, weeklyBudget: 14000)

        // Then
        #expect(result == true)
        #expect(program.collaborativeConfigData != nil)
    }

    @Test("collaborativeConfig returns saved configuration")
    @MainActor
    func testCollaborativeConfigReturnsValues() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        let dayConfigs: [Int: CollaborativeDayConfigStorage] = [
            1: CollaborativeDayConfigStorage(
                calories: 2400, proteinGramsPerLb: 0.8, carbFatRatio: 0.5, isLocked: false),
            7: CollaborativeDayConfigStorage(calories: 2200, proteinGramsPerLb: 0.9, carbFatRatio: 0.6, isLocked: true),
        ]
        program.setCollaborativeConfig(dayConfigs, weeklyBudget: 14700)

        // When
        let config = program.collaborativeConfig

        // Then
        #expect(config != nil)
        #expect(config?.weeklyCalorieBudget == 14700)
        #expect(config?.dayConfigs[1]?.calories == 2400)
        #expect(config?.dayConfigs[1]?.proteinGramsPerLb == 0.8)
        #expect(config?.dayConfigs[1]?.isLocked == false)
        #expect(config?.dayConfigs[7]?.calories == 2200)
        #expect(config?.dayConfigs[7]?.isLocked == true)
    }

    @Test("collaborativeConfig returns nil when not set")
    @MainActor
    func testCollaborativeConfigNilWhenNotSet() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // Then
        #expect(program.collaborativeConfig == nil)
    }

    @Test("collaborativeConfig returns nil for invalid JSON data")
    @MainActor
    func testCollaborativeConfigNilForInvalidData() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // When - set invalid JSON data
        program.collaborativeConfigData = Data("not valid json".utf8)

        // Then
        #expect(program.collaborativeConfig == nil)
    }

    // MARK: - CalorieTargetForDay Shifted Without Distribution

    @Test("calorieTargetForDay returns base calories for shifted mode without stored distribution")
    @MainActor
    func testCalorieTargetForDayShiftedNoDistribution() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.dailyCalorieTarget = 2000.0
        context.insert(goal)

        let program = NutritionProgram()
        program.distributionMode = .shifted
        // Don't set weeklyDistributionData - force the fallback path
        context.insert(program)
        program.goal = goal

        try context.save()

        // Then - should return base calories as fallback
        #expect(program.calorieTargetForDay(1) == 2000.0)
        #expect(program.calorieTargetForDay(4) == 2000.0)
    }

    // MARK: - Initialization with TrainingLevel

    @Test("Initialization with custom training level")
    @MainActor
    func testInitializationWithTrainingLevel() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let program = NutritionProgram(
            style: .coached,
            diet: .balanced,
            calorieFloor: .standard,
            trainingLevel: .cardioAndLifting,
            distributionMode: .even,
            proteinLevel: .high
        )
        context.insert(program)
        try context.save()

        // Then
        #expect(program.training == .cardioAndLifting)
        #expect(program.trainingLevelRaw == "cardio_and_lifting")

        // Configuration should also include training level
        let config = program.configuration
        #expect(config?.trainingLevel == .cardioAndLifting)
    }

    // MARK: - Configuration Updates on Property Changes

    @Test("Configuration updates when calorieFloor changes")
    @MainActor
    func testConfigurationUpdatesOnCalorieFloorChange() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // When
        program.calorieFloor = .low

        // Then
        let decoded = program.configuration
        #expect(decoded?.calorieFloorType == .low)
    }

    @Test("Configuration updates when protein changes")
    @MainActor
    func testConfigurationUpdatesOnProteinChange() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // When
        program.protein = .extraHigh

        // Then
        let decoded = program.configuration
        #expect(decoded?.proteinLevel == .extraHigh)
    }

    @Test("Configuration updates when training changes")
    @MainActor
    func testConfigurationUpdatesOnTrainingChange() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // When
        program.training = .lifting

        // Then
        let decoded = program.configuration
        #expect(decoded?.trainingLevel == .lifting)
    }

    @Test("Configuration updates when distributionMode changes")
    @MainActor
    func testConfigurationUpdatesOnDistributionModeChange() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let program = NutritionProgram()
        context.insert(program)

        // When
        program.distributionMode = .shifted

        // Then
        let decoded = program.configuration
        #expect(decoded?.weeklyDistributionMode == .shifted)
    }

    // MARK: - CollaborativeDayConfigStorage Tests

    @Test("CollaborativeDayConfigStorage is Codable")
    func testCollaborativeDayConfigStorageCodable() throws {
        // Given
        let config = CollaborativeDayConfigStorage(
            calories: 2000,
            proteinGramsPerLb: 0.8,
            carbFatRatio: 0.5,
            isLocked: true
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CollaborativeDayConfigStorage.self, from: data)

        // Then
        #expect(decoded.calories == 2000)
        #expect(decoded.proteinGramsPerLb == 0.8)
        #expect(decoded.carbFatRatio == 0.5)
        #expect(decoded.isLocked == true)
    }

    @Test("CollaborativeConfigStorage is Codable")
    func testCollaborativeConfigStorageCodable() throws {
        // Given
        let dayConfigs: [Int: CollaborativeDayConfigStorage] = [
            1: CollaborativeDayConfigStorage(
                calories: 2400, proteinGramsPerLb: 0.8, carbFatRatio: 0.5, isLocked: false),
            7: CollaborativeDayConfigStorage(calories: 2200, proteinGramsPerLb: 0.9, carbFatRatio: 0.6, isLocked: true),
        ]
        let storage = CollaborativeConfigStorage(dayConfigs: dayConfigs, weeklyCalorieBudget: 14000)

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(storage)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CollaborativeConfigStorage.self, from: data)

        // Then
        #expect(decoded.weeklyCalorieBudget == 14000)
        #expect(decoded.dayConfigs.count == 2)
        #expect(decoded.dayConfigs[1]?.calories == 2400)
        #expect(decoded.dayConfigs[7]?.isLocked == true)
    }
}
