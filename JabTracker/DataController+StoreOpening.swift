import Foundation
import OSLog
import SwiftData

enum StorageState {
    case ready(ModelContainer)
    case failed(StorageFailure)
}

enum StorageOpenStage: String, Equatable {
    case configuredStore = "configured-store"
    case localFallback = "local-fallback"
}

struct StorageAttemptFailure {
    let stage: StorageOpenStage
    let systemCode: Int?

    init(stage: StorageOpenStage, error: Error) {
        self.stage = stage
        let systemError = error as NSError
        let allowedDomains = [NSCocoaErrorDomain, NSPOSIXErrorDomain, "NSSQLiteErrorDomain"]
        self.systemCode = allowedDomains.contains(systemError.domain) ? systemError.code : nil
    }

    var safeDescription: String {
        let code = systemCode.map { "\ncode=\($0)" } ?? ""
        return "stage=\(stage.rawValue)\(code)"
    }
}

struct StorageFailure {
    let attemptCount: Int
    let stages: [StorageAttemptFailure]

    var supportInformation: String {
        supportInformation(
            version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "",
            os: ProcessInfo.processInfo.operatingSystemVersion
        )
    }

    func supportInformation(version: String, build: String, os: OperatingSystemVersion) -> String {
        let safeVersion = version.range(of: #"\A[0-9]+(\.[0-9]+){0,2}\z"#, options: .regularExpression) == nil
            ? "unknown" : version
        let safeBuild = build.range(of: #"\A[0-9]+\z"#, options: .regularExpression) == nil ? "unknown" : build
        let fields = [
            "app=JabTracker",
            "version=\(safeVersion)",
            "build=\(safeBuild)",
            "os=\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)",
            "event=storage-open-failed",
            "attempt=\(attemptCount)",
        ]
        return (fields + stages.map(\.safeDescription)).joined(separator: "\n")
    }
}

@MainActor
struct StoreOpening {
    typealias ContainerFactory = @MainActor (Schema, [ModelConfiguration]) throws -> ModelContainer

    struct Outcome {
        let state: StorageState
        let cloudKitEnabled: Bool
    }

    private let schema: Schema
    private let configuredStore: ModelConfiguration
    private let localFallback: ModelConfiguration?
    private let usesCloudKit: Bool
    private let makeContainer: ContainerFactory
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "StoreOpening")

    init(
        schema: Schema,
        inMemory: Bool,
        shouldEnableCloudKit: Bool,
        storeURL: URL? = nil,
        makeContainer: @escaping ContainerFactory = { schema, configurations in
            try ModelContainer(for: schema, configurations: configurations)
        }
    ) {
        self.schema = schema
        self.makeContainer = makeContainer
        #if JABTRACKER_TEST_HARNESS
        self.usesCloudKit = false
        #else
        self.usesCloudKit = shouldEnableCloudKit && !inMemory && storeURL == nil
        #endif
        if let storeURL {
            self.configuredStore = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
        } else if inMemory {
            self.configuredStore = ModelConfiguration(
                "JabTracker-memory-\(UUID().uuidString)", schema: schema,
                isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            #if JABTRACKER_TEST_HARNESS
            self.configuredStore = ModelConfiguration(
                schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
            #else
            self.configuredStore = ModelConfiguration(
                schema: schema, isStoredInMemoryOnly: false,
                cloudKitDatabase: self.usesCloudKit ? .private("iCloud.com.gannonhall.JabTracker") : .none)
            #endif
        }
        self.localFallback = self.usesCloudKit
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .none)
            : nil
    }

    func open(attempt: Int) -> Outcome {
        var failures: [StorageAttemptFailure] = []
        do {
            let container = try makeContainer(schema, [configuredStore])
            return Outcome(state: .ready(container), cloudKitEnabled: usesCloudKit)
        } catch {
            let failure = StorageAttemptFailure(stage: .configuredStore, error: error)
            failures.append(failure)
            Self.logger.error("Storage open failed: \(failure.safeDescription, privacy: .public)")
        }
        if let localFallback {
            do {
                let container = try makeContainer(schema, [localFallback])
                return Outcome(state: .ready(container), cloudKitEnabled: false)
            } catch {
                let failure = StorageAttemptFailure(stage: .localFallback, error: error)
                failures.append(failure)
                Self.logger.error("Storage open failed: \(failure.safeDescription, privacy: .public)")
            }
        }
        return Outcome(state: .failed(StorageFailure(attemptCount: attempt, stages: failures)), cloudKitEnabled: false)
    }
}
