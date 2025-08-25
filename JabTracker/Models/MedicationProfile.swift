//
//  MedicationProfile.swift
//  JabTracker
//

import Foundation
import SwiftData

@Model
final class MedicationProfile {
    var id: UUID = UUID()
    var genericName: String?
    var brandName: String?
    var currentDose: Double?
    var startDate: Date?
    var refillDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \Dose.medication)
    var doses: [Dose]?

    init(
        id: UUID = UUID(),
        genericName: String? = nil,
        brandName: String? = nil,
        currentDose: Double? = nil,
        startDate: Date? = nil,
        refillDate: Date? = nil) {
        self.id = id
        self.genericName = genericName
        self.brandName = brandName
        self.currentDose = currentDose
        self.startDate = startDate
        self.refillDate = refillDate
        doses = []
    }
}
