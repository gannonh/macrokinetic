//
//  WeightServiceTests.swift
//  JabTrackerTests
//
//  Tests for WeightService - CRUD operations and queries for WeightEntry
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Tests for WeightService
/// Verifies CRUD operations, date-based queries, and User.weight sync
@Suite("WeightService Tests")
@MainActor
struct WeightServiceTests {

    // MARK: - Log Weight Tests

    @Test("Log weight creates entry with correct values")
    func testLogWeightCreatesEntry() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let entry = try await service.logWeight(
            weightKg: 75.5,
            bodyFat: 22.0,
            timestamp: Date(),
            notes: "Morning weigh-in"
        )

        #expect(entry.weightKg == 75.5)
        #expect(entry.bodyFatPercentage == 22.0)
        #expect(entry.source == "manual")
        #expect(entry.notes == "Morning weigh-in")
    }

    @Test("Log weight persists entry to context")
    func testLogWeightPersistsEntry() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        _ = try await service.logWeight(weightKg: 70.0)

        let descriptor = FetchDescriptor<WeightEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        #expect(entries.first?.weightKg == 70.0)
    }

    @Test("Log weight without body fat leaves bodyFatPercentage nil")
    func testLogWeightWithoutBodyFat() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let entry = try await service.logWeight(weightKg: 72.0)

        #expect(entry.bodyFatPercentage == nil)
    }

    @Test("Log weight uses provided timestamp")
    func testLogWeightUsesProvidedTimestamp() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let customDate = Date().addingTimeInterval(-3600)
        let entry = try await service.logWeight(weightKg: 70.0, timestamp: customDate)

        #expect(entry.timestamp == customDate)
    }

    // MARK: - Validation Tests

    @Test("Log weight throws for weight below minimum")
    func testLogWeightThrowsForBelowMinimum() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        await #expect(throws: WeightServiceError.self) {
            _ = try await service.logWeight(weightKg: 19.9)
        }
    }

    @Test("Log weight throws for weight above maximum")
    func testLogWeightThrowsForAboveMaximum() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        await #expect(throws: WeightServiceError.self) {
            _ = try await service.logWeight(weightKg: 500.1)
        }
    }

    @Test("Log weight throws for zero weight")
    func testLogWeightThrowsForZeroWeight() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        await #expect(throws: WeightServiceError.self) {
            _ = try await service.logWeight(weightKg: 0)
        }
    }

    @Test("Log weight throws for negative weight")
    func testLogWeightThrowsForNegativeWeight() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        await #expect(throws: WeightServiceError.self) {
            _ = try await service.logWeight(weightKg: -10.0)
        }
    }

    @Test("Log weight accepts weight at minimum boundary")
    func testLogWeightAcceptsMinBoundary() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let entry = try await service.logWeight(weightKg: 20.0)

        #expect(entry.weightKg == 20.0)
    }

    @Test("Log weight accepts weight at maximum boundary")
    func testLogWeightAcceptsMaxBoundary() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let entry = try await service.logWeight(weightKg: 500.0)

        #expect(entry.weightKg == 500.0)
    }

    @Test("Log weight throws for body fat below zero")
    func testLogWeightThrowsForNegativeBodyFat() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        await #expect(throws: WeightServiceError.self) {
            _ = try await service.logWeight(weightKg: 70.0, bodyFat: -1.0)
        }
    }

    @Test("Log weight throws for body fat above 100")
    func testLogWeightThrowsForBodyFatOver100() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        await #expect(throws: WeightServiceError.self) {
            _ = try await service.logWeight(weightKg: 70.0, bodyFat: 100.1)
        }
    }

    @Test("Log weight accepts body fat at boundaries")
    func testLogWeightAcceptsBodyFatBoundaries() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let entryZero = try await service.logWeight(weightKg: 70.0, bodyFat: 0.0)
        let entry100 = try await service.logWeight(weightKg: 70.0, bodyFat: 100.0)

        #expect(entryZero.bodyFatPercentage == 0.0)
        #expect(entry100.bodyFatPercentage == 100.0)
    }

    // MARK: - Get Latest Entry Tests

    @Test("Get latest entry returns most recent by timestamp")
    func testGetLatestEntryReturnsMostRecent() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let now = Date()
        _ = try await service.logWeight(weightKg: 70.0, timestamp: now.addingTimeInterval(-3600))
        _ = try await service.logWeight(weightKg: 72.0, timestamp: now.addingTimeInterval(-1800))
        _ = try await service.logWeight(weightKg: 71.0, timestamp: now)

        let latest = try await service.getLatestEntry()

        #expect(latest?.weightKg == 71.0)
    }

    @Test("Get latest entry returns nil when no entries exist")
    func testGetLatestEntryReturnsNilWhenEmpty() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let latest = try await service.getLatestEntry()

        #expect(latest == nil)
    }

    // MARK: - Get Entries by Date Range Tests

    @Test("Get entries filters by date range")
    func testGetEntriesFiltersByDateRange() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172_800)

        _ = try await service.logWeight(weightKg: 70.0, timestamp: twoDaysAgo)
        _ = try await service.logWeight(weightKg: 71.0, timestamp: yesterday)
        _ = try await service.logWeight(weightKg: 72.0, timestamp: now)

        // Get only yesterday's entries
        let startOfYesterday = Calendar.current.startOfDay(for: yesterday)
        let endOfYesterday = Calendar.current.date(byAdding: .day, value: 1, to: startOfYesterday)!

        let entries = try await service.getEntries(from: startOfYesterday, to: endOfYesterday)

        #expect(entries.count == 1)
        #expect(entries.first?.weightKg == 71.0)
    }

    @Test("Get entries returns empty array when no entries in range")
    func testGetEntriesReturnsEmptyForNoMatches() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let now = Date()
        _ = try await service.logWeight(weightKg: 70.0, timestamp: now)

        // Query for next week (no entries)
        let nextWeek = now.addingTimeInterval(604_800)
        let entries = try await service.getEntries(from: nextWeek, to: nextWeek.addingTimeInterval(86400))

        #expect(entries.isEmpty)
    }

    @Test("Get entries sorts by timestamp descending")
    func testGetEntriesSortsByTimestampDescending() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let now = Date()
        _ = try await service.logWeight(weightKg: 70.0, timestamp: now.addingTimeInterval(-3600))
        _ = try await service.logWeight(weightKg: 72.0, timestamp: now)
        _ = try await service.logWeight(weightKg: 71.0, timestamp: now.addingTimeInterval(-1800))

        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let entries = try await service.getEntries(from: startOfDay, to: endOfDay)

        #expect(entries.count == 3)
        #expect(entries[0].weightKg == 72.0)  // Most recent first
        #expect(entries[1].weightKg == 71.0)
        #expect(entries[2].weightKg == 70.0)
    }

    // MARK: - Get All Entries Tests

    @Test("Get all entries returns all entries sorted by timestamp")
    func testGetAllEntriesReturnsAll() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let now = Date()
        _ = try await service.logWeight(weightKg: 70.0, timestamp: now.addingTimeInterval(-7200))
        _ = try await service.logWeight(weightKg: 71.0, timestamp: now.addingTimeInterval(-3600))
        _ = try await service.logWeight(weightKg: 72.0, timestamp: now)

        let entries = try await service.getAllEntries()

        #expect(entries.count == 3)
        #expect(entries[0].weightKg == 72.0)  // Most recent first
    }

    @Test("Get all entries respects limit")
    func testGetAllEntriesRespectsLimit() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let now = Date()
        for index in 0..<5 {
            _ = try await service.logWeight(
                weightKg: Double(70 + index),
                timestamp: now.addingTimeInterval(Double(-index * 3600))
            )
        }

        let entries = try await service.getAllEntries(limit: 3)

        #expect(entries.count == 3)
    }

    // MARK: - Update Entry Tests

    @Test("Update entry modifies weight")
    func testUpdateEntryModifiesWeight() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let entry = try await service.logWeight(weightKg: 70.0)

        try await service.updateEntry(entry, weightKg: 72.5)

        #expect(entry.weightKg == 72.5)
    }

    @Test("Update entry modifies body fat")
    func testUpdateEntryModifiesBodyFat() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let entry = try await service.logWeight(weightKg: 70.0, bodyFat: 20.0)

        try await service.updateEntry(entry, bodyFat: 22.0)

        #expect(entry.bodyFatPercentage == 22.0)
    }

    @Test("Update entry can clear body fat")
    func testUpdateEntryCanClearBodyFat() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let entry = try await service.logWeight(weightKg: 70.0, bodyFat: 20.0)

        try await service.updateEntry(entry, bodyFat: .some(nil))

        #expect(entry.bodyFatPercentage == nil)
    }

    @Test("Update entry modifies notes")
    func testUpdateEntryModifiesNotes() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let entry = try await service.logWeight(weightKg: 70.0)

        try await service.updateEntry(entry, notes: "Updated note")

        #expect(entry.notes == "Updated note")
    }

    @Test("Update entry validates weight")
    func testUpdateEntryValidatesWeight() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let entry = try await service.logWeight(weightKg: 70.0)

        await #expect(throws: WeightServiceError.self) {
            try await service.updateEntry(entry, weightKg: 10.0)
        }
    }

    @Test("Update entry validates body fat")
    func testUpdateEntryValidatesBodyFat() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let entry = try await service.logWeight(weightKg: 70.0)

        await #expect(throws: WeightServiceError.self) {
            try await service.updateEntry(entry, bodyFat: 150.0)
        }
    }

    // MARK: - Delete Entry Tests

    @Test("Delete entry removes from context")
    func testDeleteEntryRemovesFromContext() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        let entry = try await service.logWeight(weightKg: 70.0)
        let entryId = entry.id

        try await service.deleteEntry(entry)

        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate { $0.id == entryId }
        )
        let found = try context.fetch(descriptor)

        #expect(found.isEmpty)
    }

    // MARK: - Update User Weight Tests

    @Test("Update user weight syncs latest entry to User.weight")
    func testUpdateUserWeightSyncsLatest() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        // Create user
        let user = User()
        user.weight = 65.0
        context.insert(user)
        try context.save()

        // Log weight entries
        let now = Date()
        _ = try await service.logWeight(weightKg: 70.0, timestamp: now.addingTimeInterval(-3600))
        _ = try await service.logWeight(weightKg: 75.0, timestamp: now)

        // Update user weight
        try await service.updateUserWeight()

        #expect(user.weight == 75.0)
    }

    @Test("Update user weight throws when no entries exist")
    func testUpdateUserWeightThrowsWhenNoEntries() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        // Create user but no weight entries
        let user = User()
        context.insert(user)
        try context.save()

        await #expect(throws: WeightServiceError.self) {
            try await service.updateUserWeight()
        }
    }

    @Test("Update user weight handles no user gracefully")
    func testUpdateUserWeightHandlesNoUser() async throws {
        let context = createTestContext()
        let service = WeightService(context: context)

        // Log weight but no user
        _ = try await service.logWeight(weightKg: 70.0)

        // Should not throw - just logs warning and returns
        try await service.updateUserWeight()
    }

    // MARK: - Error Tests

    @Test("WeightServiceError.invalidWeight has correct description")
    func testInvalidWeightErrorDescription() throws {
        let error = WeightServiceError.invalidWeight("Weight must be positive")

        #expect(error.errorDescription?.contains("Invalid weight") == true)
    }

    @Test("WeightServiceError.noEntriesFound has correct description")
    func testNoEntriesFoundErrorDescription() throws {
        let error = WeightServiceError.noEntriesFound

        #expect(error.errorDescription == "No weight entries found")
    }

    // MARK: - Helper Methods

    private func createTestContext() -> ModelContext {
        let schema = Schema([
            User.self,
            WeightEntry.self,
            Dose.self,
            MedicationProfile.self,
            DoseTitration.self,
            Food.self,
            FoodEntry.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }
}
