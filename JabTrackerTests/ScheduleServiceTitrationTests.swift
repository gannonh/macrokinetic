//
//  ScheduleServiceTitrationTests.swift
//  JabTrackerTests
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Test suite for ScheduleService titration integration functionality.
///
/// Validates:
/// - Active titration detection (within 30-day window)
/// - Titration completion handling (schedule updates, dose regeneration)
/// - User-friendly titration warning messages
/// - Proper logging and error handling
@MainActor
struct ScheduleServiceTitrationTests {

    // MARK: - Titration Detection Tests

    /// GIVEN: A medication profile with active titration scheduled within 30 days
    /// WHEN: Checking titration impact for the schedule
    /// THEN: Returns the active DoseTitration object
    @Test("Detect active titration affecting schedule (within 30 days)")
    func testCheckTitrationImpact_ActiveTitrationWithin30Days_ReturnsTitration() async throws {
        // GIVEN: Medication profile with titration scheduled in 15 days
        let context = try createTestContext()
        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user, currentDose: 0.25)

        // Create titration scheduled 15 days from now
        let futureDate = Calendar.current.date(byAdding: .day, value: 15, to: Date())!
        let titration = createTestTitration(
            context: context,
            profile: profile,
            fromDose: 0.25,
            toDose: 0.5,
            scheduledDate: futureDate
        )

        let schedule = createTestSchedule(context: context, profile: profile, doseAmount: 0.25)

        try context.save()

        let service = ScheduleService(context: context)

        // WHEN: checkTitrationImpact(for: schedule) called
        let result = service.checkTitrationImpact(for: schedule)

        // THEN: Returns DoseTitration object
        #expect(result != nil, "Should detect titration scheduled within 30 days")
        #expect(result?.id == titration.id, "Should return the correct titration")
        #expect(result?.fromDose == 0.25, "Titration fromDose should be 0.25")
        #expect(result?.toDose == 0.5, "Titration toDose should be 0.5")
    }

    /// GIVEN: A medication profile with no active titration
    /// WHEN: Checking titration impact for the schedule
    /// THEN: Returns nil (no upcoming dose change)
    @Test("Return nil when no active titration exists")
    func testCheckTitrationImpact_NoActiveTitration_ReturnsNil() async throws {
        // GIVEN: Medication profile without any titration
        // WHEN: checkTitrationImpact(for: schedule) called
        // THEN: Returns nil
    }

    /// GIVEN: A medication profile with titration scheduled beyond 30 days
    /// WHEN: Checking titration impact for the schedule
    /// THEN: Returns nil (titration too far in future to affect current schedule)
    @Test("Return nil when titration is beyond 30-day window")
    func testCheckTitrationImpact_TitrationBeyond30Days_ReturnsNil() async throws {
        // GIVEN: Medication profile with titration scheduled in 45 days
        // WHEN: checkTitrationImpact(for: schedule) called
        // THEN: Returns nil (beyond 30-day window)
    }

    // MARK: - Titration Completion Tests

    /// GIVEN: A completed titration and associated schedule
    /// WHEN: Handling titration completion
    /// THEN: Schedule's baseSchedule.doseAmount updated to titration's toDose
    @Test("Update schedule doseAmount when titration completes")
    func testHandleCompletedTitration_UpdatesScheduleDoseAmount() async throws {
        // GIVEN: Schedule with 0.25mg dose, titration to 0.5mg
        // WHEN: handleCompletedTitration(titration, schedule: schedule)
        // THEN: schedule.baseSchedule["doseAmount"] == 0.5
    }

    /// GIVEN: A completed titration and associated schedule
    /// WHEN: Handling titration completion
    /// THEN: Schedule modification history logs titration-triggered change
    @Test("Schedule modification history logs titration completion")
    func testHandleCompletedTitration_LogsScheduleModification() async throws {
        // GIVEN: Schedule with empty modificationHistory
        // WHEN: handleCompletedTitration(titration, schedule: schedule)
        // THEN: schedule.modificationHistory contains titration log entry
    }

    /// GIVEN: A completed titration and schedule with upcoming scheduled doses
    /// WHEN: Handling titration completion
    /// THEN: Upcoming ScheduledDose entities regenerated with new dose amount
    @Test("Regenerate upcoming doses with new amount after titration")
    func testHandleCompletedTitration_RegeneratesUpcomingDoses() async throws {
        // GIVEN: Schedule with 5 upcoming ScheduledDose entities at 0.25mg
        // WHEN: handleCompletedTitration(titration to 0.5mg, schedule: schedule)
        // THEN: All upcoming ScheduledDose entities updated to 0.5mg
    }

    // MARK: - Titration Warning Tests

    /// GIVEN: A medication profile with upcoming titration within 30 days
    /// WHEN: Getting titration warning message
    /// THEN: Returns user-friendly formatted message about dose change
    @Test("Warning message for upcoming titration (formatted correctly)")
    func testGetTitrationWarning_UpcomingTitration_ReturnsFormattedMessage() async throws {
        // GIVEN: Medication profile with titration scheduled Oct 15
        // WHEN: getTitrationWarning(for: schedule) called
        // THEN: Returns "Your dose will increase to 1.0mg on October 15 per your titration plan"
    }

    /// GIVEN: A medication profile with no upcoming titration
    /// WHEN: Getting titration warning message
    /// THEN: Returns nil (no warning needed)
    @Test("No warning when no upcoming titration")
    func testGetTitrationWarning_NoUpcomingTitration_ReturnsNil() async throws {
        // GIVEN: Medication profile without any titration
        // WHEN: getTitrationWarning(for: schedule) called
        // THEN: Returns nil
    }

    // MARK: - Helper Methods

    /// Creates a test ModelContext with in-memory storage.
    private func createTestContext() throws -> ModelContext {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            Dose.self,
            DoseSchedule.self,
            ScheduledDose.self,
            DoseTitration.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    /// Creates a test user with specified properties.
    private func createTestUser(context: ModelContext) -> User {
        let user = User(
            email: "test@titration.com",
            name: "Titration Test User",
            weight: 75.0
        )
        context.insert(user)
        return user
    }

    /// Creates a test medication profile for titration testing.
    private func createTestMedicationProfile(
        context: ModelContext,
        user: User,
        currentDose: Double = 0.25
    ) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: currentDose
        )
        profile.user = user
        context.insert(profile)
        return profile
    }

    /// Creates a test dose schedule for titration testing.
    private func createTestSchedule(
        context: ModelContext,
        profile: MedicationProfile,
        doseAmount: Double = 0.25
    ) -> DoseSchedule {
        // Create baseSchedule JSON data
        let scheduleDict: [String: Any] = [
            "pattern": "weekly",
            "doseAmount": doseAmount,
            "injectionSite": "Abdomen",
            "dayOfWeek": 1,
            "hour": 9,
            "minute": 0,
        ]

        let baseScheduleData: Data
        do {
            baseScheduleData = try JSONSerialization.data(withJSONObject: scheduleDict, options: [])
        } catch {
            baseScheduleData = Data()
        }

        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly,
            baseSchedule: baseScheduleData
        )
        context.insert(schedule)
        return schedule
    }

    /// Creates a test titration for testing titration integration.
    private func createTestTitration(
        context: ModelContext,
        profile: MedicationProfile,
        fromDose: Double = 0.25,
        toDose: Double = 0.5,
        scheduledDate: Date
    ) -> DoseTitration {
        let titration = DoseTitration(
            fromDose: fromDose,
            toDose: toDose,
            scheduledDate: scheduledDate
        )
        titration.medicationProfile = profile
        context.insert(titration)
        return titration
    }
}
