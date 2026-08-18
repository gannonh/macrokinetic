//
//  DoseEventTests.swift
//  JabTrackerTests
//
//  Tests for DoseEvent struct - calculated timeline entity combining scheduled and actual doses
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Comprehensive test suite for DoseEvent struct
/// Tests factory methods, adherence calculation, sorting, and equality
@Suite("DoseEvent Tests")
struct DoseEventTests {

    // MARK: - Test Helpers

    /// Create test container with all required models
    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            Dose.self,
            DoseSchedule.self,
            ScheduledDose.self,
        ])
        let config = InMemoryTestStore.configuration(schema: schema)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Create test ScheduledDose with specified status
    @MainActor
    private func createTestScheduledDose(
        context: ModelContext,
        scheduledTime: Date = Date(),
        status: ScheduledDoseStatus = .pending,
        doseAmount: Double = 0.5
    ) throws -> ScheduledDose {
        let scheduledDose = ScheduledDose(
            scheduledTime: scheduledTime,
            doseAmount: doseAmount,
            windowStart: scheduledTime.addingTimeInterval(-2 * 3600),  // 2 hours before
            windowEnd: scheduledTime.addingTimeInterval(2 * 3600)  // 2 hours after
        )
        context.insert(scheduledDose)

        // Set status by creating appropriate conditions
        switch status {
        case .taken:
            let actualDose = Dose(amount: doseAmount, timestamp: scheduledTime)
            context.insert(actualDose)
            scheduledDose.actualDose = actualDose
        case .skipped:
            scheduledDose.skippedAt = Date()
            scheduledDose.skipReason = "Test skip"
        case .missed:
            // Set window to past to ensure dose is actually missed
            // Note: scheduledTime should already be set appropriately by caller
            scheduledDose.windowEnd = scheduledTime.addingTimeInterval(-3600)  // Window ended 1 hour before scheduled time
        case .pending:
            break  // Default state
        }

        try context.save()
        return scheduledDose
    }

    /// Create test Dose
    @MainActor
    private func createTestDose(
        context: ModelContext,
        amount: Double = 0.5,
        timestamp: Date = Date()
    ) throws -> Dose {
        let dose = Dose(amount: amount, timestamp: timestamp)
        context.insert(dose)
        try context.save()
        return dose
    }

    // MARK: - Factory Method Tests

    @Test("Create DoseEvent from pending ScheduledDose")
    @MainActor
    func createFromPendingScheduledDose() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledTime = Date()
        let scheduledDose = try createTestScheduledDose(
            context: context,
            scheduledTime: scheduledTime,
            status: .pending,
            doseAmount: 0.5
        )

        let event = DoseEvent.from(scheduledDose: scheduledDose)

        #expect(event.type == .scheduled)
        #expect(event.adherenceStatus == .pending)
        #expect(event.timestamp == scheduledTime)
        #expect(event.doseAmount == 0.5)
        #expect(event.scheduledDose?.id == scheduledDose.id)
        #expect(event.actualDose == nil)
        #expect(!event.isAdherent)  // Pending is not adherent
    }

    @Test("Create DoseEvent from taken ScheduledDose")
    @MainActor
    func createFromTakenScheduledDose() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledTime = Date()
        let scheduledDose = try createTestScheduledDose(
            context: context,
            scheduledTime: scheduledTime,
            status: .taken,
            doseAmount: 0.5
        )

        let event = DoseEvent.from(scheduledDose: scheduledDose)

        #expect(event.type == .taken)
        #expect(event.adherenceStatus == .adherent)
        #expect(event.timestamp == scheduledTime)
        #expect(event.doseAmount == 0.5)
        #expect(event.isAdherent)
    }

    @Test("Create DoseEvent from skipped ScheduledDose")
    @MainActor
    func createFromSkippedScheduledDose() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledTime = Date()
        let scheduledDose = try createTestScheduledDose(
            context: context,
            scheduledTime: scheduledTime,
            status: .skipped,
            doseAmount: 0.5
        )

        let event = DoseEvent.from(scheduledDose: scheduledDose)

        #expect(event.type == .skipped)
        #expect(event.adherenceStatus == .adherent)  // Valid skip is adherent
        #expect(event.timestamp == scheduledTime)
        #expect(!event.isAdherent)  // But computed property is false for skipped
    }

    @Test("Create DoseEvent from missed ScheduledDose")
    @MainActor
    func createFromMissedScheduledDose() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledTime = Date().addingTimeInterval(-86400)  // 1 day ago
        let scheduledDose = try createTestScheduledDose(
            context: context,
            scheduledTime: scheduledTime,
            status: .missed,
            doseAmount: 0.5
        )

        let event = DoseEvent.from(scheduledDose: scheduledDose)

        #expect(event.type == .missed)
        #expect(event.adherenceStatus == .nonAdherent)
        #expect(event.timestamp == scheduledTime)
        #expect(!event.isAdherent)
    }

    @Test("Create DoseEvent from actual Dose without scheduled dose")
    @MainActor
    func createFromActualDoseUnscheduled() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let timestamp = Date()
        let dose = try createTestDose(context: context, amount: 0.75, timestamp: timestamp)

        let event = DoseEvent.from(actualDose: dose)

        #expect(event.type == .taken)
        #expect(event.adherenceStatus == .adherent)  // Unscheduled dose is adherent
        #expect(event.timestamp == timestamp)
        #expect(event.doseAmount == 0.75)
        #expect(event.scheduledDose == nil)
        #expect(event.actualDose?.id == dose.id)
        #expect(event.isAdherent)
    }

    @Test("Create combined DoseEvent from scheduled and actual dose")
    @MainActor
    func createCombinedEvent() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledTime = Date()
        let scheduledDose = try createTestScheduledDose(
            context: context,
            scheduledTime: scheduledTime,
            status: .pending,
            doseAmount: 0.5
        )

        // Dose taken within window (1 hour after scheduled)
        let actualTime = scheduledTime.addingTimeInterval(3600)
        let actualDose = try createTestDose(context: context, amount: 0.5, timestamp: actualTime)

        let event = DoseEvent.combined(scheduled: scheduledDose, actual: actualDose)

        #expect(event.type == .taken)
        #expect(event.adherenceStatus == .adherent)  // Within window
        #expect(event.timestamp == actualTime)  // Uses actual time
        #expect(event.doseAmount == 0.5)
        #expect(event.scheduledDose?.id == scheduledDose.id)
        #expect(event.actualDose?.id == actualDose.id)
        #expect(event.isAdherent)
    }

    // MARK: - Adherence Calculation Tests

    @Test("Combined event adherent when dose taken within window")
    @MainActor
    func adherenceWithinWindow() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledTime = Date()
        let scheduledDose = try createTestScheduledDose(
            context: context,
            scheduledTime: scheduledTime,
            status: .pending,
            doseAmount: 0.5
        )

        // Dose taken 30 minutes after scheduled (within 2 hour window)
        let actualTime = scheduledTime.addingTimeInterval(30 * 60)
        let actualDose = try createTestDose(context: context, amount: 0.5, timestamp: actualTime)

        let event = DoseEvent.combined(scheduled: scheduledDose, actual: actualDose)

        #expect(event.adherenceStatus == .adherent)
        #expect(event.isAdherent)
    }

    @Test("Combined event non-adherent when dose taken outside window")
    @MainActor
    func adherenceOutsideWindow() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledTime = Date()
        let scheduledDose = try createTestScheduledDose(
            context: context,
            scheduledTime: scheduledTime,
            status: .pending,
            doseAmount: 0.5
        )

        // Dose taken 3 hours after scheduled (outside 2 hour window)
        let actualTime = scheduledTime.addingTimeInterval(3 * 3600)
        let actualDose = try createTestDose(context: context, amount: 0.5, timestamp: actualTime)

        let event = DoseEvent.combined(scheduled: scheduledDose, actual: actualDose)

        #expect(event.adherenceStatus == .nonAdherent)
        #expect(!event.isAdherent)
    }

    @Test("Combined event with skipped dose marked as adherent")
    @MainActor
    func combinedEventWithSkippedDose() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledTime = Date()
        let scheduledDose = try createTestScheduledDose(
            context: context,
            scheduledTime: scheduledTime,
            status: .pending,
            doseAmount: 0.5
        )

        // Create a skipped dose
        let actualTime = scheduledTime.addingTimeInterval(3600)
        let actualDose = try createTestDose(context: context, amount: 0.5, timestamp: actualTime)
        actualDose.skipped = true
        try context.save()

        let event = DoseEvent.combined(scheduled: scheduledDose, actual: actualDose)

        #expect(event.type == .skipped)
        #expect(event.adherenceStatus == .adherent)  // Intentional skip is adherent
        #expect(event.timestamp == actualTime)
        #expect(!event.isAdherent)  // Computed property returns false for skipped
        #expect(event.scheduledDose?.id == scheduledDose.id)
        #expect(event.actualDose?.id == actualDose.id)
    }

    @Test("isAdherent computed property for pending status")
    @MainActor
    func isAdherentPendingStatus() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledDose = try createTestScheduledDose(
            context: context,
            status: .pending
        )

        let event = DoseEvent.from(scheduledDose: scheduledDose)

        #expect(event.adherenceStatus == .pending)
        #expect(!event.isAdherent)  // Pending is not adherent
    }

    @Test("isAdherent computed property for adherent status")
    @MainActor
    func isAdherentAdherentStatus() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let dose = try createTestDose(context: context)
        let event = DoseEvent.from(actualDose: dose)

        #expect(event.adherenceStatus == .adherent)
        #expect(event.isAdherent)
    }

    @Test("isAdherent computed property for non-adherent status")
    @MainActor
    func isAdherentNonAdherentStatus() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledDose = try createTestScheduledDose(
            context: context,
            status: .missed
        )

        let event = DoseEvent.from(scheduledDose: scheduledDose)

        #expect(event.adherenceStatus == .nonAdherent)
        #expect(!event.isAdherent)
    }

    // MARK: - Sorting Tests

    @Test("Sort DoseEvents by timestamp ascending")
    @MainActor
    func sortEventsByTimestamp() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let now = Date()
        let dose1 = try createTestDose(context: context, timestamp: now.addingTimeInterval(3600))  // 1 hour later
        let dose2 = try createTestDose(context: context, timestamp: now)  // Now
        let dose3 = try createTestDose(context: context, timestamp: now.addingTimeInterval(-3600))  // 1 hour ago

        let event1 = DoseEvent.from(actualDose: dose1)
        let event2 = DoseEvent.from(actualDose: dose2)
        let event3 = DoseEvent.from(actualDose: dose3)

        let unsorted = [event1, event2, event3]
        let sorted = unsorted.sorted()

        #expect(sorted[0].timestamp == event3.timestamp)  // Oldest first
        #expect(sorted[1].timestamp == event2.timestamp)
        #expect(sorted[2].timestamp == event1.timestamp)  // Newest last
    }

    @Test("Compare two DoseEvents")
    @MainActor
    func compareEvents() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let now = Date()
        let dose1 = try createTestDose(context: context, timestamp: now)
        let dose2 = try createTestDose(context: context, timestamp: now.addingTimeInterval(3600))

        let event1 = DoseEvent.from(actualDose: dose1)
        let event2 = DoseEvent.from(actualDose: dose2)

        #expect(event1 < event2)  // Earlier event is "less than"
        #expect(!(event2 < event1))
    }

    // MARK: - Enum Tests

    @Test("DoseEventType enum values")
    func doseEventTypeEnum() throws {
        #expect(DoseEventType.scheduled.rawValue == "scheduled")
        #expect(DoseEventType.taken.rawValue == "taken")
        #expect(DoseEventType.skipped.rawValue == "skipped")
        #expect(DoseEventType.missed.rawValue == "missed")
    }

    @Test("DoseAdherenceStatus enum values")
    func doseAdherenceStatusEnum() throws {
        #expect(DoseAdherenceStatus.adherent.rawValue == "adherent")
        #expect(DoseAdherenceStatus.nonAdherent.rawValue == "nonAdherent")
        #expect(DoseAdherenceStatus.pending.rawValue == "pending")
    }

    // MARK: - Edge Cases

    @Test("DoseEvent with zero dose amount")
    @MainActor
    func eventWithZeroDoseAmount() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let dose = try createTestDose(context: context, amount: 0.0)
        let event = DoseEvent.from(actualDose: dose)

        #expect(event.doseAmount == 0.0)
        #expect(event.type == .taken)
    }

    @Test("DoseEvent Identifiable conformance")
    @MainActor
    func identifiableConformance() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let dose = try createTestDose(context: context)
        let event = DoseEvent.from(actualDose: dose)

        // Test that id is a valid UUID
        #expect(event.id.uuidString.count > 0)

        // Create another event and verify unique IDs
        let dose2 = try createTestDose(context: context)
        let event2 = DoseEvent.from(actualDose: dose2)

        #expect(event.id != event2.id)
    }
}
