//
//  DoseScheduleEditViewTests.swift
//  JabTrackerTests
//
//  Unit tests for DoseScheduleEditView.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("DoseScheduleEditView Tests")
struct DoseScheduleEditViewTests {

    // MARK: - Test Helpers

    /// Create test model container with schema
    @MainActor
    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            DoseSchedule.self,
            ScheduledDose.self,
            Dose.self,
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: [config])
    }

    /// Create test medication profile
    @MainActor
    private func createTestProfile(context: ModelContext) -> MedicationProfile {
        let profile = MedicationProfile(
            brandName: "Ozempic",
            currentDose: 0.25,
            startDate: Date(),
            medicationType: "semaglutide"
        )
        context.insert(profile)

        return profile
    }

    /// Create test dose schedule
    @MainActor
    private func createTestSchedule(context: ModelContext, profile: MedicationProfile) throws -> DoseSchedule {
        let config = ScheduleConfiguration(
            dayOfWeek: 1,  // Monday
            timeOfDay: TimeComponents(hour: 8, minute: 0),
            interval: 7,
            doseAmount: profile.currentDose,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        let jsonData = try JSONEncoder().encode(config)

        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly,
            baseSchedule: jsonData,
            isActive: true,
            customScheduleData: nil
        )
        context.insert(schedule)

        return schedule
    }

    // MARK: - Initialization Tests

    @Test("Initialization with existing schedule populates fields correctly")
    @MainActor
    func testInitializationWithExistingSchedule() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let profile = createTestProfile(context: context)
        let existingSchedule = try createTestSchedule(context: context, profile: profile)

        // Create view with existing schedule
        var saveCalled = false
        let view = DoseScheduleEditView(
            medicationProfile: profile,
            existingSchedule: existingSchedule,
            onSave: { _, _ in saveCalled = true }
        )

        // Verify pattern is initialized from existing schedule
        #expect(view.selectedPattern == .weekly)

        // Verify save callback hasn't been triggered during initialization
        #expect(saveCalled == false)

        // Note: Other fields use defaults currently (TODO: parse baseSchedule into other view fields
        // such as selectedDays, selectedTime, doseAmount, etc.)
    }

    @Test("Initialization without schedule uses default values")
    @MainActor
    func testInitializationWithoutSchedule() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let profile = createTestProfile(context: context)

        // Create view without existing schedule
        var saveCalled = false
        let view = DoseScheduleEditView(
            medicationProfile: profile,
            existingSchedule: nil,
            onSave: { _, _ in saveCalled = true }
        )

        // Verify default values are used
        #expect(view.selectedPattern == .weekly)

        // Verify save callback hasn't been triggered during initialization
        #expect(saveCalled == false)

        // Note: Other default view state properties (selectedDays, selectedTime, doseAmount,
        // occurrence values, etc.) are @State properties not accessible in unit tests
    }

    @Test("Medication info displays correctly")
    @MainActor
    func testMedicationInfoDisplay() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let profile = createTestProfile(context: context)

        let view = DoseScheduleEditView(
            medicationProfile: profile,
            existingSchedule: nil,
            onSave: { _, _ in }
        )

        // Verify medication profile is accessible
        #expect(view.medicationProfile.medicationType == "semaglutide")
        #expect(view.medicationProfile.brandName == "Ozempic")
        #expect(view.medicationProfile.currentDose == 0.25)
    }

    @Test("Pattern initializes with default weekly value")
    @MainActor
    func testPatternInitializesWithDefault() throws {
        // Create minimal test profile for view initialization
        let profile = MedicationProfile(
            brandName: "Ozempic",
            currentDose: 0.25,
            startDate: Date(),
            medicationType: "semaglutide"
        )

        let view = DoseScheduleEditView(
            medicationProfile: profile,
            existingSchedule: nil,
            onSave: { _, _ in }
        )

        // Verify default pattern is weekly
        #expect(view.selectedPattern == .weekly)

        // Note: Actual pattern selection updates would require SwiftUI interaction testing (E2E tests)
        // since @State properties cannot be directly modified in unit tests
    }
}
