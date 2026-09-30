import XCTest
@testable import JabTracker

final class FoodDatabaseProvenanceTests: XCTestCase {
    private let abcSHA = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"

    func testMissingManifestKeepsActualChecksumWithoutClaimingProvenance() throws {
        try withFixture { database, _ in
            let result = FoodDatabaseProvenance.inspect(databaseURL: database, manifestURL: nil, version: "1.0.0", build: "18")
            guard case .unavailable(let checksum, let reason) = result else {
                return XCTFail("A database without provenance must remain unverified")
            }
            XCTAssertEqual(checksum, abcSHA)
            XCTAssertEqual(reason, "A readable provenance manifest is unavailable. Source dates and build provenance are unverified.")
        }
    }

    func testMatchingManifestReportsTheExactBundledDatabase() throws {
        try withFixture { database, manifest in
            try writeManifest(to: manifest)
            let result = FoodDatabaseProvenance.inspect(databaseURL: database, manifestURL: manifest, version: "1.0.0", build: "18")
            guard case .matched(let provenance) = result else {
                return XCTFail("Matching bytes and app version must expose their manifest")
            }
            XCTAssertEqual(provenance.databaseSHA256, abcSHA)
            XCTAssertEqual(provenance.createdAt, "2026-09-30T20:00:00Z")
            XCTAssertEqual(provenance.workflowRunID, "123")
        }
    }

    func testChangedDatabaseOrAppBuildCannotClaimTheManifest() throws {
        try withFixture { database, manifest in
            try writeManifest(to: manifest)
            let changedBuild = FoodDatabaseProvenance.inspect(databaseURL: database, manifestURL: manifest, version: "1.0.0", build: "19")
            guard case .unavailable = changedBuild else { return XCTFail("An old build manifest must be rejected") }
            try Data("abd".utf8).write(to: database)
            let changedBytes = FoodDatabaseProvenance.inspect(databaseURL: database, manifestURL: manifest, version: "1.0.0", build: "18")
            guard case .unavailable = changedBytes else { return XCTFail("Changed bytes must be rejected") }
        }
    }

    func testUnsupportedManifestSchemaRemainsUnverified() throws {
        try withFixture { database, manifest in
            try writeManifest(to: manifest, schema: 99)
            let result = FoodDatabaseProvenance.inspect(databaseURL: database, manifestURL: manifest, version: "1.0.0", build: "18")
            guard case .unavailable = result else { return XCTFail("An unsupported schema must be rejected") }
        }
    }

    private func withFixture(_ check: (URL, URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let database = root.appendingPathComponent("usda_foods.sqlite")
        try Data("abc".utf8).write(to: database)
        try check(database, root.appendingPathComponent("food-db-manifest.json"))
    }

    private func writeManifest(to url: URL, schema: Int = 2) throws {
        let manifest: [String: Any] = [
            "schema_version": schema, "database_sha256": abcSHA, "database_bytes": 3,
            "created_at": "2026-09-30T20:00:00Z", "commit_sha": String(repeating: "a", count: 40),
            "workflow_run_id": "123", "total_rows": 3, "build_mode": "full",
            "usda_urls": ["foundation": "https://fdc.nal.usda.gov/foundation.zip", "sr_legacy": "https://fdc.nal.usda.gov/sr.zip"],
            "off_full_export_url": "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz",
            "marketing_version": "1.0.0", "build_number": "18"
        ]
        try JSONSerialization.data(withJSONObject: manifest).write(to: url)
    }
}
