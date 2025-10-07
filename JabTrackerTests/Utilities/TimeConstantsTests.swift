//
//  TimeConstantsTests.swift
//  JabTrackerTests
//
//  Created by Claude Code on 2025-10-07.
//

import Foundation
import Testing

@testable import JabTracker

@Suite("TimeConstants Utility Tests")
struct TimeConstantsTests {

    // MARK: - Adherence Window Defaults Tests

    @Test("Default window minutes constant has correct value")
    func testDefaultWindowMinutes() {
        #expect(TimeConstants.defaultWindowMinutes == 120)
    }

    @Test("Default window seconds matches minutes conversion")
    func testDefaultWindowSeconds() {
        let expectedSeconds: TimeInterval = TimeInterval(TimeConstants.defaultWindowMinutes * 60)
        #expect(TimeConstants.defaultWindowSeconds == expectedSeconds)
        #expect(TimeConstants.defaultWindowSeconds == 7200)  // 2 hours in seconds
    }

    // MARK: - Reschedule Limits Tests

    @Test("Max reschedule days constant has correct value")
    func testMaxRescheduleDays() {
        #expect(TimeConstants.maxRescheduleDays == 7)
    }

    @Test("Max reschedule seconds matches days conversion")
    func testMaxRescheduleSeconds() {
        let expectedSeconds: TimeInterval = TimeInterval(TimeConstants.maxRescheduleDays * 24 * 60 * 60)
        #expect(TimeConstants.maxRescheduleSeconds == expectedSeconds)
        #expect(TimeConstants.maxRescheduleSeconds == 604800)  // 7 days in seconds
    }

    // MARK: - Time Unit Conversion Constants Tests

    @Test("Seconds per minute constant")
    func testSecondsPerMinute() {
        #expect(TimeConstants.secondsPerMinute == 60)
    }

    @Test("Seconds per hour constant")
    func testSecondsPerHour() {
        #expect(TimeConstants.secondsPerHour == 3600)
    }

    @Test("Seconds per day constant")
    func testSecondsPerDay() {
        #expect(TimeConstants.secondsPerDay == 86400)
    }

    @Test("Seconds per week constant")
    func testSecondsPerWeek() {
        #expect(TimeConstants.secondsPerWeek == 604800)
    }

    // MARK: - Helper Methods Tests

    @Test("days() helper converts single day correctly")
    func testDaysSingleDay() {
        let result = TimeConstants.days(1)
        #expect(result == 86400)
        #expect(result == TimeConstants.secondsPerDay)
    }

    @Test("days() helper converts multiple days correctly")
    func testDaysMultipleDays() {
        #expect(TimeConstants.days(7) == 604800)
        #expect(TimeConstants.days(7) == TimeConstants.secondsPerWeek)
        #expect(TimeConstants.days(30) == 2_592_000)
        #expect(TimeConstants.days(365) == 31_536_000)
    }

    @Test("days() helper handles zero days")
    func testDaysZero() {
        #expect(TimeConstants.days(0) == 0)
    }

    @Test("hours() helper converts single hour correctly")
    func testHoursSingleHour() {
        let result = TimeConstants.hours(1)
        #expect(result == 3600)
        #expect(result == TimeConstants.secondsPerHour)
    }

    @Test("hours() helper converts multiple hours correctly")
    func testHoursMultipleHours() {
        #expect(TimeConstants.hours(2) == 7200)
        #expect(TimeConstants.hours(24) == 86400)
        #expect(TimeConstants.hours(24) == TimeConstants.secondsPerDay)
        #expect(TimeConstants.hours(168) == 604800)  // 1 week
    }

    @Test("hours() helper handles zero hours")
    func testHoursZero() {
        #expect(TimeConstants.hours(0) == 0)
    }

    @Test("minutes() helper converts single minute correctly")
    func testMinutesSingleMinute() {
        let result = TimeConstants.minutes(1)
        #expect(result == 60)
        #expect(result == TimeConstants.secondsPerMinute)
    }

    @Test("minutes() helper converts multiple minutes correctly")
    func testMinutesMultipleMinutes() {
        #expect(TimeConstants.minutes(30) == 1800)
        #expect(TimeConstants.minutes(60) == 3600)
        #expect(TimeConstants.minutes(60) == TimeConstants.secondsPerHour)
        #expect(TimeConstants.minutes(120) == 7200)
        #expect(TimeConstants.minutes(120) == TimeConstants.defaultWindowSeconds)
    }

    @Test("minutes() helper handles zero minutes")
    func testMinutesZero() {
        #expect(TimeConstants.minutes(0) == 0)
    }

    // MARK: - Integration Tests

    @Test("Helper methods produce consistent results")
    func testHelperMethodsConsistency() {
        // 1 day = 24 hours
        #expect(TimeConstants.days(1) == TimeConstants.hours(24))

        // 1 hour = 60 minutes
        #expect(TimeConstants.hours(1) == TimeConstants.minutes(60))

        // 1 week = 7 days = 168 hours
        #expect(TimeConstants.days(7) == TimeConstants.hours(168))

        // 2 hour window = 120 minutes
        #expect(TimeConstants.hours(2) == TimeConstants.minutes(120))
    }

    @Test("Constants are internally consistent")
    func testConstantsConsistency() {
        // Verify relationships between constants
        #expect(TimeConstants.secondsPerHour == TimeConstants.secondsPerMinute * 60)
        #expect(TimeConstants.secondsPerDay == TimeConstants.secondsPerHour * 24)
        #expect(TimeConstants.secondsPerWeek == TimeConstants.secondsPerDay * 7)

        // Verify default window
        #expect(TimeConstants.defaultWindowSeconds == TimeConstants.hours(2))

        // Verify max reschedule
        #expect(TimeConstants.maxRescheduleSeconds == TimeConstants.days(7))
    }

    @Test("Helper methods handle large values")
    func testHelperMethodsLargeValues() {
        // Test with larger values to ensure no overflow issues
        let hundredDays = TimeConstants.days(100)
        #expect(hundredDays == 8_640_000)

        let thousandHours = TimeConstants.hours(1000)
        #expect(thousandHours == 3_600_000)

        let tenThousandMinutes = TimeConstants.minutes(10000)
        #expect(tenThousandMinutes == 600000)
    }
}
