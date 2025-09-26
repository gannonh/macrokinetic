//
//  AdherenceInsightsServiceTests.swift
//  JabTrackerTests
//
//  Tests for AdherenceInsightsService
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

struct AdherenceInsightsServiceTests {

    // MARK: - Test Setup Helpers

    func createTestContext() -> ModelContext {
        let schema = Schema([User.self, MedicationProfile.self, Dose.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    func createTestUser(context: ModelContext) -> User {
        let user = User(email: "test@adherenceinsights.com", name: "Test User", appleUserId: "test_insights_123")
        context.insert(user)
        return user
    }

    func createTestMedicationProfile(user: User, context: ModelContext, medication: Medication = .semaglutide)
        -> MedicationProfile
    {
        let profile = MedicationProfile(
            genericName: medication == .liraglutide ? "liraglutide" : "semaglutide",
            brandName: medication == .liraglutide ? "Victoza" : "Ozempic",
            currentDose: medication == .liraglutide ? 1.8 : 1.0,
            startDate: Date().addingTimeInterval(-8 * 7 * 24 * 3600)  // 8 weeks ago to match dose test data
        )
        profile.medication = medication
        profile.user = user
        context.insert(profile)

        // Save the context to ensure the profile is properly persisted
        try? context.save()

        return profile
    }

    func createTestDose(
        profile: MedicationProfile,
        user: User,
        context: ModelContext,
        timestamp: Date = Date(),
        amount: Double = 1.0,
        skipped: Bool = false
    ) -> Dose {
        let dose = Dose(
            amount: amount,
            timestamp: timestamp,
            skipped: skipped,
            user: user,
            medication: profile
        )
        context.insert(dose)

        // Ensure relationships are set correctly - this is critical for SwiftData
        dose.user = user
        dose.medication = profile

        // Save context to ensure relationships are persisted
        try? context.save()

        return dose
    }

    // MARK: - Service Initialization Tests

    @Test("AdherenceInsightsService initializes correctly")
    func testServiceInitialization() {
        let service = AdherenceInsightsService()
        // Service should be initialized and observable
        // Just verify it's not nil by calling a method
        let emptyContext = createTestContext()
        let emptyUser = createTestUser(context: emptyContext)
        let insights = service.generateInsights(for: emptyUser, context: emptyContext)
        #expect(insights.isEmpty)
    }

    // MARK: - Basic Insight Generation Tests

    @Test("generateInsights returns empty array for user with no medications")
    func testGenerateInsightsNoMedications() {
        let context = createTestContext()
        let user = createTestUser(context: context)
        let service = AdherenceInsightsService()

        let insights = service.generateInsights(for: user, context: context)

        #expect(insights.isEmpty)
    }

    @Test("generateInsights returns empty array for user with empty medication profiles")
    func testGenerateInsightsEmptyProfiles() {
        let context = createTestContext()
        let user = createTestUser(context: context)
        _ = createTestMedicationProfile(user: user, context: context)

        // Don't add any doses
        let service = AdherenceInsightsService()
        let insights = service.generateInsights(for: user, context: context)

        #expect(insights.isEmpty)
    }

    @Test("generateInsights returns empty array for insufficient data points")
    func testGenerateInsightsInsufficientData() {
        let context = createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(user: user, context: context)

        // Add only 2 doses (below minimum of 5)
        _ = createTestDose(
            profile: profile, user: user, context: context, timestamp: Date().addingTimeInterval(-14 * 24 * 3600))
        _ = createTestDose(
            profile: profile, user: user, context: context, timestamp: Date().addingTimeInterval(-7 * 24 * 3600))

        try? context.save()

        let service = AdherenceInsightsService()
        let insights = service.generateInsights(for: user, context: context)

        #expect(insights.isEmpty)
    }

    // MARK: - Excellent Adherence Tests

    @Test("generateInsights creates excellent adherence insight for perfect compliance")
    func testExcellentAdherenceInsight() {
        let context = createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(user: user, context: context)

        // Create perfect weekly adherence for 12 weeks with varied days to ensure 90%+ adherence
        // Use Tuesdays to avoid weekend detection issues
        let calendar = Calendar.current
        let baseDate = Date()

        for week in 0..<12 {
            let doseDate = calendar.date(byAdding: .weekOfYear, value: -week, to: baseDate)!
            // Set to Tuesday of each week
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: doseDate)
            components.weekday = 3  // Tuesday
            if let tuesday = calendar.date(from: components) {
                _ = createTestDose(profile: profile, user: user, context: context, timestamp: tuesday, skipped: false)
            }
        }

        try? context.save()

        let service = AdherenceInsightsService()
        let insights = service.generateInsights(for: user, context: context)

        #expect(!insights.isEmpty, "Should generate at least one insight")

        let excellentInsights = insights.filter { $0.type == .excellentAdherence }

        // Use safe unwrapping instead of force unwrap
        guard !excellentInsights.isEmpty else {
            print("🔍 No excellent adherence insights found. Available insights:")
            for insight in insights {
                print("🔍   - \(insight.title) (\(insight.type))")
            }
            #expect(Bool(false), "Expected at least one excellent adherence insight")
            return
        }

        let insight = excellentInsights.first!
        #expect(insight.priority == .low)
        #expect(insight.confidence == 1.0)
        #expect(insight.colorTheme == .green)
        #expect(insight.title == "Excellent Adherence!")
    }

    // MARK: - Pattern Detection Tests

    @Test("detectPatterns returns empty for insufficient data")
    func testDetectPatternsInsufficientData() {
        let service = AdherenceInsightsService()
        let dateRange = DateInterval(start: Date().addingTimeInterval(-30 * 24 * 3600), end: Date())

        // Create only 2 doses (below minimum of 5)
        let context = createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(user: user, context: context)

        let dose1 = createTestDose(
            profile: profile, user: user, context: context, timestamp: Date().addingTimeInterval(-14 * 24 * 3600))
        let dose2 = createTestDose(
            profile: profile, user: user, context: context, timestamp: Date().addingTimeInterval(-7 * 24 * 3600))

        let patterns = service.detectPatterns(in: [dose1, dose2], dateRange: dateRange)

        #expect(patterns.isEmpty)
    }

    @Test("detectPatterns identifies weekend gaps correctly")
    func testDetectWeekendGaps() {
        let service = AdherenceInsightsService()
        let dateRange = DateInterval(start: Date().addingTimeInterval(-35 * 24 * 3600), end: Date())

        let context = createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(user: user, context: context, medication: .liraglutide)

        var doses: [Dose] = []
        let calendar = Calendar.current

        // Create doses for 5 weeks, but skip all weekend doses
        for week in 0..<5 {
            let baseDate = calendar.date(byAdding: .weekOfYear, value: -week, to: Date())!

            // Add a weekday dose (Wednesday)
            let wednesday = calendar.date(
                byAdding: .day, value: 2, to: calendar.dateInterval(of: .weekOfYear, for: baseDate)!.start)!
            doses.append(createTestDose(profile: profile, user: user, context: context, timestamp: wednesday))

            // Skip weekend doses entirely (no Saturday/Sunday doses created)
        }

        let patterns = service.detectPatterns(in: doses, dateRange: dateRange)

        let weekendPatterns = patterns.filter { $0.type == .weekendGaps }
        #expect(!weekendPatterns.isEmpty)

        if let weekendPattern = weekendPatterns.first {
            #expect(weekendPattern.confidence >= 0.7)
            #expect(weekendPattern.name == "Weekend Dose Gaps")
        }
    }

    @Test("detectPatterns identifies perfect adherence correctly")
    func testDetectPerfectAdherence() {
        let service = AdherenceInsightsService()
        let dateRange = DateInterval(start: Date().addingTimeInterval(-56 * 24 * 3600), end: Date())  // 8 weeks

        let context = createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(user: user, context: context)

        var doses: [Dose] = []
        let calendar = Calendar.current

        // Create perfect weekly adherence for 8 weeks
        for week in 0..<8 {
            let doseDate = calendar.date(byAdding: .weekOfYear, value: -week, to: Date())!
            doses.append(
                createTestDose(profile: profile, user: user, context: context, timestamp: doseDate, skipped: false))
        }

        let patterns = service.detectPatterns(in: doses, dateRange: dateRange)

        let perfectPatterns = patterns.filter { $0.type == .perfectAdherence }
        #expect(!perfectPatterns.isEmpty)

        if let perfectPattern = perfectPatterns.first {
            #expect(perfectPattern.confidence >= 0.95)
            #expect(perfectPattern.riskLevel == .low)
            #expect(perfectPattern.frequency == .constant)
        }
    }

    @Test("detectPatterns identifies site rotation correctly")
    func testDetectSiteRotation() {
        let service = AdherenceInsightsService()
        let dateRange = DateInterval(start: Date().addingTimeInterval(-42 * 24 * 3600), end: Date())  // 6 weeks

        let context = createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(user: user, context: context)

        var doses: [Dose] = []
        let sites = ["Left thigh", "Right thigh", "Left abdomen", "Right abdomen"]

        // Create doses with good site rotation
        for week in 0..<6 {
            let doseDate = Calendar.current.date(byAdding: .weekOfYear, value: -week, to: Date())!
            let site = sites[week % sites.count]
            let dose = createTestDose(profile: profile, user: user, context: context, timestamp: doseDate)
            dose.site = site
            doses.append(dose)
        }

        let patterns = service.detectPatterns(in: doses, dateRange: dateRange)

        let sitePatterns = patterns.filter { $0.type == .siteRotationGood }
        #expect(!sitePatterns.isEmpty)

        if let sitePattern = sitePatterns.first {
            #expect(sitePattern.confidence >= 0.75)
            #expect(sitePattern.riskLevel == .low)
        }
    }

    // MARK: - Medical Insights Tests

    @Test("generates dose escalation insight for good adherence on stable dose")
    func testDoseEscalationInsight() {
        let context = createTestContext()
        let user = createTestUser(context: context)

        // Create profile that started 13 weeks ago to cover the 90-day analysis window
        let startDate = Date().addingTimeInterval(-91 * 24 * 3600)  // 13 weeks ago
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: startDate
        )
        profile.medication = .semaglutide
        profile.user = user
        context.insert(profile)

        // Create excellent adherence for 13 weeks to cover the 90-day analysis window
        // Using Tuesdays to avoid weekend issues
        let calendar = Calendar.current
        for week in 0..<13 {
            let doseDate = calendar.date(byAdding: .weekOfYear, value: -week, to: Date())!
            // Set to Tuesday of each week
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: doseDate)
            components.weekday = 3  // Tuesday
            if let tuesday = calendar.date(from: components) {
                _ = createTestDose(profile: profile, user: user, context: context, timestamp: tuesday, skipped: false)
            }
        }

        try? context.save()

        let service = AdherenceInsightsService()
        let insights = service.generateInsights(for: user, context: context)

        // Test should generate dose escalation insight for excellent adherence after 8 weeks
        let escalationInsights = insights.filter { $0.type == .doseEscalationReady }
        #expect(!escalationInsights.isEmpty, "Should generate dose escalation insight for 13 weeks at 100% adherence")

        if let insight = escalationInsights.first {
            #expect(insight.priority == .high)
            #expect(insight.isHighlighted == true)
            #expect(insight.colorTheme == .purple)
            #expect(insight.description.contains("1.0mg"))
        }
    }

    @Test("generates provider consultation insight for poor adherence")
    func testProviderConsultationInsight() {
        let context = createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(user: user, context: context)

        // Create poor adherence - 3 taken, 3 skipped out of 6 expected doses
        for week in 0..<6 {
            let doseDate = Calendar.current.date(byAdding: .weekOfYear, value: -week, to: Date())!
            let skipped = (week % 2 == 0)  // Skip every other dose
            _ = createTestDose(profile: profile, user: user, context: context, timestamp: doseDate, skipped: skipped)
        }

        try? context.save()

        let service = AdherenceInsightsService()
        let insights = service.generateInsights(for: user, context: context)

        let consultationInsights = insights.filter { $0.type == .providerConsultation }
        #expect(!consultationInsights.isEmpty)

        if let insight = consultationInsights.first {
            #expect(insight.priority == .high)
            #expect(insight.colorTheme == .red)
            #expect(insight.clinicalSignificance == .significant)
            #expect(insight.treatmentImpact == .critical)
        }
    }

    // MARK: - Weekend Reminder Insight Tests

    @Test("generates weekend reminder insight from weekend gap patterns")
    func testWeekendReminderInsightGeneration() {
        let context = createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(user: user, context: context, medication: .liraglutide)

        var doses: [Dose] = []
        let calendar = Calendar.current

        // Create a pattern of missing weekend doses but having weekday doses
        for week in 0..<6 {
            let baseDate = calendar.date(byAdding: .weekOfYear, value: -week, to: Date())!
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: baseDate)!.start

            // Add a Tuesday dose (good adherence on weekdays)
            let tuesday = calendar.date(byAdding: .day, value: 1, to: weekStart)!
            doses.append(createTestDose(profile: profile, user: user, context: context, timestamp: tuesday))
        }

        try? context.save()

        let service = AdherenceInsightsService()
        let insights = service.generateInsights(for: user, context: context)

        let weekendInsights = insights.filter { $0.type == .weekendReminder }
        #expect(!weekendInsights.isEmpty)

        if let insight = weekendInsights.first {
            #expect(insight.priority == .medium)
            #expect(insight.colorTheme == .orange)
            #expect(insight.actionableRecommendation.contains("weekend"))
        }
    }

    // MARK: - Insight Sorting and Filtering Tests

    @Test("insights are sorted by importance score")
    func testInsightsSortedByImportance() {
        let context = createTestContext()
        let user = createTestUser(context: context)
        // Use daily medication (liraglutide) to enable weekend gap detection
        let profile = createTestMedicationProfile(user: user, context: context, medication: .liraglutide)

        // Create mixed adherence pattern over 90 days to generate multiple insights
        var doses: [Dose] = []
        let calendar = Calendar.current
        let startDate = Date().addingTimeInterval(-90 * 24 * 3600)  // 90 days ago

        // Create poor adherence pattern to trigger provider consultation insight
        // and weekend gaps for daily medication to trigger weekend reminder
        for day in 0..<90 {
            let doseDate = calendar.date(byAdding: .day, value: day, to: startDate)!
            let weekday = calendar.component(.weekday, from: doseDate)

            // Skip many doses to create poor adherence (~50%)
            // Skip all weekends (Saturday=7, Sunday=1) to create weekend pattern
            // Skip some random weekdays too
            let shouldSkip =
                (weekday == 1 || weekday == 7)  // weekends
                || (day % 3 == 0)  // every 3rd day

            if !shouldSkip {
                doses.append(
                    createTestDose(profile: profile, user: user, context: context, timestamp: doseDate, skipped: false))
            }
        }

        try? context.save()

        let service = AdherenceInsightsService()
        let insights = service.generateInsights(for: user, context: context)

        #expect(insights.count > 1)

        // Verify sorting: each insight should have importance >= the next one
        for index in 0..<(insights.count - 1) {
            #expect(insights[index].importanceScore >= insights[index + 1].importanceScore)
        }
    }

    @Test("insights are limited to maximum count")
    func testInsightsLimitedToMaximum() {
        let context = createTestContext()
        let user = createTestUser(context: context)

        // Create multiple medication profiles to potentially generate many insights
        for profileIndex in 0..<3 {
            let medications = ["semaglutide", "tirzepatide", "liraglutide"]
            let medicationTypes: [Medication] = [.semaglutide, .tirzepatide, .liraglutide]
            let profile = MedicationProfile(
                genericName: medications[profileIndex],
                brandName: "Test Brand",
                currentDose: 1.0,
                startDate: Date().addingTimeInterval(-60 * 24 * 3600)
            )
            profile.medication = medicationTypes[profileIndex]
            profile.user = user
            context.insert(profile)

            // Add various doses to trigger multiple insights
            for week in 0..<10 {
                if let doseDate = Calendar.current.date(byAdding: .weekOfYear, value: -week, to: Date()) {
                    _ = createTestDose(profile: profile, user: user, context: context, timestamp: doseDate)
                }
            }
        }

        try? context.save()

        let service = AdherenceInsightsService()
        let insights = service.generateInsights(for: user, context: context)

        // Should be limited to 8 insights maximum
        #expect(insights.count <= 8)
    }

    @Test("only displays insights that meet shouldDisplay criteria")
    func testOnlyDisplayableInsights() {
        let context = createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(user: user, context: context)

        // Create enough data to generate insights
        for week in 0..<6 {
            let doseDate = Calendar.current.date(byAdding: .weekOfYear, value: -week, to: Date())!
            _ = createTestDose(profile: profile, user: user, context: context, timestamp: doseDate)
        }

        try? context.save()

        let service = AdherenceInsightsService()
        let insights = service.generateInsights(for: user, context: context)

        // All returned insights should meet display criteria
        for insight in insights {
            #expect(insight.shouldDisplay == true)
            #expect(insight.confidence >= 0.6)
            #expect(insight.isActionable == true)
        }
    }
}
