//
//  Dose.swift
//  JabTracker
//

import Foundation
import SwiftData

@Model
final class Dose {
    var id: UUID = UUID()
    var amount: Double?
    var timestamp: Date?
    var site: String?
    var notes: String?
    var imageData: Data?
    var skipped: Bool = false

    var user: User?
    var medication: MedicationProfile?

    init(
        id: UUID = UUID(),
        amount: Double? = nil,
        timestamp: Date? = nil,
        site: String? = nil,
        notes: String? = nil,
        imageData: Data? = nil,
        skipped: Bool = false,
        user: User? = nil,
        medication: MedicationProfile? = nil)
    {
        self.id = id
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
