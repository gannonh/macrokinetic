//
//  MetricsServiceTests.swift
//  JabTrackerTests
//
//  Tests for MetricsService - CRUD operations for body metrics.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("MetricsService Tests")
@MainActor
struct MetricsServiceTests {

    // MARK: - Test Helpers

    private func createTestContext() -> ModelContext {
        let schema = Schema([MetricsEntry.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func createWeightTestContext() -> ModelContext {
        let schema = Schema([WeightEntry.self, User.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func createTestUser(in context: ModelContext, weightUnit: String = "kg") -> User {
        let user = User(
            email: "test@example.com",
            name: "Test User",
            weight: 70.0,
            weightUnit: weightUnit,
            healthSyncEnabled: false
        )
        context.insert(user)
        return user
    }

    // MARK: - Log Metrics Tests

    @Test("Log metrics creates entry with waist measurement")
    func testLogMetricsCreatesEntryWithWaist() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let entry = try await service.logMetrics(waistCm: 80.0)

        #expect(entry.waistCm == 80.0)
        #expect(entry.hipCm == nil)
        #expect(entry.chestCm == nil)
        #expect(entry.neckCm == nil)
        #expect(entry.source == "manual")
    }

    @Test("Log metrics creates entry with all measurements")
    func testLogMetricsAllMeasurements() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let entry = try await service.logMetrics(
            waistCm: 80.0,
            hipCm: 95.0,
            chestCm: 100.0,
            neckCm: 38.0,
            notes: "Morning measurement"
        )

        #expect(entry.waistCm == 80.0)
        #expect(entry.hipCm == 95.0)
        #expect(entry.chestCm == 100.0)
        #expect(entry.neckCm == 38.0)
        #expect(entry.notes == "Morning measurement")
    }

    @Test("Log metrics persists entry to context")
    func testLogMetricsPersists() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        _ = try await service.logMetrics(waistCm: 80.0)

        let descriptor = FetchDescriptor<MetricsEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        #expect(entries.first?.waistCm == 80.0)
    }

    @Test("Log metrics uses provided timestamp")
    func testLogMetricsUsesTimestamp() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let customDate = Date().addingTimeInterval(-3600)
        let entry = try await service.logMetrics(waistCm: 80.0, timestamp: customDate)

        #expect(entry.timestamp == customDate)
    }

    // MARK: - Validation Tests

    @Test("Log metrics throws when no measurements provided")
    func testLogMetricsThrowsNoMeasurements() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        await #expect(throws: MetricsServiceError.self) {
            _ = try await service.logMetrics()
        }
    }

    @Test("Log metrics throws for waist below minimum")
    func testLogMetricsThrowsWaistBelowMin() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        await #expect(throws: MetricsServiceError.self) {
            _ = try await service.logMetrics(waistCm: 5.0)
        }
    }

    @Test("Log metrics throws for waist above maximum")
    func testLogMetricsThrowsWaistAboveMax() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        await #expect(throws: MetricsServiceError.self) {
            _ = try await service.logMetrics(waistCm: 500.0)
        }
    }

    @Test("Log metrics throws for hip below minimum")
    func testLogMetricsThrowsHipBelowMin() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        await #expect(throws: MetricsServiceError.self) {
            _ = try await service.logMetrics(hipCm: 5.0)
        }
    }

    @Test("Log metrics throws for chest below minimum")
    func testLogMetricsThrowsChestBelowMin() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        await #expect(throws: MetricsServiceError.self) {
            _ = try await service.logMetrics(chestCm: 5.0)
        }
    }

    @Test("Log metrics throws for neck below minimum")
    func testLogMetricsThrowsNeckBelowMin() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        await #expect(throws: MetricsServiceError.self) {
            _ = try await service.logMetrics(neckCm: 5.0)
        }
    }

    @Test("Log metrics accepts values at boundaries")
    func testLogMetricsAcceptsBoundaries() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let entryMin = try await service.logMetrics(waistCm: 10.0)
        let entryMax = try await service.logMetrics(waistCm: 300.0)

        #expect(entryMin.waistCm == 10.0)
        #expect(entryMax.waistCm == 300.0)
    }

    // MARK: - Get Latest Entry Tests

    @Test("Get latest entry returns most recent by timestamp")
    func testGetLatestEntryReturnsMostRecent() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let now = Date()
        _ = try await service.logMetrics(waistCm: 80.0, timestamp: now.addingTimeInterval(-3600))
        _ = try await service.logMetrics(waistCm: 82.0, timestamp: now.addingTimeInterval(-1800))
        _ = try await service.logMetrics(waistCm: 81.0, timestamp: now)

        let latest = try await service.getLatestEntry()

        #expect(latest?.waistCm == 81.0)
    }

    @Test("Get latest entry returns nil when no entries exist")
    func testGetLatestEntryReturnsNilWhenEmpty() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let latest = try await service.getLatestEntry()

        #expect(latest == nil)
    }

    // MARK: - Get Entries by Date Range Tests

    @Test("Get entries filters by date range")
    func testGetEntriesFiltersByDateRange() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172_800)

        _ = try await service.logMetrics(waistCm: 80.0, timestamp: twoDaysAgo)
        _ = try await service.logMetrics(waistCm: 81.0, timestamp: yesterday)
        _ = try await service.logMetrics(waistCm: 82.0, timestamp: now)

        let startOfYesterday = Calendar.current.startOfDay(for: yesterday)
        let endOfYesterday = Calendar.current.date(byAdding: .day, value: 1, to: startOfYesterday)!

        let entries = try await service.getEntries(from: startOfYesterday, to: endOfYesterday)

        #expect(entries.count == 1)
        #expect(entries.first?.waistCm == 81.0)
    }

    @Test("Get entries returns empty array when no entries in range")
    func testGetEntriesReturnsEmptyForNoMatches() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let now = Date()
        _ = try await service.logMetrics(waistCm: 80.0, timestamp: now)

        let nextWeek = now.addingTimeInterval(604_800)
        let entries = try await service.getEntries(from: nextWeek, to: nextWeek.addingTimeInterval(86400))

        #expect(entries.isEmpty)
    }

    // MARK: - Get All Entries Tests

    @Test("Get all entries returns all entries sorted by timestamp")
    func testGetAllEntriesReturnsAll() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let now = Date()
        _ = try await service.logMetrics(waistCm: 80.0, timestamp: now.addingTimeInterval(-7200))
        _ = try await service.logMetrics(waistCm: 81.0, timestamp: now.addingTimeInterval(-3600))
        _ = try await service.logMetrics(waistCm: 82.0, timestamp: now)

        let entries = try await service.getAllEntries()

        #expect(entries.count == 3)
        #expect(entries[0].waistCm == 82.0)  // Most recent first
    }

    @Test("Get all entries respects limit")
    func testGetAllEntriesRespectsLimit() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let now = Date()
        for index in 0..<5 {
            _ = try await service.logMetrics(
                waistCm: Double(80 + index),
                timestamp: now.addingTimeInterval(Double(-index * 3600))
            )
        }

        let entries = try await service.getAllEntries(limit: 3)

        #expect(entries.count == 3)
    }

    // MARK: - Update Entry Tests

    @Test("Update entry modifies waist")
    func testUpdateEntryModifiesWaist() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let entry = try await service.logMetrics(waistCm: 80.0)

        try await service.updateEntry(entry, waistCm: 82.0)

        #expect(entry.waistCm == 82.0)
    }

    @Test("Update entry modifies hip")
    func testUpdateEntryModifiesHip() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let entry = try await service.logMetrics(waistCm: 80.0)

        try await service.updateEntry(entry, hipCm: 95.0)

        #expect(entry.hipCm == 95.0)
    }

    @Test("Update entry can clear a measurement")
    func testUpdateEntryCanClearMeasurement() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let entry = try await service.logMetrics(waistCm: 80.0, hipCm: 95.0)

        try await service.updateEntry(entry, hipCm: .some(nil))

        #expect(entry.hipCm == nil)
        #expect(entry.waistCm == 80.0)  // Other measurement preserved
    }

    @Test("Update entry modifies notes")
    func testUpdateEntryModifiesNotes() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let entry = try await service.logMetrics(waistCm: 80.0)

        try await service.updateEntry(entry, notes: "Updated note")

        #expect(entry.notes == "Updated note")
    }

    @Test("Update entry validates measurement")
    func testUpdateEntryValidatesMeasurement() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let entry = try await service.logMetrics(waistCm: 80.0)

        await #expect(throws: MetricsServiceError.self) {
            try await service.updateEntry(entry, waistCm: 5.0)
        }
    }

    @Test("Update entry throws when all measurements cleared")
    func testUpdateEntryThrowsWhenAllCleared() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let entry = try await service.logMetrics(waistCm: 80.0)

        await #expect(throws: MetricsServiceError.self) {
            try await service.updateEntry(entry, waistCm: .some(nil))
        }
    }

    @Test("Update entry preserves state on validation failure")
    func testUpdateEntryPreservesStateOnValidationFailure() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let entry = try await service.logMetrics(waistCm: 80.0)
        let originalWaist = entry.waistCm

        // Try to clear the only measurement (should fail)
        do {
            try await service.updateEntry(entry, waistCm: .some(nil))
            Issue.record("Expected updateEntry to throw when clearing all measurements")
        } catch {
            // Expected: validation error thrown
        }

        // Verify original value is preserved after failed update
        #expect(entry.waistCm == originalWaist)
    }

    @Test("Update entry preserves state on range validation failure")
    func testUpdateEntryPreservesStateOnRangeValidationFailure() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let entry = try await service.logMetrics(waistCm: 80.0, hipCm: 95.0)
        let originalWaist = entry.waistCm
        let originalHip = entry.hipCm

        // Try to set invalid waist value (should fail)
        do {
            try await service.updateEntry(entry, waistCm: 5.0)  // Below minimum
            Issue.record("Expected updateEntry to throw for invalid range")
        } catch {
            // Expected: validation error thrown
        }

        // Verify original values are preserved after failed update
        #expect(entry.waistCm == originalWaist)
        #expect(entry.hipCm == originalHip)
    }

    // MARK: - Delete Entry Tests

    @Test("Delete entry removes from context")
    func testDeleteEntryRemovesFromContext() async throws {
        let context = createTestContext()
        let service = MetricsService(context: context)

        let entry = try await service.logMetrics(waistCm: 80.0)
        let entryId = entry.id

        try await service.deleteEntry(entry)

        let descriptor = FetchDescriptor<MetricsEntry>(
            predicate: #Predicate { $0.id == entryId }
        )
        let found = try context.fetch(descriptor)

        #expect(found.isEmpty)
    }

    // MARK: - Error Tests

    @Test("MetricsServiceError.invalidMeasurement has correct description")
    func testInvalidMeasurementErrorDescription() throws {
        let error = MetricsServiceError.invalidMeasurement("Test message")

        #expect(error.errorDescription?.contains("Invalid measurement") == true)
        #expect(error.errorDescription?.contains("Test message") == true)
    }

    @Test("MetricsServiceError.noEntriesFound has correct description")
    func testNoEntriesFoundErrorDescription() throws {
        let error = MetricsServiceError.noEntriesFound

        #expect(error.errorDescription == "No entries found")
    }

    @Test("MetricsServiceError.contextError has correct description")
    func testContextErrorDescription() throws {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        let error = MetricsServiceError.contextError(underlyingError)

        #expect(error.errorDescription?.contains("Database error") == true)
    }

    @Test("MetricsServiceError.invalidWeight has correct description")
    func testInvalidWeightErrorDescription() throws {
        let error = MetricsServiceError.invalidWeight("Test weight message")

        #expect(error.errorDescription?.contains("Invalid weight") == true)
        #expect(error.errorDescription?.contains("Test weight message") == true)
    }

    // MARK: - Log Weight Tests

    @Test("Log weight creates entry with valid weight in kg")
    func testLogWeightCreatesEntryKg() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context, weightUnit: "kg")

        let entry = try await service.logWeight(weightKg: 75.0, for: user)

        #expect(entry.weightKg == 75.0)
        #expect(entry.source == "manual")
        #expect(entry.bodyFatPercentage == nil)
        #expect(user.weight == 75.0)
    }

    @Test("Log weight creates entry with body fat percentage")
    func testLogWeightWithBodyFat() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entry = try await service.logWeight(weightKg: 80.0, bodyFat: 15.5, for: user)

        #expect(entry.weightKg == 80.0)
        #expect(entry.bodyFatPercentage == 15.5)
    }

    @Test("Log weight updates user weight in lbs when user prefers lbs")
    func testLogWeightUpdatesUserWeightInLbs() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context, weightUnit: "lbs")

        _ = try await service.logWeight(weightKg: 70.0, for: user)

        // User weight should be stored in lbs
        let expectedLbs = 70.0 * WeightEntry.kgToLbsConversion
        #expect(abs(user.weight - expectedLbs) < 0.01)
    }

    @Test("Log weight persists entry to context")
    func testLogWeightPersists() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        _ = try await service.logWeight(weightKg: 85.0, for: user)

        let descriptor = FetchDescriptor<WeightEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        #expect(entries.first?.weightKg == 85.0)
    }

    @Test("Log weight uses provided timestamp")
    func testLogWeightUsesTimestamp() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let customDate = Date().addingTimeInterval(-3600)
        let entry = try await service.logWeight(weightKg: 75.0, for: user, timestamp: customDate)

        #expect(entry.timestamp == customDate)
    }

    @Test("Log weight includes notes")
    func testLogWeightWithNotes() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entry = try await service.logWeight(weightKg: 75.0, for: user, notes: "Morning weigh-in")

        #expect(entry.notes == "Morning weigh-in")
    }

    @Test("Log weight throws for weight below minimum")
    func testLogWeightThrowsBelowMin() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        await #expect(throws: MetricsServiceError.self) {
            _ = try await service.logWeight(weightKg: 10.0, for: user)
        }
    }

    @Test("Log weight throws for weight above maximum")
    func testLogWeightThrowsAboveMax() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        await #expect(throws: MetricsServiceError.self) {
            _ = try await service.logWeight(weightKg: 600.0, for: user)
        }
    }

    @Test("Log weight throws for body fat below minimum")
    func testLogWeightThrowsBodyFatBelowMin() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        await #expect(throws: MetricsServiceError.self) {
            _ = try await service.logWeight(weightKg: 75.0, bodyFat: -5.0, for: user)
        }
    }

    @Test("Log weight throws for body fat above maximum")
    func testLogWeightThrowsBodyFatAboveMax() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        await #expect(throws: MetricsServiceError.self) {
            _ = try await service.logWeight(weightKg: 75.0, bodyFat: 105.0, for: user)
        }
    }

    @Test("Log weight accepts values at boundaries")
    func testLogWeightAcceptsBoundaries() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entryMin = try await service.logWeight(weightKg: 20.0, for: user)
        let entryMax = try await service.logWeight(weightKg: 500.0, for: user)

        #expect(entryMin.weightKg == 20.0)
        #expect(entryMax.weightKg == 500.0)
    }

    @Test("Log weight accepts body fat at boundaries")
    func testLogWeightAcceptsBodyFatBoundaries() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entryMin = try await service.logWeight(weightKg: 75.0, bodyFat: 0.0, for: user)
        let entryMax = try await service.logWeight(weightKg: 75.0, bodyFat: 100.0, for: user)

        #expect(entryMin.bodyFatPercentage == 0.0)
        #expect(entryMax.bodyFatPercentage == 100.0)
    }

    // MARK: - Get Latest Weight Entry Tests

    @Test("Get latest weight entry returns most recent by timestamp")
    func testGetLatestWeightEntryReturnsMostRecent() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let now = Date()
        _ = try await service.logWeight(weightKg: 70.0, for: user, timestamp: now.addingTimeInterval(-3600))
        _ = try await service.logWeight(weightKg: 72.0, for: user, timestamp: now.addingTimeInterval(-1800))
        _ = try await service.logWeight(weightKg: 71.0, for: user, timestamp: now)

        let latest = try await service.getLatestWeightEntry()

        #expect(latest?.weightKg == 71.0)
    }

    @Test("Get latest weight entry returns nil when no entries exist")
    func testGetLatestWeightEntryReturnsNilWhenEmpty() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)

        let latest = try await service.getLatestWeightEntry()

        #expect(latest == nil)
    }

    // MARK: - Get Weight Entries by Date Range Tests

    @Test("Get weight entries filters by date range")
    func testGetWeightEntriesFiltersByDateRange() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172_800)

        _ = try await service.logWeight(weightKg: 70.0, for: user, timestamp: twoDaysAgo)
        _ = try await service.logWeight(weightKg: 71.0, for: user, timestamp: yesterday)
        _ = try await service.logWeight(weightKg: 72.0, for: user, timestamp: now)

        let startOfYesterday = Calendar.current.startOfDay(for: yesterday)
        let endOfYesterday = Calendar.current.date(byAdding: .day, value: 1, to: startOfYesterday)!

        let entries = try await service.getWeightEntries(from: startOfYesterday, to: endOfYesterday)

        #expect(entries.count == 1)
        #expect(entries.first?.weightKg == 71.0)
    }

    @Test("Get weight entries returns empty array when no entries in range")
    func testGetWeightEntriesReturnsEmptyForNoMatches() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let now = Date()
        _ = try await service.logWeight(weightKg: 70.0, for: user, timestamp: now)

        let nextWeek = now.addingTimeInterval(604_800)
        let entries = try await service.getWeightEntries(from: nextWeek, to: nextWeek.addingTimeInterval(86400))

        #expect(entries.isEmpty)
    }

    // MARK: - Get All Weight Entries Tests

    @Test("Get all weight entries returns all entries sorted by timestamp")
    func testGetAllWeightEntriesReturnsAll() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let now = Date()
        _ = try await service.logWeight(weightKg: 70.0, for: user, timestamp: now.addingTimeInterval(-7200))
        _ = try await service.logWeight(weightKg: 71.0, for: user, timestamp: now.addingTimeInterval(-3600))
        _ = try await service.logWeight(weightKg: 72.0, for: user, timestamp: now)

        let entries = try await service.getAllWeightEntries()

        #expect(entries.count == 3)
        #expect(entries[0].weightKg == 72.0)  // Most recent first
    }

    @Test("Get all weight entries respects limit")
    func testGetAllWeightEntriesRespectsLimit() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let now = Date()
        for index in 0..<5 {
            _ = try await service.logWeight(
                weightKg: Double(70 + index),
                for: user,
                timestamp: now.addingTimeInterval(Double(-index * 3600))
            )
        }

        let entries = try await service.getAllWeightEntries(limit: 3)

        #expect(entries.count == 3)
    }

    @Test("Get all weight entries with no limit returns all")
    func testGetAllWeightEntriesNoLimit() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let now = Date()
        for index in 0..<10 {
            _ = try await service.logWeight(
                weightKg: Double(70 + index),
                for: user,
                timestamp: now.addingTimeInterval(Double(-index * 3600))
            )
        }

        let entries = try await service.getAllWeightEntries(limit: nil)

        #expect(entries.count == 10)
    }

    // MARK: - Update Weight Entry Tests

    @Test("Update weight entry modifies weight")
    func testUpdateWeightEntryModifiesWeight() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entry = try await service.logWeight(weightKg: 70.0, for: user)

        try await service.updateWeightEntry(entry, weightKg: 72.0)

        #expect(entry.weightKg == 72.0)
    }

    @Test("Update weight entry modifies body fat")
    func testUpdateWeightEntryModifiesBodyFat() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entry = try await service.logWeight(weightKg: 70.0, for: user)

        try await service.updateWeightEntry(entry, bodyFat: 18.5)

        #expect(entry.bodyFatPercentage == 18.5)
    }

    @Test("Update weight entry can clear body fat")
    func testUpdateWeightEntryCanClearBodyFat() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entry = try await service.logWeight(weightKg: 70.0, bodyFat: 20.0, for: user)

        try await service.updateWeightEntry(entry, bodyFat: .some(nil))

        #expect(entry.bodyFatPercentage == nil)
    }

    @Test("Update weight entry modifies notes")
    func testUpdateWeightEntryModifiesNotes() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entry = try await service.logWeight(weightKg: 70.0, for: user)

        try await service.updateWeightEntry(entry, notes: "Updated note")

        #expect(entry.notes == "Updated note")
    }

    @Test("Update weight entry can clear notes")
    func testUpdateWeightEntryCanClearNotes() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entry = try await service.logWeight(weightKg: 70.0, for: user, notes: "Original note")

        try await service.updateWeightEntry(entry, notes: .some(nil))

        #expect(entry.notes == nil)
    }

    @Test("Update weight entry validates weight range")
    func testUpdateWeightEntryValidatesWeightRange() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entry = try await service.logWeight(weightKg: 70.0, for: user)

        await #expect(throws: MetricsServiceError.self) {
            try await service.updateWeightEntry(entry, weightKg: 10.0)
        }
    }

    @Test("Update weight entry validates body fat range")
    func testUpdateWeightEntryValidatesBodyFatRange() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entry = try await service.logWeight(weightKg: 70.0, for: user)

        await #expect(throws: MetricsServiceError.self) {
            try await service.updateWeightEntry(entry, bodyFat: 105.0)
        }
    }

    // MARK: - Delete Weight Entry Tests

    @Test("Delete weight entry removes from context")
    func testDeleteWeightEntryRemovesFromContext() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entry = try await service.logWeight(weightKg: 70.0, for: user)
        let entryId = entry.id

        try await service.deleteWeightEntry(entry)

        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate { $0.id == entryId }
        )
        let found = try context.fetch(descriptor)

        #expect(found.isEmpty)
    }

    @Test("Delete weight entry logs deletion")
    func testDeleteWeightEntryLogs() async throws {
        let context = createWeightTestContext()
        let service = MetricsService(context: context)
        let user = createTestUser(in: context)

        let entry = try await service.logWeight(weightKg: 75.0, for: user)

        // Should complete without throwing
        try await service.deleteWeightEntry(entry)

        let descriptor = FetchDescriptor<WeightEntry>()
        let remaining = try context.fetch(descriptor)

        #expect(remaining.isEmpty)
    }
}
