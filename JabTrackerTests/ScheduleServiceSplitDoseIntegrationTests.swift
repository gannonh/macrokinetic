//
//  ScheduleServiceSplitDoseIntegrationTests.swift
//  JabTrackerTests
//
//  Created by Claude Code on 2025-10-20.
//  Stream C: Integration tests for split-dose medical accuracy fix (Issue #180)
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - Split-Dose Integration Tests

/// Integration tests validating that ScheduleService split-dose logic (Stream A)
/// works correctly with UI filtering logic (Stream B) for medical accuracy.
@Suite("Split-Dose Integration Tests")
struct ScheduleServiceSplitDoseIntegrationTests {

    var container: ModelContainer
    var context: ModelContext

    init() throws {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            Dose.self,
            DoseSchedule.self,
            ScheduledDose.self,
        ])

        let config = InMemoryTestStore.configuration(schema: schema)

        self.container = try ModelContainer(for: schema, configurations: [config])
        self.context = ModelContext(container)
    }

    // MARK: - Test Helpers

    func createTestMedicationProfile(
        medication: Medication,
        currentDose: Double = 0.25
    ) throws -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: medication.displayName,
            brandName: medication.displayName,
            currentDose: currentDose
        )
        profile.medication = medication
        context.insert(profile)
        try context.save()
        return profile
    }

    func availablePatternsForMedication(_ medication: Medication) -> [SchedulePatternType] {
        // Mirror UI logic from Stream B (SchedulePatternPicker)
        switch medication.frequency {
        case .daily:
            return [.weekly]
        case .weekly:
            return [.weekly, .splitDose]
        }
    }

    // MARK: - Integration Test 1: Service Layer Creates Correct Schedule

    @Test("Split-dose configuration creates correct twice-weekly schedule")
    @MainActor
    func testSplitDoseIntegrationCreatesCorrectSchedule() throws {
        // GIVEN: Weekly medication (Semaglutide)
        let medication = Medication.semaglutide
        #expect(medication.frequency == .weekly, "Semaglutide should be weekly medication")

        // WHEN: Create split-dose configuration using Stream A's factory method
        let config = try ScheduleConfiguration.splitDoseConfiguration(
            for: medication,
            totalWeeklyDose: 0.25
        )

        // THEN: Verify configuration has correct medical parameters
        #expect(config.splitDoseCount == 2, "Split-dose should create 2 doses per week")
        #expect(config.splitIntervalMinutes == TimeConstants.splitDoseInterval, "Split interval should be 3.5 days")
        #expect(config.interval == 7, "Weekly cycle should be 7 days")

        // WHEN: Generate schedule for 2 weeks using ScheduleService
        let service = ScheduleService(context: context)
        let profile = try createTestMedicationProfile(medication: medication)

        // Use fixed reference date to avoid timing race conditions
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 6
        dateComponents.day = 1
        dateComponents.hour = 8
        dateComponents.minute = 0
        let startDate = calendar.date(from: dateComponents)!

        let schedule = try service.createSchedule(
            for: profile,
            pattern: .splitDose,
            startDate: startDate,
            baseSchedule: config
        )

        // Use 13 days to avoid boundary condition at exactly 14 days
        let endDate = calendar.date(byAdding: .day, value: 13, to: startDate)!
        let doses = service.generateScheduledDoses(
            for: schedule,
            from: startDate,
            to: endDate
        )

        // THEN: Verify 4 doses over 13 days (day 0, 3.5, 7, 10.5)
        #expect(doses.count == 4, "Should generate 4 doses over 2 weeks (2 per week)")

        // Verify 3.5-day spacing between consecutive doses
        for index in 0..<(doses.count - 1) {
            let interval = doses[index + 1].scheduledTime.timeIntervalSince(doses[index].scheduledTime)
            let days = interval / (24 * 60 * 60)
            #expect(abs(days - 3.5) < 0.1, "Consecutive doses should be 3.5 days apart, got \(days)")
        }

        // Verify each dose is half the weekly dose
        let expectedDoseAmount = 0.25 / 2.0  // Weekly dose split in two
        for dose in doses {
            #expect(
                abs(dose.doseAmount - expectedDoseAmount) < 0.001,
                "Each split dose should be half weekly dose (0.125mg)")
        }
    }

    // MARK: - Integration Test 2: UI Filtering Matches Service Layer Support

    @Test("Split-dose pattern filtered correctly by medication frequency")
    @MainActor
    func testSplitDoseFilteringIntegration() throws {
        // GIVEN: Weekly medication (Semaglutide)
        let semaglutide = Medication.semaglutide
        #expect(semaglutide.frequency == .weekly, "Semaglutide should be weekly")

        // WHEN: Get available patterns (simulating UI logic from Stream B)
        let weeklyPatterns = availablePatternsForMedication(semaglutide)

        // THEN: Should include split-dose (UI allows it)
        #expect(
            weeklyPatterns.contains(.splitDose),
            "Weekly medications should show split-dose option in UI")

        // AND: Service layer should support creating split-dose config
        let config = try? ScheduleConfiguration.splitDoseConfiguration(
            for: semaglutide,
            totalWeeklyDose: 0.25
        )
        #expect(config != nil, "Service layer should support split-dose for weekly medication")
        #expect(config?.splitIntervalMinutes == TimeConstants.splitDoseInterval, "Should use correct 3.5-day interval")

        // GIVEN: Daily medication (Liraglutide)
        let liraglutide = Medication.liraglutide
        #expect(liraglutide.frequency == .daily, "Liraglutide should be daily")

        // WHEN: Get available patterns
        let dailyPatterns = availablePatternsForMedication(liraglutide)

        // THEN: Should NOT include split-dose (UI hides it)
        #expect(
            !dailyPatterns.contains(.splitDose),
            "Daily medications should NOT show split-dose option in UI")

        // AND: Service layer should reject split-dose config
        var threwError = false
        do {
            _ = try ScheduleConfiguration.splitDoseConfiguration(
                for: liraglutide,
                totalWeeklyDose: 0.25
            )
        } catch {
            threwError = true
            #expect(
                error is ScheduleServiceError,
                "Should throw ScheduleServiceError for daily medication")
        }
        #expect(threwError, "Service layer should reject split-dose for daily medication")
    }

    // MARK: - Integration Test 3: Medical Safety - No Overdosing Risk

    @Test("Split-dose prevents dangerous twice-daily pattern")
    @MainActor
    func testSplitDosePreventsOverdosingRisk() throws {
        // This test validates the critical medical safety fix:
        // OLD BUG: 720 minutes = 12 hours = TWICE DAILY dosing (DANGEROUS!)
        // FIX: TimeConstants.splitDoseInterval = 84 hours = 3.5 days = TWICE WEEKLY (SAFE)

        // GIVEN: Weekly medication with split-dose configuration
        let medication = Medication.semaglutide
        let config = try ScheduleConfiguration.splitDoseConfiguration(
            for: medication,
            totalWeeklyDose: 1.0  // 1mg weekly
        )

        // WHEN: Generate schedule
        let service = ScheduleService(context: context)
        let profile = try createTestMedicationProfile(medication: medication, currentDose: 1.0)

        // Use fixed reference date to avoid timing race conditions
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 6
        dateComponents.day = 1
        dateComponents.hour = 8
        dateComponents.minute = 0
        let startDate = calendar.date(from: dateComponents)!

        let schedule = try service.createSchedule(
            for: profile,
            pattern: .splitDose,
            startDate: startDate,
            baseSchedule: config
        )

        // Use 6 days to avoid boundary condition at exactly 7 days
        let sixDaysLater = calendar.date(byAdding: .day, value: 6, to: startDate)!
        let doses = service.generateScheduledDoses(
            for: schedule,
            from: startDate,
            to: sixDaysLater
        )

        // THEN: Should only have 2 doses in one week (NOT 14!)
        #expect(
            doses.count == 2,
            "Split-dose should create 2 doses per week, not 14 (twice daily would be dangerous)")

        // THEN: Doses should be ~3.5 days apart (NOT 12 hours!)
        if doses.count == 2 {
            let interval = doses[1].scheduledTime.timeIntervalSince(doses[0].scheduledTime)
            let hours = interval / 3600

            // Should be ~84 hours (3.5 days), NOT 12 hours
            #expect(hours > 72, "Interval should be >72 hours (3+ days), not 12 hours")
            #expect(hours < 96, "Interval should be <96 hours (4 days)")

            // Specifically verify it's NOT the dangerous 12-hour pattern
            let isSafeTwiceWeekly = abs(hours - 84) < 12  // Within 12 hours of 3.5 days
            let isDangerousTwiceDaily = abs(hours - 12) < 2  // Within 2 hours of 12 hours

            #expect(isSafeTwiceWeekly, "Should use safe twice-weekly pattern (~84 hours)")
            #expect(!isDangerousTwiceDaily, "Must NOT use dangerous twice-daily pattern (12 hours)")
        }

        // THEN: Total weekly dose should equal original (0.5mg + 0.5mg = 1.0mg)
        let totalWeeklyDose = doses.reduce(0.0) { $0 + $1.doseAmount }
        #expect(
            abs(totalWeeklyDose - 1.0) < 0.001,
            "Total weekly dose should equal configured amount (1.0mg)")
    }
}
