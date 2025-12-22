//
//  SearchMethodTabs.swift
//  JabTracker
//
//  Search method tabs for the food search sheet.
//

import SwiftUI

/// Available methods for adding food entries
enum SearchMethod: String, CaseIterable, Identifiable {
    case scan
    case search
    case ai
    case quickAdd
    case library

    var id: String { rawValue }

    /// Display name for the tab
    var displayName: String {
        switch self {
        case .scan: return "Scan"
        case .search: return "Search"
        case .ai: return "AI"
        case .quickAdd: return "Quick Add"
        case .library: return "Library"
        }
    }

    /// SF Symbol icon for the tab
    var icon: String {
        switch self {
        case .scan: return "barcode.viewfinder"
        case .search: return "magnifyingglass"
        case .ai: return "sparkles"
        case .quickAdd: return "plus.circle"
        case .library: return "books.vertical"
        }
    }

    /// Whether this method is currently functional
    var isEnabled: Bool {
        switch self {
        case .search: return true
        default: return false
        }
    }
}
