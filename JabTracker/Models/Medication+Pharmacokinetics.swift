//
//  Medication+Pharmacokinetics.swift
//  JabTracker
//

import Foundation

/// Pharmacokinetic properties and calculations for medications
extension Medication {
  /// Half-life in hours for precise pharmacokinetic calculations
  /// Derived from halfLifeDays property but expressed in hours for computational precision
  var halfLifeHours: Double {
    halfLifeDays * 24.0
  }

  /// Elimination rate constant (k) in hours^-1
  /// Used in exponential decay calculations: C(t) = C₀ * e^(-kt)
  /// k = ln(2) / t₁/₂
  var eliminationRateConstant: Double {
    log(2.0) / self.halfLifeHours
  }

  /// Time to reach steady state (hours)
  /// Typically 5 half-lives for 97% steady state
  var timeToSteadyStateHours: Double {
    self.halfLifeHours * 5.0
  }

  /// Time to reach steady state (days)
  /// Convenience property for display purposes
  var timeToSteadyStateDays: Double {
    self.timeToSteadyStateHours / 24.0
  }

  /// Bioavailability factor for subcutaneous injection
  /// GLP-1 receptor agonists have high subcutaneous bioavailability
  var subcutaneousBioavailability: Double {
    switch self {
    case .semaglutide: return 0.89  // ~89% bioavailability for subcutaneous
    case .tirzepatide: return 0.80  // ~80% bioavailability for subcutaneous
    case .liraglutide: return 0.55  // ~55% bioavailability for subcutaneous
    case .dulaglutide: return 0.65  // ~65% bioavailability for subcutaneous
    }
  }

  /// Calculate the concentration at a given time after a single dose
  /// Uses first-order exponential decay: C(t) = C₀ * e^(-kt)
  /// - Parameters:
  ///   - initialConcentration: The peak concentration immediately after dose (C₀)
  ///   - timeElapsedHours: Time elapsed since the dose was administered (hours)
  /// - Returns: The concentration at the specified time
  func concentrationAtTime(
    initialConcentration: Double,
    timeElapsedHours: Double
  ) -> Double {
    guard timeElapsedHours >= 0 else { return initialConcentration }
    return initialConcentration * exp(-self.eliminationRateConstant * timeElapsedHours)
  }

  /// Calculate the fraction remaining after a given time
  /// Convenience method that returns the decay factor (0-1)
  /// - Parameter timeElapsedHours: Time elapsed since dose (hours)
  /// - Returns: Fraction of original dose remaining (0.0 to 1.0)
  func fractionRemainingAfter(timeElapsedHours: Double) -> Double {
    guard timeElapsedHours >= 0 else { return 1.0 }
    return exp(-self.eliminationRateConstant * timeElapsedHours)
  }

  /// Calculate steady-state progress as a percentage
  /// Based on the principle that steady state is reached after ~5 half-lives
  /// - Parameter timeOnMedicationHours: Total time user has been on this medication
  /// - Returns: Percentage toward steady state (0.0 to 100.0)
  func steadyStateProgress(timeOnMedicationHours: Double) -> Double {
    guard timeOnMedicationHours >= 0 else { return 0.0 }
    let progress = min(timeOnMedicationHours / self.timeToSteadyStateHours, 1.0)
    return progress * 100.0
  }

  /// Expected peak time after subcutaneous injection (hours)
  /// Time to reach maximum concentration after injection
  var peakTimeHours: Double {
    switch self {
    case .semaglutide: return 1.0  // Peak at ~1 hour post-injection
    case .tirzepatide: return 8.0  // Peak at ~8 hours post-injection
    case .liraglutide: return 8.0  // Peak at ~8-12 hours post-injection
    case .dulaglutide: return 24.0  // Peak at ~24-72 hours post-injection
    }
  }

  /// Calculate the relative potency factor compared to semaglutide
  /// Used for cross-medication comparisons and visualization
  var relativePotencyFactor: Double {
    switch self {
    case .semaglutide: return 1.0  // Reference medication
    case .tirzepatide: return 2.0  // Dual receptor agonist, higher potency
    case .liraglutide: return 0.8  // Similar potency but daily dosing
    case .dulaglutide: return 0.9  // Similar potency to semaglutide
    }
  }
}

// MARK: - Pharmacokinetic Validation

extension Medication {
  /// Validates that pharmacokinetic parameters are within expected medical ranges
  /// Used for safety checks during calculations
  var hasValidPharmacokinetics: Bool {
    halfLifeDays > 0 && halfLifeDays < 30  // No medication should have >30 day half-life
      && self.subcutaneousBioavailability > 0 && self.subcutaneousBioavailability <= 1.0
      && self.peakTimeHours > 0 && self.peakTimeHours < 168  // No peak time should exceed 1 week
  }

  /// Returns a validation error message if pharmacokinetics are invalid
  var pharmacokineticValidationError: String? {
    if !self.hasValidPharmacokinetics {
      return "Invalid pharmacokinetic parameters for \(displayName)"
    }
    return nil
  }
}
