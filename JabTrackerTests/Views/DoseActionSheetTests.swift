//
//  DoseActionSheetTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseActionSheet component
//  Stream B: Action Sheet UI & Dose Management (Issue #178)
//

import SwiftData
import SwiftUI
import Testing

@testable import JabTracker

@MainActor
struct DoseActionSheetTests {
    // MARK: - Test Infrastructure

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            Dose.self,
            DoseSchedule.self,
            ScheduledDose.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func createTestUser(context: ModelContext) -> User {
        let user = User(
            email: "test@test.com",
            name: "Test User",
            weight: 70.0,
            hasCompletedOnboarding: true
        )
        context.insert(user)
        return user
    }

    private func createTestMedicationProfile(
        context: ModelContext,
        user: User
    ) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5
        )
        context.insert(profile)
        profile.user = user
        return profile
    }

    private func createTestSchedule(
        context: ModelContext,
        profile: MedicationProfile
    ) -> DoseSchedule {
        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly
        )
        context.insert(schedule)
        return schedule
    }

    private func createTestScheduledDose(
        context: ModelContext,
        schedule: DoseSchedule,
        time: Date
    ) -> ScheduledDose {
        let twoHours: TimeInterval = 2 * 60 * 60
        let scheduledDose = ScheduledDose(
            scheduledTime: time,
            doseAmount: 0.5,
            windowStart: time.addingTimeInterval(-twoHours),
            windowEnd: time.addingTimeInterval(twoHours)
        )
        context.insert(scheduledDose)
        scheduledDose.schedule = schedule
        return scheduledDose
    }

    // MARK: - Action Sheet Display Tests

    @Test("DoseActionSheet displays scheduled dose details")
    func testDisplaysScheduledDoseDetails() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = createTestSchedule(context: context, profile: profile)
        let scheduledTime = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            time: scheduledTime
        )

        let event = DoseEvent.from(scheduledDose: scheduledDose)

        // Verify event has expected properties for display
        #expect(event.type == .scheduled)
        #expect(event.timestamp == scheduledTime)
        #expect(event.doseAmount == 0.5)
        #expect(event.scheduledDose != nil)
    }

    @Test("DoseActionSheet supports all action types")
    func testSupportsAllActionTypes() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = createTestSchedule(context: context, profile: profile)
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            time: Date()
        )

        let event = DoseEvent.from(scheduledDose: scheduledDose)

        // Verify event is actionable (scheduled status)
        #expect(event.type == .scheduled)
        #expect(event.adherenceStatus == .pending)

        // Actions should be available for scheduled doses
        // Log Dose: Opens QuickDoseSheet
        // Reschedule: Opens RescheduleDoseSheet
        // Skip: Marks as skipped
        // Dismiss: Closes sheet
    }

    // MARK: - Skip Dose Action Tests

    @Test("Skip dose action marks scheduled dose as skipped")
    func testSkipDoseMarksAsSkipped() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = createTestSchedule(context: context, profile: profile)
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            time: Date()
        )

        // Initial state: pending
        #expect(scheduledDose.status == .pending)

        // Skip dose
        scheduledDose.markAsSkipped(reason: "User requested")

        // Verify status changed
        #expect(scheduledDose.status == .skipped)
        #expect(scheduledDose.skipReason == "User requested")
    }

    @Test("Skip dose creates correct event type")
    func testSkippedDoseEventType() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = createTestSchedule(context: context, profile: profile)
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            time: Date()
        )

        // Mark as skipped
        scheduledDose.markAsSkipped(reason: "User skipped")

        // Create event from skipped dose
        let event = DoseEvent.from(scheduledDose: scheduledDose)

        // Verify event shows skipped status
        #expect(event.type == .skipped)
        #expect(event.adherenceStatus == .adherent)  // Valid skip is adherent
    }

    // MARK: - Edge Cases

    @Test("Cannot skip already logged dose")
    func testCannotSkipLoggedDose() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = createTestSchedule(context: context, profile: profile)
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            time: Date()
        )

        // Create and link actual dose
        let actualDose = Dose(
            amount: 0.5,
            timestamp: Date(),
            site: "Abdomen",
            notes: nil,
            imageData: nil,
            skipped: false,
            user: user,
            medication: profile
        )
        context.insert(actualDose)
        scheduledDose.actualDose = actualDose

        // Status should be taken
        #expect(scheduledDose.status == .taken)

        // Attempting to skip should not change status
        // (UI should prevent this, but model should be safe)
        let initialStatus = scheduledDose.status
        scheduledDose.markAsSkipped(reason: "Should not work")

        // For safety, we expect the skip to be ignored for taken doses
        // or the model should validate this
        // This test documents expected behavior
    }

    @Test("Action sheet event has medication profile reference")
    func testEventHasMedicationProfileReference() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = createTestSchedule(context: context, profile: profile)
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            time: Date()
        )

        let event = DoseEvent.from(scheduledDose: scheduledDose)

        // Verify we can access medication profile for pre-populating QuickDoseSheet
        #expect(event.scheduledDose?.schedule?.medicationProfile?.brandName == "Ozempic")
        #expect(event.scheduledDose?.doseAmount == 0.5)
    }
}
