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

    enum Selection {
        case absent
        case rejected
        case fixture(StorageTestFixture)
    }

    /// Any argument that starts with --storage-fixture selects the fixture path. Exactly one valid UUID
    /// selects a fixture; anything else (malformed, duplicate, bare flag) is rejected, never ignored.
    static func selection(arguments: [String]) -> Selection {
        let requests = arguments.filter { $0.hasPrefix("--storage-fixture") }
        guard !requests.isEmpty else { return .absent }
        guard requests.count == 1, requests[0].hasPrefix("--storage-fixture="),
            let identifier = UUID(uuidString: String(requests[0].dropFirst("--storage-fixture=".count)))
        else { return .rejected }
        return .fixture(fixture(identifier: identifier, arguments: arguments))
    }

    static func from(arguments: [String]) -> StorageTestFixture? {
        if case let .fixture(fixture) = selection(arguments: arguments) { return fixture }
        return nil
    }

    /// A controller for a rejected fixture request. It never opens a store, so the recovery screen
    /// appears and no ordinary or fixture file is touched.
    @MainActor
    static func makeRejectedController() -> DataController {
        let unused = URL.applicationSupportDirectory
            .appendingPathComponent("JabTrackerStorageFixtures", isDirectory: true)
            .appendingPathComponent("rejected", isDirectory: true)
            .appendingPathComponent("default.store")
        return DataController(storeURL: unused) { _, _ in
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError)
        }
    }

    /// Returns nil when no fixture is requested, so the ordinary controller is used.
    @MainActor
    static func controller(arguments: [String]) -> DataController? {
        switch selection(arguments: arguments) {
        case .absent: nil
        case .rejected: makeRejectedController()
        case let .fixture(fixture): fixture.makeController()
        }
    }

    private static func fixture(identifier: UUID, arguments: [String]) -> StorageTestFixture {
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
