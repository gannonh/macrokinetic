//
//  MetricsService.swift
//  JabTracker
//
//  CRUD operations and queries for body metrics tracking.
//

import Foundation
import OSLog
import SwiftData

/// Errors for metrics service operations
enum MetricsServiceError: LocalizedError {
    case invalidMeasurement(String)
    case noEntriesFound
    case contextError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidMeasurement(let message):
            return "Invalid measurement: \(message)"
        case .noEntriesFound:
            return "No metrics entries found"
        case .contextError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }
}

/// Service for managing body metrics log entries
/// Provides CRUD operations and date-based queries
@MainActor
final class MetricsService {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "MetricsService")

    private let context: ModelContext

    /// Initialize with model context
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Validation Helpers

    /// Validate circumference measurement is within acceptable range
    /// - Parameter cm: Circumference in centimeters
    /// - Throws: MetricsServiceError.invalidMeasurement if out of range
    private func validateCircumference(_ cm: Double) throws {
        guard MetricsEntry.isValidCircumference(cm) else {
            let minCm = Int(MetricsEntry.minCircumferenceCm)
            let maxCm = Int(MetricsEntry.maxCircumferenceCm)
            throw MetricsServiceError.invalidMeasurement(
                "Circumference must be between \(minCm) cm and \(maxCm) cm"
            )
        }
    }

    // MARK: - Create

    /// Log a new metrics entry
    /// - Parameters:
    ///   - waistCm: Optional waist circumference in cm
    ///   - hipCm: Optional hip circumference in cm
    ///   - chestCm: Optional chest circumference in cm
    ///   - neckCm: Optional neck circumference in cm
    ///   - timestamp: When the measurement was taken
    ///   - notes: Optional notes
    /// - Returns: The created MetricsEntry
    /// - Throws: MetricsServiceError if validation fails or no measurements provided
    func logMetrics(
        waistCm: Double? = nil,
        hipCm: Double? = nil,
        chestCm: Double? = nil,
        neckCm: Double? = nil,
        timestamp: Date = Date(),
        notes: String? = nil
    ) async throws -> MetricsEntry {
        // Validate at least one measurement is provided
        guard waistCm != nil || hipCm != nil || chestCm != nil || neckCm != nil else {
            throw MetricsServiceError.invalidMeasurement("At least one measurement is required")
        }

        // Validate all provided measurements
        if let waist = waistCm {
            try validateCircumference(waist)
        }
        if let hip = hipCm {
            try validateCircumference(hip)
        }
        if let chest = chestCm {
            try validateCircumference(chest)
        }
        if let neck = neckCm {
            try validateCircumference(neck)
        }

        let entry = MetricsEntry(
            timestamp: timestamp,
            waistCm: waistCm,
            hipCm: hipCm,
            chestCm: chestCm,
            neckCm: neckCm,
            source: "manual",
            notes: notes
        )

        context.insert(entry)

        do {
            try context.save()
            Self.logger.info("Logged metrics entry at \(timestamp)")
            return entry
        } catch {
            throw MetricsServiceError.contextError(error)
        }
    }

    // MARK: - Read

    /// Get the most recent metrics entry
    /// - Returns: The latest MetricsEntry or nil if none exist
    func getLatestEntry() async throws -> MetricsEntry? {
        var descriptor = FetchDescriptor<MetricsEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        do {
            let entries = try context.fetch(descriptor)
            return entries.first
        } catch {
            throw MetricsServiceError.contextError(error)
        }
    }

    /// Get metrics entries within a date range
    /// - Parameters:
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    /// - Returns: Array of MetricsEntry sorted by timestamp descending
    func getEntries(from startDate: Date, to endDate: Date) async throws -> [MetricsEntry] {
        let descriptor = FetchDescriptor<MetricsEntry>(
            predicate: #Predicate { entry in
                entry.timestamp >= startDate && entry.timestamp <= endDate
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            throw MetricsServiceError.contextError(error)
        }
    }

    /// Get all metrics entries
    /// - Parameter limit: Maximum number of entries to return (nil for all)
    /// - Returns: Array of MetricsEntry sorted by timestamp descending
    func getAllEntries(limit: Int? = nil) async throws -> [MetricsEntry] {
        var descriptor = FetchDescriptor<MetricsEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        if let limit = limit {
            descriptor.fetchLimit = limit
        }

        do {
            return try context.fetch(descriptor)
        } catch {
            throw MetricsServiceError.contextError(error)
        }
    }

    // MARK: - Update

    /// Update an existing metrics entry
    /// - Parameters:
    ///   - entry: Entry to update
    ///   - waistCm: New waist circumference (optional, use inner nil to clear)
    ///   - hipCm: New hip circumference (optional, use inner nil to clear)
    ///   - chestCm: New chest circumference (optional, use inner nil to clear)
    ///   - neckCm: New neck circumference (optional, use inner nil to clear)
    ///   - notes: New notes (optional, use inner nil to clear)
    /// - Throws: MetricsServiceError if validation fails
    func updateEntry(
        _ entry: MetricsEntry,
        waistCm: Double?? = nil,
        hipCm: Double?? = nil,
        chestCm: Double?? = nil,
        neckCm: Double?? = nil,
        notes: String?? = nil
    ) async throws {
        // Save original values for rollback on validation failure
        let originalWaist = entry.waistCm
        let originalHip = entry.hipCm
        let originalChest = entry.chestCm
        let originalNeck = entry.neckCm

        do {
            try updateMeasurement(&entry.waistCm, newValue: waistCm)
            try updateMeasurement(&entry.hipCm, newValue: hipCm)
            try updateMeasurement(&entry.chestCm, newValue: chestCm)
            try updateMeasurement(&entry.neckCm, newValue: neckCm)

            if let notes = notes {
                entry.notes = notes
            }

            // Validate at least one measurement remains
            guard entry.hasAnyMetrics else {
                throw MetricsServiceError.invalidMeasurement("At least one measurement must be present")
            }
        } catch {
            // Roll back to original values on any validation error
            entry.waistCm = originalWaist
            entry.hipCm = originalHip
            entry.chestCm = originalChest
            entry.neckCm = originalNeck
            throw error
        }

        do {
            try context.save()
            Self.logger.info("Updated metrics entry")
        } catch {
            throw MetricsServiceError.contextError(error)
        }
    }

    /// Helper to update a measurement field with validation
    private func updateMeasurement(_ field: inout Double?, newValue: Double??) throws {
        if let newValue = newValue {
            if let value = newValue {
                try validateCircumference(value)
            }
            field = newValue
        }
    }

    // MARK: - Delete

    /// Delete a metrics entry
    /// - Parameter entry: Entry to delete
    func deleteEntry(_ entry: MetricsEntry) async throws {
        context.delete(entry)

        do {
            try context.save()
            Self.logger.info("Deleted metrics entry")
        } catch {
            throw MetricsServiceError.contextError(error)
        }
    }
}
