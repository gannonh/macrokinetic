//
//  ProfileValidation.swift
//  JabTracker
//

import Foundation

/// Utility class for profile field validation
/// Extracted to promote single responsibility principle and improve testability
enum ProfileValidation {
  // MARK: - Weight Validation

  /// Validates weight input string for medical application
  /// - Parameter weight: String representation of weight
  /// - Returns: true if weight is valid (10-500), false otherwise
  static func isValidWeight(_ weight: String) -> Bool {
    guard let weightValue = Double(weight) else { return false }
    return weightValue >= 10 && weightValue <= 500
  }

  /// Validates weight value for medical application
  /// - Parameter weight: Double value of weight
  /// - Returns: true if weight is valid (10-500), false otherwise
  static func isValidWeight(_ weight: Double) -> Bool {
    weight >= 10 && weight <= 500
  }

  // MARK: - Name Validation

  /// Validates name input for profile creation
  /// - Parameter name: String to validate
  /// - Returns: true if name is valid (not empty after trimming), false otherwise
  static func isValidName(_ name: String) -> Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  // MARK: - Combined Profile Validation

  /// Validates complete profile data for saving
  /// - Parameters:
  ///   - name: User's name
  ///   - weight: User's weight as string
  /// - Returns: true if both name and weight are valid
  static func isValidProfile(name: String, weight: String) -> Bool {
    self.isValidName(name) && self.isValidWeight(weight)
  }

  // MARK: - Constants

  enum WeightLimits {
    static let minimum: Double = 10.0
    static let maximum: Double = 500.0
  }
}
