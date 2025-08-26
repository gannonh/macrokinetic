//
//  MedicationProfile.swift
//  JabTracker
//

import Foundation
import SwiftData

@Model
final class MedicationProfile {
    var id: UUID = UUID()
    var genericName: String // Required - must specify medication
    var brandName: String // Required - must specify brand  
    var currentDose: Double // Required - must specify current dose
    var startDate: Date = Date() // Required with default
    var refillDate: Date? // Optional - may not have refill scheduled yet

    @Relationship(deleteRule: .cascade, inverse: \Dose.medication)
    var doses: [Dose] = [] // Non-nil empty array by default

    init(
        genericName: String,
        brandName: String,
        currentDose: Double,
        startDate: Date = Date(),
        refillDate: Date? = nil)
    {
        self.genericName = genericName
        self.brandName = brandName
        self.currentDose = currentDose
        self.startDate = startDate
        self.refillDate = refillDate
        self.doses = []
    }
}
