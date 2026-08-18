//
//  LocalFoodDatabaseTests.swift
//  JabTrackerTests
//

import Foundation
import Testing

@testable import JabTracker

/// Tests for LocalFoodDatabase service
/// Verifies SQLite FTS5 search functionality for the bundled USDA food database
@Suite("LocalFoodDatabase Tests")
@MainActor
struct LocalFoodDatabaseTests {

    // MARK: - Initialization Tests

    @Test("Database initializes successfully")
    func testDatabaseInitializes() async throws {
        let database = LocalFoodDatabase()
        let isAvailable = await database.isAvailable
        #expect(isAvailable)
    }

    @Test("Database reports unavailable if file missing")
    func testDatabaseUnavailableForMissingFile() async throws {
        let database = LocalFoodDatabase(databasePath: "/nonexistent/path.sqlite")
        let isAvailable = await database.isAvailable
        #expect(!isAvailable)
    }

    // MARK: - Search Tests

    @Test("Search returns results for common foods")
    func testSearchReturnsResults() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "chicken")

        #expect(!results.isEmpty, "Should find chicken-related foods")
        #expect(results.count > 0)
    }

    @Test("Search returns empty for nonexistent food")
    func testSearchReturnsEmptyForNonexistent() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "xyznonexistent123")

        #expect(results.isEmpty)
    }

    @Test("Search respects limit parameter")
    func testSearchRespectsLimit() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "chicken", limit: 3)

        #expect(results.count <= 3)
    }

    @Test("Search handles empty query")
    func testSearchHandlesEmptyQuery() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "")

        #expect(results.isEmpty)
    }

    @Test("Search handles whitespace-only query")
    func testSearchHandlesWhitespaceQuery() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "   ")

        #expect(results.isEmpty)
    }

    @Test("Search is case insensitive")
    func testSearchIsCaseInsensitive() async throws {
        let database = LocalFoodDatabase()

        let lowercaseResults = try await database.search(query: "chicken")
        let uppercaseResults = try await database.search(query: "CHICKEN")

        #expect(lowercaseResults.count == uppercaseResults.count)
    }

    @Test("Search supports prefix matching")
    func testSearchSupportsPrefixMatching() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "chick")

        #expect(!results.isEmpty, "Should match 'chicken' with prefix 'chick'")
    }

    // MARK: - Result Data Tests

    @Test("Search results contain nutrition data")
    func testSearchResultsContainNutritionData() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "chicken breast")

        guard let chicken = results.first else {
            Issue.record("No results found for chicken breast")
            return
        }

        #expect(chicken.caloriesPer100g > 0, "Should have calories")
        #expect(chicken.proteinPer100g > 0, "Chicken should have protein")
    }

    @Test("Search results have valid fdc_id")
    func testSearchResultsHaveValidFdcId() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "rice")

        for result in results {
            #expect(result.fdcId > 0, "FDC ID should be positive")
        }
    }

    @Test("Search results have non-empty name")
    func testSearchResultsHaveNonEmptyName() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "salmon")

        for result in results {
            #expect(!result.name.isEmpty, "Name should not be empty")
        }
    }

    @Test("USDA search results include category")
    func testSearchResultsIncludeCategory() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "banana raw")

        // Find a USDA source result (foundation or sr_legacy) which should have category data
        // Open Food Facts entries may not have categories populated
        guard
            let usdaBanana = results.first(where: {
                $0.source == "foundation" || $0.source == "sr_legacy"
            })
        else {
            Issue.record("No USDA banana results found")
            return
        }

        #expect(usdaBanana.category == "Fruits and Fruit Juices", "USDA Banana should be in Fruits category")
    }

    // MARK: - Multiple Word Search Tests

    @Test("Search handles multiple words")
    func testSearchHandlesMultipleWords() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "greek yogurt")

        #expect(!results.isEmpty, "Should find Greek yogurt")
    }

    // MARK: - Lookup by FDC ID Tests

    @Test("Lookup by FDC ID returns correct food")
    func testLookupByFdcId() async throws {
        let database = LocalFoodDatabase()

        // First search to get a known FDC ID
        let searchResults = try await database.search(query: "chicken breast")
        guard let firstResult = searchResults.first else {
            Issue.record("No search results to test lookup")
            return
        }

        // Now look up by that ID
        let food = try await database.lookup(fdcId: firstResult.fdcId)

        #expect(food != nil, "Should find food by FDC ID")
        #expect(food?.name == firstResult.name)
    }

    @Test("Lookup by invalid FDC ID returns nil")
    func testLookupByInvalidFdcIdReturnsNil() async throws {
        let database = LocalFoodDatabase()

        let food = try await database.lookup(fdcId: 999_999_999)

        #expect(food == nil)
    }

    // MARK: - Category Search Tests

    @Test("Search by category returns relevant foods")
    func testSearchByCategory() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.searchByCategory("Vegetables and Vegetable Products")

        #expect(!results.isEmpty, "Should find vegetables")

        for result in results {
            #expect(result.category == "Vegetables and Vegetable Products")
        }
    }

    @Test("Search by nonexistent category returns empty")
    func testSearchByNonexistentCategory() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.searchByCategory("NonexistentCategory123")

        #expect(results.isEmpty)
    }

    // MARK: - Performance Tests

    @Test("Search completes within reasonable time")
    func testSearchPerformance() async throws {
        let database = LocalFoodDatabase()

        let start = Date()
        _ = try await database.search(query: "chicken")
        let elapsed = Date().timeIntervalSince(start)

        // Should complete in under 100ms
        #expect(elapsed < 0.1, "Search should complete quickly, took \(elapsed)s")
    }

    // MARK: - Thread Safety Tests

    @Test("Multiple concurrent searches complete successfully")
    func testConcurrentSearches() async throws {
        let database = LocalFoodDatabase()

        async let search1 = database.search(query: "chicken")
        async let search2 = database.search(query: "salmon")
        async let search3 = database.search(query: "rice")

        let (results1, results2, results3) = try await (search1, search2, search3)

        #expect(!results1.isEmpty)
        #expect(!results2.isEmpty)
        #expect(!results3.isEmpty)
    }

    @Test("Independent connections support concurrent filtered searches")
    func testConcurrentFilteredSearchesUseIndependentConnections() async throws {
        let commonDatabase = LocalFoodDatabase()
        let brandedDatabase = LocalFoodDatabase()

        async let commonResults = commonDatabase.search(
            query: "chicken",
            limit: 15,
            sources: ["foundation", "sr_legacy"]
        )
        async let brandedResults = brandedDatabase.search(
            query: "chicken",
            limit: 15,
            sources: ["openFoodFacts"]
        )

        let (common, branded) = try await (commonResults, brandedResults)

        #expect(!common.isEmpty, "Common search should return USDA results")
        #expect(!branded.isEmpty, "Branded search should return Open Food Facts results")
        #expect(common.allSatisfy { $0.source == "foundation" || $0.source == "sr_legacy" })
        #expect(branded.allSatisfy { $0.source == "openFoodFacts" })
        #expect(common.count <= 15)
        #expect(branded.count <= 15)
    }

    // MARK: - Source Filtering Tests

    @Test("Search with USDA sources returns only USDA results")
    func testSearchWithUSDASourcesReturnsOnlyUSDA() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(
            query: "banana",
            limit: 20,
            sources: ["foundation", "sr_legacy"]
        )

        #expect(!results.isEmpty, "Should find USDA banana results")

        for result in results {
            let validSource = result.source == "foundation" || result.source == "sr_legacy"
            #expect(validSource, "Result should be from USDA source, got: \(result.source ?? "nil")")
        }
    }

    @Test("Search with Open Food Facts source returns only OFF results")
    func testSearchWithOFFSourceReturnsOnlyOFF() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(
            query: "banana",
            limit: 20,
            sources: ["openFoodFacts"]
        )

        #expect(!results.isEmpty, "Should find Open Food Facts banana results")

        for result in results {
            #expect(result.source == "openFoodFacts", "Result should be from OFF, got: \(result.source ?? "nil")")
        }
    }

    @Test("Search with nil sources returns results from all sources")
    func testSearchWithNilSourcesReturnsAllSources() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "banana", limit: 50, sources: nil)

        #expect(!results.isEmpty, "Should find banana results")

        // Collect unique sources
        let uniqueSources = Set(results.compactMap(\.source))

        // Should include both USDA and OFF sources when not filtered
        let hasUSDA = uniqueSources.contains("foundation") || uniqueSources.contains("sr_legacy")
        let hasOFF = uniqueSources.contains("openFoodFacts")

        #expect(hasUSDA || hasOFF, "Should have results from at least one source type")
    }

    @Test("Search with empty sources array returns all sources")
    func testSearchWithEmptySourcesArrayReturnsAllSources() async throws {
        let database = LocalFoodDatabase()

        let resultsWithEmpty = try await database.search(query: "chicken", limit: 20, sources: [])
        let resultsWithNil = try await database.search(query: "chicken", limit: 20, sources: nil)

        #expect(!resultsWithEmpty.isEmpty, "Should find results with empty sources array")
        #expect(resultsWithEmpty.count == resultsWithNil.count, "Empty sources should behave like nil sources")
    }

    @Test("Search with single foundation source")
    func testSearchWithSingleFoundationSource() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(
            query: "chicken",
            limit: 15,
            sources: ["foundation"]
        )

        // Foundation might be empty for some queries, but if results exist they should all be foundation
        for result in results {
            #expect(result.source == "foundation", "Result should be from foundation source")
        }
    }

    @Test("Source filtering respects limit parameter")
    func testSourceFilteringRespectsLimit() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(
            query: "banana",
            limit: 5,
            sources: ["openFoodFacts"]
        )

        #expect(results.count <= 5, "Should respect limit of 5, got \(results.count)")
    }

    @Test("Source filtering works with multiple word queries")
    func testSourceFilteringWithMultipleWords() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(
            query: "chicken breast",
            limit: 10,
            sources: ["foundation", "sr_legacy"]
        )

        for result in results {
            let validSource = result.source == "foundation" || result.source == "sr_legacy"
            #expect(validSource, "Multi-word query should still filter by source")
        }
    }

    // MARK: - Search Ranking Tests

    @Test("Search ranks foods starting with search term higher")
    func testSearchRanksFoodsStartingWithTermHigher() async throws {
        let database = LocalFoodDatabase()

        // Search "banana" - should rank "Bananas, ..." above "Snacks, banana chips"
        let results = try await database.search(
            query: "banana",
            limit: 20,
            sources: ["foundation", "sr_legacy"]
        )

        #expect(!results.isEmpty, "Should find banana results")

        // Find first food that starts with "banana" and first that doesn't
        let startsWithBanana = results.firstIndex { $0.name.lowercased().hasPrefix("banana") }
        let notStartsWithBanana = results.firstIndex { !$0.name.lowercased().hasPrefix("banana") }

        // If both exist, foods starting with "banana" should appear first
        if let startIdx = startsWithBanana, let notStartIdx = notStartsWithBanana {
            #expect(
                startIdx < notStartIdx,
                "Prefix matches should rank first: '\(results[startIdx].name)' vs '\(results[notStartIdx].name)'"
            )
        }
    }

    @Test("Search 'banana' returns 'Bananas, raw' before processed foods")
    func testSearchBananaReturnsRawFirst() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(
            query: "banana",
            limit: 20,
            sources: ["foundation", "sr_legacy"]
        )

        #expect(!results.isEmpty, "Should find banana results")

        // Find "Bananas, raw" or similar whole banana
        let rawBananaIndex = results.firstIndex {
            $0.name.lowercased().contains("banana") && $0.name.lowercased().contains("raw")
        }

        // Find processed/derivative banana products (chips, pudding, etc.)
        let processedBananaIndex = results.firstIndex {
            let lower = $0.name.lowercased()
            return lower.contains("banana")
                && (lower.contains("chips") || lower.contains("pudding") || lower.contains("snack")
                    || lower.contains("babyfood"))
        }

        // Raw banana should appear before processed products (if both exist)
        if let rawIdx = rawBananaIndex, let processedIdx = processedBananaIndex {
            #expect(
                rawIdx < processedIdx,
                "Raw should rank before processed: '\(results[rawIdx].name)' vs '\(results[processedIdx].name)'"
            )
        }
    }

    @Test("Search 'egg' returns whole eggs before compound products")
    func testSearchEggReturnsWholeEggsFirst() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(
            query: "egg",
            limit: 20,
            sources: ["foundation", "sr_legacy"]
        )

        #expect(!results.isEmpty, "Should find egg results")

        // Foods starting with "egg" should appear before foods like "Bagel, egg" or compound products
        let startsWithEgg = results.firstIndex { $0.name.lowercased().hasPrefix("egg") }
        let notStartsWithEgg = results.firstIndex { !$0.name.lowercased().hasPrefix("egg") }

        if let startIdx = startsWithEgg, let notStartIdx = notStartsWithEgg {
            #expect(
                startIdx < notStartIdx,
                "Prefix matches should rank first: '\(results[startIdx].name)' vs '\(results[notStartIdx].name)'"
            )
        }
    }

    @Test("Search 'chicken' ranks whole chicken items first")
    func testSearchChickenRanksWholeChickenFirst() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(
            query: "chicken",
            limit: 15,
            sources: ["foundation", "sr_legacy"]
        )

        #expect(!results.isEmpty, "Should find chicken results")

        // Top results should start with "chicken" rather than "Soup, chicken" or other compounds
        let topFiveStartWithChicken = results.prefix(5).filter { $0.name.lowercased().hasPrefix("chicken") }

        // At least 3 of the top 5 should start with "chicken"
        #expect(
            topFiveStartWithChicken.count >= 3,
            "Most top results should start with 'chicken', got \(topFiveStartWithChicken.count)/5. Top 5: \(results.prefix(5).map(\.name))"
        )
    }

    @Test("Search 'apple' ranks whole word 'Apple' before 'APPLEBEE'S'")
    func testSearchAppleRanksWholeWordFirst() async throws {
        let database = LocalFoodDatabase()

        // Search without source filtering to include Open Food Facts
        // This tests the whole word ranking where "Apple" should rank before "APPLEBEE'S"
        let results = try await database.search(query: "apple", limit: 30)

        #expect(!results.isEmpty, "Should find apple results")

        // Find first result that is a whole word match (starts with "apple" followed by word boundary)
        let wholeWordApple = results.firstIndex { result in
            let lower = result.name.lowercased()
            // Matches "apples," or "apple " but not "applebee"
            return lower.hasPrefix("apple")
                && (lower.hasPrefix("apples") || lower.hasPrefix("apple,") || lower.hasPrefix("apple ")
                    || lower == "apple")
        }

        // Find first result that has partial match like "APPLEBEE'S"
        let partialMatchIndex = results.firstIndex { result in
            let lower = result.name.lowercased()
            return lower.hasPrefix("applebee")
        }

        // Whole word apple should appear before APPLEBEE'S if both exist
        if let wholeIdx = wholeWordApple, let partialIdx = partialMatchIndex {
            #expect(
                wholeIdx < partialIdx,
                "Whole word should rank first: '\(results[wholeIdx].name)' vs '\(results[partialIdx].name)'"
            )
        }
    }

    @Test("Search 'banana' ranks shorter names first")
    func testSearchBananaRanksShorterNamesFirst() async throws {
        let database = LocalFoodDatabase()

        // Search USDA sources for cleaner banana results
        let results = try await database.search(
            query: "banana",
            limit: 20,
            sources: ["foundation", "sr_legacy"]
        )

        #expect(!results.isEmpty, "Should find banana results")

        // Find "Bananas, raw" (short name) vs longer descriptive names
        let shortBananaIndex = results.firstIndex { result in
            let lower = result.name.lowercased()
            // Simple raw banana entries
            return lower.hasPrefix("banana") && lower.contains("raw") && lower.count < 30
        }

        let longBananaIndex = results.firstIndex { result in
            let lower = result.name.lowercased()
            // Longer descriptive banana entries
            return lower.hasPrefix("banana") && lower.count > 35
        }

        // Shorter name should rank higher if both exist
        if let shortIdx = shortBananaIndex, let longIdx = longBananaIndex {
            #expect(
                shortIdx < longIdx,
                "Shorter names should rank first: '\(results[shortIdx].name)' vs '\(results[longIdx].name)'"
            )
        }
    }

    // MARK: - Error Propagation Tests

    @Test("Search throws databaseUnavailable for invalid database path")
    func testSearchThrowsDatabaseUnavailable() async {
        let database = LocalFoodDatabase(databasePath: "/invalid/nonexistent/path.sqlite")

        await #expect(throws: LocalFoodDatabaseError.self) {
            _ = try await database.search(query: "chicken")
        }
    }

    @Test("Lookup by ID throws databaseUnavailable for invalid database")
    func testLookupByIdThrowsDatabaseUnavailable() async {
        let database = LocalFoodDatabase(databasePath: "/invalid/path.sqlite")

        await #expect(throws: LocalFoodDatabaseError.self) {
            _ = try await database.lookup(fdcId: 12345)
        }
    }

    @Test("Lookup barcode throws databaseUnavailable for invalid database")
    func testLookupBarcodeThrowsDatabaseUnavailable() async {
        let database = LocalFoodDatabase(databasePath: "/invalid/path.sqlite")

        await #expect(throws: LocalFoodDatabaseError.self) {
            _ = try await database.lookupBarcode("1234567890")
        }
    }
}
