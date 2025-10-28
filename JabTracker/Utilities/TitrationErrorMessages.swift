//
//  TitrationErrorMessages.swift
//  JabTracker
//
//  Centralized error messages for titration operations
//  Ensures consistent messaging across ViewModels and Views
//

import Foundation

enum TitrationErrorMessages {
    /// Error message when titration completion fails
    static func completionFailed(_ error: Error) -> String {
        "Failed to complete dose increase: \(error.localizedDescription)"
    }

    /// Error message when titration rescheduling fails
    static func rescheduleFailed(_ error: Error) -> String {
        "Failed to reschedule dose increase: \(error.localizedDescription)"
    }

    /// Error message when no medication profile is found
    static let noMedicationProfile = "No medication profile found. Please create a medication profile first."
}
