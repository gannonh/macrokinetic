//
//  Dose.swift
//  JabTracker
//

import Foundation
import SwiftData

@Model
final class Dose {
    var id: UUID = UUID()
    var amount: Double = 0.0 // CloudKit requires default value
    var timestamp: Date = Date() // CloudKit requires default value
    var site: String? // Optional - injection site
    var notes: String? // Optional - user notes
    var imageData: Data? // Optional - photo attachment
    var skipped: Bool = false // Required with default

    var user: User?
    var medication: MedicationProfile?

    init(
        amount: Double = 0.0,
        timestamp: Date = Date(),
        site: String? = nil,
        notes: String? = nil,
        imageData: Data? = nil,
        skipped: Bool = false,
        user: User? = nil,
        medication: MedicationProfile? = nil)
    {
        self.amount = amount
        self.timestamp = timestamp
        self.site = site
        self.notes = notes
        self.imageData = imageData
        self.skipped = skipped
        self.user = user
        self.medication = medication
    }
}
