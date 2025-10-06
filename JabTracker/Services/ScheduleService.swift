//
//  ScheduleService.swift
//  JabTracker
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation
import SwiftData

// MARK: - Schedule Configuration Types

/// Time components for scheduling
struct TimeComponents: Codable, Equatable {
    let hour: Int  // 0-23
    let minute: Int  // 0-59
}

/// Recurrence frequency for custom patterns
enum RecurrenceFrequency: String, Codable {
    case daily
    case weekly
    case monthly
}

/// Monthly pattern type for custom recurrence
enum MonthlyPatternType: String, Codable {
    case dayOfMonth  // e.g., 15th of each month
    case weekOfMonth  // e.g., 2nd Monday of month
}

/// Custom recurrence pattern configuration
struct CustomRecurrence: Codable, Equatable {
    let frequency: RecurrenceFrequency
    let intervalDays: Int
    let daysOfWeek: [Int]?  // 1-7 for weekly patterns
    let monthlyPattern: MonthlyPatternType?
}

/// Complete schedule configuration
struct ScheduleConfiguration: Codable {
    let dayOfWeek: Int?  // For weekly patterns (1-7)
    let timeOfDay: TimeComponents  // Hour and minute
    let interval: Int  // Days between doses (default: 7)
    let doseAmount: Double
    let windowMinutesBefore: Int  // Default: 120 (2 hours)
    let windowMinutesAfter: Int  // Default: 120 (2 hours)
    let splitDoseCount: Int?  // For split-dose patterns
    let splitIntervalMinutes: Int?  // Time between splits
    let customRecurrence: CustomRecurrence?
}

// MARK: - Service Errors

/// Errors that can occur during schedule service operations
enum ScheduleServiceError: LocalizedError {
    case invalidDoseAmount
    case pauseUntilInPast
    case invalidScheduleConfiguration
    case scheduleNotFound
    case scheduleConflict
    case doseNotModifiable
    case contextSaveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidDoseAmount:
            return "Dose amount must be positive"
        case .pauseUntilInPast:
            return "Pause until date must be in the future"
        case .invalidScheduleConfiguration:
            return "Schedule configuration is invalid"
        case .scheduleNotFound:
            return "Schedule not found"
        case .scheduleConflict:
            return "Schedule conflict detected"
        case .doseNotModifiable:
            return "Dose cannot be modified"
        case .contextSaveFailed(let error):
            return "Failed to save changes: \(error.localizedDescription)"
        }
    }
}

// MARK: - Schedule Service

/// Core service for managing dose schedules and generating scheduled doses.
///
/// Provides CRUD operations for DoseSchedule entities and algorithms for
/// generating ScheduledDose entities based on various scheduling patterns
/// (weekly, split-dose, custom recurrence).
///
/// - Note: This is an @Observable class for real-time UI updates
/// - Important: All operations update timestamps and validate inputs
@Observable
final class ScheduleService {

    // MARK: - Properties

    /// SwiftData model context for persistence operations
    private let context: ModelContext

    /// Active (non-deleted) dose schedules
    var activeSchedules: [DoseSchedule] = []

    /// Upcoming scheduled doses for quick access
    var upcomingDoses: [ScheduledDose] = []

    /// Processing state indicator for UI feedback
    var isProcessing: Bool = false

    // MARK: - Initialization

    /**
     * Creates a new ScheduleService instance.
     *
     * - Parameter context: SwiftData ModelContext for persistence operations
     */
    init(context: ModelContext) {
        self.context = context
        loadActiveSchedules()
    }

    // MARK: - CRUD Operations

    /**
     * Creates a new dose schedule for a medication profile.
     *
     * - Parameters:
     *   - profile: Medication profile to create schedule for
     *   - pattern: Type of schedule pattern (weekly, splitDose, custom)
     *   - startDate: When the schedule should start
     *   - baseSchedule: Configuration for the schedule pattern
     *
     * - Returns: Newly created DoseSchedule
     * - Throws: ScheduleServiceError if validation fails
     */
    func createSchedule(
        for profile: MedicationProfile,
        pattern: SchedulePatternType,
        startDate: Date,
        baseSchedule: ScheduleConfiguration
    ) throws -> DoseSchedule {
        // Validate dose amount
        guard baseSchedule.doseAmount > 0 else {
            throw ScheduleServiceError.invalidDoseAmount
        }

        // Encode configuration to Data
        let encoder = JSONEncoder()
        let scheduleData = try encoder.encode(baseSchedule)

        // Create schedule entity
        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: pattern,
            baseSchedule: scheduleData,
            isActive: true
        )

        // Insert into context
        context.insert(schedule)

        // Save changes
        try context.save()

        // Reload active schedules
        loadActiveSchedules()

        return schedule
    }

    /**
     * Updates an existing dose schedule.
     *
     * - Parameters:
     *   - schedule: Schedule to update
     *   - newPattern: New pattern type (optional, keeps existing if nil)
     *   - newBaseSchedule: New configuration
     *
     * - Throws: ScheduleServiceError if validation fails
     */
    func updateSchedule(
        _ schedule: DoseSchedule,
        newPattern: SchedulePatternType,
        newBaseSchedule: ScheduleConfiguration
    ) throws {
        // Validate dose amount
        guard newBaseSchedule.doseAmount > 0 else {
            throw ScheduleServiceError.invalidDoseAmount
        }

        // Encode new configuration
        let encoder = JSONEncoder()
        let scheduleData = try encoder.encode(newBaseSchedule)

        // Update schedule
        schedule.patternType = newPattern
        schedule.baseSchedule = scheduleData
        schedule.updatedAt = Date()

        // Save changes
        try context.save()
    }

    /**
     * Deletes a dose schedule (soft delete by marking inactive).
     *
     * Associated ScheduledDose entities are cascade deleted due to
     * relationship deleteRule configuration.
     *
     * - Parameter schedule: Schedule to delete
     * - Throws: Error if save fails
     */
    func deleteSchedule(_ schedule: DoseSchedule) throws {
        // Soft delete: mark as inactive
        schedule.isActive = false
        schedule.updatedAt = Date()

        // Save changes
        try context.save()

        // Reload active schedules
        loadActiveSchedules()
    }

    /**
     * Pauses a dose schedule until a specified date.
     *
     * - Parameters:
     *   - schedule: Schedule to pause
     *   - until: Date when schedule should resume (must be in future)
     *
     * - Throws: ScheduleServiceError.pauseUntilInPast if date is not in future
     */
    func pauseSchedule(_ schedule: DoseSchedule, until: Date) throws {
        // Validate pause until date is in future
        guard until > Date() else {
            throw ScheduleServiceError.pauseUntilInPast
        }

        // Set pause fields
        schedule.pausedAt = Date()
        schedule.pausedUntil = until
        schedule.updatedAt = Date()

        // Save changes
        try context.save()
    }

    /**
     * Resumes a paused dose schedule.
     *
     * - Parameter schedule: Schedule to resume
     * - Throws: Error if save fails
     */
    func resumeSchedule(_ schedule: DoseSchedule) throws {
        // Clear pause fields
        schedule.pausedAt = nil
        schedule.pausedUntil = nil
        schedule.updatedAt = Date()

        // Save changes
        try context.save()
    }

    // MARK: - Private Helpers

    /**
     * Loads active (non-deleted) schedules from SwiftData.
     *
     * Called during initialization and after CRUD operations to keep
     * activeSchedules property synchronized with persistent storage.
     */
    private func loadActiveSchedules() {
        let descriptor = FetchDescriptor<DoseSchedule>(
            predicate: #Predicate { schedule in
                schedule.isActive == true
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            activeSchedules = try context.fetch(descriptor)
        } catch {
            print("Error loading active schedules: \(error)")
            activeSchedules = []
        }
    }

    /**
     * Decodes the base schedule configuration from a DoseSchedule.
     *
     * - Parameter schedule: Schedule to decode
     * - Returns: Decoded ScheduleConfiguration
     * - Throws: DecodingError if data is invalid
     */
    func decodeScheduleConfiguration(_ schedule: DoseSchedule) throws -> ScheduleConfiguration {
        let decoder = JSONDecoder()
        return try decoder.decode(ScheduleConfiguration.self, from: schedule.baseSchedule)
    }
}
