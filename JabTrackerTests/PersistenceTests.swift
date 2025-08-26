import Foundation
@testable import JabTracker
import SwiftData
import Testing

@MainActor
@Suite("Data Persistence Tests")
struct DataPersistenceTests {
    @Test("DataController initialization")
    func dataControllerInit() throws {
        let controller = DataController.testContainer()

        // Verify container and context are accessible
        _ = controller.container.mainContext
        #expect(controller.container.schema.entities.count == 3)
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
        #expect(user.email == "save-test-\(uniqueID)@example.com") // If we get here, save was successful
    }

    @Test("Preview data controller works")
    func previewDataController() throws {
        // Don't actually use the static preview in tests - it causes conflicts
        // Instead, just verify that we can create a preview-style controller
        let previewStyleController = DataController(inMemory: true)

        // Verify context is accessible and schema is correct
        _ = previewStyleController.container.mainContext
        #expect(previewStyleController.container.schema.entities.count == 3)
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
        #expect(user.weight == 70.0) // Should have default value
        #expect(user.weightUnit == "kg") // Should have default value
        #expect(!user.timezone.isEmpty) // Should have default timezone
        #expect(user.createdAt != nil) // Should be auto-generated
        #expect(user.updatedAt != nil) // Should be auto-generated
        #expect(user.doses.isEmpty) // Should be empty array, not nil
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
        #expect(user.weightUnit == "kg") // Default
        #expect(!user.timezone.isEmpty)
        #expect(user.createdAt != nil)
        #expect(user.updatedAt != nil)
        #expect(user.doses.count == 0) // Non-nil empty array
        
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
        #expect(medication.startDate != nil) // Should have default value
        #expect(medication.doses.isEmpty) // Should be empty array, not nil
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
        #expect(dose.timestamp != nil)
        #expect(dose.skipped == false) // Should have default value
        
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
        let doseID = UUID()

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
        #expect(user.doses.contains { $0.id == dose.id })
    }
}
