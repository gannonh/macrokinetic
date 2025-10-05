//
//  DoseTitrationTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Unit tests for DoseTitration model business logic and computed properties
@Suite("DoseTitration Model Tests")
struct DoseTitrationTests {
    // MARK: - Test Setup

    @MainActor
    func createTestModelContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(
            for: DoseTitration.self, MedicationProfile.self,
            DoseSchedule.self, ScheduledDose.self,
            configurations: config)
    }

    @MainActor
    func createTestTitration(
        fromDose: Double = 0.25,
        toDose: Double = 0.5,
        scheduledDate: Date = Date(),
        isCompleted: Bool = false
    ) -> DoseTitration {
        DoseTitration(
            fromDose: fromDose,
            toDose: toDose,
            scheduledDate: scheduledDate,
            isCompleted: isCompleted)
    }

    // MARK: - Initialization Tests

    @Test("DoseTitration initializes with correct default values")
    @MainActor
    func initialization() throws {
        let titration = DoseTitration()

        #expect(titration.fromDose == 0.0)
        #expect(titration.toDose == 0.0)
        #expect(titration.isCompleted == false)
        #expect(titration.completedDate == nil)
        #expect(titration.notes == "")
        #expect(titration.medicationProfile == nil)
    }

    @Test("DoseTitration initializes with custom values")
    @MainActor
    func customInitialization() throws {
        let scheduledDate = Date().addingTimeInterval(86400 * 7)  // 1 week from now
        let titration = self.createTestTitration(
            fromDose: 1.0,
            toDose: 1.7,
            scheduledDate: scheduledDate,
            isCompleted: false)

        #expect(titration.fromDose == 1.0)
        #expect(titration.toDose == 1.7)
        #expect(titration.scheduledDate == scheduledDate)
        #expect(titration.isCompleted == false)
    }

    // MARK: - Business Logic Tests

    @Test("markCompleted updates titration state correctly")
    @MainActor
    func testMarkCompleted() throws {
        let container = try createTestModelContainer()
        let context = container.mainContext

        // Create medication profile
        let profile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic",
            currentDose: 0.25,
            medicationType: "semaglutide")
        context.insert(profile)

        // Create titration
        let titration = self.createTestTitration(fromDose: 0.25, toDose: 0.5)
        titration.medicationProfile = profile
        context.insert(titration)

        let beforeDate = Date()

        // Mark as completed
        titration.markCompleted()

        let afterDate = Date()

        // Verify titration state
        #expect(titration.isCompleted == true)
        #expect(titration.completedDate != nil)
        #expect(titration.completedDate! >= beforeDate)
        #expect(titration.completedDate! <= afterDate)

        // Verify medication profile dose was updated
        #expect(profile.currentDose == 0.5)
    }

    @Test("validateTitration returns true for valid escalation")
    @MainActor
    func validateTitrationValid() throws {
        let futureDate = Date().addingTimeInterval(86400 * 7)  // 1 week from now
        let titration = self.createTestTitration(
            fromDose: 0.25,
            toDose: 0.5,
            scheduledDate: futureDate)

        #expect(titration.validateTitration() == true)
    }

    @Test("validateTitration returns false for same dose")
    @MainActor
    func validateTitrationSameDose() throws {
        let futureDate = Date().addingTimeInterval(86400 * 7)
        let titration = self.createTestTitration(
            fromDose: 0.25,
            toDose: 0.25,  // Same dose
            scheduledDate: futureDate)

        #expect(titration.validateTitration() == false)
    }

    @Test("validateTitration returns false for lower target dose")
    @MainActor
    func validateTitrationLowerDose() throws {
        let futureDate = Date().addingTimeInterval(86400 * 7)
        let titration = self.createTestTitration(
            fromDose: 0.5,
            toDose: 0.25,  // Lower dose
            scheduledDate: futureDate)

        #expect(titration.validateTitration() == false)
    }

    @Test("validateTitration returns false for past date")
    @MainActor
    func validateTitrationPastDate() throws {
        let pastDate = Date().addingTimeInterval(-86400)  // 1 day ago
        let titration = self.createTestTitration(
            fromDose: 0.25,
            toDose: 0.5,
            scheduledDate: pastDate)

        #expect(titration.validateTitration() == false)
    }

    // MARK: - Computed Properties Tests

    @Test("titrationDescription formats doses correctly")
    @MainActor
    func testTitrationDescription() throws {
        let titration = self.createTestTitration(fromDose: 0.25, toDose: 1.0)

        #expect(titration.titrationDescription == "0.25 mg → 1.00 mg")
    }

    @Test("statusText shows scheduled for incomplete titration")
    @MainActor
    func statusTextScheduled() throws {
        let titration = self.createTestTitration(fromDose: 0.25, toDose: 0.5, isCompleted: false)

        #expect(titration.statusText == "Scheduled: 0.25 mg → 0.50 mg")
    }

    @Test("statusText shows completed for finished titration")
    @MainActor
    func statusTextCompleted() throws {
        let titration = self.createTestTitration(fromDose: 0.25, toDose: 0.5, isCompleted: true)

        #expect(titration.statusText == "Completed: 0.25 mg → 0.50 mg")
    }

    @Test("isFuture returns true for future uncompleted titration")
    @MainActor
    func isFutureTrue() throws {
        let futureDate = Date().addingTimeInterval(86400 * 7)  // 1 week from now
        let titration = self.createTestTitration(scheduledDate: futureDate, isCompleted: false)

        #expect(titration.isFuture == true)
    }

    @Test("isFuture returns false for past titration")
    @MainActor
    func isFutureFalseForPast() throws {
        let pastDate = Date().addingTimeInterval(-86400)  // 1 day ago
        let titration = self.createTestTitration(scheduledDate: pastDate, isCompleted: false)

        #expect(titration.isFuture == false)
    }

    @Test("isFuture returns false for completed titration")
    @MainActor
    func isFutureFalseForCompleted() throws {
        let futureDate = Date().addingTimeInterval(86400 * 7)
        let titration = self.createTestTitration(scheduledDate: futureDate, isCompleted: true)

        #expect(titration.isFuture == false)
    }

    @Test("isOverdue returns true for past uncompleted titration")
    @MainActor
    func isOverdueTrue() throws {
        let pastDate = Date().addingTimeInterval(-86400)  // 1 day ago
        let titration = self.createTestTitration(scheduledDate: pastDate, isCompleted: false)

        #expect(titration.isOverdue == true)
    }

    @Test("isOverdue returns false for future titration")
    @MainActor
    func isOverdueFalseForFuture() throws {
        let futureDate = Date().addingTimeInterval(86400 * 7)
        let titration = self.createTestTitration(scheduledDate: futureDate, isCompleted: false)

        #expect(titration.isOverdue == false)
    }

    @Test("isOverdue returns false for completed titration")
    @MainActor
    func isOverdueFalseForCompleted() throws {
        let pastDate = Date().addingTimeInterval(-86400)
        let titration = self.createTestTitration(scheduledDate: pastDate, isCompleted: true)

        #expect(titration.isOverdue == false)
    }

    // MARK: - Relationship Tests

    @Test("titration can be associated with medication profile")
    @MainActor
    func medicationProfileRelationship() throws {
        let container = try createTestModelContainer()
        let context = container.mainContext

        let profile = MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic",
            currentDose: 0.25,
            medicationType: "semaglutide")
        context.insert(profile)

        let titration = self.createTestTitration()
        titration.medicationProfile = profile
        context.insert(titration)

        try context.save()

        #expect(titration.medicationProfile == profile)
    }

    // MARK: - Edge Cases and Error Conditions

    @Test("markCompleted works without medication profile")
    @MainActor
    func markCompletedWithoutProfile() throws {
        let titration = self.createTestTitration()

        // Should not crash even without profile
        titration.markCompleted()

        #expect(titration.isCompleted == true)
        #expect(titration.completedDate != nil)
    }

    @Test("titration handles extreme dose values")
    @MainActor
    func extremeDoseValues() throws {
        let futureDate = Date().addingTimeInterval(86400)  // 1 day from now
        let titration = self.createTestTitration(
            fromDose: 0.0001,
            toDose: 999.9999,
            scheduledDate: futureDate)

        #expect(titration.titrationDescription == "0.00 mg → 1000.00 mg")
        #expect(titration.validateTitration() == true)  // Still valid escalation
    }

    @Test("audit fields are set correctly on creation")
    @MainActor
    func auditFields() throws {
        let beforeCreation = Date()
        let titration = self.createTestTitration()
        let afterCreation = Date()

        #expect(titration.createdAt >= beforeCreation)
        #expect(titration.createdAt <= afterCreation)
        #expect(titration.updatedAt >= beforeCreation)
        #expect(titration.updatedAt <= afterCreation)
    }
}
