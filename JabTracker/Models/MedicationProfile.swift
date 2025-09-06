//
//  MedicationProfile.swift
//  JabTracker
//

import Foundation
import SwiftData

@Model
final class MedicationProfile {
    var id: UUID = UUID()
    var genericName: String = "" // CloudKit requires default value
    var brandName: String = "" // CloudKit requires default value
    var currentDose: Double = 0.0 // CloudKit requires default value
    var startDate: Date = Date() // Required with default
    var refillDate: Date? // Optional - may not have refill scheduled yet
    var medicationType: String = "" // Store Medication enum rawValue for CloudKit compatibility
    
    // Enhanced fields for compounding and pen support
    var isCompounded: Bool = false // Compounded vs branded medication
    var vialStrength: Double? // For compounded: mg in vial
    var reconstitutionVolume: Double? // For compounded: ml of water to add
    var penType: String? // For branded: specific pen model
    var notes: String = "" // User notes about medication
    var updatedAt: Date = Date() // Track modifications
    var createdAt: Date = Date() // Track creation

    @Relationship(deleteRule: .cascade, inverse: \Dose.medication)
    var doses: [Dose]? // CloudKit requires optional relationships

    init(
        genericName: String = "",
        brandName: String = "",
        currentDose: Double = 0.0,
        startDate: Date = Date(),
        refillDate: Date? = nil,
        medicationType: String = "",
        isCompounded: Bool = false,
        vialStrength: Double? = nil,
        reconstitutionVolume: Double? = nil,
        penType: String? = nil,
        notes: String = "")
    {
        self.genericName = genericName
        self.brandName = brandName
        self.currentDose = currentDose
        self.startDate = startDate
        self.refillDate = refillDate
        self.medicationType = medicationType
        self.isCompounded = isCompounded
        self.vialStrength = vialStrength
        self.reconstitutionVolume = reconstitutionVolume
        self.penType = penType
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
        // Don't initialize optional relationship - let SwiftData handle it
    }

    // MARK: - Computed Properties

    var medication: Medication? {
        get {
            Medication(rawValue: self.medicationType)
        }
        set {
            self.medicationType = newValue?.rawValue ?? ""
        }
    }
}
