//
//  DayStatus.swift
//  JabTracker
//
//  Tracks daily status for nutrition calculations.
//  Allows users to mark days as intentional fasting days.
//

import Foundation
import SwiftData

/// Day status model for tracking fasting state per day.
///
/// When a user does a full-day fast, they can mark it as a fasting day.
/// This tells the algorithm "I intentionally consumed zero calories" so it
/// counts as a 0-calorie day in calculations rather than being skipped as unknown data.
@Model
final class DayStatus {
    /// Unique identifier
    var id: UUID = UUID()

    /// Date for this status (normalized to start of day)
    /// This should be unique per day - one status per calendar day
    var date: Date

    /// Whether this day is marked as a fasting day
    /// When true, the day counts as 0-calorie in calculations
    /// When false with no food entries, the day is skipped as "unknown"
    var isFasting: Bool = false

    /// Timestamp when this status was created
    var createdAt: Date = Date()

    /// Timestamp when this status was last modified
    var updatedAt: Date = Date()

    /// Initialize a new DayStatus
    /// - Parameters:
    ///   - date: The date for this status (will be normalized to start of day)
    ///   - isFasting: Whether this day is a fasting day (default: false)
    init(date: Date, isFasting: Bool = false) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.isFasting = isFasting
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
