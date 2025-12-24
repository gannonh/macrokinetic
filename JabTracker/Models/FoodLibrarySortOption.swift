//
//  FoodLibrarySortOption.swift
//  JabTracker
//
//  Sort options for the Food Library.
//

import Foundation

/// Sort options for the Food Library
enum FoodLibrarySortOption: String, CaseIterable {
    case modified  // Date Added (newest first)
    case name  // Alphabetical

    var displayName: String {
        switch self {
        case .modified:
            return "Modified"
        case .name:
            return "Name"
        }
    }
}
