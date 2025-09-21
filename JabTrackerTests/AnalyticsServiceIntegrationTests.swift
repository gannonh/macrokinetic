import Foundation
@testable import JabTracker
import SwiftData
import Testing

/// Comprehensive integration tests for AnalyticsService cross-model functionality
struct AnalyticsServiceIntegrationTests {
    // MARK: - Test Setup

    @MainActor private func createTestContainer() -> ModelContainer {
        DataController.testContainer().container
    }

    private func createTestUser() -> User {
        User(
            email: "analytics@test.com",
            name: "Analytics Test User",
            appleUserId: "test-analytics-user")
    }

    private func createTestMedicationProfile(medication: Medication, user: User) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: medication.displayName,
            brandName: medication.displayName,
            currentDose: 1.0)
        // Set the medication and user relationships
        profile.medication = medication
        profile.user = user
        return profile
    }

    private func createTestDose(amount: Double, medicationProfile: MedicationProfile, user: User, daysAgo: Int = 0) -> Dose {
        let timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let dose = Dose(
            amount: amount,
            timestamp: timestamp,
            site: "abdomen",
            notes: "Test dose")
        // Set relationships
        dose.user = user
        dose.medication = medicationProfile
        return dose
    }

    // MARK: - Core Integration Tests

    @Test("AnalyticsService integrates User and MedicationProfile data correctly")
    @MainActor func userAnalyticsIntegration() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let semaglutideProfile = self.createTestMedicationProfile(medication: .semaglutide, user: user)
        let tirezepatideProfile = self.createTestMedicationProfile(medication: .tirzepatide, user: user)

        semaglutideProfile.user = user
        tirezepatideProfile.user = user

        // Insert user and profiles first to prevent duplicate registration
        context.insert(user)
        context.insert(semaglutideProfile)
        context.insert(tirezepatideProfile)

        // Create dose history for both medications
        let dose1 = self.createTestDose(amount: 1.0, medicationProfile: semaglutideProfile, user: user, daysAgo: 7)
        let dose2 = self.createTestDose(amount: 1.0, medicationProfile: semaglutideProfile, user: user, daysAgo: 14)
        let dose3 = self.createTestDose(amount: 2.5, medicationProfile: tirezepatideProfile, user: user, daysAgo: 10)

        dose1.user = user
        dose1.medication = semaglutideProfile
        dose2.user = user
        dose2.medication = semaglutideProfile
        dose3.user = user
        dose3.medication = tirezepatideProfile

        context.insert(dose1)
        context.insert(dose2)
        context.insert(dose3)

        try context.save()

        // Test analytics service integration
        let analyticsService = AnalyticsService()
        let userAnalytics = analyticsService.calculateUserAnalytics(user: user, context: context)

        #expect(userAnalytics.medicationEffectiveness.count == 2, "Should analyze both medications")
        #expect(userAnalytics.concentrationTrends.count == 2, "Should generate trends for both medications")
        #expect(userAnalytics.overallAdherence >= 0.0 && userAnalytics.overallAdherence <= 1.0, "Adherence should be normalized")
        #expect(userAnalytics.totalActiveDays >= 0, "Should count active days")
        #expect(!userAnalytics.adherenceInsights.isEmpty, "Should generate insights")
    }

    @Test("Cross-medication adherence calculations are accurate")
    @MainActor func crossMedicationAdherence() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let semaglutideProfile = self.createTestMedicationProfile(medication: .semaglutide, user: user)
        let tirezepatideProfile = self.createTestMedicationProfile(medication: .tirzepatide, user: user)

        semaglutideProfile.user = user
        tirezepatideProfile.user = user

        context.insert(user)
        context.insert(semaglutideProfile)
        context.insert(tirezepatideProfile)

        // Create perfect adherence for semaglutide (weekly dosing)
        for week in 0 ..< 4 {
            let dose = self.createTestDose(amount: 1.0, medicationProfile: semaglutideProfile, user: user, daysAgo: week * 7)
            dose.user = user
            dose.medication = semaglutideProfile
            context.insert(dose)
        }

        // Create partial adherence for tirzepatide (missed some doses)
        for week in [0, 2] { // Skip weeks 1 and 3
            let dose = self.createTestDose(amount: 2.5, medicationProfile: tirezepatideProfile, user: user, daysAgo: week * 7)
            dose.user = user
            dose.medication = tirezepatideProfile
            context.insert(dose)
        }

        try context.save()

        let analyticsService = AnalyticsService()
        let overallAdherence = analyticsService.calculateOverallAdherence(user: user, context: context)

        // Overall adherence should be average of both medications
        // Semaglutide: ~100%, Tirzepatide: ~50%, Average: ~75%
        #expect(overallAdherence > 0.6 && overallAdherence < 0.9, "Overall adherence should reflect mixed performance")
    }

    @Test("Concentration-adherence correlation analysis works correctly")
    @MainActor func concentrationAdherenceCorrelation() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)
        profile.user = user

        context.insert(user)
        context.insert(profile)

        // Create consistent dosing pattern
        let dose1 = self.createTestDose(amount: 1.0, medicationProfile: profile, user: user, daysAgo: 7)
        let dose2 = self.createTestDose(amount: 1.0, medicationProfile: profile, user: user, daysAgo: 14)
        let dose3 = self.createTestDose(amount: 1.0, medicationProfile: profile, user: user, daysAgo: 21)

        dose1.user = user
        dose1.medication = profile
        dose2.user = user
        dose2.medication = profile
        dose3.user = user
        dose3.medication = profile

        context.insert(dose1)
        context.insert(dose2)
        context.insert(dose3)

        try context.save()

        let analyticsService = AnalyticsService()
        let concentrationInsights = analyticsService.generateConcentrationInsights(user: user, context: context)

        #expect(!concentrationInsights.isEmpty, "Should generate concentration insights")

        let semaglutideInsight = concentrationInsights.first { $0.medication == .semaglutide }
        #expect(semaglutideInsight != nil, "Should have semaglutide insight")
        #expect(semaglutideInsight!.currentConcentration >= 0.0, "Should calculate current concentration")
        #expect(semaglutideInsight!.adherenceImpact >= 0.0 && semaglutideInsight!.adherenceImpact <= 1.0, "Adherence impact should be normalized")
        #expect(!semaglutideInsight!.recommendation.isEmpty, "Should provide recommendation")
    }

    @Test("Medication effectiveness scoring integrates multiple factors")
    @MainActor func medicationEffectivenessScoring() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)
        profile.user = user

        context.insert(user)
        context.insert(profile)

        // Create high adherence dose pattern
        for day in 0 ..< 7 {
            let dose = self.createTestDose(amount: 1.0, medicationProfile: profile, user: user, daysAgo: day * 7)
            dose.user = user
            dose.medication = profile
            context.insert(dose)
        }

        try context.save()

        let analyticsService = AnalyticsService()
        let effectiveness = analyticsService.calculateMedicationEffectiveness(profile: profile, user: user, context: context)

        #expect(effectiveness.medicationProfile == profile, "Should reference correct profile")
        #expect(effectiveness.effectivenessScore >= 0.0 && effectiveness.effectivenessScore <= 1.0, "Score should be normalized")
        #expect(effectiveness.adherenceRate >= 0.0 && effectiveness.adherenceRate <= 1.0, "Adherence rate should be normalized")
        #expect(
            effectiveness.concentrationOptimality >= 0.0 && effectiveness.concentrationOptimality <= 1.0,
            "Concentration optimality should be normalized")
        #expect(!effectiveness.recommendedAdjustments.isEmpty, "Should provide recommendations")
    }

    @Test("Analytics service generates appropriate insights for different scenarios")
    @MainActor func insightGeneration() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)
        profile.user = user

        context.insert(user)
        context.insert(profile)

        // Create excellent adherence pattern
        for week in 0 ..< 4 {
            let dose = self.createTestDose(amount: 1.0, medicationProfile: profile, user: user, daysAgo: week * 7)
            dose.user = user
            dose.medication = profile
            context.insert(dose)
        }

        try context.save()

        let analyticsService = AnalyticsService()
        let userAnalytics = analyticsService.calculateUserAnalytics(user: user, context: context)

        #expect(!userAnalytics.adherenceInsights.isEmpty, "Should generate insights")

        let excellentAdherenceInsight = userAnalytics.adherenceInsights.first { $0.type == .excellentAdherence }
        #expect(excellentAdherenceInsight != nil, "Should recognize excellent adherence")
        #expect(!excellentAdherenceInsight!.description.isEmpty, "Should provide description")
        #expect(!excellentAdherenceInsight!.actionableRecommendation.isEmpty, "Should provide recommendation")
    }

    @Test("Analytics service handles edge cases gracefully")
    @MainActor func edgeCaseHandling() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        // Test with user having no medication profiles
        let userWithoutMedications = self.createTestUser()
        context.insert(userWithoutMedications)

        // Test with user having profile but no doses
        let userWithoutDoses = self.createTestUser()
        userWithoutDoses.appleUserId = "user-without-doses"
        let emptyProfile = self.createTestMedicationProfile(medication: .semaglutide, user: userWithoutDoses)
        emptyProfile.user = userWithoutDoses

        context.insert(userWithoutDoses)
        context.insert(emptyProfile)

        try context.save()

        let analyticsService = AnalyticsService()

        // Test analytics for user without medications
        let analyticsWithoutMeds = analyticsService.calculateUserAnalytics(user: userWithoutMedications, context: context)
        #expect(analyticsWithoutMeds.medicationEffectiveness.isEmpty, "Should handle no medications")
        #expect(analyticsWithoutMeds.concentrationTrends.isEmpty, "Should handle no trends")
        #expect(analyticsWithoutMeds.overallAdherence == 0.0, "Should show zero adherence")

        // Test analytics for user without doses
        let analyticsWithoutDoses = analyticsService.calculateUserAnalytics(user: userWithoutDoses, context: context)
        #expect(analyticsWithoutDoses.medicationEffectiveness.count == 1, "Should include medication")
        #expect(analyticsWithoutDoses.medicationEffectiveness.first?.effectivenessScore == 0.0, "Should show zero effectiveness")
    }

    @Test("Performance testing with large dose histories")
    @MainActor func performanceWithLargeDoseHistory() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)
        profile.user = user

        context.insert(user)
        context.insert(profile)

        // Create large dose history (100 doses over ~2 years)
        for daysAgo in 0 ..< 700 where daysAgo % 7 == 0 { // Weekly doses
            let dose = createTestDose(amount: 1.0, medicationProfile: profile, user: user, daysAgo: daysAgo)
            dose.user = user
            dose.medication = profile
            context.insert(dose)
        }

        try context.save()

        let analyticsService = AnalyticsService()

        // Measure performance
        let startTime = Date()
        let userAnalytics = analyticsService.calculateUserAnalytics(user: user, context: context)
        let executionTime = Date().timeIntervalSince(startTime)

        #expect(executionTime < 1.0, "Analytics calculation should complete within 1 second")
        #expect(!userAnalytics.medicationEffectiveness.isEmpty, "Should handle large dose history")
        #expect(userAnalytics.totalActiveDays > 90, "Should count many active days")
    }

    @Test("Analytics service maintains data consistency across calculations")
    @MainActor func dataConsistency() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)
        profile.user = user

        context.insert(user)
        context.insert(profile)

        // Create consistent dose pattern
        for week in 0 ..< 4 {
            let dose = self.createTestDose(amount: 1.0, medicationProfile: profile, user: user, daysAgo: week * 7)
            dose.user = user
            dose.medication = profile
            context.insert(dose)
        }

        try context.save()

        let analyticsService = AnalyticsService()

        // Run multiple calculations
        let analytics1 = analyticsService.calculateUserAnalytics(user: user, context: context)
        let analytics2 = analyticsService.calculateUserAnalytics(user: user, context: context)

        // Verify consistency
        #expect(analytics1.overallAdherence == analytics2.overallAdherence, "Adherence calculations should be consistent")
        #expect(analytics1.totalActiveDays == analytics2.totalActiveDays, "Active days should be consistent")
        #expect(analytics1.medicationEffectiveness.count == analytics2.medicationEffectiveness.count, "Effectiveness count should be consistent")

        // Verify adherence calculation matches individual model calculations
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let profileAdherence = profile.calculateAdherence(from: thirtyDaysAgo, to: Date(), context: context)
        #expect(abs(analytics1.overallAdherence - profileAdherence) < 0.001, "Overall adherence should match profile adherence for single medication")
    }

    @Test("Cross-model integration preserves individual model functionality")
    @MainActor func individualModelFunctionalityPreservation() throws {
        let container = self.createTestContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let profile = self.createTestMedicationProfile(medication: .semaglutide, user: user)
        profile.user = user

        context.insert(user)
        context.insert(profile)

        // Create dose history
        let dose1 = self.createTestDose(amount: 1.0, medicationProfile: profile, user: user, daysAgo: 7)
        let dose2 = self.createTestDose(amount: 1.0, medicationProfile: profile, user: user, daysAgo: 14)

        dose1.user = user
        dose1.medication = profile
        dose2.user = user
        dose2.medication = profile

        context.insert(dose1)
        context.insert(dose2)

        try context.save()

        // Test that individual model analytics still work
        let userStreak = user.currentStreak
        let profileAdherence = profile.calculateAdherence(
            from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            to: Date(),
            context: context)
        let doseTimestamp = dose1.timestamp

        #expect(userStreak >= 0, "User streak calculation should work")
        #expect(profileAdherence >= 0.0 && profileAdherence <= 1.0, "Profile adherence should work")
        #expect(doseTimestamp > Date.distantPast, "Dose timestamp should be valid")

        // Test that analytics service doesn't interfere
        let analyticsService = AnalyticsService()
        _ = analyticsService.calculateUserAnalytics(user: user, context: context)

        // Verify individual calculations remain unchanged
        #expect(user.currentStreak == userStreak, "User calculations should be preserved")
        let newProfileAdherence = profile.calculateAdherence(
            from: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
            to: Date(),
            context: context)
        #expect(abs(newProfileAdherence - profileAdherence) < 0.001, "Profile calculations should be preserved")
        #expect(dose1.timestamp == doseTimestamp, "Dose data should be preserved")
    }
}
