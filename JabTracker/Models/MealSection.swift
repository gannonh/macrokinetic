//
//  MealSection.swift
//  JabTracker
//
//  Meal sections for categorizing food entries throughout the day.
//

import Foundation

/// Meal sections for categorizing food entries throughout the day
enum MealSection: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snacks

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snacks: return "Snacks"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snacks: return "leaf.fill"
        }
    }

    /// Default time range (hour of day) for each meal section
    var defaultTimeRange: ClosedRange<Int> {
        switch self {
        case .breakfast: return 5...10
        case .lunch: return 11...14
        case .dinner: return 17...21
        case .snacks: return 0...23  // Any time
        }
    }

    /// Determines meal section from time of day
    static func from(date: Date) -> MealSection {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5...10: return .breakfast
        case 11...14: return .lunch
        case 17...21: return .dinner
        default: return .snacks
        }
    }
}
