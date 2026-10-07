import CryptoKit
import Foundation

struct FoodDataNotices: Decodable {
    struct SourceLink: Decodable {
        let label: String
        let url: URL
    }

    struct Source: Decodable, Identifiable {
        let id: String
        let title: String
        let notice: String
        let links: [SourceLink]
    }

    let sources: [Source]
    let imageNotice: String

    enum CodingKeys: String, CodingKey {
        case sources
        case imageNotice = "image_notice"
    }

    static func load(bundle: Bundle = .main) -> Self? {
        guard let url = bundle.url(forResource: "food-data-notices", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}

struct FoodDatabaseManifest: Decodable, Sendable {
    let schemaVersion: Int
    let databaseSHA256: String
    let databaseBytes: Int
    let createdAt: String
    let commitSHA: String
    let workflowRunID: String
    let totalRows: Int
    let buildMode: String
    let usdaURLs: [String: URL]
    let offFullExportURL: URL
    let offCursor: Int
    let marketingVersion: String
    let buildNumber: String

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case databaseSHA256 = "database_sha256"
        case databaseBytes = "database_bytes"
        case createdAt = "created_at"
        case commitSHA = "commit_sha"
        case workflowRunID = "workflow_run_id"
        case totalRows = "total_rows"
        case buildMode = "build_mode"
        case usdaURLs = "usda_urls"
        case offFullExportURL = "off_full_export_url"
        case offCursor = "off_cursor"
        case marketingVersion = "marketing_version"
        case buildNumber = "build_number"
    }
}

extension FoodDatabaseManifest {
    /// Release date in the USDA dataset file name, such as "2024-04-18" or "2018-04".
    func usdaReleaseDate(for source: String) -> String? {
        guard let name = usdaURLs[source]?.lastPathComponent,
              let match = name.range(of: #"\d{4}-\d{2}(-\d{2})?(?=\.zip$)"#, options: .regularExpression)
        else { return nil }
        return String(name[match])
    }

    /// UTC calendar date of the Open Food Facts snapshot cursor, such as "2026-08-21".
    var openFoodFactsSnapshotDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(offCursor)))
    }
}

enum FoodDatabaseProvenance: Sendable {
    case matched(FoodDatabaseManifest)
    case unavailable(checksum: String?, reason: String)

    static func inspect(databaseURL: URL?, manifestURL: URL?, version: String?, build: String?) -> Self {
        guard let databaseURL else {
            return .unavailable(checksum: nil, reason: "The bundled food database is unavailable.")
        }
        let checksum: String
        let byteCount: Int
        do {
            let file = try FileHandle(forReadingFrom: databaseURL)
            defer { try? file.close() }
            var digest = SHA256()
            byteCount = Int(try file.seekToEnd())
            try file.seek(toOffset: 0)
            while let chunk = try file.read(upToCount: 1024 * 1024), !chunk.isEmpty {
                try Task.checkCancellation()
                digest.update(data: chunk)
            }
            checksum = digest.finalize().map { String(format: "%02x", $0) }.joined()
        } catch {
            return .unavailable(checksum: nil, reason: "The food database checksum could not be read.")
        }
        guard let manifestURL,
              let data = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(FoodDatabaseManifest.self, from: data) else {
            return .unavailable(
                checksum: checksum,
                reason: "A readable provenance manifest is unavailable. " +
                    "Source dates and build provenance are unverified."
            )
        }
        guard manifest.schemaVersion == 2,
              ["full", "delta"].contains(manifest.buildMode), manifest.totalRows > 0,
              manifest.databaseSHA256 == checksum, manifest.databaseBytes == byteCount,
              manifest.marketingVersion == version, manifest.buildNumber == build,
              Set(manifest.usdaURLs.keys) == ["foundation", "sr_legacy"],
              manifest.usdaURLs.values.allSatisfy({ $0.scheme == "https" && $0.host == "fdc.nal.usda.gov" }),
              manifest.offCursor > 0,
              manifest.offFullExportURL.scheme == "https",
              manifest.offFullExportURL.host == "static.openfoodfacts.org" else {
            return .unavailable(
                checksum: checksum,
                reason: "The provenance manifest does not match this database or app build. " +
                    "Source dates and build provenance are unverified."
            )
        }
        return .matched(manifest)
    }
}
