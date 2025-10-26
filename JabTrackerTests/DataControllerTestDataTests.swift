//
//  DataControllerTestDataTests.swift
//  JabTrackerTests
//

import CloudKit
import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
@Suite("DataController Test Data Seeding Tests")
struct DataControllerTestDataTests {
    @Test("seedTitrationTestData creates medication profile")
    @MainActor
    func seedTitrationTestDataCreatesMedicationProfile() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Create a test user first (required for seeding)
        let testUser = User(email: "test@example.com", name: "Test User")
        context.insert(testUser)
        try context.save()

        // Seed test data
        controller.seedTitrationTestData()

        // Verify medication profile was created
        let profileDescriptor = FetchDescriptor<MedicationProfile>()
        let profiles = try context.fetch(profileDescriptor)

        #expect(profiles.count == 1, "Should create one medication profile")
        #expect(profiles.first?.genericName == "semaglutide", "Should be semaglutide")
        #expect(profiles.first?.brandName == "Ozempic", "Should be Ozempic")
        #expect(profiles.first?.currentDose == 1.0, "Should have 1.0mg current dose")
    }

    @Test("seedTitrationTestData creates test dose")
    @MainActor
    func seedTitrationTestDataCreatesTestDose() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Create a test user first
        let testUser = User(email: "test@example.com", name: "Test User")
        context.insert(testUser)
        try context.save()

        // Seed test data
        controller.seedTitrationTestData()

        // Verify dose was created
        let doseDescriptor = FetchDescriptor<Dose>()
        let doses = try context.fetch(doseDescriptor)

        #expect(doses.count == 1, "Should create one test dose")
        #expect(doses.first?.amount == 1.0, "Dose amount should be 1.0mg")
        #expect(doses.first?.site == "Abdomen", "Injection site should be Abdomen")
    }

    @Test("seedTitrationTestData creates dose schedule")
    @MainActor
    func seedTitrationTestDataCreatesSchedule() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Create a test user first
        let testUser = User(email: "test@example.com", name: "Test User")
        context.insert(testUser)
        try context.save()

        // Seed test data
        controller.seedTitrationTestData()

        // Verify schedule was created
        let scheduleDescriptor = FetchDescriptor<DoseSchedule>()
        let schedules = try context.fetch(scheduleDescriptor)

        #expect(schedules.count == 1, "Should create one dose schedule")
        #expect(schedules.first?.patternType == .weekly, "Should be weekly schedule")
        #expect(schedules.first?.isActive == true, "Should be active")
    }

    @Test("seedTitrationTestData creates multiple titrations")
    @MainActor
    func seedTitrationTestDataCreatesTitrations() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Create a test user first
        let testUser = User(email: "test@example.com", name: "Test User")
        context.insert(testUser)
        try context.save()

        // Seed test data
        controller.seedTitrationTestData()

        // Verify titrations were created
        let titrationDescriptor = FetchDescriptor<DoseTitration>()
        let titrations = try context.fetch(titrationDescriptor)

        #expect(titrations.count == 3, "Should create 3 titrations (today, tomorrow, next week)")

        // Verify doses are correct
        let doses = titrations.map { $0.fromDose }.sorted()
        #expect(doses == [1.0, 2.0, 3.0], "Titrations should have correct from doses")

        let toDoses = titrations.map { $0.toDose }.sorted()
        #expect(toDoses == [2.0, 3.0, 4.0], "Titrations should have correct to doses")

        // Verify all are incomplete
        let incompleteTitrations = titrations.filter { !$0.isCompleted }
        #expect(
            incompleteTitrations.count == 3, "All titrations should be incomplete initially")
    }

    @Test("seedTitrationTestData does not duplicate data")
    @MainActor
    func seedTitrationTestDataDoesNotDuplicate() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Create a test user first
        let testUser = User(email: "test@example.com", name: "Test User")
        context.insert(testUser)
        try context.save()

        // Seed test data twice
        controller.seedTitrationTestData()
        controller.seedTitrationTestData()

        // Verify data was only created once
        let titrationDescriptor = FetchDescriptor<DoseTitration>()
        let titrations = try context.fetch(titrationDescriptor)

        #expect(
            titrations.count == 3,
            "Should still have 3 titrations (not duplicated)")
    }

    @Test("seedTitrationTestData requires existing user")
    @MainActor
    func seedTitrationTestDataRequiresUser() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Don't create a user - should fail gracefully
        controller.seedTitrationTestData()

        // Verify nothing was created
        let profileDescriptor = FetchDescriptor<MedicationProfile>()
        let profiles = try context.fetch(profileDescriptor)

        #expect(profiles.isEmpty, "Should not create profiles without a user")
    }

    @Test("seedTitrationTestData today titration has correct date")
    @MainActor
    func seedTitrationTestDataTodayTitrationDate() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Create a test user first
        let testUser = User(email: "test@example.com", name: "Test User")
        context.insert(testUser)
        try context.save()

        // Seed test data
        controller.seedTitrationTestData()

        // Find today's titration
        let titrationDescriptor = FetchDescriptor<DoseTitration>()
        let titrations = try context.fetch(titrationDescriptor)
        let todayTitration = titrations.first { $0.fromDose == 1.0 }

        #expect(todayTitration != nil, "Should have today's titration")

        // Verify date is today using robust same-day check
        guard let titration = todayTitration else {
            #expect(Bool(false), "todayTitration was nil")
            return
        }

        let today = Date()
        #expect(
            Calendar.current.isDate(titration.scheduledDate, inSameDayAs: today),
            "Today's titration should be scheduled for today")
    }

    @Test("seedTitrationTestData tomorrow titration has correct date")
    @MainActor
    func seedTitrationTestDataTomorrowTitrationDate() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Create a test user first
        let testUser = User(email: "test@example.com", name: "Test User")
        context.insert(testUser)
        try context.save()

        // Seed test data
        controller.seedTitrationTestData()

        // Find tomorrow's titration
        let titrationDescriptor = FetchDescriptor<DoseTitration>()
        let titrations = try context.fetch(titrationDescriptor)
        let tomorrowTitration = titrations.first { $0.fromDose == 2.0 }

        #expect(tomorrowTitration != nil, "Should have tomorrow's titration")

        // Verify date is tomorrow (at start of day)
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else {
            #expect(Bool(false), "Failed to calculate tomorrow's date")
            return
        }

        guard let titration = tomorrowTitration else {
            #expect(Bool(false), "tomorrowTitration was nil")
            return
        }

        let tomorrowMidnight = Calendar.current.startOfDay(for: tomorrow)

        // Use absolute value to ensure scheduled date is within 60 seconds of midnight
        let timeInterval = abs(titration.scheduledDate.timeIntervalSince(tomorrowMidnight))
        #expect(
            timeInterval < 60,
            "Tomorrow's titration should be scheduled for tomorrow (within 60s of midnight)")
    }

    @Test("seedTitrationTestData next week titration has correct date")
    @MainActor
    func seedTitrationTestDataNextWeekTitrationDate() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Create a test user first
        let testUser = User(email: "test@example.com", name: "Test User")
        context.insert(testUser)
        try context.save()

        // Seed test data
        controller.seedTitrationTestData()

        // Find next week's titration
        let titrationDescriptor = FetchDescriptor<DoseTitration>()
        let titrations = try context.fetch(titrationDescriptor)
        let nextWeekTitration = titrations.first { $0.fromDose == 3.0 }

        #expect(nextWeekTitration != nil, "Should have next week's titration")

        // Verify date is next week (at start of day)
        guard let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date()) else {
            #expect(Bool(false), "Failed to calculate next week's date")
            return
        }

        guard let titration = nextWeekTitration else {
            #expect(Bool(false), "nextWeekTitration was nil")
            return
        }

        let nextWeekMidnight = Calendar.current.startOfDay(for: nextWeek)

        // Use absolute value to ensure scheduled date is within 60 seconds of midnight
        let timeInterval = abs(titration.scheduledDate.timeIntervalSince(nextWeekMidnight))
        #expect(
            timeInterval < 60,
            "Next week's titration should be scheduled for 7 days from now (within 60s of midnight)")
    }
}
