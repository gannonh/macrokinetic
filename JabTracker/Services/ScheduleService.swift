//
//  ScheduleService.swift
//  JabTracker
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation
import SwiftData

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
}
