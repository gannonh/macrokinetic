#if DEBUG || JABTRACKER_TEST_HARNESS
import Foundation
import SwiftData

struct StorageTestFixture {
    enum FailureMode: Equatable {
        case none
        case firstOpen
        case everyOpen
    }

    let storeURL: URL
    let failureMode: FailureMode

    static func from(arguments: [String]) -> StorageTestFixture? {
        let identifiers = arguments.filter { $0.hasPrefix("--storage-fixture=") }
        guard identifiers.count == 1,
            let identifier = UUID(uuidString: String(identifiers[0].dropFirst("--storage-fixture=".count)))
        else { return nil }
        let directory = URL.applicationSupportDirectory
            .appendingPathComponent("JabTrackerStorageFixtures", isDirectory: true)
            .appendingPathComponent(identifier.uuidString, isDirectory: true)
        let mode: FailureMode = arguments.contains("--storage-always-fail-open")
            ? .everyOpen : (arguments.contains("--storage-fail-first-open") ? .firstOpen : .none)
        return StorageTestFixture(storeURL: directory.appendingPathComponent("default.store"), failureMode: mode)
    }

    @MainActor
    func makeController() -> DataController {
        var opens = 0
        return DataController(storeURL: storeURL) { schema, configurations in
            opens += 1
            if self.failureMode == .everyOpen || (self.failureMode == .firstOpen && opens == 1) {
                throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError)
            }
            try FileManager.default.createDirectory(
                at: self.storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            return try ModelContainer(for: schema, configurations: configurations)
        }
    }
}
#endif
