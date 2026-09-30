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

    @Published var doseAmount: Double = 0.0 {
        didSet {
            self.doseAmountText = RecordedAmountInput.text(for: self.doseAmount)
        }
    }
    @Published var doseAmountText = ""
    @Published var selectedInjectionSite: String = ""
    @Published var doseDate: Date = .init()
    @Published var doseTime: Date = .init()
    @Published var notes: String = ""

    @Published var recommendedInjectionSites: [String] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // MARK: - Dose Adjustment Properties

    var doseAmountRange: ClosedRange<Double> {
        guard ReleasePolicy.isEnabled(.medicalCalculators) else { return 0...0 }
        guard let profile = selectedMedicationProfile,
            let medication = profile.medication
        else {
            return 0.0...0.0
        }

        // Get therapeutic range based on medication type
        let (minDose, maxDose): (Double, Double) = {
            switch medication {
            case .semaglutide:
                return (0.25, 2.4)
            case .tirzepatide:
                return (2.5, 15.0)
            case .liraglutide:
                return (0.6, 3.0)
            case .dulaglutide:
                return (0.75, 4.5)
            }
        }()

        return minDose...maxDose
    }

    var doseAmountStep: Double {
        guard ReleasePolicy.isEnabled(.medicalCalculators) else { return 0 }
        guard let profile = selectedMedicationProfile,
            let medication = profile.medication
        else {
            return 0.25
        }

        // Compounded medications use fine-grained 0.25mg steps
        if profile.brandName == "Generic" || profile.isCompounded {
            return 0.25
        }

        // Branded medications use discrete steps based on available doses
        let availableDoses = medication.availableDoses(for: profile.brandName)
        guard availableDoses.count > 1 else {
            return 0.25
        }

        // Calculate smallest step between available doses
        let sortedDoses = availableDoses.sorted()
        var minStep = Double.greatestFiniteMagnitude
        for index in 0..<(sortedDoses.count - 1) {
            let step = sortedDoses[index + 1] - sortedDoses[index]
            if step < minStep {
                minStep = step
            }
        }

        return minStep > 0 ? minStep : 0.25
    }

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
        guard let amount = self.amountToSave else { return false }

        if ReleasePolicy.isEnabled(.medicalCalculators) {
            let range = doseAmountRange
            guard range.lowerBound > 0, range.contains(amount) else { return false }
        }

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

    var amountToSave: Double? {
        if ReleasePolicy.isEnabled(.medicalCalculators) {
            return self.doseAmount.isFinite && self.doseAmount > 0 ? self.doseAmount : nil
        }
        return RecordedAmountInput.parse(self.doseAmountText)
    }

    // MARK: - Initialization

    init() {
        let now = Date()
        self.doseDate = now
        self.doseTime = now
    }

    // MARK: - Smart Defaults Loading

    @discardableResult
    func loadSmartDefaults(
        context: ModelContext,
        prePopulatedTimestamp: Date? = nil,
        prePopulatedAmount: Double? = nil,
        preSelectedProfile: MedicationProfile? = nil
    ) -> Task<Void, Never> {
        if let timestamp = prePopulatedTimestamp {
            self.doseDate = timestamp
            self.doseTime = timestamp
        }

        return Task { @MainActor in
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

                self.selectedMedicationProfile = preSelectedProfile ?? self.medicationProfiles.first

                // Update dose amount from selected profile
                self.updateDoseAmount()
                if let prePopulatedAmount {
                    self.doseAmount = prePopulatedAmount
                }

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
    @discardableResult
    func loadEditData(_ editData: DoseEditData, context: ModelContext) -> Task<Void, Never> {
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

    /// Pre-populate form with data from a scheduled dose (for deeplink/notification handling)
    /// - Parameters:
    ///   - scheduledDoseId: UUID of the scheduled dose to load
    ///   - context: ModelContext for database access
    @discardableResult
    func prepareForScheduledDose(scheduledDoseId: UUID, context: ModelContext) -> Task<Void, Never> {
        Task { @MainActor in
            do {
                self.isLoading = true
                self.errorMessage = nil

                // Fetch the scheduled dose
                let scheduleDescriptor = FetchDescriptor<ScheduledDose>(
                    predicate: #Predicate<ScheduledDose> { dose in
                        dose.id == scheduledDoseId
                    }
                )
                guard let scheduledDose = try context.fetch(scheduleDescriptor).first else {
                    self.errorMessage = "Scheduled dose not found"
                    self.isLoading = false
                    return
                }

                // Load smart defaults with the scheduled time
                await self.loadSmartDefaults(
                    context: context,
                    prePopulatedTimestamp: scheduledDose.scheduledTime,
                    prePopulatedAmount: scheduledDose.doseAmount,
                    preSelectedProfile: scheduledDose.schedule?.medicationProfile
                ).value

                self.isLoading = false

            } catch {
                self.errorMessage = "Failed to load scheduled dose: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // MARK: - Smart Default Updates

    private func updateDoseAmount() {
        guard let profile = selectedMedicationProfile else {
            self.doseAmount = 0.0
            return
        }

        if !ReleasePolicy.isEnabled(.medicalCalculators) {
            let hasSplitSchedule = profile.schedules?.contains { $0.isActive && $0.patternType == .splitDose } ?? false
            self.doseAmount = hasSplitSchedule ? 0 : profile.currentDose
            return
        }

        // Check if active schedule uses split-dose pattern
        var newDose: Double
        if let schedule = profile.schedules?.first(where: { $0.isActive }),
            schedule.patternType == .splitDose
        {
            // Split-dose: Show half the weekly dose per administration
            // Example: 1.0mg weekly split → 0.5mg per dose (2x per week)
            newDose = profile.currentDose / 2
        } else {
            newDose = profile.currentDose
        }

        // Clamp to valid range
        self.doseAmount = clampDoseAmount(newDose)
    }

    func clampDoseAmount(_ dose: Double) -> Double {
        guard ReleasePolicy.isEnabled(.medicalCalculators) else { return dose }
        let range = doseAmountRange
        return min(max(dose, range.lowerBound), range.upperBound)
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

    // MARK: - Form Management

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
        guard ReleasePolicy.isEnabled(.medicalCalculators) else { return false }
        logger.trace("Checking if titration dialog should be shown")

        guard let pendingTitration = getPendingTitration() else {
            logger.trace("No pending titration found")
            return false
        }

        // Don't show if user clicked "Remind Me Later"
        if titrationRemindLater {
            logger.trace("Titration reminder deferred by user")
            return false
        }

        // Show if titration date is today or in the past
        let shouldShow = pendingTitration.scheduledDate <= Date()

        if shouldShow {
            logger.debug("Showing titration dialog: \(pendingTitration.fromDose)mg → \(pendingTitration.toDose)mg")
        }

        return shouldShow
    }

    /// Gets the pending titration for the selected medication profile
    /// Returns nil if no medication profile selected or no pending titration exists
    func getPendingTitration() -> DoseTitration? {
        guard ReleasePolicy.isEnabled(.medicalCalculators) else { return nil }
        logger.trace("Getting pending titration")

        guard let profile = selectedMedicationProfile else {
            logger.trace("No medication profile selected")
            return nil
        }

        guard let incompleteTitrations = profile.doseTitrations?.filter({ !$0.isCompleted }),
            !incompleteTitrations.isEmpty
        else {
            logger.trace("No incomplete titrations for \(profile.brandName)")
            return nil
        }

        // Find the EARLIEST (nearest) incomplete titration
        let pending = incompleteTitrations.min(by: { $0.scheduledDate < $1.scheduledDate })

        if let pending {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            let dateStr = formatter.string(from: pending.scheduledDate)
            logger.debug("Found pending titration: \(pending.fromDose)mg → \(pending.toDose)mg on \(dateStr)")
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
        guard ReleasePolicy.isEnabled(.medicalCalculators) else {
            throw MedicationManager.MedicationError.medicalCalculatorsUnavailable
        }
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
        guard ReleasePolicy.isEnabled(.medicalCalculators) else {
            throw MedicationManager.MedicationError.medicalCalculatorsUnavailable
        }
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
