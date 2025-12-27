//
//  ProgressPhotoTests.swift
//  JabTrackerTests
//
//  Tests for ProgressPhoto and PhotoType models.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("ProgressPhoto Tests")
@MainActor
struct ProgressPhotoTests {

    // MARK: - Test Helpers

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([ProgressPhoto.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - PhotoType Tests

    @Test("PhotoType.front has correct raw value")
    func testPhotoTypeFrontRawValue() {
        #expect(PhotoType.front.rawValue == "front")
    }

    @Test("PhotoType.side has correct raw value")
    func testPhotoTypeSideRawValue() {
        #expect(PhotoType.side.rawValue == "side")
    }

    @Test("PhotoType.back has correct raw value")
    func testPhotoTypeBackRawValue() {
        #expect(PhotoType.back.rawValue == "back")
    }

    @Test("PhotoType.front has correct display name")
    func testPhotoTypeFrontDisplayName() {
        #expect(PhotoType.front.displayName == "Front")
    }

    @Test("PhotoType.side has correct display name")
    func testPhotoTypeSideDisplayName() {
        #expect(PhotoType.side.displayName == "Side")
    }

    @Test("PhotoType.back has correct display name")
    func testPhotoTypeBackDisplayName() {
        #expect(PhotoType.back.displayName == "Back")
    }

    @Test("PhotoType.front has correct icon")
    func testPhotoTypeFrontIcon() {
        #expect(PhotoType.front.icon == "person.fill")
    }

    @Test("PhotoType.side has correct icon")
    func testPhotoTypeSideIcon() {
        #expect(PhotoType.side.icon == "person.fill.turn.right")
    }

    @Test("PhotoType.back has correct icon")
    func testPhotoTypeBackIcon() {
        #expect(PhotoType.back.icon == "person.fill.turn.left")
    }

    @Test("PhotoType allCases contains all types")
    func testPhotoTypeAllCases() {
        let allCases = PhotoType.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.front))
        #expect(allCases.contains(.side))
        #expect(allCases.contains(.back))
    }

    // MARK: - ProgressPhoto Initialization Tests

    @Test("Default initialization has correct values")
    func testDefaultInitialization() {
        let photo = ProgressPhoto()

        // Verify id is a valid non-nil UUID (not the zero UUID sentinel)
        let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        #expect(photo.id != zeroUUID, "Photo ID should not be the zero UUID sentinel")
        #expect(photo.timestamp <= Date())
        #expect(photo.imageData == nil)
        #expect(photo.photoType == PhotoType.front.rawValue)
        #expect(photo.notes == nil)
    }

    @Test("Custom initialization sets all values")
    func testCustomInitialization() {
        let timestamp = Date()
        let imageData = Data([0x00, 0x01, 0x02])
        let photo = ProgressPhoto(
            timestamp: timestamp,
            imageData: imageData,
            photoType: .side,
            notes: "Progress check"
        )

        #expect(photo.timestamp == timestamp)
        #expect(photo.imageData == imageData)
        #expect(photo.photoType == "side")
        #expect(photo.notes == "Progress check")
    }

    // MARK: - photoTypeEnum Tests

    @Test("photoTypeEnum getter returns correct enum")
    func testPhotoTypeEnumGetter() {
        let photo = ProgressPhoto(photoType: .back)
        #expect(photo.photoTypeEnum == .back)
    }

    @Test("photoTypeEnum getter defaults to front for invalid value")
    func testPhotoTypeEnumGetterInvalid() {
        let photo = ProgressPhoto()
        photo.photoType = "invalid"
        #expect(photo.photoTypeEnum == .front)
    }

    @Test("photoTypeEnum setter updates photoType string")
    func testPhotoTypeEnumSetter() {
        let photo = ProgressPhoto()

        photo.photoTypeEnum = .side
        #expect(photo.photoType == "side")

        photo.photoTypeEnum = .back
        #expect(photo.photoType == "back")

        photo.photoTypeEnum = .front
        #expect(photo.photoType == "front")
    }

    // MARK: - hasValidPhoto Tests

    @Test("hasValidPhoto returns true when imageData exists and not empty")
    func testHasValidPhotoTrue() {
        let photo = ProgressPhoto(imageData: Data([0x00, 0x01]))
        #expect(photo.hasValidPhoto == true)
    }

    @Test("hasValidPhoto returns false when imageData is nil")
    func testHasValidPhotoNil() {
        let photo = ProgressPhoto(imageData: nil)
        #expect(photo.hasValidPhoto == false)
    }

    @Test("hasValidPhoto returns false when imageData is empty")
    func testHasValidPhotoEmpty() {
        let photo = ProgressPhoto(imageData: Data())
        #expect(photo.hasValidPhoto == false)
    }

    // MARK: - SwiftData Persistence Tests

    @Test("ProgressPhoto can be inserted into context")
    func testInsert() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let imageData = Data([0xFF, 0xD8, 0xFF])  // Simulated JPEG header
        let photo = ProgressPhoto(
            imageData: imageData,
            photoType: .front,
            notes: "Week 1"
        )

        context.insert(photo)
        try context.save()

        let descriptor = FetchDescriptor<ProgressPhoto>()
        let photos = try context.fetch(descriptor)

        #expect(photos.count == 1)
        #expect(photos.first?.imageData == imageData)
        #expect(photos.first?.photoTypeEnum == .front)
        #expect(photos.first?.notes == "Week 1")
    }

    @Test("ProgressPhoto can be updated")
    func testUpdate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let photo = ProgressPhoto(photoType: .front)
        context.insert(photo)
        try context.save()

        photo.photoTypeEnum = .side
        photo.notes = "Updated"
        try context.save()

        let descriptor = FetchDescriptor<ProgressPhoto>()
        let photos = try context.fetch(descriptor)

        #expect(photos.first?.photoTypeEnum == .side)
        #expect(photos.first?.notes == "Updated")
    }

    @Test("ProgressPhoto can be deleted")
    func testDelete() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let photo = ProgressPhoto()
        context.insert(photo)
        try context.save()

        context.delete(photo)
        try context.save()

        let descriptor = FetchDescriptor<ProgressPhoto>()
        let photos = try context.fetch(descriptor)

        #expect(photos.count == 0)
    }
}
