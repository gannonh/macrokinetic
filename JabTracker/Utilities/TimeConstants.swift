//
//  TimeConstants.swift
//  JabTracker
//
//  Created by Claude Code on 2025-10-07.
//

import Foundation

/// Centralized time constants for schedule calculations.
///
/// Provides single source of truth for time-related values used across
/// ScheduleService and its extensions. All values are in seconds (TimeInterval).
///
/// ## Usage Examples
/// ```swift
/// // Convert minutes to seconds
/// let windowBefore = TimeInterval(config.windowMinutesBefore * 60)
/// // Using constant:
/// let windowBefore = TimeInterval(config.windowMinutesBefore) * TimeConstants.secondsPerMinute
///
/// // Calculate 7 days in seconds
/// let maxShift: TimeInterval = 7 * 24 * 60 * 60
/// // Using helper:
/// let maxShift = TimeConstants.days(7)
/// ```
enum TimeConstants {
    // MARK: - Adherence Window Defaults

    /// Default adherence window before scheduled time (minutes)
    static let defaultWindowMinutes: Int = 120  // 2 hours

    /// Default adherence window before scheduled time (seconds)
    static let defaultWindowSeconds: TimeInterval = TimeInterval(defaultWindowMinutes * 60)

    // MARK: - Reschedule Limits

    /// Maximum number of days a dose can be rescheduled
    static let maxRescheduleDays: Int = 7

    /// Maximum time shift for rescheduling (seconds)
    static let maxRescheduleSeconds: TimeInterval = TimeInterval(maxRescheduleDays * 24 * 60 * 60)

    // MARK: - Schedule Pattern Intervals

    /// Split-dose interval for twice-weekly dosing (3.5 days in minutes)
    ///
    /// Used for split-dose schedule patterns where a weekly medication
    /// is divided into two doses separated by 3.5 days (e.g., Monday + Thursday).
    /// This ensures even distribution across the week.
    ///
    /// - Note: Value is in minutes for compatibility with ScheduleConfiguration.splitIntervalMinutes
    static let splitDoseInterval: Int = 5040  // 3.5 days * 24 hours * 60 minutes

    // MARK: - Time Unit Conversions

    /// Seconds in one minute
    static let secondsPerMinute: TimeInterval = 60

    /// Seconds in one hour
    static let secondsPerHour: TimeInterval = 3600

    /// Seconds in one day
    static let secondsPerDay: TimeInterval = 86400

    /// Seconds in one week (7 days)
    static let secondsPerWeek: TimeInterval = 604800

    // MARK: - Helper Methods

    /**
     * Converts a number of days to seconds.
     *
     * - Parameter count: Number of days
     * - Returns: Equivalent time interval in seconds
     *
     * ## Example
     * ```swift
     * let sevenDays = TimeConstants.days(7)  // 604800 seconds
     * ```
     */
    static func days(_ count: Int) -> TimeInterval {
        TimeInterval(count) * secondsPerDay
    }

    /**
     * Converts a number of hours to seconds.
     *
     * - Parameter count: Number of hours
     * - Returns: Equivalent time interval in seconds
     *
     * ## Example
     * ```swift
     * let twoHours = TimeConstants.hours(2)  // 7200 seconds
     * ```
     */
    static func hours(_ count: Int) -> TimeInterval {
        TimeInterval(count) * secondsPerHour
    }

    /**
     * Converts a number of minutes to seconds.
     *
     * - Parameter count: Number of minutes
     * - Returns: Equivalent time interval in seconds
     *
     * ## Example
     * ```swift
     * let thirtyMinutes = TimeConstants.minutes(30)  // 1800 seconds
     * ```
     */
    static func minutes(_ count: Int) -> TimeInterval {
        TimeInterval(count) * secondsPerMinute
    }
}
