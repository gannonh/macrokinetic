//
//  ScheduleHistoryRowTests.swift
//  JabTrackerTests
//
//  Unit tests for ScheduleHistoryRow component.
//

import Foundation
import SwiftUI
import Testing

@testable import JabTracker

@Suite("ScheduleHistoryRow Tests")
struct ScheduleHistoryRowTests {

    // MARK: - ScheduleChangeType Tests

    @Test("ScheduleChangeType displays correct display names")
    func testChangeTypeDisplayNames() {
        #expect(ScheduleChangeType.created.displayName == "Created")
        #expect(ScheduleChangeType.modified.displayName == "Modified")
        #expect(ScheduleChangeType.paused.displayName == "Paused")
        #expect(ScheduleChangeType.resumed.displayName == "Resumed")
        #expect(ScheduleChangeType.deactivated.displayName == "Deactivated")
    }

    @Test("ScheduleChangeType provides correct icon names")
    func testChangeTypeIconNames() {
        #expect(ScheduleChangeType.created.iconName == "plus.circle.fill")
        #expect(ScheduleChangeType.modified.iconName == "pencil.circle.fill")
        #expect(ScheduleChangeType.paused.iconName == "pause.circle.fill")
        #expect(ScheduleChangeType.resumed.iconName == "play.circle.fill")
        #expect(ScheduleChangeType.deactivated.iconName == "xmark.circle.fill")
    }

    @Test("ScheduleChangeType provides correct colors")
    func testChangeTypeColors() {
        #expect(ScheduleChangeType.created.color == .green)
        #expect(ScheduleChangeType.modified.color == .blue)
        #expect(ScheduleChangeType.paused.color == .orange)
        #expect(ScheduleChangeType.resumed.color == .green)
        #expect(ScheduleChangeType.deactivated.color == .red)
    }

    // MARK: - ScheduleHistoryItem Tests

    @Test("ScheduleHistoryItem creates with all properties")
    func testHistoryItemCreation() {
        let id = UUID()
        let timestamp = Date()
        let item = ScheduleHistoryItem(
            id: id,
            changeType: .modified,
            description: "Updated dose time",
            timestamp: timestamp
        )

        #expect(item.id == id)
        #expect(item.changeType == .modified)
        #expect(item.description == "Updated dose time")
        #expect(item.timestamp == timestamp)
    }

    @Test("ScheduleHistoryItem generates UUID by default")
    func testHistoryItemDefaultID() {
        let item1 = ScheduleHistoryItem(
            changeType: .created,
            description: "Test",
            timestamp: Date()
        )
        let item2 = ScheduleHistoryItem(
            changeType: .created,
            description: "Test",
            timestamp: Date()
        )

        #expect(item1.id != item2.id, "Each item should have unique UUID")
    }

    // MARK: - Timestamp Formatting Tests

    @Test("Timestamp formats as abbreviated date without time")
    func testTimestampFormatting() {
        let calendar = Calendar.current
        let components = DateComponents(year: 2025, month: 10, day: 18, hour: 14, minute: 30)
        guard let testDate = calendar.date(from: components) else {
            Issue.record("Failed to create test date")
            return
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let formatted = formatter.string(from: testDate)

        // Verify format is date-only (no time component)
        #expect(!formatted.contains("14:30"))
        #expect(!formatted.contains("2:30"))
        #expect(formatted.contains("2025"))
    }
}
