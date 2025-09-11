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
            updateDoseAmount()
            updateRecommendedInjectionSites()
        }
    }
    
    @Published var doseAmount: Double = 0.0
    @Published var selectedInjectionSite: String = ""
    @Published var doseTime: Date = Date()
    @Published var notes: String = ""
    
    @Published var recommendedInjectionSites: [String] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // MARK: - Computed Properties
    
    /// Determines if dose can be saved based on current state
    var canSaveDose: Bool {
        guard selectedMedicationProfile != nil else { return false }
        guard doseAmount > 0 else { return false }
        guard !selectedInjectionSite.isEmpty else { return false }
        return true
    }
    
    // MARK: - Initialization
    
    init() {
        self.doseTime = Date()
    }
    
    // MARK: - Smart Defaults Loading
    
    /// Loads smart defaults from user's medication profiles and dose history
    func loadSmartDefaults(context: ModelContext) {
        Task { @MainActor in
            do {
                isLoading = true
                errorMessage = nil
                
                // Fetch all medication profiles for the current user
                let profileDescriptor = FetchDescriptor<MedicationProfile>()
                self.medicationProfiles = try context.fetch(profileDescriptor)
                
                guard !medicationProfiles.isEmpty else {
                    errorMessage = "No medication profiles found. Please create a medication profile first."
                    isLoading = false
                    return
                }
                
                // Select the most recent medication profile as default
                selectedMedicationProfile = medicationProfiles.first
                
                // Update dose amount from selected profile
                updateDoseAmount()
                
                // Get smart injection site recommendation
                updateRecommendedInjectionSites()
                
                isLoading = false
                
            } catch {
                errorMessage = "Failed to load medication profiles: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - Smart Default Updates
    
    /// Updates dose amount based on selected medication profile's current dose
    private func updateDoseAmount() {
        guard let profile = selectedMedicationProfile else {
            doseAmount = 0.0
            return
        }
        
        doseAmount = profile.currentDose
    }
    
    /// Updates recommended injection sites and selects smart default based on dose history
    private func updateRecommendedInjectionSites() {
        guard let profile = selectedMedicationProfile,
              let medication = profile.medication else {
            recommendedInjectionSites = DoseDefaults.allInjectionSites
            selectedInjectionSite = DoseDefaults.allInjectionSites.first ?? ""
            return
        }
        
        // Get recommended sites for this medication
        recommendedInjectionSites = DoseDefaults.recommendedInjectionSites(for: medication)
        
        // Get recent doses for this medication profile
        let recentDoses = (profile.doses ?? []).suffix(5) // Last 5 doses for rotation analysis
        
        // Use DoseDefaults to get next recommended site based on rotation
        selectedInjectionSite = DoseDefaults.nextRecommendedSite(
            for: medication,
            recentDoses: Array(recentDoses),
            preferredSites: profile.preferredInjectionSites
        )
    }
    
    // MARK: - Dose Saving
    
    /// Saves the current dose with smart defaults to the data store
    func saveDose(context: ModelContext) async throws {
        guard let profile = selectedMedicationProfile else {
            throw QuickDoseError.noMedicationProfile
        }
        
        guard canSaveDose else {
            throw QuickDoseError.invalidDoseData
        }
        
        // Create new dose with current values
        let newDose = Dose(
            amount: doseAmount,
            timestamp: doseTime,
            site: selectedInjectionSite,
            notes: notes.isEmpty ? nil : notes,
            imageData: nil, // Quick dose entry doesn't support photos
            skipped: false,
            user: nil, // Will be set when user relationship is established
            medication: profile
        )
        
        // Insert into context
        context.insert(newDose)
        
        // Save context
        try context.save()
        
        // Reset form for next use
        resetForm()
    }
    
    /// Resets form to initial state after successful save
    private func resetForm() {
        notes = ""
        doseTime = Date()
        // Keep medication selection and injection site rotation for convenience
    }
    
    // MARK: - Convenience Methods
    
    /// Gets the next scheduled dose time for the selected medication profile
    func getNextScheduledDoseTime() -> Date? {
        guard let profile = selectedMedicationProfile else { return nil }
        
        return DoseDefaults.nextScheduledDose(
            for: profile,
            from: Date(),
            doses: profile.doses
        )
    }
    
    /// Checks if a dose is overdue for the selected medication profile
    func isDoseOverdue() -> Bool {
        guard let profile = selectedMedicationProfile else { return false }
        
        return DoseDefaults.isDoseOverdue(
            for: profile,
            currentDate: Date(),
            gracePeriodHours: 2,
            doses: profile.doses
        )
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
        case .saveFailed(let error):
            return "Failed to save dose: \(error.localizedDescription)"
        }
    }
}

// MARK: - Extensions

extension MedicationProfile {
    /// Computed property to get Medication enum from generic/brand names
    var medication: Medication? {
        Medication.fromGenericName(genericName)
    }
}

extension Medication {
    /// Helper to create Medication from generic name string
    static func fromGenericName(_ name: String) -> Medication? {
        switch name.lowercased() {
        case "semaglutide":
            return .semaglutide
        case "tirzepatide":
            return .tirzepatide
        case "liraglutide":
            return .liraglutide
        case "dulaglutide":
            return .dulaglutide
        default:
            return nil
        }
    }
}
