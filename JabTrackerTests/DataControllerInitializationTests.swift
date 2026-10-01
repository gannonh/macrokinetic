import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
@Suite("DataController storage recovery")
struct DataControllerInitializationTests {
    private enum FixtureError: Error { case unavailable, unexpectedState }

    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func readyContainer(_ state: StorageState) throws -> ModelContainer {
        guard case let .ready(container) = state else { throw FixtureError.unexpectedState }
        return container
    }

    private func failedStorage(_ state: StorageState) throws -> StorageFailure {
        guard case let .failed(failure) = state else { throw FixtureError.unexpectedState }
        return failure
    }

    private func saveSentinels(at url: URL) throws -> (UUID, UUID) {
        let controller = DataController(storeURL: url)
        let context = try readyContainer(controller.storageState).mainContext
        let user = User(email: "storage-sentinel@example.invalid", name: "Storage Sentinel")
        let dose = Dose(amount: 0.75, notes: "Storage sentinel dose")
        context.insert(user)
        context.insert(dose)
        dose.user = user
        try context.save()
        return (user.id, dose.id)
    }

    private func expectSentinels(in state: StorageState, ids: (UUID, UUID)) throws {
        let container = try readyContainer(state)
        let users = try container.mainContext.fetch(FetchDescriptor<User>())
        let doses = try container.mainContext.fetch(FetchDescriptor<Dose>())
        #expect(container.schema.entities.count == 16)
        #expect(users.count == 1)
        #expect(users.first?.id == ids.0)
        #expect(users.first?.email == "storage-sentinel@example.invalid")
        #expect(doses.count == 1)
        #expect(doses.first?.id == ids.1)
        #expect(doses.first?.amount == 0.75)
        #expect(doses.first?.notes == "Storage sentinel dose")
        #expect(doses.first?.user?.id == ids.0)
    }

    @Test("A real disk store reopens the same user and 0.75 dose")
    func diskStartupAndReopen() throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("sentinel.store")
        let ids = try saveSentinels(at: url)
        #expect(FileManager.default.fileExists(atPath: url.path))
        let reopened = DataController(storeURL: url)
        #expect(reopened.isCloudKitEnabled == false)
        #expect(reopened.syncStatus == .unavailable)
        try expectSentinels(in: reopened.storageState, ids: ids)
        #expect(reopened.container.configurations.first?.isStoredInMemoryOnly == false)
    }

    @Test("A failed disk open has no emergency memory configuration")
    func failureNeverCreatesMemoryStore() throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("failed.store")
        var attempted: [ModelConfiguration] = []
        let controller = DataController(storeURL: url) { _, configurations in
            attempted += configurations
            throw FixtureError.unavailable
        }
        let failure = try failedStorage(controller.storageState)
        #expect(failure.attemptCount == 1)
        #expect(failure.stages.map(\.stage) == [.configuredStore])
        #expect(attempted.count == 1)
        #expect(attempted.map(\.isStoredInMemoryOnly) == [false])
        #expect(attempted.map(\.url) == [url])
        #expect(controller.isCloudKitEnabled == false)
        #expect(FileManager.default.fileExists(atPath: url.path) == false)
    }

    @Test("Retry reads preexisting disk records without reset or reinsertion")
    func retryRecoversOriginalRecordsAndReadyIsTerminal() throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("recovery.store")
        let ids = try saveSentinels(at: url)
        var attempted: [ModelConfiguration] = []
        let controller = DataController(storeURL: url) { schema, configurations in
            attempted += configurations
            if attempted.count == 1 { throw FixtureError.unavailable }
            return try ModelContainer(for: schema, configurations: configurations)
        }
        #expect(try failedStorage(controller.storageState).attemptCount == 1)
        controller.retryStorage()
        try expectSentinels(in: controller.storageState, ids: ids)
        #expect(attempted.map(\.url) == [url, url])
        #expect(attempted.map(\.isStoredInMemoryOnly) == [false, false])
        let originalContainer = controller.container
        controller.retryStorage()
        #expect(attempted.count == 2)
        #expect(controller.container === originalContainer)
        let relaunched = DataController(storeURL: url)
        try expectSentinels(in: relaunched.storageState, ids: ids)
    }

    @Test("Repeated failures stay blocked and count completed attempts")
    func repeatFailureStaysBlocked() throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("repeat.store")
        var attempted: [ModelConfiguration] = []
        let controller = DataController(storeURL: url) { _, configurations in
            attempted += configurations
            throw FixtureError.unavailable
        }
        controller.retryStorage()
        #expect(try failedStorage(controller.storageState).attemptCount == 2)
        controller.retryStorage()
        #expect(try failedStorage(controller.storageState).attemptCount == 3)
        #expect(attempted.map(\.url) == [url, url, url])
        #expect(attempted.map(\.isStoredInMemoryOnly) == [false, false, false])
        #expect(attempted.map(\.cloudKitContainerIdentifier) == [nil, nil, nil])
    }

    @Test("Configured CloudKit failure tries the unchanged default local identity")
    func cloudKitFallbackOrderingAndProductionIdentity() throws {
        let schema = DataController(inMemory: true).container.schema
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fixtureURL = directory.appendingPathComponent("local.store")
        var attempted: [ModelConfiguration] = []
        let opening = StoreOpening(schema: schema, inMemory: false, shouldEnableCloudKit: true) {
            schema, configurations in
            attempted += configurations
            if attempted.count == 1 { throw FixtureError.unavailable }
            return try ModelContainer(for: schema, configurations: [
                ModelConfiguration(schema: schema, url: fixtureURL, cloudKitDatabase: .none),
            ])
        }
        let outcome = opening.open(attempt: 1)
        #expect(outcome.cloudKitEnabled == false)
        #expect(attempted.count == 2)
        #expect(attempted.map(\.cloudKitContainerIdentifier) == ["iCloud.com.gannonhall.JabTracker", nil])
        #expect(attempted.map(\.isStoredInMemoryOnly) == [false, false])
        #expect(attempted[0].url == attempted[1].url)
        #expect(attempted[0].name == attempted[1].name)
        let context = try readyContainer(outcome.state).mainContext
        context.insert(User(email: "local-fallback@example.invalid"))
        try context.save()
        let reopened = DataController(storeURL: fixtureURL)
        let users = try reopened.container.mainContext.fetch(FetchDescriptor<User>())
        #expect(users.map(\.email) == ["local-fallback@example.invalid"])
    }

    @Test("Production retry retains both default configurations and safe stages")
    func productionFailurePlanIsStableAcrossRetry() throws {
        let schema = DataController(inMemory: true).container.schema
        var attempted: [ModelConfiguration] = []
        let opening = StoreOpening(schema: schema, inMemory: false, shouldEnableCloudKit: true) { _, configurations in
            attempted += configurations
            throw NSError(domain: NSCocoaErrorDomain, code: 134060)
        }
        let first = try failedStorage(opening.open(attempt: 1).state)
        let second = try failedStorage(opening.open(attempt: 2).state)
        #expect(first.stages.map(\.stage) == [.configuredStore, .localFallback])
        #expect(second.stages.map(\.systemCode) == [134060, 134060])
        #expect(second.attemptCount == 2)
        #expect(attempted.count == 4)
        #expect(Set(attempted.map(\.url)).count == 1)
        #expect(Set(attempted.map(\.name)).count == 1)
        #expect(attempted.map(\.isStoredInMemoryOnly) == [false, false, false, false])
        #expect(attempted.map(\.cloudKitContainerIdentifier) == [
            "iCloud.com.gannonhall.JabTracker", nil, "iCloud.com.gannonhall.JabTracker", nil,
        ])
    }

    @Test("A real invalid store fails without modifying its bytes")
    func invalidStoreLeavesUserFileUntouched() throws {
        let directory = try directory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("invalid.store")
        let original = Data("Fictional invalid storage fixture\n".utf8)
        try original.write(to: url)
        let controller = DataController(storeURL: url)
        #expect(try failedStorage(controller.storageState).attemptCount == 1)
        #expect(try Data(contentsOf: url) == original)
        controller.retryStorage()
        #expect(try failedStorage(controller.storageState).attemptCount == 2)
        #expect(try Data(contentsOf: url) == original)
    }

    @Test("Support information drops error payloads and uses literal allowed fields")
    func supportInformationContainsNoHealthOrIdentityPayload() {
        let secret = "semaglutide 0.75; weight 185; patient@example.invalid; /private/patient.store"
        let underlying = NSError(domain: secret, code: 99, userInfo: [NSLocalizedDescriptionKey: secret])
        let hostile = NSError(domain: secret, code: 98, userInfo: [
            NSLocalizedDescriptionKey: secret, NSUnderlyingErrorKey: underlying, NSFilePathErrorKey: secret,
        ])
        let failure = StorageFailure(attemptCount: 2, stages: [
            StorageAttemptFailure(stage: .configuredStore, error: hostile),
            StorageAttemptFailure(stage: .localFallback, error: NSError(
                domain: NSCocoaErrorDomain, code: 134060, userInfo: [NSLocalizedDescriptionKey: secret])),
        ])
        let report = failure.supportInformation(
            version: "0.10.1", build: "16", os: OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 1))
        #expect(report == """
            app=JabTracker
            version=0.10.1
            build=16
            os=27.0.1
            event=storage-open-failed
            attempt=2
            stage=configured-store
            stage=local-fallback
            code=134060
            """)
        #expect(failure.stages.first?.safeDescription == "stage=configured-store")
        #expect(failure.stages.last?.safeDescription == "stage=local-fallback\ncode=134060")
        let hostileMetadata = failure.supportInformation(
            version: secret, build: secret, os: OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 1))
        #expect(hostileMetadata.contains(secret) == false)
        #expect(hostileMetadata.contains("version=unknown\nbuild=unknown"))
        let newlineMetadata = failure.supportInformation(
            version: "0.10.1\n", build: "16\n", os: OperatingSystemVersion(majorVersion: 27, minorVersion: 0, patchVersion: 1))
        #expect(newlineMetadata.contains("version=unknown\nbuild=unknown"))
    }

    @Test("Explicit memory injection still creates isolated containers")
    func intentionalMemoryIsPreserved() throws {
        let first = DataController(inMemory: true)
        let second = DataController(inMemory: true)
        #expect(first.container !== second.container)
        #expect(first.container.schema.entities.count == 16)
        #expect(first.container.configurations.first?.isStoredInMemoryOnly == true)
        #expect(first.container.configurations.first?.name != second.container.configurations.first?.name)
    }

    @Test("Fault fixtures accept UUIDs only and isolate disk storage")
    func fixtureIdentityAndCloudKitIsolation() throws {
        let id = UUID()
        let arguments = ["--storage-fixture=\(id.uuidString)", "--cloudkit-testing", "-inMemory"]
        let fixture = try #require(StorageTestFixture.from(arguments: arguments))
        let expectedDirectory = URL.applicationSupportDirectory
            .appendingPathComponent("JabTrackerStorageFixtures", isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: expectedDirectory) }
        #expect(fixture.storeURL == expectedDirectory.appendingPathComponent("default.store"))
        #expect(StorageTestFixture.from(arguments: ["--storage-fixture=../../patient"])?.storeURL == nil)
        #expect(StorageTestFixture.from(arguments: arguments + ["--storage-fixture=\(UUID().uuidString)"])?.storeURL == nil)
        let controller = fixture.makeController()
        #expect(controller.isCloudKitEnabled == false)
        #expect(controller.container.configurations.first?.isStoredInMemoryOnly == false)
        #expect(controller.container.configurations.first?.cloudKitContainerIdentifier == nil)
    }

    @Test("The guarded disk fixture fails first or always without replacing saved records")
    func fixtureFaultModesRecoverOnlyTheOriginalStore() throws {
        let argument = "--storage-fixture=\(UUID().uuidString)"
        let normal = try #require(StorageTestFixture.from(arguments: [argument]))
        let directory = normal.storeURL.deletingLastPathComponent()
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = try readyContainer(normal.makeController().storageState)
        let ids = try saveSentinels(at: normal.storeURL)
        let first = try #require(StorageTestFixture.from(arguments: [argument, "--storage-fail-first-open"]))
        let recovery = first.makeController()
        #expect(try failedStorage(recovery.storageState).attemptCount == 1)
        recovery.retryStorage()
        try expectSentinels(in: recovery.storageState, ids: ids)
        let always = try #require(StorageTestFixture.from(arguments: [argument, "--storage-always-fail-open"]))
        let blocked = always.makeController()
        blocked.retryStorage()
        #expect(try failedStorage(blocked.storageState).attemptCount == 2)
        try expectSentinels(in: normal.makeController().storageState, ids: ids)
    }

    @Test("Invalid, duplicate or bare fixture arguments fail closed without opening any store")
    func invalidFixtureArgumentsNeverOpenAStore() throws {
        let valid = "--storage-fixture=\(UUID().uuidString)"
        let rejected: [[String]] = [
            ["--storage-fixture=../../patient"],
            ["--storage-fixture="],
            ["--storage-fixture"],
            ["--storage-fixture-extra=1"],
            [valid, "--storage-fixture=\(UUID().uuidString)"],
            [valid, valid],
        ]
        for arguments in rejected {
            let controller = try #require(StorageTestFixture.controller(arguments: arguments))
            #expect(try failedStorage(controller.storageState).attemptCount == 1, "\(arguments)")
            controller.retryStorage()
            #expect(try failedStorage(controller.storageState).attemptCount == 2, "\(arguments)")
            #expect(controller.isCloudKitEnabled == false)
        }
        let rejectedDirectory = URL.applicationSupportDirectory
            .appendingPathComponent("JabTrackerStorageFixtures", isDirectory: true)
            .appendingPathComponent("rejected", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: rejectedDirectory.path) == false)
        #expect(StorageTestFixture.controller(arguments: ["--ui-testing", "--storage-always-fail-open"]) == nil)
        let single = try #require(StorageTestFixture.controller(arguments: [valid]))
        let directory = URL.applicationSupportDirectory
            .appendingPathComponent("JabTrackerStorageFixtures", isDirectory: true)
            .appendingPathComponent(String(valid.dropFirst("--storage-fixture=".count)), isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        _ = try readyContainer(single.storageState)
    }
}
