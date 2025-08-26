//
//  User.swift
//  JabTracker
//

import Foundation
import SwiftData

@Model
final class User {
    var id: UUID = UUID()
    var email: String // Required - users must have email from Sign in with Apple
    var name: String? // Optional - Apple might not provide
    var dateOfBirth: Date? // Optional - user may choose not to provide
    var weight: Double = 70.0 // Required with default for medical app
    var weightUnit: String = "kg" // Required with default
    var timezone: String = TimeZone.current.identifier // Required with default
    var appleUserId: String? // For Sign in with Apple linking
    var createdAt: Date = Date() // Required - auto-generated
    var updatedAt: Date = Date() // Required - auto-generated

    @Relationship(deleteRule: .cascade, inverse: \Dose.user)
    var doses: [Dose] = [] // Non-nil empty array by default

    init(
        email: String,
        name: String? = nil,
        dateOfBirth: Date? = nil,
        weight: Double = 70.0,
        weightUnit: String = "kg",
        timezone: String = TimeZone.current.identifier,
        appleUserId: String? = nil)
    {
        self.email = email
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.weight = weight
        self.weightUnit = weightUnit
        self.timezone = timezone
        self.appleUserId = appleUserId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.doses = []
    }
}
