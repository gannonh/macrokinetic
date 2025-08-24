import CoreData
@testable import JabTracker
import Testing

@Suite("JabTracker Core Tests")
struct JabTrackerTests {
    @Test("PersistenceController initialization")
    func persistenceControllerInit() throws {
        let controller = PersistenceController(inMemory: true)

        #expect(controller.container.name == "JabTracker")
        #expect(controller.container.viewContext != nil)
    }

    @Test("Core Data context saves successfully")
    func coreDataSave() throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // This should not throw
        try context.save()
        #expect(true) // If we get here, save was successful
    }

    @Test("Preview persistence controller works")
    func previewPersistenceController() throws {
        let previewController = PersistenceController.preview

        #expect(previewController.container.name == "JabTracker")
        #expect(previewController.container.viewContext != nil)
    }
}

@Suite("Core Data Model Tests")
struct CoreDataModelTests {
    let controller = PersistenceController(inMemory: true)

    @Test("User entity can be created")
    func createUserEntity() throws {
        let context = controller.container.viewContext

        let user = User(context: context)
        user.id = UUID()
        user.email = "test@example.com"
        user.timezone = "UTC"
        user.weight = 70.0
        user.weightUnit = "kg"
        user.createdAt = Date()

        try context.save()

        #expect(user.id != nil)
        #expect(user.email == "test@example.com")
    }

    @Test("MedicationProfile entity can be created")
    func createMedicationProfileEntity() throws {
        let context = controller.container.viewContext

        let medication = MedicationProfile(context: context)
        medication.id = UUID()
        medication.genericName = "semaglutide"
        medication.brandName = "Ozempic"
        medication.currentDose = 1.0
        medication.startDate = Date()

        try context.save()

        #expect(medication.id != nil)
        #expect(medication.genericName == "semaglutide")
        #expect(medication.brandName == "Ozempic")
    }

    @Test("Dose entity can be created")
    func createDoseEntity() throws {
        let context = controller.container.viewContext

        let dose = Dose(context: context)
        dose.id = UUID()
        dose.amount = 1.0
        dose.timestamp = Date()
        dose.skipped = false

        try context.save()

        #expect(dose.id != nil)
        #expect(dose.amount == 1.0)
        #expect(dose.skipped == false)
    }
}
