//
//  ScheduleConfiguration.swift
//  JabTracker
//
//  Value types for food schedule configuration.
//

import Foundation

/// Days of week using Calendar.Component.weekday convention (1=Sunday through 7=Saturday)
enum ScheduleDay: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    /// Full display name (e.g., "Monday")
    var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    /// Three-letter abbreviation (e.g., "Mon")
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

/// A single day+meal combination for the schedule
struct ScheduleDayMealConfig: Codable, Equatable, Identifiable {
    let id: UUID
    var day: ScheduleDay
    var meal: MealSection

    init(id: UUID = UUID(), day: ScheduleDay, meal: MealSection) {
        self.id = id
        self.day = day
        self.meal = meal
    }
}

/// Complete schedule configuration containing day+meal combinations
struct ScheduleConfig: Codable, Equatable {
    var dayMealConfigs: [ScheduleDayMealConfig]

    init(dayMealConfigs: [ScheduleDayMealConfig] = []) {
        self.dayMealConfigs = dayMealConfigs
    }

    /// All unique days in this schedule
    var scheduledDays: Set<ScheduleDay> {
        Set(dayMealConfigs.map { $0.day })
    }

    /// All unique meals in this schedule
    var scheduledMeals: Set<MealSection> {
        Set(dayMealConfigs.map { $0.meal })
    }

    /// Meals scheduled for a specific day
    func meals(for day: ScheduleDay) -> [MealSection] {
        dayMealConfigs.filter { $0.day == day }.map { $0.meal }
    }

    /// Whether a specific day+meal is scheduled
    func isScheduled(day: ScheduleDay, meal: MealSection) -> Bool {
        dayMealConfigs.contains { $0.day == day && $0.meal == meal }
    }

    /// Validation - at least one configuration required
    var isValid: Bool {
        !dayMealConfigs.isEmpty
    }
}
