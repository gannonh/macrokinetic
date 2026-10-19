import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
@Suite("DataController Initialization Tests")
struct DataControllerInitializationTests {
    @Test("In-memory controllers are isolated from each other")
    func inMemoryControllersAreIsolated() throws {
        let first = DataController(inMemory: true)
        let second = DataController(inMemory: true)

        first.container.mainContext.insert(User(email: "a@example.com", name: "A", timezone: "UTC"))
        try first.container.mainContext.save()

        #expect(try first.container.mainContext.fetch(FetchDescriptor<User>()).count == 1)
        #expect(try second.container.mainContext.fetch(FetchDescriptor<User>()).isEmpty)
    }

    @Test("Disk-backed controller opens a usable store")
    func diskControllerOpensStore() throws {
        let controller = DataController(inMemory: false)

        #expect(controller.container.schema.entities.count == 16)
        #expect(controller.initializationError == nil)
    }

    @Test("Preview controller is a singleton with sample data")
    func previewControllerIsSingleton() throws {
        #expect(DataController.preview === DataController.preview)
        #expect(try DataController.preview.container.mainContext.fetch(FetchDescriptor<User>()).count == 1)
    }
}
