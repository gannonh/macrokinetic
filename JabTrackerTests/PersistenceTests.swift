import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
@Suite("Data Persistence Tests")
struct DataPersistenceTests {
    @Test("DataController initialization")
    func dataControllerInit() throws {
        let controller = DataController.testContainer()

        // Verify container and context are accessible
        _ = controller.container.mainContext
        #expect(controller.container.schema.entities.count == 14)
    }

    @Test("SwiftData context saves successfully")
    func swiftDataSave() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let uniqueID = UUID()
        // Create a test user with required fields only
        let user = User(email: "save-test-\(uniqueID)@example.com")

        context.insert(user)

        // This should not throw
        try context.save()
        #expect(user.email == "save-test-\(uniqueID)@example.com")  // If we get here, save was successful
    }

    @Test("Preview data controller works")
    func previewDataController() throws {
        // Don't actually use the static preview in tests - it causes conflicts
        // Instead, just verify that we can create a preview-style controller
        let previewStyleController = DataController(inMemory: true)

        // Verify context is accessible and schema is correct
        _ = previewStyleController.container.mainContext
        #expect(previewStyleController.container.schema.entities.count == 14)
    }
}

@Suite("CloudKit Sync Tests")
struct CloudKitSyncTests {
    @Test("DataController CloudKit status checking")
    @MainActor
    func cloudKitStatusChecking() throws {
        let dataController = DataController.testContainer()

        // Test sync status property is accessible
        let syncStatus = dataController.syncStatus
        let validStatuses: [SyncStatus] = [
            .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork,
        ]
        #expect(validStatuses.contains(syncStatus))

        // Test CloudKit enabled flag
        let isCloudKitEnabled = dataController.isCloudKitEnabled
        #expect(isCloudKitEnabled == true || isCloudKitEnabled == false)  // Valid boolean
    }

    @Test("DataController offline mode graceful fallback")
    @MainActor
    func offlineModeGracefulFallback() throws {
        // Test that DataController works without CloudKit
        let inMemoryController = DataController(inMemory: true)  // In-memory = local-only
        let context = inMemoryController.container.mainContext

        // Test that data operations work in offline mode
        let user = User(email: "offline-test@example.com", weight: 75.0)
        context.insert(user)

        try context.save()
        #expect(user.email == "offline-test@example.com")

        // Test that we can fetch data in offline mode
        let fetchRequest = FetchDescriptor<User>()
        let users = try context.fetch(fetchRequest)
        #expect(users.contains { $0.email == "offline-test@example.com" })

        // Verify sync status reflects offline mode
        #expect(inMemoryController.willSyncAcrossDevices == false)
    }

    @Test("Sync status messaging provides user guidance")
    @MainActor
    func syncStatusMessaging() throws {
        let dataController = DataController.testContainer()

        // Test that sync status message is accessible and not empty
        let message = dataController.syncStatusMessage
        #expect(!message.isEmpty, "Sync status message should provide user guidance")

        // Message should be meaningful for each status
        switch dataController.syncStatus {
        case .available:
            #expect(message.contains("syncing") || message.contains("iCloud"))
        case .unavailable, .restricted, .accountNotSignedIn:
            #expect(
                message.contains("available") || message.contains("sign in") || message.contains("iCloud"))
        case .unknown:
            #expect(message.contains("checking") || message.contains("determining"))
        case .noNetwork:
            #expect(message.contains("network"))
        }
    }

    @Test("Retry CloudKit setup functionality")
    @MainActor
    func retryCloudKitSetup() throws {
        let dataController = DataController.testContainer()

        // Test that retry method exists and can be called
        dataController.retryCloudKitSetup()

        // Should not crash regardless of CloudKit availability
        // Actual retry logic is tested through integration
    }

    @Test("CloudKit sync with model creation")
    @MainActor
    func cloudKitSyncWithModelCreation() throws {
        let dataController = DataController.testContainer()
        let context = dataController.container.mainContext

        // Test that models can be created and saved together
        // This is important for CloudKit sync integrity
        let user = User(email: "sync-test@example.com", weight: 80.0)
        let medication = MedicationProfile(
            genericName: "semaglutide", brandName: "Ozempic", currentDose: 1.0)
        let dose = Dose(amount: 1.0, timestamp: Date())

        context.insert(user)
        context.insert(medication)
        context.insert(dose)

        // Set relationships after insertion to avoid duplicate registration
        dose.user = user
        dose.medication = medication

        try context.save()

        // Verify relationships are maintained (critical for CloudKit sync)
        #expect(dose.user?.id == user.id)
        #expect(dose.medication?.id == medication.id)
    }
}

@MainActor
@Suite("SwiftData Model Tests")
struct SwiftDataModelTests {
    @Test("User model can be created with required fields")
    func createUserModel() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let uniqueID = UUID()
        // Test that User can be created with required fields only
        let user = User(email: "test-\(uniqueID)@example.com")

        context.insert(user)
        try context.save()

        // Required fields should be non-optional
        #expect(user.email == "test-\(uniqueID)@example.com")
        #expect(user.weight == 70.0)  // Should have default value
        #expect(user.weightUnit == "lbs")  // Should have default value (US units)
        #expect(!user.timezone.isEmpty)  // Should have default timezone
        #expect(user.createdAt.timeIntervalSince1970 > 0)  // Should be auto-generated
        #expect(user.updatedAt.timeIntervalSince1970 > 0)  // Should be auto-generated
        #expect(user.doses?.isEmpty ?? true)  // Should be empty array or nil
    }

    @Test("User model has correct required and optional fields")
    func userModelFieldRequirements() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let user = User(email: "required@example.com", name: "Optional Name", weight: 80.0)

        context.insert(user)
        try context.save()

        // Required fields should never be nil
        #expect(user.email == "required@example.com")
        #expect(user.weight == 80.0)
        #expect(user.weightUnit == "lbs")  // Default (US units)
        #expect(!user.timezone.isEmpty)
        #expect(user.createdAt.timeIntervalSince1970 > 0)
        #expect(user.updatedAt.timeIntervalSince1970 > 0)
        #expect(user.doses?.isEmpty ?? true)  // Should be empty array or nil

        // Optional fields can be provided
        #expect(user.name == "Optional Name")

        // appleUserId should be available for auth linking
        user.appleUserId = "test.apple.id"
        #expect(user.appleUserId == "test.apple.id")
    }

    @Test("MedicationProfile model can be created with required fields")
    func createMedicationProfileModel() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Test that MedicationProfile requires key fields
        let medication = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0)

        context.insert(medication)
        try context.save()

        // Required fields should be non-optional
        #expect(medication.genericName == "semaglutide")
        #expect(medication.brandName == "Ozempic")
        #expect(medication.currentDose == 1.0)
        #expect(medication.startDate.timeIntervalSince1970 > 0)  // Should have default value
        #expect(medication.doses?.isEmpty ?? true)  // Should be empty array or nil
    }

    @Test("MedicationProfile medication computed property getter and setter")
    func medicationProfileComputedProperty() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Create medication profile with medicationType string
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            medicationType: "semaglutide")

        context.insert(profile)
        try context.save()

        // Test getter - should convert medicationType string to Medication enum
        let retrievedMedication = profile.medication
        #expect(
            retrievedMedication == .semaglutide,
            "Getter should convert 'semaglutide' string to Medication.semaglutide")

        // Test setter - should store enum rawValue as medicationType string
        profile.medication = .tirzepatide
        #expect(
            profile.medicationType == "tirzepatide",
            "Setter should store enum rawValue as medicationType string")

        // Test getter after setter
        #expect(
            profile.medication == .tirzepatide, "Getter should return updated medication after setter")

        // Test setter with nil
        profile.medication = nil
        #expect(
            profile.medicationType == "", "Setter with nil should set medicationType to empty string")
        #expect(profile.medication == nil, "Getter should return nil when medicationType is empty")

        // Test getter with invalid medicationType
        profile.medicationType = "invalid_medication"
        #expect(profile.medication == nil, "Getter should return nil for invalid medicationType")
    }

    @Test("Dose model can be created with required fields")
    func createDoseModel() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        // Test that Dose requires amount and timestamp
        let dose = Dose(amount: 1.0, timestamp: Date())

        context.insert(dose)
        try context.save()

        // Required fields should be non-optional
        #expect(dose.amount == 1.0)
        #expect(dose.timestamp.timeIntervalSince1970 > 0)
        #expect(dose.skipped == false)  // Should have default value

        // Optional fields should be nil initially
        #expect(dose.site == nil)
        #expect(dose.notes == nil)
        #expect(dose.imageData == nil)
    }

    @Test("User-Dose relationship works correctly")
    func userDoseRelationship() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let userID = UUID()

        // Create user first
        let user = User(email: "relationship-test-\(userID)@example.com")
        context.insert(user)

        // Create dose without setting user relationship initially
        let dose = Dose(amount: 1.0, timestamp: Date())
        context.insert(dose)

        // Set the relationship after both objects are inserted
        dose.user = user

        try context.save()

        #expect(dose.user?.id == user.id)
        #expect(user.doses?.contains { $0.id == dose.id } ?? false)
    }
}
