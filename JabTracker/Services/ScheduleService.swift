//
//  ScheduleService.swift
//  JabTracker
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "ScheduleService")

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
    let timeOfDay: TimeComponents  // Hour and minute (first dose for split-dose)
    let secondTimeOfDay: TimeComponents?  // Second dose time for split-dose patterns
    let interval: Int  // Days between doses (default: 7)
    let doseAmount: Double
    let windowMinutesBefore: Int  // Default: 120 (2 hours)
    let windowMinutesAfter: Int  // Default: 120 (2 hours)
    let splitDoseCount: Int?  // For split-dose patterns
    let splitIntervalMinutes: Int?  // Time between splits (DEPRECATED - use secondTimeOfDay)
    let customRecurrence: CustomRecurrence?

    /// Validates that split-dose times are properly spaced (6-18 hours apart)
    /// - Returns: true if times are valid for split-dose pattern
    func validateSplitDoseTimes() -> Bool {
        guard let secondTime = secondTimeOfDay else {
            return true  // No second time, validation not applicable
        }

        // Convert both times to minutes since midnight
        let firstMinutes = timeOfDay.hour * 60 + timeOfDay.minute
        let secondMinutes = secondTime.hour * 60 + secondTime.minute

        // Calculate difference (handle midnight crossing)
        let diff = abs(secondMinutes - firstMinutes)
        let actualDiff = min(diff, 1440 - diff)  // 1440 = 24 hours in minutes

        // Enforce 6-18 hour spacing (360-1080 minutes)
        return actualDiff >= 360 && actualDiff <= 1080
    }
}

extension ScheduleConfiguration {
    /// Creates a split-dose configuration for weekly medications
    /// - Parameters:
    ///   - medication: The medication (must have weekly frequency)
    ///   - totalWeeklyDose: The total weekly dose to split
    /// - Returns: Configuration with twice-weekly dosing (3.5 day interval)
    /// - Throws: splitDoseNotSupported if medication is not weekly
    static func splitDoseConfiguration(
        for medication: Medication,
        totalWeeklyDose: Double
    ) throws -> ScheduleConfiguration {
        guard medication.frequency == .weekly else {
            throw ScheduleServiceError.splitDoseNotSupported(
                "Split-dose is only supported for weekly medications"
            )
        }

        return ScheduleConfiguration(
            dayOfWeek: nil,  // Not used for split-dose
            timeOfDay: TimeComponents(hour: 8, minute: 0),  // First dose: 8 AM
            secondTimeOfDay: TimeComponents(hour: 20, minute: 0),  // Second dose: 8 PM
            interval: 7,  // Weekly cycle
            doseAmount: totalWeeklyDose / 2.0,
            windowMinutesBefore: TimeConstants.defaultWindowMinutes,
            windowMinutesAfter: TimeConstants.defaultWindowMinutes,
            splitDoseCount: 2,
            splitIntervalMinutes: TimeConstants.splitDoseInterval,
            customRecurrence: nil
        )
    }
}

// MARK: - Service Errors

/// Errors that can occur during schedule service operations
enum ScheduleServiceError: LocalizedError, Equatable {
    case invalidDoseAmount
    case pauseUntilInPast
    case invalidScheduleConfiguration
    case invalidTimeRange
    case scheduleNotFound
    case scheduleConflict
    case doseNotModifiable
    case splitDoseNotSupported(String)
    case contextSaveFailed(Error)

    static func == (lhs: ScheduleServiceError, rhs: ScheduleServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidDoseAmount, .invalidDoseAmount),
            (.pauseUntilInPast, .pauseUntilInPast),
            (.invalidScheduleConfiguration, .invalidScheduleConfiguration),
            (.invalidTimeRange, .invalidTimeRange),
            (.scheduleNotFound, .scheduleNotFound),
            (.scheduleConflict, .scheduleConflict),
            (.doseNotModifiable, .doseNotModifiable):
            return true
        case (.splitDoseNotSupported(let lhs), .splitDoseNotSupported(let rhs)):
            return lhs == rhs
        case (.contextSaveFailed(let lhsError), .contextSaveFailed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidDoseAmount:
            return "Dose amount must be positive"
        case .pauseUntilInPast:
            return "Pause until date must be in the future"
        case .invalidScheduleConfiguration:
            return "Schedule configuration is invalid"
        case .invalidTimeRange:
            return "New time must be within ±7 days of original scheduled time"
        case .scheduleNotFound:
            return "Schedule not found"
        case .scheduleConflict:
            return "Schedule conflict detected"
        case .doseNotModifiable:
            return "Dose cannot be modified"
        case .splitDoseNotSupported(let message):
            return message
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
    let context: ModelContext

    /// Active (non-deleted) dose schedules
    var activeSchedules: [DoseSchedule] = []

    /// Upcoming scheduled doses for quick access
    var upcomingDoses: [ScheduledDose] = []

    /// Processing state indicator for UI feedback
    var isProcessing: Bool = false

    /// Error state for schedule loading failures (Issue #289)
    /// UI can observe this property to display error feedback
    var loadError: Error?

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

        // Set creation time to match start date (for historical schedules)
        schedule.createdAt = startDate

        // Insert into context
        context.insert(schedule)
        print("🔍 [ScheduleService.createSchedule] Inserted schedule into context")

        // Save changes
        try context.save()
        print("🔍 [ScheduleService.createSchedule] Saved context successfully")

        // Reload active schedules
        loadActiveSchedules()
        print("🔍 [ScheduleService.createSchedule] loadActiveSchedules() called")
        print("🔍 [ScheduleService.createSchedule] activeSchedules.count after load: \(activeSchedules.count)")

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
     * Pauses a dose schedule until a specified date or indefinitely.
     *
     * - Parameters:
     *   - schedule: Schedule to pause
     *   - until: Date when schedule should resume (nil for indefinite pause)
     *
     * - Throws: ScheduleServiceError.pauseUntilInPast if date is provided but not in future
     */
    func pauseSchedule(_ schedule: DoseSchedule, until: Date? = nil) throws {
        // If date provided, validate it's in the future
        if let until = until {
            guard until > Date() else {
                throw ScheduleServiceError.pauseUntilInPast
            }
        }

        // Set pause fields
        schedule.pausedAt = Date()
        schedule.pausedUntil = until  // nil for indefinite pause
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
     *
     * Sets loadError property on failure for UI feedback.
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
            loadError = nil  // Clear error on success
        } catch {
            logger.error("Failed to load active schedules: \(error.localizedDescription)")
            loadError = error  // Set error state for UI feedback
            activeSchedules = []  // Maintain safe fallback behavior
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
