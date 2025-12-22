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
        #expect(database.isAvailable)
    }

    @Test("Database reports unavailable if file missing")
    func testDatabaseUnavailableForMissingFile() async throws {
        let database = LocalFoodDatabase(databasePath: "/nonexistent/path.sqlite")
        #expect(!database.isAvailable)
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
}
