import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// KAT-3713: health data stays on the device in 1.0, so no store opens with CloudKit.
@MainActor
@Suite("DataController local storage policy")
struct DataControllerCloudKitTests {
    @Test("Store opens with CloudKit off for every normal launch")
    func cloudKitOffByDefault() {
        #expect(!DataController.shouldEnableCloudKit(arguments: []))
        #expect(!DataController.shouldEnableCloudKit(arguments: ["--ui-testing", "--reset-app-data"]))
        // The retired `--disable-cloudkit` flag must not change anything.
        #expect(!DataController.shouldEnableCloudKit(arguments: ["--disable-cloudkit"]))
    }

    @Test("Only debug builds can opt in with --cloudkit-testing")
    func cloudKitOptInIsDebugOnly() {
        let enabled = DataController.shouldEnableCloudKit(arguments: ["--cloudkit-testing"])
        #if DEBUG
        #expect(enabled)
        #else
        #expect(!enabled)
        #endif
    }

    @Test("A local-only on-disk store keeps its records across reopen")
    func localStoreKeepsRecordsAcrossReopen() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("kat3713-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        let schema = Schema([User.self, Dose.self, MedicationProfile.self])
        let doseID: UUID
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            let dose = Dose(amount: 2.5, timestamp: Date(timeIntervalSince1970: 1_700_000_000), site: "Abdomen", skipped: false)
            container.mainContext.insert(dose)
            try container.mainContext.save()
            doseID = dose.id
        }

        let reopened = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
        let doses = try reopened.mainContext.fetch(FetchDescriptor<Dose>())
        #expect(doses.count == 1)
        #expect(doses.first?.id == doseID)
        #expect(doses.first?.amount == 2.5)
    }
}
