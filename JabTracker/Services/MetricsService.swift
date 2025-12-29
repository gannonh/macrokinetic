//
//  MetricsService.swift
//  JabTracker
//
//  Unified service for ALL body metrics: weight, height, body fat, circumferences.
//  Handles CRUD operations, date-based queries, and HealthKit sync.
//

import Foundation
import OSLog
import SwiftData

/// Errors for metrics service operations
enum MetricsServiceError: LocalizedError {
    case invalidMeasurement(String)
    case invalidWeight(String)
    case noEntriesFound
    case contextError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidMeasurement(let message):
            return "Invalid measurement: \(message)"
        case .invalidWeight(let message):
            return "Invalid weight: \(message)"
        case .noEntriesFound:
            return "No entries found"
        case .contextError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }
}

/// Unified service for managing ALL body metrics
/// Handles weight, height, body fat, and circumference measurements
/// Provides CRUD operations, date-based queries, and HealthKit sync
@MainActor
final class MetricsService {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "MetricsService")

    let context: ModelContext

    /// Initialize with model context
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Validation Helpers

    /// Validate weight is within acceptable range
    /// - Parameter weightKg: Weight in kilograms
    /// - Throws: MetricsServiceError.invalidWeight if out of range
    private func validateWeight(_ weightKg: Double) throws {
        guard weightKg >= WeightEntry.minWeightKg && weightKg <= WeightEntry.maxWeightKg else {
            throw MetricsServiceError.invalidWeight(
                "Weight must be between \(Int(WeightEntry.minWeightKg)) kg and \(Int(WeightEntry.maxWeightKg)) kg"
            )
        }
    }

    /// Validate body fat percentage is within acceptable range
    /// - Parameter bodyFat: Body fat percentage (0-100)
    /// - Throws: MetricsServiceError.invalidWeight if out of range
    private func validateBodyFat(_ bodyFat: Double) throws {
        guard bodyFat >= 0 && bodyFat <= 100 else {
            throw MetricsServiceError.invalidWeight(
                "Body fat percentage must be between 0% and 100%"
            )
        }
    }

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

    // MARK: - Weight CRUD

    /// Log a new weight entry and update User.weight
    /// - Parameters:
    ///   - weightKg: Weight in kilograms
    ///   - bodyFat: Optional body fat percentage (0-100)
    ///   - user: The user to update
    ///   - timestamp: When the measurement was taken
    ///   - notes: Optional notes
    /// - Returns: The created WeightEntry
    /// - Throws: MetricsServiceError if validation fails
    func logWeight(
        weightKg: Double,
        bodyFat: Double? = nil,
        for user: User,
        timestamp: Date = Date(),
        notes: String? = nil
    ) async throws -> WeightEntry {
        // Debug logging
        print("🟢 MetricsService.logWeight:")
        print("   weightKg received: \(weightKg)")
        print("   in lbs: \(weightKg * WeightEntry.kgToLbsConversion)")
        print("   user.weightUnit: \(user.weightUnit)")
        print("   user.healthSyncEnabled: \(user.healthSyncEnabled)")

        // Validate weight range
        try validateWeight(weightKg)

        // Validate body fat if provided
        if let bodyFat = bodyFat {
            try validateBodyFat(bodyFat)
        }

        let entry = WeightEntry(
            timestamp: timestamp,
            weightKg: weightKg,
            bodyFatPercentage: bodyFat,
            source: "manual",
            notes: notes
        )

        context.insert(entry)

        // Update User.weight to latest (in user's preferred unit)
        if user.weightUnit == "lbs" {
            user.weight = weightKg * WeightEntry.kgToLbsConversion
        } else {
            user.weight = weightKg
        }
        user.updatedAt = Date()

        do {
            try context.save()
            Self.logger.info("Logged weight entry: \(weightKg) kg at \(timestamp)")

            // Sync to HealthKit if enabled
            if user.healthSyncEnabled {
                await syncWeightToHealthKit(entry)
            }

            return entry
        } catch {
            throw MetricsServiceError.contextError(error)
        }
    }

    /// Get the most recent weight entry
    /// - Returns: The latest WeightEntry or nil if none exist
    func getLatestWeightEntry() async throws -> WeightEntry? {
        var descriptor = FetchDescriptor<WeightEntry>(
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

    /// Get weight entries within a date range
    /// - Parameters:
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    /// - Returns: Array of WeightEntry sorted by timestamp descending
    func getWeightEntries(from startDate: Date, to endDate: Date) async throws -> [WeightEntry] {
        let descriptor = FetchDescriptor<WeightEntry>(
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

    /// Get all weight entries
    /// - Parameter limit: Maximum number of entries to return (nil for all)
    /// - Returns: Array of WeightEntry sorted by timestamp descending
    func getAllWeightEntries(limit: Int? = nil) async throws -> [WeightEntry] {
        var descriptor = FetchDescriptor<WeightEntry>(
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

    /// Update an existing weight entry
    /// - Parameters:
    ///   - entry: Entry to update
    ///   - weightKg: New weight in kg (optional)
    ///   - bodyFat: New body fat percentage (optional, use inner nil to clear)
    ///   - notes: New notes (optional, use inner nil to clear)
    /// - Throws: MetricsServiceError if validation fails
    func updateWeightEntry(
        _ entry: WeightEntry,
        weightKg: Double? = nil,
        bodyFat: Double?? = nil,
        notes: String?? = nil
    ) async throws {
        if let weightKg = weightKg {
            try validateWeight(weightKg)
            entry.weightKg = weightKg
        }

        if let bodyFat = bodyFat {
            if let fat = bodyFat {
                try validateBodyFat(fat)
            }
            entry.bodyFatPercentage = bodyFat
        }

        if let notes = notes {
            entry.notes = notes
        }

        do {
            try context.save()
            Self.logger.info("Updated weight entry: \(entry.weightKg) kg")
        } catch {
            throw MetricsServiceError.contextError(error)
        }
    }

    /// Delete a weight entry
    /// - Parameter entry: Entry to delete
    func deleteWeightEntry(_ entry: WeightEntry) async throws {
        let weight = entry.weightKg
        context.delete(entry)

        do {
            try context.save()
            Self.logger.info("Deleted weight entry: \(weight) kg")
        } catch {
            throw MetricsServiceError.contextError(error)
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
