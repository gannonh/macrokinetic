//
//  ProgramConfigurationTests.swift
//  JabTrackerTests
//
//  Tests for nutrition program configuration enums and value types.
//

import Foundation
import Testing

@testable import JabTracker

@Suite("ProgramConfiguration Tests")
struct ProgramConfigurationTests {

    // MARK: - MacroPercentages Tests

    @Test("MacroPercentages calculates total correctly")
    func macroPercentagesTotal() {
        let macros = MacroPercentages(protein: 30, carbs: 40, fat: 30)
        #expect(macros.total == 100)

        let unbalanced = MacroPercentages(protein: 25, carbs: 5, fat: 70)
        #expect(unbalanced.total == 100)
    }

    @Test("MacroPercentages.isValid validates correctly")
    func macroPercentagesIsValid() {
        // Valid: sums to 100, no negatives
        let valid = MacroPercentages(protein: 30, carbs: 40, fat: 30)
        #expect(valid.isValid == true)

        // Invalid: sums to 90
        let invalidSum = MacroPercentages(protein: 30, carbs: 30, fat: 30)
        #expect(invalidSum.isValid == false)

        // Invalid: negative values
        let negativeProtein = MacroPercentages(protein: -10, carbs: 60, fat: 50)
        #expect(negativeProtein.isValid == false)

        // Invalid: sums to 100 but has negative
        let mixedInvalid = MacroPercentages(protein: -10, carbs: 60, fat: 50)
        #expect(mixedInvalid.isValid == false)
    }

    @Test("MacroPercentages is Codable")
    func macroPercentagesCodable() throws {
        let macros = MacroPercentages(protein: 25, carbs: 50, fat: 25)

        let encoder = JSONEncoder()
        let data = try encoder.encode(macros)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MacroPercentages.self, from: data)

        #expect(decoded == macros)
        #expect(decoded.protein == 25)
        #expect(decoded.carbs == 50)
        #expect(decoded.fat == 25)
    }

    @Test("MacroPercentages is Equatable")
    func macroPercentagesEquatable() {
        let macros1 = MacroPercentages(protein: 30, carbs: 40, fat: 30)
        let macros2 = MacroPercentages(protein: 30, carbs: 40, fat: 30)
        let macros3 = MacroPercentages(protein: 25, carbs: 50, fat: 25)

        #expect(macros1 == macros2)
        #expect(macros1 != macros3)
    }

    // MARK: - GoalType Tests

    @Test("GoalType has 3 cases")
    func goalTypeHasThreeCases() {
        #expect(GoalType.allCases.count == 3)
        #expect(GoalType.allCases.contains(.weightLoss))
        #expect(GoalType.allCases.contains(.maintenance))
        #expect(GoalType.allCases.contains(.muscleGain))
    }

    @Test("GoalType has displayName")
    func goalTypeDisplayName() {
        #expect(GoalType.weightLoss.displayName == "Weight Loss")
        #expect(GoalType.maintenance.displayName == "Maintenance")
        #expect(GoalType.muscleGain.displayName == "Muscle Gain")
    }

    // MARK: - ProgramStyle Tests

    @Test("ProgramStyle has 3 cases")
    func programStyleHasThreeCases() {
        #expect(ProgramStyle.allCases.count == 3)
        #expect(ProgramStyle.allCases.contains(.coached))
        #expect(ProgramStyle.allCases.contains(.collaborative))
        #expect(ProgramStyle.allCases.contains(.manual))
    }

    @Test("ProgramStyle has displayName and description")
    func programStyleMetadata() {
        #expect(ProgramStyle.coached.displayName == "Coached")
        #expect(!ProgramStyle.coached.description.isEmpty)

        #expect(ProgramStyle.collaborative.displayName == "Collaborative")
        #expect(!ProgramStyle.collaborative.description.isEmpty)

        #expect(ProgramStyle.manual.displayName == "Manual")
        #expect(!ProgramStyle.manual.description.isEmpty)
    }

    // MARK: - DietPreference Tests

    @Test("DietPreference has 4 cases")
    func dietPreferenceHasFourCases() {
        #expect(DietPreference.allCases.count == 4)
        #expect(DietPreference.allCases.contains(.balanced))
        #expect(DietPreference.allCases.contains(.lowFat))
        #expect(DietPreference.allCases.contains(.lowCarb))
        #expect(DietPreference.allCases.contains(.keto))
    }

    @Test("DietPreference macroPercentages returns correct values")
    func dietPreferenceMacroPercentages() {
        // Balanced: (30, 40, 30)
        let balanced = DietPreference.balanced.macroPercentages
        #expect(balanced.protein == 30)
        #expect(balanced.carbs == 40)
        #expect(balanced.fat == 30)

        // Low-fat: (30, 50, 20)
        let lowFat = DietPreference.lowFat.macroPercentages
        #expect(lowFat.protein == 30)
        #expect(lowFat.carbs == 50)
        #expect(lowFat.fat == 20)

        // Low-carb: (30, 20, 50)
        let lowCarb = DietPreference.lowCarb.macroPercentages
        #expect(lowCarb.protein == 30)
        #expect(lowCarb.carbs == 20)
        #expect(lowCarb.fat == 50)

        // Keto: (25, 5, 70)
        let keto = DietPreference.keto.macroPercentages
        #expect(keto.protein == 25)
        #expect(keto.carbs == 5)
        #expect(keto.fat == 70)
    }

    @Test("DietPreference macroPercentages sum to 100")
    func dietPreferenceMacroPercentagesSumTo100() {
        for preference in DietPreference.allCases {
            let macros = preference.macroPercentages
            #expect(macros.total == 100, "Expected sum of 100 for \(preference), got \(macros.total)")
        }
    }

    @Test("DietPreference has displayName and description")
    func dietPreferenceMetadata() {
        for preference in DietPreference.allCases {
            #expect(!preference.displayName.isEmpty)
            #expect(!preference.description.isEmpty)
        }
    }

    // MARK: - CalorieFloorType Tests

    @Test("CalorieFloorType has 2 cases")
    func calorieFloorTypeHasTwoCases() {
        #expect(CalorieFloorType.allCases.count == 2)
        #expect(CalorieFloorType.allCases.contains(.standard))
        #expect(CalorieFloorType.allCases.contains(.low))
    }

    @Test("CalorieFloorType minimumCalories returns correct values")
    func calorieFloorTypeMinimumCalories() {
        #expect(CalorieFloorType.standard.minimumCalories == 1538)
        #expect(CalorieFloorType.low.minimumCalories == 1025)
    }

    @Test("CalorieFloorType requiresWarning is correct")
    func calorieFloorTypeRequiresWarning() {
        #expect(CalorieFloorType.standard.requiresWarning == false)
        #expect(CalorieFloorType.low.requiresWarning == true)
    }

    @Test("CalorieFloorType has displayName and description")
    func calorieFloorTypeMetadata() {
        for floorType in CalorieFloorType.allCases {
            #expect(!floorType.displayName.isEmpty)
            #expect(!floorType.description.isEmpty)
        }
    }

    // MARK: - WeeklyDistributionMode Tests

    @Test("WeeklyDistributionMode has 2 cases")
    func weeklyDistributionModeHasTwoCases() {
        #expect(WeeklyDistributionMode.allCases.count == 2)
        #expect(WeeklyDistributionMode.allCases.contains(.even))
        #expect(WeeklyDistributionMode.allCases.contains(.shifted))
    }

    @Test("WeeklyDistributionMode has displayName and description")
    func weeklyDistributionModeMetadata() {
        for mode in WeeklyDistributionMode.allCases {
            #expect(!mode.displayName.isEmpty)
            #expect(!mode.description.isEmpty)
        }
    }

    // MARK: - ProteinLevel Tests

    @Test("ProteinLevel has 4 cases")
    func proteinLevelHasFourCases() {
        #expect(ProteinLevel.allCases.count == 4)
        #expect(ProteinLevel.allCases.contains(.low))
        #expect(ProteinLevel.allCases.contains(.moderate))
        #expect(ProteinLevel.allCases.contains(.high))
        #expect(ProteinLevel.allCases.contains(.extraHigh))
    }

    @Test("ProteinLevel gramsPerKg returns correct multipliers")
    func proteinLevelGramsPerKg() {
        #expect(ProteinLevel.low.gramsPerKg == 1.2)
        #expect(ProteinLevel.moderate.gramsPerKg == 1.6)
        #expect(ProteinLevel.high.gramsPerKg == 2.0)
        #expect(ProteinLevel.extraHigh.gramsPerKg == 2.4)
    }

    @Test("ProteinLevel has displayName and description")
    func proteinLevelMetadata() {
        for level in ProteinLevel.allCases {
            #expect(!level.displayName.isEmpty)
            #expect(!level.description.isEmpty)
        }
    }

    // MARK: - WeeklyCalorieDistribution Tests

    @Test("WeeklyCalorieDistribution.even returns base calories unchanged")
    func weeklyCalorieDistributionEven() {
        let even = WeeklyCalorieDistribution.even
        let baseCalories = 2000.0

        // All days should return base calories
        for weekday in WeeklyCalorieDistribution.validWeekdayRange {
            let target = even.calorieTargetForDay(weekday, baseCalories: baseCalories)
            #expect(
                target == baseCalories,
                "Day \(weekday) should return \(baseCalories), got \(String(describing: target))")
        }
    }

    @Test("WeeklyCalorieDistribution calculates correctly with multipliers")
    func weeklyCalorieDistributionWithMultipliers() {
        // Create shifted distribution: weekends get 20% more, weekdays get less
        // Sunday=1, Saturday=7
        let distribution = WeeklyCalorieDistribution(dayMultipliers: [
            1: 1.2,  // Sunday: +20%
            7: 1.2,  // Saturday: +20%
        ])
        let baseCalories = 2000.0

        // Weekend days should be 20% higher
        #expect(distribution.calorieTargetForDay(1, baseCalories: baseCalories) == 2400)
        #expect(distribution.calorieTargetForDay(7, baseCalories: baseCalories) == 2400)

        // Weekdays should be base (no multiplier specified means 1.0)
        for weekday in 2...6 {
            #expect(distribution.calorieTargetForDay(weekday, baseCalories: baseCalories) == 2000)
        }
    }

    @Test("WeeklyCalorieDistribution returns nil for invalid weekday")
    func weeklyCalorieDistributionInvalidWeekday() {
        let distribution = WeeklyCalorieDistribution.even
        let baseCalories = 2000.0

        // Out of bounds values should return nil
        #expect(distribution.calorieTargetForDay(0, baseCalories: baseCalories) == nil)
        #expect(distribution.calorieTargetForDay(8, baseCalories: baseCalories) == nil)
        #expect(distribution.calorieTargetForDay(-1, baseCalories: baseCalories) == nil)
        #expect(distribution.calorieTargetForDay(100, baseCalories: baseCalories) == nil)
    }

    @Test("WeeklyCalorieDistribution.isValid validates sum equals 7.0")
    func weeklyCalorieDistributionIsValid() {
        // Even distribution is valid (all 1.0, sum = 7.0)
        #expect(WeeklyCalorieDistribution.even.isValid == true)

        // Valid shifted: sum of multipliers = 7.0
        // 2 days at 1.2 = 2.4, 5 days at 0.92 = 4.6, total = 7.0
        let validShifted = WeeklyCalorieDistribution(dayMultipliers: [
            1: 1.2,  // Sunday
            2: 0.92,  // Monday
            3: 0.92,  // Tuesday
            4: 0.92,  // Wednesday
            5: 0.92,  // Thursday
            6: 0.92,  // Friday
            7: 1.2,  // Saturday
        ])
        #expect(validShifted.isValid == true)

        // Invalid: doesn't sum to 7.0
        let invalid = WeeklyCalorieDistribution(dayMultipliers: [
            1: 2.0,  // Too high
            7: 2.0,  // Too high
        ])
        #expect(invalid.isValid == false)
    }

    // MARK: - ProgramConfiguration Tests

    @Test("ProgramConfiguration is Codable")
    func programConfigurationCodable() throws {
        let config = ProgramConfiguration(
            programStyle: .coached,
            dietPreference: .balanced,
            calorieFloorType: .standard,
            weeklyDistributionMode: .even,
            proteinLevel: .moderate
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProgramConfiguration.self, from: data)

        #expect(decoded == config)
    }

    @Test("ProgramConfiguration with metadata encodes and decodes")
    func programConfigurationWithMetadata() throws {
        let config = ProgramConfiguration(
            programStyle: .collaborative,
            dietPreference: .keto,
            calorieFloorType: .low,
            weeklyDistributionMode: .shifted,
            proteinLevel: .high,
            metadata: ["customKey": "customValue"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProgramConfiguration.self, from: data)

        #expect(decoded.metadata?["customKey"] == "customValue")
    }

    @Test("ProgramConfiguration is Equatable")
    func programConfigurationEquatable() {
        let config1 = ProgramConfiguration(
            programStyle: .manual,
            dietPreference: .lowCarb,
            calorieFloorType: .standard,
            weeklyDistributionMode: .even,
            proteinLevel: .low
        )

        let config2 = ProgramConfiguration(
            programStyle: .manual,
            dietPreference: .lowCarb,
            calorieFloorType: .standard,
            weeklyDistributionMode: .even,
            proteinLevel: .low
        )

        let config3 = ProgramConfiguration(
            programStyle: .coached,
            dietPreference: .lowCarb,
            calorieFloorType: .standard,
            weeklyDistributionMode: .even,
            proteinLevel: .low
        )

        #expect(config1 == config2)
        #expect(config1 != config3)
    }
}
