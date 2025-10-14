//
//  QuickDoseViewModel.swift
//  JabTracker
//

import Foundation
import SwiftData

/// View model for quick dose entry with smart defaults and business logic
/// Handles medication profile loading, smart default computation, and dose saving
@MainActor
class QuickDoseViewModel: ObservableObject {
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

                // Fetch all medication profiles for the current user
                let profileDescriptor = FetchDescriptor<MedicationProfile>()
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

                // Fetch all medication profiles for the current user
                let profileDescriptor = FetchDescriptor<MedicationProfile>()
                self.medicationProfiles = try context.fetch(profileDescriptor)

                // Set values from edit data
                self.selectedMedicationProfile = editData.medicationProfile
                self.doseAmount = editData.amount
                self.doseDate = editData.timestamp
                self.doseTime = editData.timestamp
                self.selectedInjectionSite = editData.site ?? ""
                self.notes = editData.notes ?? ""

                // Update recommended injection sites
                self.updateRecommendedInjectionSites()

                self.isLoading = false

            } catch {
                self.errorMessage = "Failed to load dose data: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // MARK: - Smart Default Updates

    /// Updates dose amount based on selected medication profile's current dose
    private func updateDoseAmount() {
        guard let profile = selectedMedicationProfile else {
            self.doseAmount = 0.0
            return
        }

        self.doseAmount = profile.currentDose
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
