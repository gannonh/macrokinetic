//
//  MedicationManager.swift
//  JabTracker
//

import Foundation
import SwiftData

/// Manages CRUD operations for medication profiles with validation
@MainActor
class MedicationManager: ObservableObject {
    
    private let modelContext: ModelContext
    @Published var profiles: [MedicationProfile] = []
    @Published var activeProfile: MedicationProfile?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchProfiles()
    }
    
    /// Error types for medication management
    enum MedicationError: LocalizedError {
        case invalidDose
        case doseOutOfRange
        case profileNotFound
        case invalidCompoundingSettings
        case saveFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidDose:
                return "Invalid dose amount"
            case .doseOutOfRange:
                return "Dose is outside the available range for this medication"
            case .profileNotFound:
                return "Medication profile not found"
            case .invalidCompoundingSettings:
                return "Invalid compounding settings. Please check vial strength and water volume"
            case .saveFailed:
                return "Failed to save medication profile"
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Fetch all medication profiles for the current user
    func fetchProfiles() {
        let descriptor = FetchDescriptor<MedicationProfile>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        do {
            profiles = try modelContext.fetch(descriptor)
            activeProfile = profiles.first { profile in
                // Most recent profile is considered active
                profile.startDate <= Date()
            }
        } catch {
            print("Failed to fetch medication profiles: \(error)")
            profiles = []
        }
    }
    
    /// Create a new medication profile
    func createProfile(
        medication: Medication,
        brandName: String,
        currentDose: Double,
        isCompounded: Bool = false,
        vialStrength: Double? = nil,
        reconstitutionVolume: Double? = nil,
        penType: String? = nil,
        notes: String = ""
    ) throws -> MedicationProfile {
        
        // Validate dose is within medication range
        guard medication.availableDoses.contains(where: { abs($0 - currentDose) < 0.01 }) else {
            throw MedicationError.doseOutOfRange
        }
        
        // Validate compounding settings if applicable
        if isCompounded {
            guard let vialStrength = vialStrength,
                  let reconstitutionVolume = reconstitutionVolume,
                  vialStrength >= currentDose,
                  reconstitutionVolume > 0 else {
                throw MedicationError.invalidCompoundingSettings
            }
        }
        
        let profile = MedicationProfile(
            genericName: medication.displayName,
            brandName: brandName,
            currentDose: currentDose,
            startDate: Date(),
            refillDate: nil,
            medicationType: medication.rawValue,
            isCompounded: isCompounded,
            vialStrength: vialStrength,
            reconstitutionVolume: reconstitutionVolume,
            penType: penType,
            notes: notes
        )
        
        modelContext.insert(profile)
        
        do {
            try modelContext.save()
            fetchProfiles()
            return profile
        } catch {
            throw MedicationError.saveFailed
        }
    }
    
    /// Update an existing medication profile
    func updateProfile(
        _ profile: MedicationProfile,
        currentDose: Double? = nil,
        refillDate: Date? = nil,
        isCompounded: Bool? = nil,
        vialStrength: Double? = nil,
        reconstitutionVolume: Double? = nil,
        penType: String? = nil,
        notes: String? = nil
    ) throws {
        
        // Validate dose if provided
        if let currentDose = currentDose,
           let medication = profile.medication {
            guard medication.availableDoses.contains(where: { abs($0 - currentDose) < 0.01 }) else {
                throw MedicationError.doseOutOfRange
            }
            profile.currentDose = currentDose
        }
        
        // Update other fields if provided
        if let refillDate = refillDate {
            profile.refillDate = refillDate
        }
        
        if let isCompounded = isCompounded {
            profile.isCompounded = isCompounded
        }
        
        if let vialStrength = vialStrength {
            profile.vialStrength = vialStrength
        }
        
        if let reconstitutionVolume = reconstitutionVolume {
            profile.reconstitutionVolume = reconstitutionVolume
        }
        
        if let penType = penType {
            profile.penType = penType
        }
        
        if let notes = notes {
            profile.notes = notes
        }
        
        // Validate compounding settings if compounded
        if profile.isCompounded {
            guard let vialStrength = profile.vialStrength,
                  let reconstitutionVolume = profile.reconstitutionVolume,
                  vialStrength >= profile.currentDose,
                  reconstitutionVolume > 0 else {
                throw MedicationError.invalidCompoundingSettings
            }
        }
        
        profile.updatedAt = Date()
        
        do {
            try modelContext.save()
            fetchProfiles()
        } catch {
            throw MedicationError.saveFailed
        }
    }
    
    /// Delete a medication profile
    func deleteProfile(_ profile: MedicationProfile) throws {
        modelContext.delete(profile)
        
        do {
            try modelContext.save()
            fetchProfiles()
        } catch {
            throw MedicationError.saveFailed
        }
    }
    
    // MARK: - Validation Helpers
    
    /// Check if a dose is valid for a medication
    func isValidDose(_ dose: Double, for medication: Medication) -> Bool {
        medication.availableDoses.contains { availableDose in
            abs(availableDose - dose) < 0.01
        }
    }
    
    /// Get the next recommended dose for escalation
    func nextEscalationDose(for profile: MedicationProfile) -> Double? {
        guard let medication = profile.medication else { return nil }
        
        let currentDose = profile.currentDose
        let availableDoses = medication.availableDoses.sorted()
        
        // Find the next higher dose
        for dose in availableDoses {
            if dose > currentDose {
                return dose
            }
        }
        
        return nil // Already at maximum dose
    }
    
    /// Calculate days until refill needed
    func daysUntilRefill(for profile: MedicationProfile) -> Int? {
        guard let refillDate = profile.refillDate else { return nil }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: refillDate)
        return components.day
    }
    
    // MARK: - Reconstitution Helpers
    
    /// Calculate reconstitution for a compounded profile
    func calculateReconstitution(for profile: MedicationProfile) throws -> ReconstitutionCalculator.ReconstitutionResult? {
        guard profile.isCompounded,
              let vialStrength = profile.vialStrength,
              let reconstitutionVolume = profile.reconstitutionVolume else {
            return nil
        }
        
        return try ReconstitutionCalculator.calculate(
            vialStrength: vialStrength,
            targetDose: profile.currentDose,
            waterVolume: reconstitutionVolume
        )
    }
    
    // MARK: - Pen Click Helpers
    
    /// Calculate pen clicks for a branded profile
    func calculatePenClicks(for profile: MedicationProfile) throws -> PenClickCalculator.PenClickResult? {
        guard !profile.isCompounded,
              let penTypeString = profile.penType,
              let penType = PenClickCalculator.PenType(rawValue: penTypeString) else {
            return nil
        }
        
        return try PenClickCalculator.calculate(
            penType: penType,
            targetDose: profile.currentDose
        )
    }
}