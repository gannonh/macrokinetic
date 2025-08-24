//
//  User.swift
//  JabTracker
//

import Foundation
import SwiftData

@Model
final class User {
    var id: UUID = UUID()
    var email: String?
    var name: String?
    var dateOfBirth: Date?
    var weight: Double?
    var weightUnit: String?
    var timezone: String?
    var createdAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Dose.user)
    var doses: [Dose]?

    init(
        id: UUID = UUID(),
        email: String? = nil,
        name: String? = nil,
        dateOfBirth: Date? = nil,
        weight: Double? = nil,
        weightUnit: String? = nil,
        timezone: String? = nil,
        createdAt: Date? = nil)
    {
        self.id = id
        self.email = email
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.weight = weight
        self.weightUnit = weightUnit
        self.timezone = timezone
        self.createdAt = createdAt
        doses = []
    }
}
