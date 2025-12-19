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

    @Test("Search results include category")
    func testSearchResultsIncludeCategory() async throws {
        let database = LocalFoodDatabase()

        let results = try await database.search(query: "banana")

        guard let banana = results.first else {
            Issue.record("No results found for banana")
            return
        }

        #expect(banana.category == "Fruits and Fruit Juices", "Banana should be in Fruits category")
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
}
