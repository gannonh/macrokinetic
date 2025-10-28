//
//  QuickDoseViewModel.swift
//  JabTracker
//

import Foundation
import OSLog
import SwiftData

/// View model for quick dose entry with smart defaults and business logic
/// Handles medication profile loading, smart default computation, and dose saving
@MainActor
class QuickDoseViewModel: ObservableObject {
    // MARK: - Logger

    private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "QuickDoseViewModel")

    // MARK: - Published Properties

    @Published var medicationProfiles: [MedicationProfile] = []
    @Published var selectedMedicationProfile: MedicationProfile? {
        didSet {
            self.updateDoseAmount()
            self.updateRecommendedInjectionSites()
        }
    }

    @Published var doseAmount: Double = 0.0
    @Published var selectedInjectionSite: String = ""
    @Published var doseDate: Date = .init()
    @Published var doseTime: Date = .init()
    @Published var notes: String = ""

    @Published var recommendedInjectionSites: [String] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // MARK: - Titration State (Issue #286)

    /// Flag to track if user selected "Remind Me Later" for titration dialog
    /// Reset after each dose entry to prompt again next time
    @Published var titrationRemindLater: Bool = false

    // MARK: - Computed Properties

    /// Combined date and time for dose timestamp
    var doseDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: doseDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: doseTime)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? Date()
    }

    /// Determines if dose can be saved based on current state
    var canSaveDose: Bool {
        guard self.selectedMedicationProfile != nil else { return false }
        guard self.doseAmount > 0 else { return false }
        guard !self.selectedInjectionSite.isEmpty else { return false }

        // Allow dates within reasonable range (30 days past to 30 days future)
        // This supports both historical dose entry and logging scheduled future doses
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let thirtyDaysAhead = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()

        // Use date-only comparison to avoid second-level precision issues
        let doseDateOnly = Calendar.current.startOfDay(for: doseDateTime)
        let thirtyDaysAgoDateOnly = Calendar.current.startOfDay(for: thirtyDaysAgo)
        let thirtyDaysAheadDateOnly = Calendar.current.startOfDay(for: thirtyDaysAhead)

        guard doseDateOnly >= thirtyDaysAgoDateOnly && doseDateOnly <= thirtyDaysAheadDateOnly else { return false }
        return true
    }

    // MARK: - Initialization

    init() {
        let now = Date()
        self.doseDate = now
        self.doseTime = now
    }

    // MARK: - Smart Defaults Loading

    /// Loads smart defaults from user's medication profiles and dose history
    /// - Parameters:
    ///   - context: ModelContext for fetching medication profiles
    ///   - prePopulatedTimestamp: Optional timestamp to pre-populate date/time (for scheduled doses)
    func loadSmartDefaults(context: ModelContext, prePopulatedTimestamp: Date? = nil) {
        // Pre-populate date/time SYNCHRONOUSLY if provided (for scheduled doses)
        // This must happen BEFORE the async Task so date pickers bind to correct values
        if let timestamp = prePopulatedTimestamp {
            self.doseDate = timestamp
            self.doseTime = timestamp
        }

        Task { @MainActor in
            do {
                self.isLoading = true
                self.errorMessage = nil

                // Fetch only ACTIVE medication profiles for the current user
                let profileDescriptor = FetchDescriptor<MedicationProfile>(
                    predicate: #Predicate<MedicationProfile> { profile in
                        profile.isActive == true
                    }
                )
                self.medicationProfiles = try context.fetch(profileDescriptor)

                guard !self.medicationProfiles.isEmpty else {
                    self.errorMessage =
                        "No medication profiles found. Please create a medication profile first."
                    self.isLoading = false
                    return
                }

                // Select the most recent medication profile as default
                self.selectedMedicationProfile = self.medicationProfiles.first

                // Update dose amount from selected profile
                self.updateDoseAmount()

                // Get smart injection site recommendation
                self.updateRecommendedInjectionSites()

                self.isLoading = false

            } catch {
                self.errorMessage = "Failed to load medication profiles: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    /// Loads existing dose data for editing
    func loadEditData(_ editData: DoseEditData, context: ModelContext) {
        Task { @MainActor in
            do {
                self.isLoading = true
                self.errorMessage = nil

                // Fetch only ACTIVE medication profiles for the current user
                let profileDescriptor = FetchDescriptor<MedicationProfile>(
                    predicate: #Predicate<MedicationProfile> { profile in
                        profile.isActive == true
                    }
                )
                self.medicationProfiles = try context.fetch(profileDescriptor)

                // Set values from edit data
                self.selectedMedicationProfile = editData.medicationProfile
                self.doseAmount = editData.amount
                self.doseDate = editData.timestamp
                self.doseTime = editData.timestamp
                let editSite = editData.site ?? ""
                self.notes = editData.notes ?? ""

                // Update recommended injection sites (but preserve edit data site)
                self.updateRecommendedInjectionSites()

                // Restore the site from edit data (don't use rotation default)
                self.selectedInjectionSite = editSite

                self.isLoading = false

            } catch {
                self.errorMessage = "Failed to load dose data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // MARK: - Smart Default Updates

    /// Updates dose amount based on selected medication profile's current dose
    /// For split-dose schedules, shows half the weekly dose per administration
    private func updateDoseAmount() {
        guard let profile = selectedMedicationProfile else {
            self.doseAmount = 0.0
            return
        }

        // Check if active schedule uses split-dose pattern
        if let schedule = profile.schedules?.first(where: { $0.isActive }),
            schedule.patternType == .splitDose
        {
            // Split-dose: Show half the weekly dose per administration
            // Example: 1.0mg weekly split → 0.5mg per dose (2x per week)
            self.doseAmount = profile.currentDose / 2
        } else {
            self.doseAmount = profile.currentDose
        }
    }

    /// Updates recommended injection sites and selects smart default based on dose history
    private func updateRecommendedInjectionSites() {
        guard let profile = selectedMedicationProfile,
            let medication = profile.medication
        else {
            self.recommendedInjectionSites = DoseDefaults.allInjectionSites
            self.selectedInjectionSite = DoseDefaults.allInjectionSites.first ?? ""
            return
        }

        // Get recommended sites for this medication
        self.recommendedInjectionSites = DoseDefaults.recommendedInjectionSites(for: medication)

        // Get recent doses for this medication profile
        let recentDoses = (profile.doses ?? []).suffix(5)  // Last 5 doses for rotation analysis

        // Use DoseDefaults to get next recommended site based on rotation
        self.selectedInjectionSite = DoseDefaults.nextRecommendedSite(
            for: medication,
            recentDoses: Array(recentDoses),
            preferredSites: profile.preferredInjectionSites)
    }

    // MARK: - Dose Saving

    // NOTE: Dose saving is now handled by DoseService for PK integration
    // This method is deprecated in favor of DoseService.saveDose()
    // Keeping the form reset method for convenience

    /// Resets form to initial state after successful save
    func resetForm() {
        self.notes = ""
        let now = Date()
        self.doseDate = now
        self.doseTime = now
        // Keep medication selection and injection site rotation for convenience
    }

    // MARK: - Convenience Methods

    /// Gets the next scheduled dose time for the selected medication profile
    func getNextScheduledDoseTime() -> Date? {
        guard let profile = selectedMedicationProfile else { return nil }

        return DoseDefaults.nextScheduledDose(
            for: profile,
            from: Date(),
            doses: profile.doses)
    }

    /// Checks if a dose is overdue for the selected medication profile
    func isDoseOverdue() -> Bool {
        guard let profile = selectedMedicationProfile else { return false }

        return DoseDefaults.isDoseOverdue(
            for: profile,
            currentDate: Date(),
            gracePeriodHours: 2,
            doses: profile.doses)
    }

    // MARK: - Titration Detection Methods (Issue #286)

    /// Determines if the titration confirmation dialog should be shown
    /// Dialog shows when:
    /// - Medication profile has an incomplete titration
    /// - Titration scheduled date is today or in the past
    /// - User hasn't selected "Remind Me Later" for this session
    func shouldShowTitrationDialog() -> Bool {
        logger.debug("QuickDoseViewModel.shouldShowTitrationDialog called")

        guard let pendingTitration = getPendingTitration() else {
            logger.debug("No pending titration found")
            return false
        }

        logger.debug("Found pending titration: \(pendingTitration.fromDose)mg → \(pendingTitration.toDose)mg")

        // Don't show if user clicked "Remind Me Later"
        if titrationRemindLater {
            logger.debug("titrationRemindLater flag is set, not showing dialog")
            return false
        }

        // Show if titration date is today or in the past
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        logger.debug("Now: \(formatter.string(from: now))")
        logger.debug("Titration scheduled: \(formatter.string(from: pendingTitration.scheduledDate))")

        let shouldShow = pendingTitration.scheduledDate <= now
        logger.debug("scheduledDate <= now? \(shouldShow)")

        return shouldShow
    }

    /// Gets the pending titration for the selected medication profile
    /// Returns nil if no medication profile selected or no pending titration exists
    func getPendingTitration() -> DoseTitration? {
        logger.debug("QuickDoseViewModel.getPendingTitration called")

        guard let profile = selectedMedicationProfile else {
            logger.debug("No selected medication profile")
            return nil
        }

        logger.debug("Selected profile: \(profile.brandName) (\(profile.currentDose)mg)")

        guard let titrations = profile.doseTitrations, !titrations.isEmpty else {
            logger.debug("No titrations found for profile")
            return nil
        }

        logger.debug("Found \(titrations.count) total titrations")

        let incompleteTitrations = titrations.filter { !$0.isCompleted }
        logger.debug("Found \(incompleteTitrations.count) incomplete titrations:")

        for titration in incompleteTitrations {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let dateStr = formatter.string(from: titration.scheduledDate)
            logger.debug("  - \(titration.fromDose)mg → \(titration.toDose)mg scheduled for \(dateStr)")
        }

        // Find the EARLIEST (nearest) incomplete titration
        let pending = incompleteTitrations.min(by: { $0.scheduledDate < $1.scheduledDate })

        if let pending = pending {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let dateStr = formatter.string(from: pending.scheduledDate)
            logger.debug(
                "Returning EARLIEST titration: \(pending.fromDose)mg → \(pending.toDose)mg scheduled for \(dateStr)")
        } else {
            logger.debug("No incomplete titrations found")
        }

        return pending
    }

    /// Sets the "Remind Me Later" flag for titration dialog
    /// This flag prevents the dialog from showing again until reset
    func setTitrationRemindLater(_ value: Bool) {
        self.titrationRemindLater = value
    }

    /// Resets the "Remind Me Later" flag after dose entry
    /// This allows the dialog to show again on next dose entry
    func resetRemindLaterFlag() {
        self.titrationRemindLater = false
    }

    // MARK: - Titration Actions (Business Logic)

    /// Completes a titration and updates medication profile with new dose
    /// - Parameters:
    ///   - titration: The titration to complete
    ///   - context: ModelContext for saving changes
    /// - Throws: Error if save fails
    func completeTitration(_ titration: DoseTitration, context: ModelContext) throws {
        logger.debug("QuickDoseViewModel.completeTitration called")

        // Mark titration as completed
        titration.markCompleted()

        // Update medication profile with new dose
        if let profile = selectedMedicationProfile {
            logger.debug(
                "Updating \(profile.brandName) currentDose from \(profile.currentDose)mg to \(titration.toDose)mg")
            profile.currentDose = titration.toDose
        }

        // Save changes
        try context.save()
        logger.debug("Titration completed and saved")

        // Update dose amount synchronously to reflect new titration dose
        // This ensures UI shows the correct dose immediately when QuickDoseSheet appears
        updateDoseAmount()
        logger.debug("Updated dose amount to \(self.doseAmount)mg")
    }

    /// Reschedules a titration to a new date
    /// - Parameters:
    ///   - titration: The titration to reschedule
    ///   - newDate: The new scheduled date
    ///   - context: ModelContext for saving changes
    /// - Throws: Error if save fails
    func rescheduleTitration(_ titration: DoseTitration, to newDate: Date, context: ModelContext) throws {
        logger.debug("QuickDoseViewModel.rescheduleTitration called")

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let fromDate = formatter.string(from: titration.scheduledDate)
        let toDate = formatter.string(from: newDate)
        logger.debug("Rescheduling from \(fromDate) to \(toDate)")

        // Update titration date
        titration.scheduledDate = newDate
        titration.updatedAt = Date()

        // Save changes
        try context.save()
        logger.debug("Titration rescheduled and saved")
    }
}

// MARK: - Error Types

enum QuickDoseError: LocalizedError {
    case noMedicationProfile
    case invalidDoseData
    case saveFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .noMedicationProfile:
            return "No medication profile selected"
        case .invalidDoseData:
            return "Invalid dose information provided"
        case let .saveFailed(error):
            return "Failed to save dose: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions
