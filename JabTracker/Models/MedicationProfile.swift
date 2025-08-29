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

    @Relationship(deleteRule: .cascade, inverse: \Dose.medication)
    var doses: [Dose]? // CloudKit requires optional relationships

    init(
        genericName: String = "",
        brandName: String = "",
        currentDose: Double = 0.0,
        startDate: Date = Date(),
        refillDate: Date? = nil,
        medicationType: String = "")
    {
        self.genericName = genericName
        self.brandName = brandName
        self.currentDose = currentDose
        self.startDate = startDate
        self.refillDate = refillDate
        self.medicationType = medicationType
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
