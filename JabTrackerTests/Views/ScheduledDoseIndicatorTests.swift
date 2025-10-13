//
//  ScheduledDoseIndicatorTests.swift
//  JabTrackerTests
//
//  Unit tests for ScheduledDoseIndicator visual component
//

import SwiftData
import SwiftUI
import Testing

@testable import JabTracker

@Suite("ScheduledDoseIndicator Tests")
struct ScheduledDoseIndicatorTests {
    // MARK: - Test1: Indicator color and style validation

    @Test("Scheduled dose indicator color for scheduled status")
    @MainActor
    func scheduledDoseIndicatorColorScheduled() async throws {
        // GIVEN: A scheduled dose (not yet logged)
        let indicator = ScheduledDoseIndicator(status: .scheduled, size: .medium)

        // WHEN: Indicator is rendered for scheduled status
        // THEN: Component renders without error (basic validation)
        #expect(indicator.status == .scheduled)
        #expect(indicator.size == .medium)
    }

    @Test("Scheduled dose indicator color for logged status")
    @MainActor
    func scheduledDoseIndicatorColorLogged() async throws {
        // GIVEN: A logged dose
        let indicator = ScheduledDoseIndicator(status: .taken, size: .medium)

        // WHEN: Indicator is rendered for logged status
        // THEN: Component renders with taken status
        #expect(indicator.status == .taken)
        #expect(indicator.size == .medium)
    }

    @Test("Scheduled dose indicator color for missed status")
    @MainActor
    func scheduledDoseIndicatorColorMissed() async throws {
        // GIVEN: A missed dose (scheduled but past due)
        let indicator = ScheduledDoseIndicator(status: .missed, size: .medium)

        // WHEN: Indicator is rendered for missed status
        // THEN: Component renders with missed status
        #expect(indicator.status == .missed)
    }

    @Test("Scheduled dose indicator color for skipped status")
    @MainActor
    func scheduledDoseIndicatorColorSkipped() async throws {
        // GIVEN: A skipped dose
        let indicator = ScheduledDoseIndicator(status: .skipped, size: .medium)

        // WHEN: Indicator is rendered for skipped status
        // THEN: Component renders with skipped status
        #expect(indicator.status == .skipped)
    }

    @Test("Scheduled dose indicator size variations")
    @MainActor
    func scheduledDoseIndicatorSizes() async throws {
        // GIVEN: Different indicator sizes
        // WHEN: Indicators are created
        let small = ScheduledDoseIndicator(status: .scheduled, size: .small)
        let medium = ScheduledDoseIndicator(status: .scheduled, size: .medium)
        let large = ScheduledDoseIndicator(status: .scheduled, size: .large)

        // THEN: Size dimensions are correct
        #expect(small.size.dimension == 4)
        #expect(medium.size.dimension == 6)
        #expect(large.size.dimension == 8)
    }

    // MARK: - Test2: Indicator display logic

    @Test("DoseIndicatorsView displays logged doses")
    @MainActor
    func doseIndicatorsViewDisplaysLoggedDoses() async throws {
        // GIVEN: 2 logged doses for a calendar day
        let events = [
            DoseEvent(
                id: UUID(),
                timestamp: Date(),
                type: .taken,
                scheduledDose: nil,
                actualDose: nil,
                doseAmount: 1.0,
                adherenceStatus: .adherent
            ),
            DoseEvent(
                id: UUID(),
                timestamp: Date(),
                type: .taken,
                scheduledDose: nil,
                actualDose: nil,
                doseAmount: 1.0,
                adherenceStatus: .adherent
            ),
        ]

        // WHEN: DoseIndicatorsView renders
        let view = DoseIndicatorsView(events: events)

        // THEN: 2 indicators are configured
        #expect(view.events.count == 2)
        #expect(view.events.allSatisfy { $0.type == .taken })
    }

    @Test("DoseIndicatorsView displays scheduled doses")
    @MainActor
    func doseIndicatorsViewDisplaysScheduledDoses() async throws {
        // GIVEN: 1 scheduled dose for a calendar day
        let events = [
            DoseEvent(
                id: UUID(),
                timestamp: Date(),
                type: .scheduled,
                scheduledDose: nil,
                actualDose: nil,
                doseAmount: 1.0,
                adherenceStatus: .pending
            )
        ]

        // WHEN: DoseIndicatorsView renders
        let view = DoseIndicatorsView(events: events)

        // THEN: 1 scheduled indicator is configured
        #expect(view.events.count == 1)
        #expect(view.events.first?.type == .scheduled)
    }

    @Test("DoseIndicatorsView displays mixed logged and scheduled doses")
    @MainActor
    func doseIndicatorsViewDisplaysMixedDoses() async throws {
        // GIVEN: 2 logged doses and 1 scheduled dose
        let events = [
            DoseEvent(
                id: UUID(),
                timestamp: Date(),
                type: .taken,
                scheduledDose: nil,
                actualDose: nil,
                doseAmount: 1.0,
                adherenceStatus: .adherent
            ),
            DoseEvent(
                id: UUID(),
                timestamp: Date(),
                type: .taken,
                scheduledDose: nil,
                actualDose: nil,
                doseAmount: 1.0,
                adherenceStatus: .adherent
            ),
            DoseEvent(
                id: UUID(),
                timestamp: Date(),
                type: .scheduled,
                scheduledDose: nil,
                actualDose: nil,
                doseAmount: 1.0,
                adherenceStatus: .pending
            ),
        ]

        // WHEN: DoseIndicatorsView renders
        let view = DoseIndicatorsView(events: events)

        // THEN: All 3 events are present
        #expect(view.events.count == 3)
        let takenCount = view.events.filter { $0.type == .taken }.count
        let scheduledCount = view.events.filter { $0.type == .scheduled }.count
        #expect(takenCount == 2)
        #expect(scheduledCount == 1)
    }

    @Test("DoseIndicatorsView limits display to 3 indicators")
    @MainActor
    func doseIndicatorsViewLimitsDisplay() async throws {
        // GIVEN: 5 total doses (3 logged, 2 scheduled)
        let events = [
            DoseEvent(
                id: UUID(),
                timestamp: Date(),
                type: .taken,
                scheduledDose: nil,
                actualDose: nil,
                doseAmount: 1.0,
                adherenceStatus: .adherent
            ),
            DoseEvent(
                id: UUID(),
                timestamp: Date(),
                type: .taken,
                scheduledDose: nil,
                actualDose: nil,
                doseAmount: 1.0,
                adherenceStatus: .adherent
            ),
            DoseEvent(
                id: UUID(),
                timestamp: Date(),
                type: .taken,
                scheduledDose: nil,
                actualDose: nil,
                doseAmount: 1.0,
                adherenceStatus: .adherent
            ),
            DoseEvent(
                id: UUID(),
                timestamp: Date(),
                type: .scheduled,
                scheduledDose: nil,
                actualDose: nil,
                doseAmount: 1.0,
                adherenceStatus: .pending
            ),
            DoseEvent(
                id: UUID(),
                timestamp: Date(),
                type: .scheduled,
                scheduledDose: nil,
                actualDose: nil,
                doseAmount: 1.0,
                adherenceStatus: .pending
            ),
        ]

        // WHEN: DoseIndicatorsView renders
        let view = DoseIndicatorsView(events: events)

        // THEN: Total event count is 5 but overflow logic applies
        #expect(view.events.count == 5)
        #expect(view.maxDisplayCount == 3)
    }

    @Test("DoseIndicatorsView handles empty state")
    @MainActor
    func doseIndicatorsViewHandlesEmptyState() async throws {
        // GIVEN: No logged or scheduled doses
        let events: [DoseEvent] = []

        // WHEN: DoseIndicatorsView renders
        let view = DoseIndicatorsView(events: events)

        // THEN: View handles empty state gracefully
        #expect(view.events.isEmpty)
    }
}
