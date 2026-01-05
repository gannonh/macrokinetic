//
//  Tab.swift
//  JabTracker
//
//  Main app navigation tabs with enum-based type safety.
//

import SwiftUI

/// Main app navigation tabs
enum Tab: String, CaseIterable, Identifiable {
    case dashboard
    case foodLog
    case add
    case strategy
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .foodLog: return "Food Log"
        case .add: return "Add"
        case .strategy: return "Strategy"
        case .more: return "More"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .foodLog: return "fork.knife"
        case .add: return "plus.circle.fill"
        case .strategy: return "target"
        case .more: return "ellipsis.circle"
        }
    }

    /// Tabs visible in main tab bar
    static var mainTabs: [Tab] {
        [.dashboard, .foodLog, .add, .strategy, .more]
    }
}
