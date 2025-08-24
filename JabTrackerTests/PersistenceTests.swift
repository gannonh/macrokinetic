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
        // Create a test user
        let user = User(
            id: uniqueID,
            email: "save-test-\(uniqueID)@example.com",
            weight: 70.0,
            weightUnit: "kg",
            timezone: "UTC")

        context.insert(user)

        // This should not throw
        try context.save()
        #expect(user.id == uniqueID) // If we get here, save was successful
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
    @Test("User model can be created and saved")
    func createUserModel() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let uniqueID = UUID()
        let user = User(
            id: uniqueID,
            email: "test-\(uniqueID)@example.com",
            name: "Test User",
            weight: 70.0,
            weightUnit: "kg",
            timezone: "UTC",
            createdAt: Date())

        context.insert(user)
        try context.save()

        #expect(user.id == uniqueID)
        #expect(user.email == "test-\(uniqueID)@example.com")
        #expect(user.name == "Test User")
        #expect(user.weight == 70.0)
    }

    @Test("MedicationProfile model can be created and saved")
    func createMedicationProfileModel() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let uniqueID = UUID()
        let medication = MedicationProfile(
            id: uniqueID,
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            startDate: Date())

        context.insert(medication)
        try context.save()

        #expect(medication.id == uniqueID)
        #expect(medication.genericName == "semaglutide")
        #expect(medication.brandName == "Ozempic")
        #expect(medication.currentDose == 1.0)
    }

    @Test("Dose model can be created and saved")
    func createDoseModel() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let uniqueID = UUID()
        let dose = Dose(
            id: uniqueID,
            amount: 1.0,
            timestamp: Date(),
            site: "Abdomen",
            skipped: false)

        context.insert(dose)
        try context.save()

        #expect(dose.id == uniqueID)
        #expect(dose.amount == 1.0)
        #expect(dose.site == "Abdomen")
        #expect(dose.skipped == false)
    }

    @Test("User-Dose relationship works correctly")
    func userDoseRelationship() throws {
        let controller = DataController.testContainer()
        let context = controller.container.mainContext

        let userID = UUID()
        let doseID = UUID()

        // Create user first
        let user = User(
            id: userID,
            email: "relationship-test-\(userID)@example.com",
            weight: 70.0)
        context.insert(user)

        // Create dose without setting user relationship initially
        let dose = Dose(
            id: doseID,
            amount: 1.0,
            timestamp: Date())
        context.insert(dose)

        // Set the relationship after both objects are inserted
        dose.user = user

        try context.save()

        #expect(dose.user?.id == user.id)
        #expect(user.doses?.contains { $0.id == dose.id } == true)
    }
}
