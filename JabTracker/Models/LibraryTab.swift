//
//  LibraryTab.swift
//  JabTracker
//
//  Library tabs for Food Library view.
//

import Foundation

/// Library tabs for future expansion
enum LibraryTab: String, CaseIterable {
    case recipes
    case foods
    case scheduled
    case favorites

    var displayName: String {
        switch self {
        case .recipes: return "Recipes"
        case .foods: return "Foods"
        case .scheduled: return "Scheduled"
        case .favorites: return "Favorites"
        }
    }

    var isEnabled: Bool {
        switch self {
        case .foods, .scheduled: return true
        case .recipes: return ReleasePolicy.isEnabled(.recipes)
        case .favorites: return ReleasePolicy.isEnabled(.foodFavorites)
        }
    }
}
