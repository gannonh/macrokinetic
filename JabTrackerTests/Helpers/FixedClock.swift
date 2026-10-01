//
//  FixedClock.swift
//  JabTrackerTests
//
//  Fixed calendar and instants so date-boundary tests never depend on when they run.
//

import Foundation

enum FixedClock {
    /// Gregorian calendar pinned to UTC, so results do not depend on the machine's time zone.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 1
        return calendar
    }()

    /// A UTC instant. Hour and minute default to noon so the day is unambiguous.
    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, minute: Int = 0) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone, year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
