//
//  PenClickCalculator.swift
//  JabTracker
//

import Foundation

/// Calculates pen clicks for branded GLP-1 medication pens
enum PenClickCalculator {
    /// Represents the result of a pen click calculation
    struct PenClickResult {
        let clicks: Int // number of clicks to dial
        let actualDose: Double // actual dose delivered (may differ slightly)
        let penType: String // pen model used for calculation

        var displayText: String {
            "Dial to \(self.clicks) clicks for your \(self.actualDose.formatted(.number.precision(.fractionLength(2)))) mg dose"
        }
    }

    /// Error types for pen click calculations
    enum PenClickError: LocalizedError {
        case unknownPenType
        case invalidDose
        case doseExceedsMaximum
        case doseRequiresPartialClick

        var errorDescription: String? {
            switch self {
            case .unknownPenType:
                return "Unknown pen type. Please select a supported pen model"
            case .invalidDose:
                return "Dose must be greater than 0"
            case .doseExceedsMaximum:
                return "Dose exceeds maximum for this pen"
            case .doseRequiresPartialClick:
                return "This dose would require a partial click. Please adjust to the nearest available dose"
            }
        }
    }

    /// Supported pen types with their click-to-dose ratios
    enum PenType: String, CaseIterable {
        case ozempicQuarterHalf = "Ozempic 0.25/0.5mg pen"
        case ozempic1mg = "Ozempic 1mg pen"
        case ozempic2mg = "Ozempic 2mg pen"
        case wegovy025mg = "Wegovy 0.25mg pen"
        case wegovy05mg = "Wegovy 0.5mg pen"
        case wegovy1mg = "Wegovy 1mg pen"
        case wegovy17mg = "Wegovy 1.7mg pen"
        case wegovy24mg = "Wegovy 2.4mg pen"
        case mounjaro25mg = "Mounjaro 2.5mg pen"
        case mounjaro5mg = "Mounjaro 5mg pen"
        case mounjaro75mg = "Mounjaro 7.5mg pen"
        case mounjaro10mg = "Mounjaro 10mg pen"
        case mounjaro125mg = "Mounjaro 12.5mg pen"
        case mounjaro15mg = "Mounjaro 15mg pen"
        case trulicity075mg = "Trulicity 0.75mg pen"
        case trulicity15mg = "Trulicity 1.5mg pen"
        case trulicity3mg = "Trulicity 3mg pen"
        case trulicity45mg = "Trulicity 4.5mg pen"
        case victoza = "Victoza pen"
        case saxenda = "Saxenda pen"

        /// Dose per click in mg
        var dosePerClick: Double {
            switch self {
            case .ozempicQuarterHalf, .ozempic1mg:
                return 0.01 // 0.01mg per click
            case .ozempic2mg:
                return 0.02 // 0.02mg per click
            case .wegovy025mg, .wegovy05mg, .wegovy1mg, .wegovy17mg, .wegovy24mg:
                return 0.01 // Fixed dose pens - no click adjustment
            case .mounjaro25mg, .mounjaro5mg, .mounjaro75mg, .mounjaro10mg, .mounjaro125mg, .mounjaro15mg:
                return 0.025 // 0.025mg per click for all Mounjaro pens
            case .trulicity075mg, .trulicity15mg, .trulicity3mg, .trulicity45mg:
                return 0.01 // Single-use pens - no click adjustment
            case .victoza, .saxenda:
                return 0.01 // 0.01mg per click for liraglutide pens
            }
        }

        /// Maximum dose for this pen type
        var maximumDose: Double {
            switch self {
            case .ozempicQuarterHalf:
                return 0.5
            case .ozempic1mg:
                return 1.0
            case .ozempic2mg:
                return 2.0
            case .wegovy025mg:
                return 0.25
            case .wegovy05mg:
                return 0.5
            case .wegovy1mg:
                return 1.0
            case .wegovy17mg:
                return 1.7
            case .wegovy24mg:
                return 2.4
            case .mounjaro25mg:
                return 2.5
            case .mounjaro5mg:
                return 5.0
            case .mounjaro75mg:
                return 7.5
            case .mounjaro10mg:
                return 10.0
            case .mounjaro125mg:
                return 12.5
            case .mounjaro15mg:
                return 15.0
            case .trulicity075mg:
                return 0.75
            case .trulicity15mg:
                return 1.5
            case .trulicity3mg:
                return 3.0
            case .trulicity45mg:
                return 4.5
            case .victoza:
                return 1.8
            case .saxenda:
                return 3.0
            }
        }

        /// Whether this pen supports click adjustments
        var isAdjustable: Bool {
            switch self {
            case .ozempicQuarterHalf, .ozempic1mg, .ozempic2mg, .victoza, .saxenda,
                 .mounjaro25mg, .mounjaro5mg, .mounjaro75mg, .mounjaro10mg,
                 .mounjaro125mg, .mounjaro15mg:
                return true
            case .wegovy025mg, .wegovy05mg, .wegovy1mg, .wegovy17mg, .wegovy24mg,
                 .trulicity075mg, .trulicity15mg, .trulicity3mg, .trulicity45mg:
                return false // Fixed-dose pens
            }
        }
    }

    /// Calculate pen clicks for a target dose
    /// - Parameters:
    ///   - penType: Type of pen being used
    ///   - targetDose: Desired dose in mg
    /// - Returns: PenClickResult with click instructions
    /// - Throws: PenClickError for invalid inputs
    static func calculate(
        penType: PenType,
        targetDose: Double) throws -> PenClickResult
    {
        // Validate dose
        guard targetDose > 0 else {
            throw PenClickError.invalidDose
        }

        guard targetDose <= penType.maximumDose else {
            throw PenClickError.doseExceedsMaximum
        }

        // Check if pen is adjustable
        guard penType.isAdjustable else {
            // Fixed-dose pen - no clicks needed
            return PenClickResult(
                clicks: 0,
                actualDose: penType.maximumDose,
                penType: penType.rawValue)
        }

        // Calculate clicks needed
        let clicksNeeded = targetDose / penType.dosePerClick
        let roundedClicks = Int(round(clicksNeeded))

        // Check if dose requires partial click
        let actualDose = Double(roundedClicks) * penType.dosePerClick
        let tolerance = penType.dosePerClick * 0.1 // 10% tolerance

        if abs(actualDose - targetDose) > tolerance {
            throw PenClickError.doseRequiresPartialClick
        }

        return PenClickResult(
            clicks: roundedClicks,
            actualDose: actualDose,
            penType: penType.rawValue)
    }

    /// Get available doses for a pen type
    /// - Parameter penType: Type of pen
    /// - Returns: Array of available doses in mg
    static func availableDoses(for penType: PenType) -> [Double] {
        guard penType.isAdjustable else {
            // Fixed-dose pen has only one dose
            return [penType.maximumDose]
        }

        var doses: [Double] = []
        let increment = penType.dosePerClick
        var currentDose = increment

        // Use small epsilon for floating point comparison
        let epsilon = 0.0001
        while currentDose <= penType.maximumDose + epsilon {
            doses.append(currentDose)
            currentDose += increment
        }

        return doses
    }

    /// Get pen types suitable for a medication
    /// - Parameter medication: The medication type
    /// - Returns: Array of compatible pen types
    static func pensForMedication(_ medication: Medication) -> [PenType] {
        switch medication {
        case .semaglutide:
            return [
                .ozempicQuarterHalf, .ozempic1mg, .ozempic2mg,
                .wegovy025mg, .wegovy05mg, .wegovy1mg, .wegovy17mg, .wegovy24mg,
            ]
        case .tirzepatide:
            return [
                .mounjaro25mg, .mounjaro5mg, .mounjaro75mg,
                .mounjaro10mg, .mounjaro125mg, .mounjaro15mg,
            ]
        case .liraglutide:
            return [.victoza, .saxenda]
        case .dulaglutide:
            return [.trulicity075mg, .trulicity15mg, .trulicity3mg, .trulicity45mg]
        }
    }
}
