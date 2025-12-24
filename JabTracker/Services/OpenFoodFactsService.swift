//
//  OpenFoodFactsService.swift
//  JabTracker
//

import Foundation
import OSLog

/// Result from Open Food Facts API
struct OpenFoodFactsResult {
    let barcode: String?
    let name: String
    let brand: String?
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double
    let servingSize: String?
}

/// Service for searching the Open Food Facts API
@MainActor
final class OpenFoodFactsService {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "OpenFoodFactsService")

    private let baseURL = "https://world.openfoodfacts.org"
    private let session: URLSession

    /// Initialize with default session
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30  // Increased from 10s - OFF API can be slow
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    /// Initialize with custom session (for testing)
    init(session: URLSession) {
        self.session = session
    }

    // MARK: - Search Methods

    /// Search for products by name
    /// - Parameters:
    ///   - query: Search term
    ///   - limit: Maximum results to return
    /// - Returns: Array of matching products
    func search(query: String, limit: Int = 20) async throws -> [OpenFoodFactsResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        guard let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            Self.logger.warning("Failed to encode query: \(query)")
            return []
        }

        let urlString =
            "\(baseURL)/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&json=1&page_size=\(limit)"

        guard let url = URL(string: urlString) else {
            throw OpenFoodFactsError.invalidURL
        }

        do {
            let (data, _) = try await session.data(from: url)
            return try parseSearchResponse(data)
        } catch let error as OpenFoodFactsError {
            throw error
        } catch {
            Self.logger.error("Search failed: \(error.localizedDescription)")
            throw OpenFoodFactsError.networkError(error)
        }
    }

    /// Look up a product by barcode
    /// - Parameter barcode: Product barcode (EAN-13, UPC-A, etc.)
    /// - Returns: Product if found, nil otherwise
    func lookup(barcode: String) async throws -> OpenFoodFactsResult? {
        let trimmedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBarcode.isEmpty else {
            return nil
        }

        // URL-encode barcode for path safety (prevents URL injection)
        guard let encodedBarcode = trimmedBarcode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw OpenFoodFactsError.invalidURL
        }
        let urlString = "\(baseURL)/api/v0/product/\(encodedBarcode).json"

        guard let url = URL(string: urlString) else {
            throw OpenFoodFactsError.invalidURL
        }

        do {
            let (data, _) = try await session.data(from: url)
            return try parseBarcodeResponse(data)
        } catch let error as OpenFoodFactsError {
            throw error
        } catch {
            Self.logger.error("Barcode lookup failed: \(error.localizedDescription)")
            throw OpenFoodFactsError.networkError(error)
        }
    }

    // MARK: - Response Parsing

    private func parseSearchResponse(_ data: Data) throws -> [OpenFoodFactsResult] {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw OpenFoodFactsError.invalidResponse
            }

            guard let products = json["products"] as? [[String: Any]] else {
                return []
            }

            return products.compactMap { parseProduct($0) }
        } catch is OpenFoodFactsError {
            throw OpenFoodFactsError.invalidResponse
        } catch {
            Self.logger.error("Failed to parse search response: \(error.localizedDescription)")
            throw OpenFoodFactsError.parsingError(error)
        }
    }

    private func parseBarcodeResponse(_ data: Data) throws -> OpenFoodFactsResult? {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw OpenFoodFactsError.invalidResponse
            }

            // Check status
            guard let status = json["status"] as? Int, status == 1 else {
                // Product not found
                return nil
            }

            guard let product = json["product"] as? [String: Any] else {
                return nil
            }

            return parseProduct(product)
        } catch is OpenFoodFactsError {
            throw OpenFoodFactsError.invalidResponse
        } catch {
            Self.logger.error("Failed to parse barcode response: \(error.localizedDescription)")
            throw OpenFoodFactsError.parsingError(error)
        }
    }

    private func parseProduct(_ product: [String: Any]) -> OpenFoodFactsResult? {
        // Extract name - required field
        guard let name = product["product_name"] as? String, !name.isEmpty else {
            return nil
        }

        let barcode = product["code"] as? String
        let brand = product["brands"] as? String
        let servingSize = product["serving_size"] as? String

        // Extract nutrients
        let nutriments = product["nutriments"] as? [String: Any] ?? [:]

        let calories = extractNutrient(from: nutriments, key: "energy-kcal_100g")
        let protein = extractNutrient(from: nutriments, key: "proteins_100g")
        let carbs = extractNutrient(from: nutriments, key: "carbohydrates_100g")
        let fat = extractNutrient(from: nutriments, key: "fat_100g")
        let fiber = extractNutrient(from: nutriments, key: "fiber_100g")

        return OpenFoodFactsResult(
            barcode: barcode,
            name: name,
            brand: brand,
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            fiberPer100g: fiber,
            servingSize: servingSize
        )
    }

    private func extractNutrient(from nutriments: [String: Any], key: String) -> Double {
        // Try to get as Double first
        if let value = nutriments[key] as? Double {
            return value
        }
        // Try as Int
        if let value = nutriments[key] as? Int {
            return Double(value)
        }
        // Try as String
        if let valueString = nutriments[key] as? String, let value = Double(valueString) {
            return value
        }
        return 0.0
    }
}

// MARK: - Errors

enum OpenFoodFactsError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case parsingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from Open Food Facts"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parsingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}
