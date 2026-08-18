//
//  ProgressPhotoServiceTests.swift
//  JabTrackerTests
//
//  Tests for ProgressPhotoService - CRUD operations for progress photos.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("ProgressPhotoService Tests")
@MainActor
struct ProgressPhotoServiceTests {

    // MARK: - Test Helpers

    private func createTestContext() -> ModelContext {
        let schema = Schema([ProgressPhoto.self])
        let configuration = InMemoryTestStore.configuration(schema: schema)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func createTestImageData() -> Data {
        // Simulated JPEG data
        Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])
    }

    // MARK: - Log Photo Tests

    @Test("Log photo creates entry with correct values")
    func testLogPhotoCreatesEntry() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        let entry = try await service.logPhoto(
            imageData: imageData,
            photoType: .front,
            notes: "Week 1 progress"
        )

        #expect(entry.imageData == imageData)
        #expect(entry.photoTypeEnum == .front)
        #expect(entry.notes == "Week 1 progress")
    }

    @Test("Log photo persists entry to context")
    func testLogPhotoPersists() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        _ = try await service.logPhoto(imageData: imageData, photoType: .side)

        let descriptor = FetchDescriptor<ProgressPhoto>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        #expect(entries.first?.photoTypeEnum == .side)
    }

    @Test("Log photo uses provided timestamp")
    func testLogPhotoUsesTimestamp() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let customDate = Date().addingTimeInterval(-3600)
        let imageData = createTestImageData()
        let entry = try await service.logPhoto(
            imageData: imageData,
            photoType: .front,
            timestamp: customDate
        )

        #expect(entry.timestamp == customDate)
    }

    @Test("Log photo throws for empty image data")
    func testLogPhotoThrowsForEmptyData() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        await #expect(throws: ProgressPhotoServiceError.self) {
            _ = try await service.logPhoto(imageData: Data(), photoType: .front)
        }
    }

    // MARK: - Get Latest Entry Tests

    @Test("Get latest entry returns most recent by timestamp")
    func testGetLatestEntryReturnsMostRecent() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        let now = Date()

        _ = try await service.logPhoto(
            imageData: imageData,
            photoType: .front,
            timestamp: now.addingTimeInterval(-3600)
        )
        _ = try await service.logPhoto(
            imageData: imageData,
            photoType: .side,
            timestamp: now.addingTimeInterval(-1800)
        )
        _ = try await service.logPhoto(
            imageData: imageData,
            photoType: .back,
            timestamp: now
        )

        let latest = try await service.getLatestEntry()

        #expect(latest?.photoTypeEnum == .back)
    }

    @Test("Get latest entry returns nil when no entries exist")
    func testGetLatestEntryReturnsNilWhenEmpty() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let latest = try await service.getLatestEntry()

        #expect(latest == nil)
    }

    // MARK: - Get Entries by Date Range Tests

    @Test("Get entries filters by date range")
    func testGetEntriesFiltersByDateRange() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172_800)

        _ = try await service.logPhoto(
            imageData: imageData,
            photoType: .front,
            timestamp: twoDaysAgo
        )
        _ = try await service.logPhoto(
            imageData: imageData,
            photoType: .side,
            timestamp: yesterday
        )
        _ = try await service.logPhoto(
            imageData: imageData,
            photoType: .back,
            timestamp: now
        )

        let startOfYesterday = Calendar.current.startOfDay(for: yesterday)
        let endOfYesterday = Calendar.current.date(byAdding: .day, value: 1, to: startOfYesterday)!

        let entries = try await service.getEntries(from: startOfYesterday, to: endOfYesterday)

        #expect(entries.count == 1)
        #expect(entries.first?.photoTypeEnum == .side)
    }

    @Test("Get entries returns empty array when no entries in range")
    func testGetEntriesReturnsEmptyForNoMatches() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        let now = Date()
        _ = try await service.logPhoto(imageData: imageData, photoType: .front, timestamp: now)

        let nextWeek = now.addingTimeInterval(604_800)
        let entries = try await service.getEntries(from: nextWeek, to: nextWeek.addingTimeInterval(86400))

        #expect(entries.isEmpty)
    }

    // MARK: - Get All Entries Tests

    @Test("Get all entries returns all entries sorted by timestamp")
    func testGetAllEntriesReturnsAll() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        let now = Date()

        _ = try await service.logPhoto(
            imageData: imageData,
            photoType: .front,
            timestamp: now.addingTimeInterval(-7200)
        )
        _ = try await service.logPhoto(
            imageData: imageData,
            photoType: .side,
            timestamp: now.addingTimeInterval(-3600)
        )
        _ = try await service.logPhoto(
            imageData: imageData,
            photoType: .back,
            timestamp: now
        )

        let entries = try await service.getAllEntries()

        #expect(entries.count == 3)
        #expect(entries[0].photoTypeEnum == .back)  // Most recent first
    }

    @Test("Get all entries respects limit")
    func testGetAllEntriesRespectsLimit() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        let now = Date()

        for index in 0..<5 {
            _ = try await service.logPhoto(
                imageData: imageData,
                photoType: .front,
                timestamp: now.addingTimeInterval(Double(-index * 3600))
            )
        }

        let entries = try await service.getAllEntries(limit: 3)

        #expect(entries.count == 3)
    }

    // MARK: - Get Entries by Photo Type Tests

    @Test("Get entries filters by photo type")
    func testGetEntriesFiltersByPhotoType() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()

        _ = try await service.logPhoto(imageData: imageData, photoType: .front)
        _ = try await service.logPhoto(imageData: imageData, photoType: .front)
        _ = try await service.logPhoto(imageData: imageData, photoType: .side)
        _ = try await service.logPhoto(imageData: imageData, photoType: .back)

        let frontPhotos = try await service.getEntries(photoType: .front)
        let sidePhotos = try await service.getEntries(photoType: .side)
        let backPhotos = try await service.getEntries(photoType: .back)

        #expect(frontPhotos.count == 2)
        #expect(sidePhotos.count == 1)
        #expect(backPhotos.count == 1)
    }

    @Test("Get entries by photo type respects limit")
    func testGetEntriesByPhotoTypeRespectsLimit() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        let now = Date()

        for index in 0..<5 {
            _ = try await service.logPhoto(
                imageData: imageData,
                photoType: .front,
                timestamp: now.addingTimeInterval(Double(-index * 3600))
            )
        }

        let entries = try await service.getEntries(photoType: .front, limit: 3)

        #expect(entries.count == 3)
    }

    // MARK: - Update Entry Tests

    @Test("Update entry modifies image data")
    func testUpdateEntryModifiesImageData() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let originalData = createTestImageData()
        let entry = try await service.logPhoto(imageData: originalData, photoType: .front)

        let newData = Data([0xFF, 0xD8, 0xFF, 0xE1, 0x00, 0x20])
        try await service.updateEntry(entry, imageData: newData)

        #expect(entry.imageData == newData)
    }

    @Test("Update entry modifies photo type")
    func testUpdateEntryModifiesPhotoType() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        let entry = try await service.logPhoto(imageData: imageData, photoType: .front)

        try await service.updateEntry(entry, photoType: .side)

        #expect(entry.photoTypeEnum == .side)
    }

    @Test("Update entry modifies notes")
    func testUpdateEntryModifiesNotes() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        let entry = try await service.logPhoto(imageData: imageData, photoType: .front)

        try await service.updateEntry(entry, notes: "Updated note")

        #expect(entry.notes == "Updated note")
    }

    @Test("Update entry can clear notes")
    func testUpdateEntryCanClearNotes() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        let entry = try await service.logPhoto(
            imageData: imageData,
            photoType: .front,
            notes: "Original note"
        )

        try await service.updateEntry(entry, notes: .some(nil))

        #expect(entry.notes == nil)
    }

    @Test("Update entry throws for empty image data")
    func testUpdateEntryThrowsForEmptyImageData() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        let entry = try await service.logPhoto(imageData: imageData, photoType: .front)

        await #expect(throws: ProgressPhotoServiceError.self) {
            try await service.updateEntry(entry, imageData: Data())
        }
    }

    // MARK: - Delete Entry Tests

    @Test("Delete entry removes from context")
    func testDeleteEntryRemovesFromContext() async throws {
        let context = createTestContext()
        let service = ProgressPhotoService(context: context)

        let imageData = createTestImageData()
        let entry = try await service.logPhoto(imageData: imageData, photoType: .front)
        let entryId = entry.id

        try await service.deleteEntry(entry)

        let descriptor = FetchDescriptor<ProgressPhoto>(
            predicate: #Predicate { $0.id == entryId }
        )
        let found = try context.fetch(descriptor)

        #expect(found.isEmpty)
    }

    // MARK: - Error Tests

    @Test("ProgressPhotoServiceError.invalidPhoto has correct description")
    func testInvalidPhotoErrorDescription() throws {
        let error = ProgressPhotoServiceError.invalidPhoto("Test message")

        #expect(error.errorDescription?.contains("Invalid photo") == true)
        #expect(error.errorDescription?.contains("Test message") == true)
    }

    @Test("ProgressPhotoServiceError.noEntriesFound has correct description")
    func testNoEntriesFoundErrorDescription() throws {
        let error = ProgressPhotoServiceError.noEntriesFound

        #expect(error.errorDescription == "No progress photos found")
    }

    @Test("ProgressPhotoServiceError.contextError has correct description")
    func testContextErrorDescription() throws {
        let underlyingError = NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Test error"]
        )
        let error = ProgressPhotoServiceError.contextError(underlyingError)

        #expect(error.errorDescription?.contains("Database error") == true)
    }
}
