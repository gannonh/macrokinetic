//
//  FoodLibrarySortOption.swift
//  JabTracker
//
//  Sort options for the Food Library.
//

import Foundation

/// Sort options for the Food Library
enum FoodLibrarySortOption: String, CaseIterable {
    case dateAdded  // Date Added (newest first)
    case name  // Alphabetical

    var displayName: String {
        switch self {
        case .dateAdded:
            return "Date Added"
        case .name:
            return "Name"
        }
    }
}
