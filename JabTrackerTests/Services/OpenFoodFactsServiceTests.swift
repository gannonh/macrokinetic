//
//  OpenFoodFactsServiceTests.swift
//  JabTrackerTests
//

import Foundation
import Testing

@testable import JabTracker

/// Tests for OpenFoodFactsService
/// Verifies API client functionality with URL protocol mocking
@Suite("OpenFoodFactsService Tests")
@MainActor
struct OpenFoodFactsServiceTests {

    // MARK: - Search Tests

    @Test("Search returns results for valid query")
    func testSearchReturnsResults() async throws {
        let mockSession = createMockSession(withJSON: searchResponseJSON)
        let service = OpenFoodFactsService(session: mockSession)

        let results = try await service.search(query: "chicken")

        #expect(!results.isEmpty)
    }

    @Test("Search handles empty response")
    func testSearchHandlesEmptyResponse() async throws {
        let emptyJSON = """
            {
                "count": 0,
                "page": 1,
                "page_size": 20,
                "products": []
            }
            """
        let mockSession = createMockSession(withJSON: emptyJSON)
        let service = OpenFoodFactsService(session: mockSession)

        let results = try await service.search(query: "xyznonexistent")

        #expect(results.isEmpty)
    }

    @Test("Search respects limit parameter")
    func testSearchRespectsLimit() async throws {
        let mockSession = createMockSession(withJSON: searchResponseJSON)
        let service = OpenFoodFactsService(session: mockSession)

        let results = try await service.search(query: "chicken", limit: 5)

        #expect(results.count <= 5)
    }

    @Test("Search handles empty query")
    func testSearchHandlesEmptyQuery() async throws {
        let mockSession = createMockSession(withJSON: searchResponseJSON)
        let service = OpenFoodFactsService(session: mockSession)

        let results = try await service.search(query: "")

        #expect(results.isEmpty)
    }

    @Test("Search handles whitespace query")
    func testSearchHandlesWhitespaceQuery() async throws {
        let mockSession = createMockSession(withJSON: searchResponseJSON)
        let service = OpenFoodFactsService(session: mockSession)

        let results = try await service.search(query: "   ")

        #expect(results.isEmpty)
    }

    // MARK: - Result Parsing Tests

    @Test("Search results contain nutrition data")
    func testSearchResultsContainNutritionData() async throws {
        let mockSession = createMockSession(withJSON: searchResponseJSON)
        let service = OpenFoodFactsService(session: mockSession)

        let results = try await service.search(query: "chicken")

        guard let first = results.first else {
            Issue.record("No results returned")
            return
        }

        #expect(first.caloriesPer100g > 0 || first.proteinPer100g > 0)
    }

    @Test("Search results have product name")
    func testSearchResultsHaveProductName() async throws {
        let mockSession = createMockSession(withJSON: searchResponseJSON)
        let service = OpenFoodFactsService(session: mockSession)

        let results = try await service.search(query: "chicken")

        for result in results {
            #expect(!result.name.isEmpty, "Product name should not be empty")
        }
    }

    @Test("Search results have valid barcode when present")
    func testSearchResultsHaveValidBarcode() async throws {
        let mockSession = createMockSession(withJSON: searchResponseJSON)
        let service = OpenFoodFactsService(session: mockSession)

        let results = try await service.search(query: "chicken")

        guard let first = results.first, let barcode = first.barcode else {
            return  // Barcode is optional
        }

        #expect(!barcode.isEmpty)
    }

    // MARK: - Barcode Lookup Tests

    @Test("Lookup by barcode returns product")
    func testLookupByBarcode() async throws {
        let mockSession = createMockSession(withJSON: barcodeResponseJSON)
        let service = OpenFoodFactsService(session: mockSession)

        let result = try await service.lookup(barcode: "5000159407236")

        #expect(result != nil)
        #expect(result?.name == "Heinz Baked Beans")
    }

    @Test("Lookup by invalid barcode returns nil")
    func testLookupByInvalidBarcode() async throws {
        let notFoundJSON = """
            {
                "status": 0,
                "status_verbose": "product not found"
            }
            """
        let mockSession = createMockSession(withJSON: notFoundJSON)
        let service = OpenFoodFactsService(session: mockSession)

        let result = try await service.lookup(barcode: "000000000000")

        #expect(result == nil)
    }

    @Test("Lookup handles empty barcode")
    func testLookupHandlesEmptyBarcode() async throws {
        let mockSession = createMockSession(withJSON: barcodeResponseJSON)
        let service = OpenFoodFactsService(session: mockSession)

        let result = try await service.lookup(barcode: "")

        #expect(result == nil)
    }

    // MARK: - Error Handling Tests

    @Test("Search throws on network error")
    func testSearchThrowsOnNetworkError() async throws {
        let mockSession = createMockSession(withError: URLError(.notConnectedToInternet))
        let service = OpenFoodFactsService(session: mockSession)

        do {
            _ = try await service.search(query: "chicken")
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is OpenFoodFactsError)
        }
    }

    @Test("Search throws on invalid JSON")
    func testSearchThrowsOnInvalidJSON() async throws {
        let mockSession = createMockSession(withJSON: "not valid json")
        let service = OpenFoodFactsService(session: mockSession)

        do {
            _ = try await service.search(query: "chicken")
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is OpenFoodFactsError)
        }
    }

    // MARK: - Test Data

    private var searchResponseJSON: String {
        """
        {
            "count": 2,
            "page": 1,
            "page_size": 20,
            "products": [
                {
                    "code": "1234567890123",
                    "product_name": "Chicken Breast",
                    "brands": "TestBrand",
                    "nutriments": {
                        "energy-kcal_100g": 165,
                        "proteins_100g": 31,
                        "carbohydrates_100g": 0,
                        "fat_100g": 3.6,
                        "fiber_100g": 0
                    },
                    "serving_size": "100g"
                },
                {
                    "code": "9876543210987",
                    "product_name": "Grilled Chicken",
                    "brands": "AnotherBrand",
                    "nutriments": {
                        "energy-kcal_100g": 155,
                        "proteins_100g": 28,
                        "carbohydrates_100g": 1,
                        "fat_100g": 4.5,
                        "fiber_100g": 0.5
                    }
                }
            ]
        }
        """
    }

    private var barcodeResponseJSON: String {
        """
        {
            "status": 1,
            "status_verbose": "product found",
            "product": {
                "code": "5000159407236",
                "product_name": "Heinz Baked Beans",
                "brands": "Heinz",
                "nutriments": {
                    "energy-kcal_100g": 81,
                    "proteins_100g": 4.7,
                    "carbohydrates_100g": 12.5,
                    "fat_100g": 0.2,
                    "fiber_100g": 3.7
                }
            }
        }
        """
    }

    // MARK: - Mock Session Helper

    private func createMockSession(withJSON json: String) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        MockURLProtocol.requestHandler = { _ in
            let data = json.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: URL(string: "https://world.openfoodfacts.org")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }
        return URLSession(configuration: config)
    }

    private func createMockSession(withError error: Error) -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        MockURLProtocol.requestHandler = { _ in
            throw error
        }
        return URLSession(configuration: config)
    }
}

// MARK: - Mock URL Protocol

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
