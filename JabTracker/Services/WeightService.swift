//
//  WeightService.swift
//  JabTracker
//
//  CRUD operations and queries for weight tracking.
//

import Foundation
import OSLog
import SwiftData

/// Errors for weight service operations
enum WeightServiceError: LocalizedError {
    case invalidWeight(String)
    case noEntriesFound
    case contextError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidWeight(let message):
            return "Invalid weight: \(message)"
        case .noEntriesFound:
            return "No weight entries found"
        case .contextError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }
}

/// Service for managing weight log entries
/// Provides CRUD operations, date-based queries, and User.weight sync
@MainActor
final class WeightService {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "WeightService")

    private let context: ModelContext

    /// Initialize with model context
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Validation Helpers

    /// Validate weight is within acceptable range
    /// - Parameter weightKg: Weight in kilograms
    /// - Throws: WeightServiceError.invalidWeight if out of range
    private func validateWeight(_ weightKg: Double) throws {
        guard weightKg >= WeightEntry.minWeightKg && weightKg <= WeightEntry.maxWeightKg else {
            throw WeightServiceError.invalidWeight(
                "Weight must be between \(Int(WeightEntry.minWeightKg)) kg and \(Int(WeightEntry.maxWeightKg)) kg"
            )
        }
    }

    /// Validate body fat percentage is within acceptable range
    /// - Parameter bodyFat: Body fat percentage (0-100)
    /// - Throws: WeightServiceError.invalidWeight if out of range
    private func validateBodyFat(_ bodyFat: Double) throws {
        guard bodyFat >= 0 && bodyFat <= 100 else {
            throw WeightServiceError.invalidWeight(
                "Body fat percentage must be between 0% and 100%"
            )
        }
    }

    // MARK: - Create

    /// Log a new weight entry
    /// - Parameters:
    ///   - weightKg: Weight in kilograms
    ///   - bodyFat: Optional body fat percentage (0-100)
    ///   - timestamp: When the measurement was taken
    ///   - notes: Optional notes
    /// - Returns: The created WeightEntry
    /// - Throws: WeightServiceError if validation fails
    func logWeight(
        weightKg: Double,
        bodyFat: Double? = nil,
        timestamp: Date = Date(),
        notes: String? = nil
    ) async throws -> WeightEntry {
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

        do {
            try context.save()
            Self.logger.info("Logged weight entry: \(weightKg) kg at \(timestamp)")
            return entry
        } catch {
            throw WeightServiceError.contextError(error)
        }
    }

    // MARK: - Read

    /// Get the most recent weight entry
    /// - Returns: The latest WeightEntry or nil if none exist
    func getLatestEntry() async throws -> WeightEntry? {
        var descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        do {
            let entries = try context.fetch(descriptor)
            return entries.first
        } catch {
            throw WeightServiceError.contextError(error)
        }
    }

    /// Get weight entries within a date range
    /// - Parameters:
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    /// - Returns: Array of WeightEntry sorted by timestamp descending
    func getEntries(from startDate: Date, to endDate: Date) async throws -> [WeightEntry] {
        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate { entry in
                entry.timestamp >= startDate && entry.timestamp <= endDate
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            throw WeightServiceError.contextError(error)
        }
    }

    /// Get all weight entries
    /// - Parameter limit: Maximum number of entries to return (nil for all)
    /// - Returns: Array of WeightEntry sorted by timestamp descending
    func getAllEntries(limit: Int? = nil) async throws -> [WeightEntry] {
        var descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )

        if let limit = limit {
            descriptor.fetchLimit = limit
        }

        do {
            return try context.fetch(descriptor)
        } catch {
            throw WeightServiceError.contextError(error)
        }
    }

    // MARK: - Update

    /// Update an existing weight entry
    /// - Parameters:
    ///   - entry: Entry to update
    ///   - weightKg: New weight in kg (optional)
    ///   - bodyFat: New body fat percentage (optional, use inner nil to clear)
    ///   - notes: New notes (optional, use inner nil to clear)
    /// - Throws: WeightServiceError if validation fails
    func updateEntry(
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
            throw WeightServiceError.contextError(error)
        }
    }

    // MARK: - Delete

    /// Delete a weight entry
    /// - Parameter entry: Entry to delete
    func deleteEntry(_ entry: WeightEntry) async throws {
        let weight = entry.weightKg
        context.delete(entry)

        do {
            try context.save()
            Self.logger.info("Deleted weight entry: \(weight) kg")
        } catch {
            throw WeightServiceError.contextError(error)
        }
    }

    // MARK: - User Sync

    /// Update the User model with the latest weight entry
    /// - Throws: WeightServiceError if no user or entries found
    func updateUserWeight() async throws {
        // Get latest weight entry
        guard let latestEntry = try await getLatestEntry() else {
            throw WeightServiceError.noEntriesFound
        }

        // Get the user
        let userDescriptor = FetchDescriptor<User>()
        let users: [User]

        do {
            users = try context.fetch(userDescriptor)
        } catch {
            throw WeightServiceError.contextError(error)
        }

        guard let user = users.first else {
            Self.logger.warning("No user found to update weight")
            return
        }

        // Update user weight
        user.weight = latestEntry.weightKg

        do {
            try context.save()
            Self.logger.info("Updated User.weight to \(latestEntry.weightKg) kg")
        } catch {
            throw WeightServiceError.contextError(error)
        }
    }
}
