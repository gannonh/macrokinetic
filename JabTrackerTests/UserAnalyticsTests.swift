import Foundation
@testable import JabTracker
import SwiftData
import Testing

@MainActor
@Suite("User Analytics Model Tests")
struct UserAnalyticsTests {
    // MARK: - Analytics Preferences Tests

    @Test("User model has analytics preferences fields")
    func userAnalyticsPreferencesFields() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let user = User(
            email: "analytics@example.com",
            name: "Analytics User",
            analyticsEnabled: true,
            adherenceGoalDays: 6,
            analyticsReportingEnabled: false,
            preferredReportingFrequency: "monthly")

        context.insert(user)
        try context.save()

        // Verify analytics preferences fields
        #expect(user.analyticsEnabled == true, "Analytics should be enabled")
        #expect(user.adherenceGoalDays == 6, "Adherence goal should be 6 days")
        #expect(user.analyticsReportingEnabled == false, "Analytics reporting should be disabled")
        #expect(user.preferredReportingFrequency == "monthly", "Preferred reporting frequency should be monthly")
    }

    @Test("User analytics preferences default values")
    func userAnalyticsPreferencesDefaults() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Create user with minimal parameters
        let user = User()
        context.insert(user)

        // Verify analytics preferences have sensible defaults
        #expect(user.analyticsEnabled == true, "Analytics should be enabled by default")
        #expect(user.adherenceGoalDays == 7, "Default adherence goal should be 7 days (weekly)")
        #expect(user.analyticsReportingEnabled == true, "Analytics reporting should be enabled by default")
        #expect(user.preferredReportingFrequency == "weekly", "Default reporting frequency should be weekly")

        try context.save()
    }

    @Test("User analytics preferences CloudKit compatibility")
    func userAnalyticsPreferencesCloudKitCompatibility() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let user = User(
            email: "cloudkit@example.com",
            analyticsEnabled: false,
            adherenceGoalDays: 5,
            analyticsReportingEnabled: true,
            preferredReportingFrequency: "daily")

        context.insert(user)
        try context.save()

        // All analytics preference fields should have non-nil values for CloudKit
        #expect(user.analyticsEnabled != nil, "Analytics enabled should not be nil for CloudKit")
        #expect(user.adherenceGoalDays > 0, "Adherence goal days should be positive for CloudKit")
        #expect(user.analyticsReportingEnabled != nil, "Analytics reporting enabled should not be nil for CloudKit")
        #expect(!user.preferredReportingFrequency.isEmpty, "Preferred reporting frequency should not be empty for CloudKit")
    }

    // MARK: - User-Level Adherence Calculation Tests

    @Test("User adherence calculation with no doses")
    func userAdherenceCalculationNoDoses() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let user = User(email: "nodoses@example.com")
        context.insert(user)
        try context.save()

        // With no doses, adherence calculations should handle gracefully
        #expect(user.currentAdherenceRate == 0.0, "Adherence rate should be 0.0 with no doses")
        #expect(user.currentStreak == 0, "Current streak should be 0 with no doses")
        #expect(user.longestStreak == 0, "Longest streak should be 0 with no doses")
        #expect(user.averageTimeBetweenDoses == 0.0, "Average time between doses should be 0.0 with no doses")
    }

    @Test("User adherence calculation with perfect adherence")
    func userAdherenceCalculationPerfectAdherence() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let user = User(email: "perfect@example.com", adherenceGoalDays: 7)
        context.insert(user)

        // Create a medication profile for the user
        let medicationProfile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0)
        medicationProfile.user = user
        context.insert(medicationProfile)

        // Create doses for perfect weekly adherence (7 days)
        let calendar = Calendar.current
        let now = Date()
        for dayOffset in 0 ..< 7 {
            let doseDate = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let dose = Dose(
                amount: 1.0,
                timestamp: doseDate,
                user: user,
                medication: medicationProfile)
            context.insert(dose)
        }

        try context.save()

        // Should have perfect adherence
        #expect(user.currentAdherenceRate == 1.0, "Adherence rate should be 1.0 (100%) with perfect adherence")
        #expect(user.currentStreak == 7, "Current streak should be 7 days with perfect adherence")
        #expect(user.longestStreak == 7, "Longest streak should be 7 days with perfect adherence")
        #expect(user.averageTimeBetweenDoses > 0.0, "Average time between doses should be positive")
    }

    @Test("User adherence calculation with missed doses")
    func userAdherenceCalculationMissedDoses() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let user = User(email: "missed@example.com", adherenceGoalDays: 7)
        context.insert(user)

        // Create a medication profile for the user
        let medicationProfile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0)
        medicationProfile.user = user
        context.insert(medicationProfile)

        // Create doses for 5 out of 7 days (missed 2 days)
        let calendar = Calendar.current
        let now = Date()
        let doseDays = [0, 1, 2, 4, 6] // Missed days 3 and 5
        for dayOffset in doseDays {
            let doseDate = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let dose = Dose(
                amount: 1.0,
                timestamp: doseDate,
                user: user,
                medication: medicationProfile)
            context.insert(dose)
        }

        try context.save()

        // Should have 5/7 = ~71% adherence
        let expectedAdherence = 5.0 / 7.0
        #expect(abs(user.currentAdherenceRate - expectedAdherence) < 0.01, "Adherence rate should be approximately 71% (5/7)")
        #expect(user.currentStreak < 7, "Current streak should be less than 7 with missed doses")
        #expect(user.longestStreak > 0, "Longest streak should be greater than 0")
    }

    @Test("User adherence calculation with skipped doses")
    func userAdherenceCalculationSkippedDoses() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let user = User(email: "skipped@example.com", adherenceGoalDays: 7)
        context.insert(user)

        // Create a medication profile for the user
        let medicationProfile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0)
        medicationProfile.user = user
        context.insert(medicationProfile)

        // Create doses including skipped ones
        let calendar = Calendar.current
        let now = Date()
        for dayOffset in 0 ..< 7 {
            let doseDate = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let isSkipped = dayOffset == 2 || dayOffset == 5 // Skip 2 days
            let dose = Dose(
                amount: isSkipped ? 0.0 : 1.0,
                timestamp: doseDate,
                skipped: isSkipped,
                user: user,
                medication: medicationProfile)
            context.insert(dose)
        }

        try context.save()

        // Skipped doses should not count as adherent
        let expectedAdherence = 5.0 / 7.0 // 5 taken, 2 skipped
        #expect(abs(user.currentAdherenceRate - expectedAdherence) < 0.01, "Skipped doses should not count toward adherence")
    }

    @Test("User adherence rate calculation period configuration")
    func userAdherenceRateCalculationPeriod() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let user = User(email: "period@example.com", adherenceGoalDays: 30) // Monthly goal
        context.insert(user)

        // Create a medication profile for the user
        let medicationProfile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0)
        medicationProfile.user = user
        context.insert(medicationProfile)

        // Create doses for 25 out of 30 days
        let calendar = Calendar.current
        let now = Date()
        for dayOffset in 0 ..< 25 {
            let doseDate = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let dose = Dose(
                amount: 1.0,
                timestamp: doseDate,
                user: user,
                medication: medicationProfile)
            context.insert(dose)
        }

        try context.save()

        // Should calculate adherence based on user's adherence goal period
        let expectedAdherence = 25.0 / 30.0 // 25/30 = ~83%
        #expect(abs(user.currentAdherenceRate - expectedAdherence) < 0.01, "Adherence should be calculated based on user's adherence goal period")
    }

    @Test("User average time between doses calculation")
    func userAverageTimeBetweenDosesCalculation() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let user = User(email: "timing@example.com")
        context.insert(user)

        // Create a medication profile for the user
        let medicationProfile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0)
        medicationProfile.user = user
        context.insert(medicationProfile)

        // Create doses exactly 7 days apart
        let calendar = Calendar.current
        let now = Date()
        let doseDates = [
            now,
            calendar.date(byAdding: .day, value: -7, to: now)!,
            calendar.date(byAdding: .day, value: -14, to: now)!,
            calendar.date(byAdding: .day, value: -21, to: now)!,
        ]

        for doseDate in doseDates {
            let dose = Dose(
                amount: 1.0,
                timestamp: doseDate,
                user: user,
                medication: medicationProfile)
            context.insert(dose)
        }

        try context.save()

        // Average should be 7 days (604800 seconds)
        let expectedAverageSeconds = 7.0 * 24.0 * 60.0 * 60.0 // 7 days in seconds
        #expect(abs(user.averageTimeBetweenDoses - expectedAverageSeconds) < 3600, "Average time between doses should be approximately 7 days")
    }

    // MARK: - Integration Tests

    @Test("User analytics fields work with existing User functionality")
    func userAnalyticsIntegrationWithExistingFields() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let user = User(
            email: "integration@example.com",
            name: "Integration User",
            weight: 75.0,
            weightUnit: "kg",
            analyticsEnabled: true,
            adherenceGoalDays: 14,
            analyticsReportingEnabled: true,
            preferredReportingFrequency: "biweekly")

        context.insert(user)
        try context.save()

        // All existing computed properties should still work
        #expect(user.weightDisplay == "75.0 kg", "Existing weight display should still work")
        #expect(user.displayEmail == "integration@example.com", "Existing display email should still work")
        #expect(user.emailForCloudKit == "integration@example.com", "Existing CloudKit email should still work")

        // New analytics properties should work
        #expect(user.analyticsEnabled == true, "New analytics enabled field should work")
        #expect(user.adherenceGoalDays == 14, "New adherence goal days field should work")
        #expect(user.analyticsReportingEnabled == true, "New analytics reporting field should work")
        #expect(user.preferredReportingFrequency == "biweekly", "New reporting frequency field should work")
    }

    @Test("User analytics computed properties performance")
    func userAnalyticsComputedPropertiesPerformance() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let user = User(email: "performance@example.com")
        context.insert(user)

        // Create a medication profile for the user
        let medicationProfile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0)
        medicationProfile.user = user
        context.insert(medicationProfile)

        // Create a large number of doses (100)
        let calendar = Calendar.current
        let now = Date()
        for dayOffset in 0 ..< 100 {
            let doseDate = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let dose = Dose(
                amount: 1.0,
                timestamp: doseDate,
                user: user,
                medication: medicationProfile)
            context.insert(dose)
        }

        try context.save()

        // Test that computed properties complete in reasonable time
        let startTime = Date()

        _ = user.currentAdherenceRate
        _ = user.currentStreak
        _ = user.longestStreak
        _ = user.averageTimeBetweenDoses

        let elapsedTime = Date().timeIntervalSince(startTime)

        // Should complete in under 1 second even with 100 doses
        #expect(elapsedTime < 1.0, "Analytics computed properties should be performant with large datasets")
    }

    // MARK: - Test Data Factories

    static func createTestUserWithAnalytics(
        email: String = "analytics-test@example.com",
        name: String = "Analytics Test User",
        analyticsEnabled: Bool = true,
        adherenceGoalDays: Int = 7) -> User
    {
        User(
            email: email,
            name: name,
            analyticsEnabled: analyticsEnabled,
            adherenceGoalDays: adherenceGoalDays,
            analyticsReportingEnabled: true,
            preferredReportingFrequency: "weekly")
    }
}
