//
//  DoseValidation.swift
//  JabTracker
//

import Foundation

/// Comprehensive medical validation framework for dose tracking
/// Safety-critical validation for GLP-1 medication dosing
/// Ensures medical accuracy and prevents dangerous dosing errors
enum DoseValidation {
    // MARK: - Dose Amount Validation

    /// Validates dose amount against FDA-approved ranges for specific medication and brand
    /// - Parameters:
    ///   - amount: Dose amount to validate
    ///   - medication: Medication type
    ///   - brand: Specific brand name (affects available doses)
    /// - Returns: true if dose amount is medically safe and available
    static func isValidDoseAmount(_ amount: Double, for medication: Medication, brand: String) -> Bool {
        guard amount > 0 else { return false }
        let availableDoses = medication.availableDoses(for: brand)
        return availableDoses.contains(amount)
    }

    /// Validates dose amount against general medication ranges (brand-agnostic)
    /// - Parameters:
    ///   - amount: Dose amount to validate
    ///   - medication: Medication type
    /// - Returns: true if dose amount is within therapeutic ranges
    static func isValidDoseAmount(_ amount: Double, for medication: Medication) -> Bool {
        guard amount > 0 else { return false }
        let availableDoses = medication.availableDoses
        return availableDoses.contains(amount)
    }

    /// Validates dose precision for specific medication (prevents dangerous micro-dosing errors)
    /// - Parameters:
    ///   - amount: Dose amount to validate
    ///   - medication: Medication type
    /// - Returns: true if amount matches medication's precision requirements
    static func isValidDosePrecision(_ amount: Double, for medication: Medication) -> Bool {
        let precision = medication.dosePrecision
        let rounded = (amount * precision).rounded() / precision
        return abs(amount - rounded) < 0.001 // Allow for floating point precision
    }

    // MARK: - Injection Site Validation

    /// Validates injection site for anatomical safety
    /// - Parameter site: Injection site name
    /// - Returns: true if site is anatomically safe for subcutaneous injection
    static func isValidInjectionSite(_ site: String) -> Bool {
        let normalizedSite = site.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return AnatomicalSites.approved.map { $0.lowercased() }.contains(normalizedSite)
    }

    /// Validates injection site rotation pattern for safety
    /// - Parameters:
    ///   - newSite: Proposed injection site
    ///   - previousSites: Array of recent injection sites in chronological order
    ///   - rotationWindow: Number of previous doses to check for rotation (default: 4)
    /// - Returns: true if site rotation follows medical guidelines
    static func isValidSiteRotation(_ newSite: String, previousSites: [String], rotationWindow: Int = 4) -> Bool {
        guard self.isValidInjectionSite(newSite) else { return false }

        // Take only the most recent sites within rotation window
        let recentSites = Array(previousSites.suffix(rotationWindow))

        // For safety, don't use the same site consecutively
        if let lastSite = recentSites.last {
            return newSite.lowercased() != lastSite.lowercased()
        }

        return true
    }

    // MARK: - Temporal Validation

    /// Validates dose timing against frequency constraints
    /// - Parameters:
    ///   - proposedDate: Date for new dose
    ///   - lastDoseDate: Date of most recent dose
    ///   - medication: Medication type (determines frequency)
    /// - Returns: true if timing respects minimum intervals
    static func isValidDoseTiming(_ proposedDate: Date, lastDoseDate: Date?, for medication: Medication) -> Bool {
        guard let lastDate = lastDoseDate else { return true } // First dose is always valid

        let timeInterval = proposedDate.timeIntervalSince(lastDate)
        let minimumInterval = medication.minimumDoseInterval

        return timeInterval >= minimumInterval
    }

    /// Validates that dose date is not in the future
    /// - Parameter date: Date to validate
    /// - Returns: true if date is not in the future (allows current time with tolerance)
    static func isValidDoseDate(_ date: Date) -> Bool {
        let now = Date()
        let tolerance: TimeInterval = 300 // 5 minutes tolerance for clock skew
        return date <= now.addingTimeInterval(tolerance)
    }

    /// Validates dose date is not unreasonably far in the past
    /// - Parameters:
    ///   - date: Date to validate
    ///   - maxPastDays: Maximum days in the past to allow (default: 365)
    /// - Returns: true if date is within reasonable historical range
    static func isReasonableHistoricalDate(_ date: Date, maxPastDays: Int = 365) -> Bool {
        let now = Date()
        let oldestAllowed = now.addingTimeInterval(-Double(maxPastDays) * 24 * 60 * 60)
        // Add small tolerance for boundary conditions and timing precision
        let tolerance: TimeInterval = 60 // 1 minute tolerance for boundary calculations
        return date >= oldestAllowed.addingTimeInterval(-tolerance)
    }

    // MARK: - Comprehensive Dose Validation

    /// Performs comprehensive validation of a complete dose entry
    /// - Parameters:
    ///   - amount: Dose amount
    ///   - date: Dose date/time
    ///   - site: Injection site
    ///   - medication: Medication type
    ///   - brand: Brand name
    ///   - lastDoseDate: Date of previous dose (for frequency validation)
    ///   - previousSites: Recent injection sites (for rotation validation)
    /// - Returns: ValidationResult with detailed feedback
    static func validateDose(
        amount: Double,
        date: Date,
        site: String?,
        medication: Medication,
        brand: String,
        lastDoseDate: Date? = nil,
        previousSites: [String] = []) -> ValidationResult
    {
        var errors: [ValidationError] = []

        // Amount validation
        if !self.isValidDoseAmount(amount, for: medication, brand: brand) {
            errors.append(.invalidDoseAmount(amount: amount, medication: medication, brand: brand))
        }

        if !self.isValidDosePrecision(amount, for: medication) {
            errors.append(.invalidDosePrecision(amount: amount, medication: medication))
        }

        // Date validation
        if !self.isValidDoseDate(date) {
            errors.append(.futureDate(date: date))
        }

        if !self.isReasonableHistoricalDate(date) {
            errors.append(.unreasonableHistoricalDate(date: date))
        }

        // Frequency validation
        if !self.isValidDoseTiming(date, lastDoseDate: lastDoseDate, for: medication) {
            errors.append(.invalidDoseTiming(proposedDate: date, lastDate: lastDoseDate, medication: medication))
        }

        // Site validation (if provided)
        if let injectionSite = site {
            if !self.isValidInjectionSite(injectionSite) {
                errors.append(.invalidInjectionSite(site: injectionSite))
            } else if !self.isValidSiteRotation(injectionSite, previousSites: previousSites) {
                errors.append(.invalidSiteRotation(site: injectionSite, previousSites: previousSites))
            }
        }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    // MARK: - Constants

    enum AnatomicalSites {
        static let approved: [String] = [
            "Thigh",
            "Abdomen",
            "Upper Arm",
            "Buttocks",
        ]
    }
}

// MARK: - Extensions

extension Medication {
    /// Minimum interval between doses based on medication frequency
    var minimumDoseInterval: TimeInterval {
        switch self.frequency {
        case .daily:
            return 20 * 60 * 60 // 20 hours minimum for daily medications
        case .weekly:
            return 6 * 24 * 60 * 60 // 6 days minimum for weekly medications
        }
    }

    /// Dose precision multiplier for validation (prevents micro-dosing errors)
    var dosePrecision: Double {
        switch self {
        case .semaglutide, .liraglutide:
            return 100 // 0.01 mg precision
        case .tirzepatide, .dulaglutide:
            return 10 // 0.1 mg precision
        }
    }
}

// MARK: - Result Types

/// Comprehensive validation result with detailed error information
struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]

    /// User-friendly description of validation issues
    var errorDescription: String? {
        guard !self.errors.isEmpty else { return nil }
        return self.errors.map(\.localizedDescription).joined(separator: "\n")
    }
}

/// Detailed validation errors for medical safety
enum ValidationError: LocalizedError {
    case invalidDoseAmount(amount: Double, medication: Medication, brand: String)
    case invalidDosePrecision(amount: Double, medication: Medication)
    case futureDate(date: Date)
    case unreasonableHistoricalDate(date: Date)
    case invalidDoseTiming(proposedDate: Date, lastDate: Date?, medication: Medication)
    case invalidInjectionSite(site: String)
    case invalidSiteRotation(site: String, previousSites: [String])

    var errorDescription: String? {
        switch self {
        case let .invalidDoseAmount(amount, medication, brand):
            let availableDoses = medication.availableDoses(for: brand).map { String($0) }.joined(separator: ", ")
            let medicationName = medication.displayName
            return "Dose \(amount) mg is not available for \(medicationName) (\(brand)). " +
                "Available doses: \(availableDoses) mg"

        case let .invalidDosePrecision(amount, medication):
            return "Dose \(amount) mg has invalid precision for \(medication.displayName). Use appropriate increments."

        case .futureDate:
            return "Dose date cannot be in the future."

        case .unreasonableHistoricalDate:
            return "Dose date is too far in the past (more than 1 year ago)."

        case let .invalidDoseTiming(_, lastDate, medication):
            let frequencyDesc = medication.frequency == .daily ? "daily" : "weekly"
            let lastDateDesc = lastDate?.formatted(date: .abbreviated, time: .omitted) ?? "unknown"
            return "Too soon since last dose (\(lastDateDesc)). \(medication.displayName) is \(frequencyDesc)."

        case let .invalidInjectionSite(site):
            let approvedSites = DoseValidation.AnatomicalSites.approved.joined(separator: ", ")
            return "'\(site)' is not a safe injection site. Use: \(approvedSites)"

        case let .invalidSiteRotation(site, previousSites):
            let lastSite = previousSites.last ?? ""
            return "Avoid using '\(site)' again immediately after '\(lastSite)'. Rotate injection sites for safety."
        }
    }
}
