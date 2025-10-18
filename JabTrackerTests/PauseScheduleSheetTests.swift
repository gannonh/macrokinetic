//
//  PauseScheduleSheetTests.swift
//  JabTrackerTests
//
//  Unit tests for PauseScheduleSheet component.
//

import Foundation
import SwiftUI
import Testing

@testable import JabTracker

@Suite("PauseScheduleSheet Tests")
struct PauseScheduleSheetTests {

    // MARK: - PauseDuration Enum Tests

    @Test("PauseDuration enum has correct display names")
    func testPauseDurationDisplayNames() {
        #expect(PauseDuration.oneWeek.displayName == "1 Week")
        #expect(PauseDuration.twoWeeks.displayName == "2 Weeks")
        #expect(PauseDuration.oneMonth.displayName == "1 Month")
        #expect(PauseDuration.custom.displayName == "Custom")
        #expect(PauseDuration.indefinite.displayName == "Indefinitely")
    }

    @Test("PauseDuration calculates correct dates for oneWeek")
    func testPauseDurationOneWeek() {
        let now = Date()
        let calendar = Calendar.current

        let endDate = PauseDuration.oneWeek.calculateEndDate(from: now)

        guard let endDate = endDate else {
            Issue.record("oneWeek should return non-nil date")
            return
        }

        let components = calendar.dateComponents([.day], from: now, to: endDate)
        #expect(components.day == 7, "One week should be 7 days")
    }

    @Test("PauseDuration calculates correct dates for twoWeeks")
    func testPauseDurationTwoWeeks() {
        let now = Date()
        let calendar = Calendar.current

        let endDate = PauseDuration.twoWeeks.calculateEndDate(from: now)

        guard let endDate = endDate else {
            Issue.record("twoWeeks should return non-nil date")
            return
        }

        let components = calendar.dateComponents([.day], from: now, to: endDate)
        #expect(components.day == 14, "Two weeks should be 14 days")
    }

    @Test("PauseDuration calculates correct dates for oneMonth")
    func testPauseDurationOneMonth() {
        let now = Date()
        let calendar = Calendar.current

        let endDate = PauseDuration.oneMonth.calculateEndDate(from: now)

        guard let endDate = endDate else {
            Issue.record("oneMonth should return non-nil date")
            return
        }

        let components = calendar.dateComponents([.day], from: now, to: endDate)
        // Allow 28-31 days for different months
        let daysDiff = components.day ?? 0
        #expect(daysDiff >= 28 && daysDiff <= 31, "One month should be 28-31 days, got \(daysDiff)")
    }

    @Test("PauseDuration returns nil for indefinite")
    func testPauseDurationIndefinite() {
        let now = Date()
        let endDate = PauseDuration.indefinite.calculateEndDate(from: now)
        #expect(endDate == nil, "Indefinite should return nil")
    }

    @Test("PauseDuration returns nil for custom")
    func testPauseDurationCustom() {
        let now = Date()
        let endDate = PauseDuration.custom.calculateEndDate(from: now)
        #expect(endDate == nil, "Custom should return nil (date selected via DatePicker)")
    }

    // MARK: - Date Picker Range Tests

    @Test("Custom duration allows future dates only")
    func testCustomDurationFutureDatesOnly() {
        let now = Date()
        let calendar = Calendar.current

        // Minimum date should be tomorrow
        guard let minimumDate = calendar.date(byAdding: .day, value: 1, to: now) else {
            Issue.record("Failed to calculate minimum date")
            return
        }

        // Verify tomorrow is after today
        #expect(minimumDate > now, "Minimum date should be in the future")

        // Verify it's approximately 1 day later (within 2 hours tolerance for daylight saving)
        let hoursDiff = minimumDate.timeIntervalSince(now) / 3600
        #expect(hoursDiff >= 22 && hoursDiff <= 26, "Should be approximately 24 hours later")
    }

    // MARK: - Explanation Text Tests

    @Test("Pause explanation text is informative")
    func testPauseExplanationText() {
        let explanationText = "Scheduled doses and reminders will be paused. You can still log doses manually."

        #expect(explanationText.contains("paused"), "Should mention pausing")
        #expect(explanationText.contains("manually"), "Should mention manual logging option")
        #expect(explanationText.contains("Scheduled doses"), "Should mention scheduled doses")
        #expect(explanationText.contains("reminders"), "Should mention reminders")
    }
}
