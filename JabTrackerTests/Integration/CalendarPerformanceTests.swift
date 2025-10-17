//
//  CalendarPerformanceTests.swift
//  JabTracker
//
//  Stream C: Performance validation tests for calendar with scheduled doses (Issue #178)
//  Tests NFR1: Calendar rendering performance <500ms with 90 days of scheduled doses
//  Tests NFR3: Lazy loading only loads current month

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Performance validation tests for calendar integration with scheduled doses
@MainActor
struct CalendarPerformanceTests {

    // MARK: - Test Helpers

    /// Create test container with test schema
    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            Dose.self,
            DoseSchedule.self,
            ScheduledDose.self,
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Create test user with medication profile
    private func createTestUser(context: ModelContext) throws -> (User, MedicationProfile) {
        let user = User(email: "test@example.com", name: "Test User", weight: 70.0)
        context.insert(user)

        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: Date())

        context.insert(profile)

        return (user, profile)
    }

    /// Create test schedule with scheduled doses
    private func createTestSchedule(
        context: ModelContext,
        profile: MedicationProfile,
        daysOfScheduledDoses: Int
    ) throws -> DoseSchedule {
        let startDate = Calendar.current.date(byAdding: .day, value: -daysOfScheduledDoses, to: Date()) ?? Date()

        // Create a valid weekly schedule configuration
        let scheduleConfig = """
            {
                "dayOfWeek": 1,
                "timeOfDay": {"hour": 9, "minute": 0},
                "interval": 7,
                "doseAmount": 1.0,
                "windowMinutesBefore": 120,
                "windowMinutesAfter": 120
            }
            """

        // Create schedule with weekly pattern
        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly,
            baseSchedule: scheduleConfig.data(using: .utf8) ?? Data(),
            isActive: true)
        schedule.createdAt = startDate

        context.insert(schedule)
        try context.save()  // Save schedule first

        // Generate scheduled doses using ScheduleService
        let scheduleService = ScheduleService(context: context)
        let scheduledDoses = scheduleService.generateScheduledDoses(
            for: schedule,
            from: startDate,
            to: Date()
        )

        // Initialize the relationship array explicitly
        schedule.scheduledDoses = []

        // Insert scheduled doses and link them to the schedule
        for dose in scheduledDoses {
            context.insert(dose)
            dose.schedule = schedule  // Set child's parent
            schedule.scheduledDoses?.append(dose)  // Manually add to parent array
        }

        try context.save()  // Save scheduled doses

        return schedule
    }

    // MARK: - NFR1: Calendar Rendering Performance Tests

    @Test("Calendar rendering with 90 days of scheduled doses completes within 500ms")
    func testCalendarRenderingPerformance() async throws {
        // GIVEN: Calendar with 90 days of scheduled doses (~13 weekly doses)
        let container = try createTestContainer()
        let context = container.mainContext

        let (_, profile) = try createTestUser(context: context)
        _ = try createTestSchedule(context: context, profile: profile, daysOfScheduledDoses: 90)

        // WHEN: Calculating statistics for current month with schedule integration
        let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!

        let scheduleService = ScheduleService(context: context)
        let activeSchedules = try context.fetch(
            FetchDescriptor<DoseSchedule>(
                predicate: #Predicate { $0.isActive }
            )
        )

        let startTime = Date()

        // Calculate statistics with schedule integration
        _ = AdherenceStatisticsCalculator.calculate(
            doses: [],
            periodStart: monthStart,
            periodEnd: monthEnd,
            medicationFrequency: .weekly,
            scheduleService: scheduleService,
            schedule: activeSchedules.first
        )

        let renderTime = Date().timeIntervalSince(startTime) * 1000  // Convert to ms

        // THEN: Rendering completes within 500ms (NFR1)
        #expect(
            renderTime < 500,
            """
            Calendar statistics calculation with 90 days of scheduled doses should \
            complete in <500ms (actual: \(String(format: "%.1f", renderTime))ms)
            """
        )

        print("📊 Calendar statistics calculation time: \(String(format: "%.1f", renderTime))ms")
    }

    @Test("Calendar rendering with minimal data completes within 100ms")
    func testCalendarRenderingPerformanceMinimal() async throws {
        // GIVEN: Calendar with 7 days of scheduled doses (~1 weekly dose)
        let container = try createTestContainer()
        let context = container.mainContext

        let (_, profile) = try createTestUser(context: context)
        _ = try createTestSchedule(context: context, profile: profile, daysOfScheduledDoses: 7)

        // WHEN: Calculating statistics for current month
        let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!

        let scheduleService = ScheduleService(context: context)
        let activeSchedules = try context.fetch(
            FetchDescriptor<DoseSchedule>(
                predicate: #Predicate { $0.isActive }
            )
        )

        let startTime = Date()

        _ = AdherenceStatisticsCalculator.calculate(
            doses: [],
            periodStart: monthStart,
            periodEnd: monthEnd,
            medicationFrequency: .weekly,
            scheduleService: scheduleService,
            schedule: activeSchedules.first
        )

        let renderTime = Date().timeIntervalSince(startTime) * 1000  // Convert to ms

        // THEN: Rendering completes within 100ms for minimal data
        #expect(
            renderTime < 100,
            "Calendar statistics calculation with minimal data should complete in <100ms (actual: \(String(format: "%.1f", renderTime))ms)"
        )

        print("📊 Minimal calendar statistics calculation time: \(String(format: "%.1f", renderTime))ms")
    }

    // MARK: - NFR3: Lazy Loading Tests

    @Test("Scheduled dose calculation only loads current month data")
    func testLazyLoadingOnlyLoadsCurrentMonth() async throws {
        // GIVEN: Schedule with 90 days of scheduled doses
        let container = try createTestContainer()
        let context = container.mainContext

        let (_, profile) = try createTestUser(context: context)
        let schedule = try createTestSchedule(
            context: context,
            profile: profile,
            daysOfScheduledDoses: 90
        )

        // WHEN: Calculating statistics for only current month
        let currentMonth = Date()
        let monthStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: currentMonth))!
        let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!

        let scheduleService = ScheduleService(context: context)
        let adherenceMetrics = scheduleService.calculateAdherence(
            for: schedule,
            from: monthStart,
            to: monthEnd
        )

        // THEN: Only current month's doses are included (not all 90 days)
        let expectedDosesForMonth = 4  // Approximately 4 weekly doses in a 30-day month
        let tolerance = 2  // Allow ±2 doses for month boundary variations

        #expect(
            abs(adherenceMetrics.totalScheduled - expectedDosesForMonth) <= tolerance,
            "Should only load ~\(expectedDosesForMonth) doses for current month (loaded: \(adherenceMetrics.totalScheduled))"
        )

        print(
            "📊 Loaded \(adherenceMetrics.totalScheduled) doses for current month (expected ~\(expectedDosesForMonth))")
    }

    @Test("Statistics calculation filters doses to specified period")
    func testStatisticsCalculationFiltersDosesToPeriod() async throws {
        // GIVEN: Multiple months of scheduled doses
        let container = try createTestContainer()
        let context = container.mainContext

        let (_, profile) = try createTestUser(context: context)
        let schedule = try createTestSchedule(
            context: context,
            profile: profile,
            daysOfScheduledDoses: 90
        )

        // WHEN: Calculating statistics for specific month (2 months ago)
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        let monthStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: twoMonthsAgo))!
        let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!

        let scheduleService = ScheduleService(context: context)
        let adherenceMetrics = scheduleService.calculateAdherence(
            for: schedule,
            from: monthStart,
            to: monthEnd
        )

        // THEN: Only that month's doses are included
        #expect(
            adherenceMetrics.totalScheduled > 0,
            "Should load doses for the specified historical month"
        )

        #expect(
            adherenceMetrics.totalScheduled <= 5,
            "Should only load ~4-5 weekly doses for one month period"
        )

        print("📊 Loaded \(adherenceMetrics.totalScheduled) doses for 2 months ago")
    }

    // MARK: - Integration Tests

    @Test("Statistics integration populates schedule adherence fields")
    func testStatisticsIntegrationPopulatesScheduleFields() async throws {
        // GIVEN: Schedule with doses taken and missed
        let container = try createTestContainer()
        let context = container.mainContext

        let (user, profile) = try createTestUser(context: context)
        let schedule = try createTestSchedule(
            context: context,
            profile: profile,
            daysOfScheduledDoses: 30
        )

        // Create some actual doses (logged doses)
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let dose = Dose(
            amount: 1.0,
            timestamp: weekAgo,
            site: "Thigh",
            notes: nil,
            skipped: false
        )
        dose.user = user
        dose.medication = profile
        context.insert(dose)
        try context.save()

        // WHEN: Calculating statistics with schedule integration
        let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!

        let scheduleService = ScheduleService(context: context)
        let statistics = AdherenceStatisticsCalculator.calculate(
            doses: [dose],
            periodStart: monthStart,
            periodEnd: monthEnd,
            medicationFrequency: .weekly,
            scheduleService: scheduleService,
            schedule: schedule
        )

        // THEN: Schedule adherence fields are populated
        #expect(
            statistics.totalScheduledDoses > 0,
            "Should have scheduled doses from schedule"
        )

        #expect(
            statistics.takenScheduledDoses >= 0,
            "Should calculate taken scheduled doses"
        )

        #expect(
            statistics.missedScheduledDoses >= 0,
            "Should calculate missed scheduled doses"
        )

        #expect(
            statistics.skippedScheduledDoses >= 0,
            "Should calculate skipped scheduled doses"
        )

        #expect(
            statistics.scheduleAdherenceRate >= 0.0 && statistics.scheduleAdherenceRate <= 1.0,
            "Schedule adherence rate should be between 0.0 and 1.0"
        )

        print("📊 Schedule adherence: \(statistics.scheduleAdherenceRatePercentage)")
        print("   Total scheduled: \(statistics.totalScheduledDoses)")
        print("   Taken: \(statistics.takenScheduledDoses)")
        print("   Missed: \(statistics.missedScheduledDoses)")
        print("   Skipped: \(statistics.skippedScheduledDoses)")
    }

    @Test("Statistics calculation works without schedule (backward compatibility)")
    func testStatisticsCalculationWorksWithoutSchedule() async throws {
        // GIVEN: Doses without schedule
        let container = try createTestContainer()
        let context = container.mainContext

        let (user, profile) = try createTestUser(context: context)

        // Create doses without schedule
        let dose = Dose(
            amount: 1.0,
            timestamp: Date(),
            site: "Thigh",
            notes: nil,
            skipped: false
        )
        dose.user = user
        dose.medication = profile
        context.insert(dose)
        try context.save()

        // WHEN: Calculating statistics without schedule integration
        let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        let monthEnd = Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!

        let statistics = AdherenceStatisticsCalculator.calculate(
            doses: [dose],
            periodStart: monthStart,
            periodEnd: monthEnd,
            medicationFrequency: .weekly,
            scheduleService: nil,  // No schedule service
            schedule: nil  // No schedule
        )

        // THEN: Statistics are calculated correctly without schedule data
        #expect(statistics.totalDoses == 1)
        #expect(statistics.totalScheduledDoses == 0, "Should have no scheduled doses")
        #expect(statistics.takenScheduledDoses == 0)
        #expect(statistics.missedScheduledDoses == 0)
        #expect(statistics.skippedScheduledDoses == 0)
        #expect(statistics.scheduleAdherenceRate == 0.0)

        print("✅ Statistics calculation works without schedule integration (backward compatible)")
    }
}
