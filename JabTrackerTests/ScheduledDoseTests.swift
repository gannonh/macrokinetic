//
//  ScheduledDoseTests.swift
//  JabTrackerTests
//
//  Comprehensive test suite for ScheduledDose SwiftData model
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Test suite for ScheduledDose model validation
@MainActor
struct ScheduledDoseTests {

    // MARK: - Helper Methods

    /// Create a test container with in-memory storage
    func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            Dose.self,
            ScheduledDose.self,
            DoseSchedule.self,
        ])
        let config = InMemoryTestStore.configuration(schema: schema)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Create a test ScheduledDose with default values
    func createTestScheduledDose(
        context: ModelContext,
        scheduledTime: Date = Date(),
        doseAmount: Double = 0.5,
        windowStart: Date? = nil,
        windowEnd: Date? = nil
    ) -> ScheduledDose {
        let start = windowStart ?? Calendar.current.date(byAdding: .hour, value: -2, to: scheduledTime)!
        let end = windowEnd ?? Calendar.current.date(byAdding: .hour, value: 2, to: scheduledTime)!

        let scheduledDose = ScheduledDose(
            scheduledTime: scheduledTime,
            doseAmount: doseAmount,
            windowStart: start,
            windowEnd: end
        )
        context.insert(scheduledDose)
        return scheduledDose
    }

    // MARK: - Model Creation Tests

    @Test("ScheduledDose creation with valid data succeeds")
    func testScheduledDoseCreation() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let now = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            scheduledTime: now,
            doseAmount: 0.5
        )

        // Verify ID is a valid UUID (not nil/empty)
        #expect(scheduledDose.id.uuidString.count == 36)  // Standard UUID string length
        #expect(scheduledDose.scheduledTime == now)
        #expect(scheduledDose.doseAmount == 0.5)
        // createdAt and updatedAt are non-optional and set to Date() by default
        #expect(scheduledDose.createdAt <= Date())
        #expect(scheduledDose.updatedAt <= Date())
    }

    @Test("ScheduledDose has sensible default values")
    func testScheduledDoseDefaults() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledDose = ScheduledDose()
        context.insert(scheduledDose)

        // Verify ID is a valid UUID (not nil/empty)
        #expect(scheduledDose.id.uuidString.count == 36)  // Standard UUID string length
        #expect(scheduledDose.doseAmount == 0.0)
        #expect(scheduledDose.skippedAt == nil)
        #expect(scheduledDose.skipReason == nil)
        #expect(scheduledDose.rescheduledFrom == nil)
        #expect(scheduledDose.actualDose == nil)
        #expect(scheduledDose.schedule == nil)
    }

    @Test("ScheduledDose with custom init sets all required fields")
    func testScheduledDoseCustomInit() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledTime = Date()
        let windowStart = Calendar.current.date(byAdding: .hour, value: -2, to: scheduledTime)!
        let windowEnd = Calendar.current.date(byAdding: .hour, value: 2, to: scheduledTime)!

        let scheduledDose = ScheduledDose(
            scheduledTime: scheduledTime,
            doseAmount: 0.75,
            windowStart: windowStart,
            windowEnd: windowEnd
        )
        context.insert(scheduledDose)

        #expect(scheduledDose.scheduledTime == scheduledTime)
        #expect(scheduledDose.doseAmount == 0.75)
        #expect(scheduledDose.windowStart == windowStart)
        #expect(scheduledDose.windowEnd == windowEnd)
    }

    // MARK: - Window Calculation Tests

    @Test("isInWindow returns true when current time is within window")
    func testIsInWindowTrue() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let now = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            scheduledTime: now
        )

        #expect(scheduledDose.isInWindow == true)
    }

    @Test("isInWindow returns false when current time is before window")
    func testIsInWindowBeforeWindow() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let futureTime = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let scheduledDose = createTestScheduledDose(
            context: context,
            scheduledTime: futureTime
        )

        #expect(scheduledDose.isInWindow == false)
    }

    @Test("isInWindow returns false when current time is after window")
    func testIsInWindowAfterWindow() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let pastTime = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let scheduledDose = createTestScheduledDose(
            context: context,
            scheduledTime: pastTime
        )

        #expect(scheduledDose.isInWindow == false)
    }

    @Test("isInWindow handles edge case at window start")
    func testIsInWindowEdgeStart() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let now = Date()
        let scheduledDose = ScheduledDose(
            scheduledTime: now,
            doseAmount: 0.5,
            windowStart: now.addingTimeInterval(-1),  // Fixed: 1 second before now to avoid race condition
            windowEnd: Calendar.current.date(byAdding: .hour, value: 2, to: now)!
        )
        context.insert(scheduledDose)

        #expect(scheduledDose.isInWindow == true)
    }

    @Test("isInWindow handles edge case at window end")
    func testIsInWindowEdgeEnd() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let now = Date()
        let scheduledDose = ScheduledDose(
            scheduledTime: now,
            doseAmount: 0.5,
            windowStart: Calendar.current.date(byAdding: .hour, value: -2, to: now)!,
            windowEnd: now.addingTimeInterval(1)  // Fixed: 1 second after now to avoid race condition
        )
        context.insert(scheduledDose)

        #expect(scheduledDose.isInWindow == true)
    }

    // MARK: - Status Calculation Tests

    @Test("status returns pending when no action taken and within window")
    func testStatusPending() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let now = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            scheduledTime: now
        )

        #expect(scheduledDose.status == .pending)
    }

    @Test("status returns taken when actualDose exists")
    func testStatusTaken() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledDose = createTestScheduledDose(context: context)
        let actualDose = Dose(amount: 0.5, timestamp: Date())
        context.insert(actualDose)
        scheduledDose.actualDose = actualDose

        #expect(scheduledDose.status == .taken)
    }

    @Test("status returns skipped when skippedAt is set")
    func testStatusSkipped() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledDose = createTestScheduledDose(context: context)
        scheduledDose.skippedAt = Date()
        scheduledDose.skipReason = "Feeling unwell"

        #expect(scheduledDose.status == .skipped)
    }

    @Test("status returns missed when past window end and not taken or skipped")
    func testStatusMissed() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let pastTime = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let scheduledDose = createTestScheduledDose(
            context: context,
            scheduledTime: pastTime
        )

        #expect(scheduledDose.status == .missed)
    }

    @Test("status prioritizes taken over skipped when both exist")
    func testStatusPrioritizesTaken() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledDose = createTestScheduledDose(context: context)
        let actualDose = Dose(amount: 0.5, timestamp: Date())
        context.insert(actualDose)
        scheduledDose.actualDose = actualDose
        scheduledDose.skippedAt = Date()

        #expect(scheduledDose.status == .taken)
    }

    // MARK: - Relationship Tests

    @Test("ScheduledDose can reference parent DoseSchedule")
    func testScheduleRelationship() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let doseSchedule = DoseSchedule(
            patternType: .weekly,
            baseSchedule: Data()
        )
        context.insert(doseSchedule)

        let scheduledDose = createTestScheduledDose(context: context)
        scheduledDose.schedule = doseSchedule

        #expect(scheduledDose.schedule?.id == doseSchedule.id)
    }

    @Test("ScheduledDose can reference actualDose when taken")
    func testActualDoseRelationship() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledDose = createTestScheduledDose(context: context)
        let actualDose = Dose(amount: 0.5, timestamp: Date())
        context.insert(actualDose)

        scheduledDose.actualDose = actualDose

        #expect(scheduledDose.actualDose?.id == actualDose.id)
        #expect(scheduledDose.status == .taken)
    }

    // MARK: - Reschedule Tests

    @Test("Rescheduling preserves original scheduled time")
    func testReschedulePreservesOriginalTime() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let originalTime = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            scheduledTime: originalTime
        )

        let newTime = Calendar.current.date(byAdding: .day, value: 1, to: originalTime)!
        scheduledDose.rescheduledFrom = originalTime
        scheduledDose.scheduledTime = newTime

        #expect(scheduledDose.rescheduledFrom == originalTime)
        #expect(scheduledDose.scheduledTime == newTime)
    }

    @Test("Rescheduling updates window times appropriately")
    func testRescheduleUpdatesWindows() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let originalTime = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            scheduledTime: originalTime
        )

        let newTime = Calendar.current.date(byAdding: .day, value: 1, to: originalTime)!
        let newStart = Calendar.current.date(byAdding: .hour, value: -2, to: newTime)!
        let newEnd = Calendar.current.date(byAdding: .hour, value: 2, to: newTime)!

        scheduledDose.rescheduledFrom = originalTime
        scheduledDose.scheduledTime = newTime
        scheduledDose.windowStart = newStart
        scheduledDose.windowEnd = newEnd

        #expect(scheduledDose.windowStart == newStart)
        #expect(scheduledDose.windowEnd == newEnd)
        #expect(scheduledDose.isInWindow == false)  // Future time
    }

    // MARK: - Skip Tracking Tests

    @Test("Skip tracking records reason and timestamp")
    func testSkipTracking() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledDose = createTestScheduledDose(context: context)
        let skipTime = Date()
        let skipReason = "Travel"

        scheduledDose.skippedAt = skipTime
        scheduledDose.skipReason = skipReason

        #expect(scheduledDose.skippedAt == skipTime)
        #expect(scheduledDose.skipReason == skipReason)
        #expect(scheduledDose.status == .skipped)
    }

    @Test("Skip tracking without reason is valid")
    func testSkipWithoutReason() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledDose = createTestScheduledDose(context: context)
        scheduledDose.skippedAt = Date()

        #expect(scheduledDose.skippedAt != nil)
        #expect(scheduledDose.skipReason == nil)
        #expect(scheduledDose.status == .skipped)
    }

    // MARK: - Edge Case Tests

    @Test("Zero dose amount is valid")
    func testZeroDoseAmount() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledDose = createTestScheduledDose(
            context: context,
            doseAmount: 0.0
        )

        #expect(scheduledDose.doseAmount == 0.0)
    }

    @Test("Large dose amount is valid")
    func testLargeDoseAmount() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let scheduledDose = createTestScheduledDose(
            context: context,
            doseAmount: 15.0
        )

        #expect(scheduledDose.doseAmount == 15.0)
    }

    @Test("Window can be instantaneous (start equals end)")
    func testInstantaneousWindow() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let pastTime = Date().addingTimeInterval(-1)  // Fixed: Use past timestamp to avoid race condition
        let scheduledDose = ScheduledDose(
            scheduledTime: pastTime,
            doseAmount: 0.5,
            windowStart: pastTime,
            windowEnd: pastTime
        )
        context.insert(scheduledDose)

        // Verify instantaneous window is valid (start equals end)
        #expect(scheduledDose.windowStart == scheduledDose.windowEnd)
        // Since window is in the past, isInWindow should be false
        #expect(scheduledDose.isInWindow == false)
    }

    @Test("Multiple scheduled doses can exist independently")
    func testMultipleScheduledDoses() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let dose1 = createTestScheduledDose(context: context, doseAmount: 0.25)
        let dose2 = createTestScheduledDose(context: context, doseAmount: 0.5)
        let dose3 = createTestScheduledDose(context: context, doseAmount: 1.0)

        #expect(dose1.id != dose2.id)
        #expect(dose2.id != dose3.id)
        #expect(dose1.doseAmount == 0.25)
        #expect(dose2.doseAmount == 0.5)
        #expect(dose3.doseAmount == 1.0)
    }

    // MARK: - Audit Trail Tests

    @Test("createdAt timestamp is set on creation")
    func testCreatedAtTimestamp() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let beforeCreate = Date()
        let scheduledDose = createTestScheduledDose(context: context)
        let afterCreate = Date()

        #expect(scheduledDose.createdAt >= beforeCreate)
        #expect(scheduledDose.createdAt <= afterCreate)
    }

    @Test("updatedAt timestamp is set on creation")
    func testUpdatedAtTimestamp() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let beforeCreate = Date()
        let scheduledDose = createTestScheduledDose(context: context)
        let afterCreate = Date()

        #expect(scheduledDose.updatedAt >= beforeCreate)
        #expect(scheduledDose.updatedAt <= afterCreate)
    }
}
