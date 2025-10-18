//
//  MedicationProfileViewModel.swift
//  JabTracker
//
//  Created by Stream B Agent on 2025-10-18.
//  ViewModel for managing medication profile schedule operations.
//

import Foundation
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "MedicationProfileViewModel")

/// ViewModel for managing medication profile schedule operations
///
/// Coordinates between the UI layer and ScheduleService for schedule
/// CRUD operations, pause/resume functionality, and schedule history tracking.
@Observable
final class MedicationProfileViewModel {

    // MARK: - Properties

    /// Medication profile this ViewModel manages
    let medicationProfile: MedicationProfile

    /// SwiftData context for persistence operations
    private let context: ModelContext

    /// Schedule service for schedule operations
    private let scheduleService: ScheduleService

    /// Currently active schedule for this medication profile
    var activeSchedule: DoseSchedule?

    /// Schedule modification history
    var scheduleHistory: [ScheduleHistoryItem] = []

    /// UI state for schedule edit sheet
    var showScheduleEditSheet: Bool = false

    /// UI state for pause schedule sheet
    var showPauseScheduleSheet: Bool = false

    /// UI state for deactivate confirmation dialog
    var showDeactivateConfirmation: Bool = false

    /// UI state for dose titration navigation
    var showDoseTitration: Bool = false

    /// Error state
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Initialization

    /// Initialize ViewModel for a medication profile
    ///
    /// - Parameters:
    ///   - medicationProfile: Medication profile to manage
    ///   - context: SwiftData ModelContext for persistence
    init(medicationProfile: MedicationProfile, context: ModelContext) {
        self.medicationProfile = medicationProfile
        self.context = context
        self.scheduleService = ScheduleService(context: context)
    }

    // MARK: - Schedule Loading

    /// Load the active schedule for this medication profile
    @MainActor
    func loadActiveSchedule() async {
        logger.debug("Loading active schedule for profile: \(self.medicationProfile.id)")

        // Query for active schedules belonging to this profile
        let profileId = self.medicationProfile.id
        let descriptor = FetchDescriptor<DoseSchedule>(
            predicate: #Predicate<DoseSchedule> { schedule in
                schedule.medicationProfile?.id == profileId && schedule.isActive == true
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let schedules = try context.fetch(descriptor)
            activeSchedule = schedules.first
            logger.info("Loaded active schedule: \(String(describing: self.activeSchedule?.id))")
        } catch {
            logger.error("Failed to load active schedule: \(error.localizedDescription)")
            activeSchedule = nil
        }
    }

    /// Load schedule modification history
    @MainActor
    func loadScheduleHistory() async {
        logger.debug("Loading schedule history for profile: \(self.medicationProfile.id)")

        // Query all schedules for this profile
        let profileId = self.medicationProfile.id
        let descriptor = FetchDescriptor<DoseSchedule>(
            predicate: #Predicate<DoseSchedule> { schedule in
                schedule.medicationProfile?.id == profileId
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let schedules = try context.fetch(descriptor)

            // Convert to history items
            scheduleHistory = schedules.compactMap { schedule in
                // Determine change type based on schedule state
                let changeType: ScheduleChangeType
                if !schedule.isActive {
                    changeType = .deactivated
                } else if schedule.pausedAt != nil {
                    changeType = .paused
                } else {
                    changeType = .created
                }

                return ScheduleHistoryItem(
                    id: schedule.id,
                    changeType: changeType,
                    description: descriptionForSchedule(schedule),
                    timestamp: schedule.updatedAt
                )
            }

            logger.info("Loaded \(self.scheduleHistory.count) schedule history items")
        } catch {
            logger.error("Failed to load schedule history: \(error.localizedDescription)")
            scheduleHistory = []
        }
    }

    // MARK: - Schedule CRUD Operations

    /// Create or update a schedule
    ///
    /// - Parameters:
    ///   - config: Schedule configuration
    ///   - pattern: Schedule pattern type
    @MainActor
    func updateSchedule(_ config: ScheduleConfiguration, pattern: SchedulePatternType) async {
        logger.debug("Updating schedule for profile: \(self.medicationProfile.id)")

        do {
            if activeSchedule == nil {
                // Create new schedule
                activeSchedule = try scheduleService.createSchedule(
                    for: medicationProfile,
                    pattern: pattern,
                    startDate: Date(),
                    baseSchedule: config
                )
                logger.info("Created new schedule: \(String(describing: self.activeSchedule?.id))")
            } else if let schedule = activeSchedule {
                // Update existing schedule
                // Update schedule
                try scheduleService.updateSchedule(
                    schedule,
                    newPattern: pattern,
                    newBaseSchedule: config
                )

                logger.info("Updated schedule: \(schedule.id)")
            }

            // Reload schedule and history
            await loadActiveSchedule()
            await loadScheduleHistory()

        } catch {
            logger.error("Failed to update schedule: \(error.localizedDescription)")
            errorMessage = "Failed to update schedule: \(error.localizedDescription)"
            showError = true
        }
    }

    /// Pause the active schedule
    ///
    /// - Parameter until: Optional date to automatically resume (nil = indefinite)
    @MainActor
    func pauseSchedule(until date: Date?) async {
        guard let schedule = activeSchedule else {
            logger.warning("No active schedule to pause")
            return
        }

        logger.debug("Pausing schedule: \(schedule.id)")

        do {
            if let until = date {
                try scheduleService.pauseSchedule(schedule, until: until)
            } else {
                // Indefinite pause - set pausedAt but leave pausedUntil nil
                schedule.pausedAt = Date()
                schedule.pausedUntil = nil
                schedule.updatedAt = Date()
                try context.save()
            }

            // Reload schedule and history
            await loadActiveSchedule()
            await loadScheduleHistory()

            logger.info("Schedule paused successfully")
        } catch {
            logger.error("Failed to pause schedule: \(error.localizedDescription)")
            errorMessage = "Failed to pause schedule: \(error.localizedDescription)"
            showError = true
        }
    }

    /// Resume the paused schedule
    @MainActor
    func resumeSchedule() async {
        guard let schedule = activeSchedule else {
            logger.warning("No active schedule to resume")
            return
        }

        logger.debug("Resuming schedule: \(schedule.id)")

        do {
            try scheduleService.resumeSchedule(schedule)

            // Reload schedule and history
            await loadActiveSchedule()
            await loadScheduleHistory()

            logger.info("Schedule resumed successfully")
        } catch {
            logger.error("Failed to resume schedule: \(error.localizedDescription)")
            errorMessage = "Failed to resume schedule: \(error.localizedDescription)"
            showError = true
        }
    }

    /// Deactivate the active schedule
    @MainActor
    func deactivateSchedule() async {
        guard let schedule = activeSchedule else {
            logger.warning("No active schedule to deactivate")
            return
        }

        logger.debug("Deactivating schedule: \(schedule.id)")

        do {
            try scheduleService.deleteSchedule(schedule)

            // Clear active schedule
            activeSchedule = nil

            // Reload history
            await loadScheduleHistory()

            logger.info("Schedule deactivated successfully")
        } catch {
            logger.error("Failed to deactivate schedule: \(error.localizedDescription)")
            errorMessage = "Failed to deactivate schedule: \(error.localizedDescription)"
            showError = true
        }
    }

    /// Navigate to dose titration view
    func navigateToTitrationPlan() {
        showDoseTitration = true
    }

    // MARK: - Helper Methods

    /// Generate description for a schedule
    private func descriptionForSchedule(_ schedule: DoseSchedule) -> String {
        let patternName =
            schedule.patternType == .weekly ? "Weekly" : schedule.patternType == .splitDose ? "Split Dose" : "Custom"

        if !schedule.isActive {
            return "\(patternName) schedule deactivated"
        } else if schedule.pausedAt != nil {
            if let until = schedule.pausedUntil {
                return "\(patternName) schedule paused until \(until.formatted(date: .abbreviated, time: .omitted))"
            } else {
                return "\(patternName) schedule paused indefinitely"
            }
        } else {
            return "\(patternName) schedule created"
        }
    }
}
