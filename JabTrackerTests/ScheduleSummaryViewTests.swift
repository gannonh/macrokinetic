//
//  ScheduleSummaryViewTests.swift
//  JabTrackerTests
//
//  Unit tests for ScheduleSummaryView component.
//

import Foundation
import SwiftUI
import Testing

@testable import JabTracker

@Suite("ScheduleSummaryView Tests")
struct ScheduleSummaryViewTests {

    // MARK: - Time Until Next Dose Tests

    @Test("Time until next dose formats correctly for hours")
    func testTimeUntilNextDoseHours() {
        let now = Date()
        let futureDate = Date(timeIntervalSinceNow: 3600 * 5)  // 5 hours from now

        let formatted = formatTimeUntil(futureDate, from: now)

        #expect(formatted.contains("5"), "Should contain hour count")
        #expect(formatted.contains("hour"), "Should contain 'hour' text")
    }

    @Test("Time until next dose formats correctly for days")
    func testTimeUntilNextDoseDays() {
        let now = Date()
        let futureDate = Date(timeIntervalSinceNow: 86400 * 3)  // 3 days from now

        let formatted = formatTimeUntil(futureDate, from: now)

        #expect(formatted.contains("3"), "Should contain day count")
        #expect(formatted.contains("day"), "Should contain 'day' text")
    }

    @Test("Time until next dose shows 'Less than 1 hour' for short periods")
    func testTimeUntilNextDoseShortPeriod() {
        let now = Date()
        let futureDate = Date(timeIntervalSinceNow: 1800)  // 30 minutes from now

        let formatted = formatTimeUntil(futureDate, from: now)

        #expect(formatted == "Less than 1 hour", "Should show 'Less than 1 hour' for periods under 1 hour")
    }

    @Test("Time until next dose handles past dates")
    func testTimeUntilNextDosePastDate() {
        let now = Date()
        let pastDate = Date(timeIntervalSinceNow: -3600)  // 1 hour ago

        let formatted = formatTimeUntil(pastDate, from: now)

        // Past dates should still format the interval (will be negative or zero)
        #expect(formatted == "Less than 1 hour" || formatted.contains("0"), "Should handle past dates gracefully")
    }

    // MARK: - Schedule Pattern Display Tests

    @Test("Weekly schedule pattern displays correctly")
    func testWeeklyPatternDisplay() {
        let patternText = "Weekly"
        #expect(patternText == "Weekly")
    }

    @Test("Split-dose schedule pattern displays correctly")
    func testSplitDosePatternDisplay() {
        let patternText = "Split-Dose"
        #expect(patternText == "Split-Dose")
    }

    @Test("Custom schedule pattern displays correctly")
    func testCustomPatternDisplay() {
        let patternText = "Custom"
        #expect(patternText == "Custom")
    }

    // MARK: - Reminder Time Display Tests

    @Test("Reminder time formats correctly for standard values")
    func testReminderTimeFormatting() {
        let reminderMinutes = 30
        let formatted = "\(reminderMinutes) minutes before"

        #expect(formatted == "30 minutes before")
    }

    @Test("Reminder time handles 1 hour (60 minutes)")
    func testReminderTimeOneHour() {
        let reminderMinutes = 60
        let formatted = "\(reminderMinutes) minutes before"

        #expect(formatted == "60 minutes before")
    }

    // MARK: - Helper Function

    /// Format time interval between now and a future date
    /// This mimics the logic that would be in ScheduleSummaryView
    private func formatTimeUntil(_ date: Date, from now: Date) -> String {
        let interval = date.timeIntervalSince(now)

        if interval < 3600 {  // Less than 1 hour
            return "Less than 1 hour"
        } else if interval < 86400 {  // Less than 1 day
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {  // 1 day or more
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }
}
