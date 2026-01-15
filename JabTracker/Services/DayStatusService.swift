//
//  DayStatusService.swift
//  JabTracker
//
//  Service for managing day status (fasting days).
//  Provides methods to mark days as fasting and query fasting status.
//

import Foundation
import OSLog
import SwiftData

/// Service for managing day status entries.
///
/// Handles setting and querying fasting status for specific dates.
/// Uses date normalization to ensure consistent day-level tracking.
@MainActor
@Observable
final class DayStatusService {
    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "DayStatusService"
    )

    private let context: ModelContext

    /// Initialize with model context
    /// - Parameter context: The SwiftData ModelContext for persistence
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Public Methods

    /// Set or update fasting status for a specific date
    /// - Parameters:
    ///   - date: The date to update
    ///   - isFasting: Whether the day should be marked as fasting
    /// - Throws: Error if save operation fails
    func setFasting(for date: Date, isFasting: Bool) throws {
        let normalizedDate = Calendar.current.startOfDay(for: date)

        if let existing = getDayStatus(for: normalizedDate) {
            // Update existing status
            existing.isFasting = isFasting
            existing.updatedAt = Date()
            Self.logger.debug(
                "Updated fasting status for \(normalizedDate): isFasting=\(isFasting)"
            )
        } else if isFasting {
            // Only create new entry if marking as fasting
            // No need to store "not fasting" entries - absence means not fasting
            let status = DayStatus(date: normalizedDate, isFasting: true)
            context.insert(status)
            Self.logger.debug(
                "Created fasting status for \(normalizedDate)"
            )
        }

        do {
            try context.save()
        } catch {
            Self.logger.error(
                "Failed to save fasting status for \(normalizedDate): \(error.localizedDescription)"
            )
            throw error
        }
    }

    /// Check if a specific date is marked as fasting
    /// - Parameter date: The date to check
    /// - Returns: true if the day is marked as fasting, false otherwise
    func isFasting(for date: Date) -> Bool {
        let status = getDayStatus(for: date)
        return status?.isFasting ?? false
    }

    /// Get all dates marked as fasting within a date range
    /// - Parameters:
    ///   - startDate: Start of the date range (inclusive)
    ///   - endDate: End of the date range (inclusive)
    /// - Returns: Set of dates that are marked as fasting
    /// - Throws: Error if fetch operation fails
    func getFastingDates(from startDate: Date, to endDate: Date) throws -> Set<Date> {
        let calendar = Calendar.current
        let normalizedStart = calendar.startOfDay(for: startDate)
        let normalizedEnd = calendar.startOfDay(for: endDate)

        let descriptor = FetchDescriptor<DayStatus>(
            predicate: #Predicate { status in
                status.date >= normalizedStart && status.date <= normalizedEnd && status.isFasting == true
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        do {
            let statuses = try context.fetch(descriptor)
            let dates = Set(statuses.map { calendar.startOfDay(for: $0.date) })
            Self.logger.debug(
                "Found \(dates.count) fasting dates between \(normalizedStart) and \(normalizedEnd)"
            )
            return dates
        } catch {
            Self.logger.error(
                "Failed to fetch fasting dates: \(error.localizedDescription)"
            )
            throw error
        }
    }

    /// Get the DayStatus for a specific date, if one exists
    /// - Parameter date: The date to query
    /// - Returns: The DayStatus for that date, or nil if none exists
    func getDayStatus(for date: Date) -> DayStatus? {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        // Calculate the end of the day for range query
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: normalizedDate) else {
            return nil
        }

        let descriptor = FetchDescriptor<DayStatus>(
            predicate: #Predicate { status in
                status.date >= normalizedDate && status.date < endOfDay
            }
        )

        do {
            let statuses = try context.fetch(descriptor)
            return statuses.first
        } catch {
            Self.logger.error(
                "Failed to fetch day status for \(normalizedDate): \(error.localizedDescription)"
            )
            return nil
        }
    }
}
