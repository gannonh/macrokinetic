//
//  LocalFoodDatabase.swift
//  JabTracker
//

import Foundation
import OSLog
import SQLite3

/// Result from local food database search
struct LocalFoodResult {
    let fdcId: Int
    let name: String
    let brand: String?
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double
    let category: String?
    let source: String?
    let barcode: String?
    let servingSize: Double
    let servingUnit: String
    let servingOptions: String  // JSON array string
}

/// Service for searching the bundled food database (USDA + Open Food Facts) using SQLite FTS5
/// Note: Actor ensures serial access to SQLite connection (required for thread safety)
actor LocalFoodDatabase {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "LocalFoodDatabase")

    private var database: OpaquePointer?
    private let databasePath: String
    private var hasOpened = false

    /// Whether the database is available for queries
    var isAvailable: Bool {
        get async {
            ensureDatabaseOpen()
            return database != nil
        }
    }

    /// Initialize with the bundled database
    init() {
        // Find bundled database in app bundle
        if let bundlePath = Bundle.main.path(forResource: "usda_foods", ofType: "sqlite") {
            self.databasePath = bundlePath
        } else {
            Self.logger.warning("USDA foods database not found in bundle")
            self.databasePath = ""
        }
        // Database opened lazily on first query
    }

    /// Initialize with a custom path (for testing)
    init(databasePath: String) {
        self.databasePath = databasePath
        // Database opened lazily on first query
    }

    deinit {
        if let db = database {
            sqlite3_close(db)
            Self.logger.debug("Closed USDA foods database connection")
        }
    }

    // MARK: - Database Connection

    /// Opens database on first use (lazy initialization)
    private func ensureDatabaseOpen() {
        guard !hasOpened else { return }
        hasOpened = true

        guard !databasePath.isEmpty else {
            Self.logger.warning("Database path is empty, database unavailable")
            return
        }

        guard FileManager.default.fileExists(atPath: databasePath) else {
            Self.logger.warning("Database file does not exist at: \(self.databasePath)")
            return
        }

        // Open in read-only mode since it's a bundled resource
        if sqlite3_open_v2(databasePath, &database, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            Self.logger.error("Failed to open database: \(errorMessage)")
            database = nil
        } else {
            Self.logger.info("Successfully opened USDA foods database")
        }
    }

    // MARK: - Search Methods

    /// Search for foods matching the query using FTS5 full-text search
    /// - Parameters:
    ///   - query: Search term (supports prefix matching)
    ///   - limit: Maximum number of results to return
    ///   - sources: Optional array of source values to filter by (e.g., ["foundation", "sr_legacy"] for USDA,
    ///              or ["openFoodFacts"] for branded). If nil, searches all sources.
    /// - Returns: Array of matching foods
    func search(query: String, limit: Int = 20, sources: [String]? = nil) throws -> [LocalFoodResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        ensureDatabaseOpen()
        guard database != nil else {
            Self.logger.warning("Database not available for search")
            return []
        }

        // Prepare FTS5 query with prefix matching
        let queryWords =
            trimmedQuery
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
        let ftsQuery =
            queryWords
            .map { "\($0)*" }  // Add prefix matching
            .joined(separator: " ")

        // Create pattern for name prefix boosting (names starting with search term rank higher)
        // E.g., "banana" -> "banana%" so "Bananas, raw" ranks above "Snacks, banana chips"
        let namePrefixPattern = (queryWords.first ?? trimmedQuery).lowercased() + "%"

        // Create pattern for whole word matching (exact word should rank higher than partial)
        // E.g., "apple" matches "Apples, raw" as whole word but not "APPLEBEE'S"
        // GLOB pattern: word followed by word boundary (s for plural, comma, space)
        // SQLite GLOB is case-sensitive, so we use LOWER() in the query
        let firstWord = (queryWords.first ?? trimmedQuery).lowercased()
        // Match: "apples,*" or "apples *" or "apple,*" or "apple *" (with optional 's' for plurals)
        let wholeWordPattern = firstWord + "[s,]*"

        // Build SQL with optional source filtering
        // Ranking factors (in order of priority):
        // 1) Names starting with search term (prefix match)
        // 2) Whole word matches ("Apple" > "APPLEBEE'S")
        // 3) Shorter names preferred ("Bananas, raw" > "Bananas, dehydrated, or...")
        // 4) BM25 relevance score
        let sql: String
        var parameters: [Any] = []

        if let sources = sources, !sources.isEmpty {
            // Build placeholders for IN clause (?, ?, ...)
            let placeholders = sources.map { _ in "?" }.joined(separator: ", ")
            sql = """
                SELECT f.fdc_id, f.name, f.brand,
                       f.calories_per_100g, f.protein_per_100g, f.carbs_per_100g,
                       f.fat_per_100g, f.fiber_per_100g, f.category,
                       f.source, f.barcode,
                       f.serving_size, f.serving_unit, f.serving_options
                FROM foods_fts fts
                JOIN foods f ON fts.rowid = f.id
                WHERE foods_fts MATCH ? AND f.source IN (\(placeholders))
                ORDER BY
                    CASE WHEN LOWER(f.name) LIKE ? THEN 0 ELSE 1 END,
                    CASE WHEN LOWER(f.name) GLOB ? THEN 0 ELSE 1 END,
                    LENGTH(f.name),
                    bm25(foods_fts, 10.0, 1.0)
                LIMIT ?
                """
            // Parameter order: ftsQuery, sources..., namePrefixPattern, wholeWordPattern, limit
            parameters.append(ftsQuery)
            parameters.append(contentsOf: sources)
            parameters.append(namePrefixPattern)
            parameters.append(wholeWordPattern)
            parameters.append(limit)
        } else {
            sql = """
                SELECT f.fdc_id, f.name, f.brand,
                       f.calories_per_100g, f.protein_per_100g, f.carbs_per_100g,
                       f.fat_per_100g, f.fiber_per_100g, f.category,
                       f.source, f.barcode,
                       f.serving_size, f.serving_unit, f.serving_options
                FROM foods_fts fts
                JOIN foods f ON fts.rowid = f.id
                WHERE foods_fts MATCH ?
                ORDER BY
                    CASE WHEN LOWER(f.name) LIKE ? THEN 0 ELSE 1 END,
                    CASE WHEN LOWER(f.name) GLOB ? THEN 0 ELSE 1 END,
                    LENGTH(f.name),
                    bm25(foods_fts, 10.0, 1.0)
                LIMIT ?
                """
            // Parameter order: ftsQuery, namePrefixPattern, wholeWordPattern, limit
            parameters.append(ftsQuery)
            parameters.append(namePrefixPattern)
            parameters.append(wholeWordPattern)
            parameters.append(limit)
        }

        return try executeSearch(sql: sql, parameters: parameters)
    }

    /// Look up a specific food by FDC ID
    /// - Parameter fdcId: USDA FoodData Central ID
    /// - Returns: The food if found, nil otherwise
    func lookup(fdcId: Int) throws -> LocalFoodResult? {
        ensureDatabaseOpen()
        guard database != nil else {
            return nil
        }

        let sql = """
            SELECT fdc_id, name, brand,
                   calories_per_100g, protein_per_100g, carbs_per_100g,
                   fat_per_100g, fiber_per_100g, category,
                   source, barcode,
                   serving_size, serving_unit, serving_options
            FROM foods
            WHERE fdc_id = ?
            LIMIT 1
            """

        let results = try executeSearch(sql: sql, parameters: [fdcId])
        return results.first
    }

    /// Look up a food by barcode
    /// - Parameter barcode: Product barcode (EAN/UPC)
    /// - Returns: The food if found, nil otherwise
    func lookupBarcode(_ barcode: String) throws -> LocalFoodResult? {
        ensureDatabaseOpen()
        guard database != nil else {
            return nil
        }

        let sql = """
            SELECT fdc_id, name, brand,
                   calories_per_100g, protein_per_100g, carbs_per_100g,
                   fat_per_100g, fiber_per_100g, category,
                   source, barcode,
                   serving_size, serving_unit, serving_options
            FROM foods
            WHERE barcode = ?
            LIMIT 1
            """

        let results = try executeSearch(sql: sql, parameters: [barcode])
        return results.first
    }

    /// Search foods by category
    /// - Parameters:
    ///   - category: Category name to filter by
    ///   - limit: Maximum number of results
    /// - Returns: Array of foods in the category
    func searchByCategory(_ category: String, limit: Int = 50) throws -> [LocalFoodResult] {
        ensureDatabaseOpen()
        guard database != nil else {
            return []
        }

        let sql = """
            SELECT fdc_id, name, brand,
                   calories_per_100g, protein_per_100g, carbs_per_100g,
                   fat_per_100g, fiber_per_100g, category,
                   source, barcode,
                   serving_size, serving_unit, serving_options
            FROM foods
            WHERE category = ?
            ORDER BY name
            LIMIT ?
            """

        return try executeSearch(sql: sql, parameters: [category, limit])
    }

    // MARK: - Private Helpers

    private func executeSearch(sql: String, parameters: [Any]) throws -> [LocalFoodResult] {
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            Self.logger.error("Failed to prepare statement: \(errorMessage)")
            throw LocalFoodDatabaseError.queryFailed(errorMessage)
        }

        defer {
            sqlite3_finalize(statement)
        }

        // Bind parameters
        for (index, param) in parameters.enumerated() {
            let bindIndex = Int32(index + 1)
            switch param {
            case let stringValue as String:
                sqlite3_bind_text(
                    statement, bindIndex, stringValue, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            case let intValue as Int:
                sqlite3_bind_int(statement, bindIndex, Int32(intValue))
            default:
                Self.logger.warning("Unsupported parameter type at index \(index)")
            }
        }

        // Execute and collect results
        var results: [LocalFoodResult] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            results.append(parseRow(statement))
        }
        return results
    }

    private func parseRow(_ statement: OpaquePointer?) -> LocalFoodResult {
        let fdcId = Int(sqlite3_column_int(statement, 0))
        let name = String(cString: sqlite3_column_text(statement, 1))
        let brand = sqlite3_column_text(statement, 2).map { String(cString: $0) }
        let calories = sqlite3_column_double(statement, 3)
        let protein = sqlite3_column_double(statement, 4)
        let carbs = sqlite3_column_double(statement, 5)
        let fat = sqlite3_column_double(statement, 6)
        let fiber = sqlite3_column_double(statement, 7)
        let category = sqlite3_column_text(statement, 8).map { String(cString: $0) }
        let source = sqlite3_column_text(statement, 9).map { String(cString: $0) }
        let barcode = sqlite3_column_text(statement, 10).map { String(cString: $0) }
        let servingSize = sqlite3_column_double(statement, 11)
        let servingUnit = sqlite3_column_text(statement, 12).map { String(cString: $0) } ?? "g"
        let servingOptions = sqlite3_column_text(statement, 13).map { String(cString: $0) } ?? "[]"

        return LocalFoodResult(
            fdcId: fdcId,
            name: name,
            brand: brand,
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            fiberPer100g: fiber,
            category: category,
            source: source,
            barcode: barcode,
            servingSize: servingSize,
            servingUnit: servingUnit,
            servingOptions: servingOptions
        )
    }
}

// MARK: - Errors

enum LocalFoodDatabaseError: LocalizedError {
    case databaseUnavailable
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .databaseUnavailable:
            return "Food database is not available"
        case .queryFailed(let message):
            return "Database query failed: \(message)"
        }
    }
}
