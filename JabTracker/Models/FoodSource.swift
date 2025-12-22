//
//  FoodSource.swift
//  JabTracker
//
//  Identifies the source of food data for attribution and sync.
//

import Foundation

/// Source of food data for attribution and sync
enum FoodSource: String, Codable, CaseIterable {
    /// Bundled USDA database
    case local
    /// Open Food Facts API
    case openFoodFacts
    /// User-added custom foods
    case userCreated

    /// Human-readable display name for the source
    var displayName: String {
        switch self {
        case .local:
            return "USDA"
        case .openFoodFacts:
            return "Open Food Facts"
        case .userCreated:
            return "Custom"
        }
    }

    /// SF Symbol icon name for the source
    var iconName: String {
        switch self {
        case .local:
            return "leaf.fill"  // Whole foods / raw ingredients
        case .openFoodFacts:
            return "barcode"  // Packaged / branded foods
        case .userCreated:
            return "person.fill"  // User-created
        }
    }
}
