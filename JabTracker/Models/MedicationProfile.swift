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
    var concentration: Double? // For compounded: mg/ml (calculated from reconstitution)
    var unitsPerDose: Double? // For compounded: units to draw (calculated from dose/concentration)
    var preferredInjectionSites: [String] = ["Thigh"] // Preferred injection sites from onboarding
    var notes: String = "" // User notes about medication
    var updatedAt: Date = Date() // Track modifications
    var createdAt: Date = Date() // Track creation

    @Relationship(deleteRule: .cascade, inverse: \Dose.medication)
    var doses: [Dose]? // CloudKit requires optional relationships

    @Relationship(deleteRule: .cascade, inverse: \DoseTitration.medicationProfile)
    var doseTitrations: [DoseTitration]? // Titration plans for this medication

    var user: User? // Parent user relationship

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
        concentration: Double? = nil,
        unitsPerDose: Double? = nil,
        preferredInjectionSites: [String] = ["Thigh"],
        notes: String = "")
    {
        self.genericName = genericName
        self.brandName = brandName
        self.currentDose = currentDose
        self.startDate = startDate
        self.refillDate = refillDate
        // If medicationType is empty but genericName matches a known medication, use that
        if medicationType.isEmpty, !genericName.isEmpty {
            self.medicationType = Medication.fromGenericName(genericName)?.rawValue ?? ""
        } else {
            self.medicationType = medicationType
        }
        self.isCompounded = isCompounded
        self.vialStrength = vialStrength
        self.reconstitutionVolume = reconstitutionVolume
        self.concentration = concentration
        self.unitsPerDose = unitsPerDose
        self.preferredInjectionSites = preferredInjectionSites
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
