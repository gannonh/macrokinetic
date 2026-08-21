import Foundation

enum DoseFrequency: String, CaseIterable, Codable {
    case daily
    case weekly

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}

struct MedicationNames {
    let genericName: String?
    let brandName: String?

    var singleLabel: String? {
        let brandName = self.normalized(self.brandName)
        if let brandName,
           brandName.caseInsensitiveCompare("Generic") != .orderedSame
        {
            return brandName
        }

        guard let genericName = self.normalized(self.genericName) else {
            return nil
        }

        return Medication.fromGenericName(genericName)?.displayName ?? genericName
    }

    private func normalized(_ name: String?) -> String? {
        guard let name else { return nil }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? nil : trimmedName
    }
}

enum Medication: String, CaseIterable, Codable, Identifiable {
    case semaglutide
    case tirzepatide
    case liraglutide
    case dulaglutide

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .semaglutide: return "Semaglutide"
        case .tirzepatide: return "Tirzepatide"
        case .liraglutide: return "Liraglutide"
        case .dulaglutide: return "Dulaglutide"
        }
    }

    var brands: [String] {
        switch self {
        case .semaglutide: return ["Ozempic", "Wegovy", "Rybelsus (oral)", "Generic"]
        case .tirzepatide: return ["Mounjaro", "Zepbound", "Generic"]
        case .liraglutide: return ["Victoza", "Saxenda", "Generic"]
        case .dulaglutide: return ["Trulicity", "Generic"]
        }
    }

    var halfLifeDays: Double {
        switch self {
        case .semaglutide: return 7.0
        case .tirzepatide: return 5.0
        case .liraglutide: return 0.54
        case .dulaglutide: return 4.7
        }
    }

    /// Get available doses for a specific brand of this medication
    /// Based on FDA-approved pen specifications and clinical documentation
    func availableDoses(for brand: String) -> [Double] {
        switch self {
        case .semaglutide:
            return self.semaglutideDoses(for: brand)
        case .tirzepatide:
            return self.tirzepatideDoses(for: brand)
        case .liraglutide:
            return self.liraglutideDoses(for: brand)
        case .dulaglutide:
            return self.dulaglutideDoses(for: brand)
        }
    }

    private func semaglutideDoses(for brand: String) -> [Double] {
        switch brand {
        case "Ozempic":
            return [0.25, 0.5, 1.0, 2.0]  // Multi-dose adjustable pens
        case "Wegovy":
            return [0.25, 0.5, 1.0, 1.7, 2.4]  // Single-dose fixed pens
        case "Generic":
            return [0.25, 0.5, 1.0, 1.5, 2.0, 2.5]  // Compounded - flexible dosing
        default:
            return self.defaultAvailableDoses
        }
    }

    private func tirzepatideDoses(for brand: String) -> [Double] {
        switch brand {
        case "Mounjaro", "Zepbound":
            return [2.5, 5.0, 7.5, 10.0, 12.5, 15.0]  // Fixed-dose single-use pens
        case "Generic":
            return [2.5, 5.0, 7.5, 10.0, 12.5, 15.0]  // Compounded - match clinical doses
        default:
            return self.defaultAvailableDoses
        }
    }

    private func liraglutideDoses(for brand: String) -> [Double] {
        switch brand {
        case "Victoza":
            return [0.6, 1.2, 1.8]  // Dial-selected doses
        case "Saxenda":
            return [0.6, 1.2, 1.8, 2.4, 3.0]  // Extended dial-selected doses
        case "Generic":
            return [0.6, 1.2, 1.8, 2.4, 3.0]  // Compounded - full range
        default:
            return self.defaultAvailableDoses
        }
    }

    private func dulaglutideDoses(for brand: String) -> [Double] {
        switch brand {
        case "Trulicity":
            return [0.75, 1.5, 3.0, 4.5]  // Fixed-dose auto-injectors
        case "Generic":
            return [0.75, 1.5, 3.0, 4.5]  // Compounded - match clinical doses
        default:
            return self.defaultAvailableDoses
        }
    }

    /// Default available doses when brand is not specified (for onboarding/general use)
    var availableDoses: [Double] {
        switch self {
        case .semaglutide: return [0.25, 0.5, 1.0, 1.7, 2.0, 2.4]
        case .tirzepatide: return [2.5, 5.0, 7.5, 10.0, 12.5, 15.0]
        case .liraglutide: return [0.6, 1.2, 1.8, 2.4, 3.0]
        case .dulaglutide: return [0.75, 1.5, 3.0, 4.5]
        }
    }

    /// Default available doses when brand is not specified
    private var defaultAvailableDoses: [Double] {
        self.availableDoses
    }

    var frequency: DoseFrequency {
        switch self {
        case .liraglutide: return .daily
        default: return .weekly
        }
    }

    var unit: String {
        "mg"
    }

    var description: String {
        switch self {
        case .semaglutide:
            return "A weekly GLP-1 receptor agonist that helps regulate blood sugar and weight."
        case .tirzepatide:
            return "A dual GIP/GLP-1 receptor agonist taken weekly for diabetes and weight management."
        case .liraglutide:
            return "A daily GLP-1 receptor agonist for blood sugar control and weight loss."
        case .dulaglutide:
            return "A weekly GLP-1 receptor agonist for type 2 diabetes management."
        }
    }

    var colorHex: String {
        switch self {
        case .semaglutide: return "667eea"
        case .tirzepatide: return "764ba2"
        case .liraglutide: return "4c5fbf"
        case .dulaglutide: return "8b9ff4"
        }
    }

    /// Helper method to create Medication from generic name string (case insensitive)
    static func fromGenericName(_ name: String) -> Medication? {
        let lowercaseName = name.lowercased()
        return Medication.allCases.first { $0.rawValue.lowercased() == lowercaseName }
    }
}

// MARK: - Analytics Properties

extension Medication {
    /// Therapeutic concentration range for effectiveness calculations
    var therapeuticMinConcentration: Double {
        switch self {
        case .semaglutide: return 0.5  // ng/mL
        case .tirzepatide: return 1.0  // ng/mL
        case .liraglutide: return 2.0  // ng/mL
        case .dulaglutide: return 0.8  // ng/mL
        }
    }

    var therapeuticMaxConcentration: Double {
        switch self {
        case .semaglutide: return 15.0  // ng/mL
        case .tirzepatide: return 25.0  // ng/mL
        case .liraglutide: return 12.0  // ng/mL
        case .dulaglutide: return 18.0  // ng/mL
        }
    }

    /// Therapeutic window as a range for chart visualization
    var therapeuticWindow: ClosedRange<Double> {
        self.therapeuticMinConcentration...self.therapeuticMaxConcentration
    }

    /// Base effectiveness score (0.0 to 1.0) representing medication's inherent efficacy
    var baseEffectivenessScore: Double {
        switch self {
        case .semaglutide: return 0.85  // High efficacy
        case .tirzepatide: return 0.90  // Highest efficacy (dual agonist)
        case .liraglutide: return 0.75  // Moderate efficacy
        case .dulaglutide: return 0.80  // Good efficacy
        }
    }

    /// Factors that influence effectiveness for this medication
    var effectivenessFactors: [String] {
        switch self {
        case .semaglutide:
            return ["adherence", "timing", "dose_escalation", "injection_site_rotation"]
        case .tirzepatide:
            return [
                "adherence", "timing", "dose_escalation", "injection_site_rotation",
                "dual_receptor_activity",
            ]
        case .liraglutide:
            return ["adherence", "timing", "injection_site_rotation", "daily_consistency"]
        case .dulaglutide:
            return ["adherence", "timing", "dose_escalation", "injection_site_rotation"]
        }
    }

    /// Calculate effectiveness score based on current concentration
    /// - Parameter concentration: Current medication concentration
    /// - Returns: Effectiveness score from 0.0 to 1.0
    func calculateEffectiveness(concentration: Double) -> Double {
        guard concentration > 0 else { return 0.0 }

        let windowRange = self.therapeuticWindow
        let normalizedConcentration: Double

        if concentration < windowRange.lowerBound {
            // Below therapeutic range - linear scale from 0 to baseEffectivenessScore
            normalizedConcentration = concentration / windowRange.lowerBound
            return normalizedConcentration * self.baseEffectivenessScore * 0.5  // Reduced effectiveness below range
        } else if concentration > windowRange.upperBound {
            // Above therapeutic range - diminishing returns/side effects
            let excessFactor = (concentration - windowRange.upperBound) / windowRange.upperBound
            let penalty = min(excessFactor * 0.3, 0.6)  // Max 60% penalty for very high concentrations
            return max(self.baseEffectivenessScore * (1.0 - penalty), 0.1)
        } else {
            // Within therapeutic range - optimal effectiveness
            return self.baseEffectivenessScore
        }
    }

    /// Time to onset of therapeutic effect (hours)
    var onsetTimeHours: Double {
        switch self {
        case .semaglutide: return 2.0  // Effects begin within hours
        case .tirzepatide: return 4.0  // Slightly slower onset due to dual mechanism
        case .liraglutide: return 1.0  // Faster onset, daily dosing
        case .dulaglutide: return 8.0  // Slower onset, longer acting
        }
    }

    /// Duration of effective therapeutic action (hours)
    var effectiveDurationHours: Double {
        switch self {
        case .semaglutide: return 168.0  // 7 days
        case .tirzepatide: return 120.0  // 5 days
        case .liraglutide: return 24.0  // 1 day
        case .dulaglutide: return 168.0  // 7 days
        }
    }

    /// Returns available schedule patterns for this medication based on frequency
    ///
    /// Schedule pattern availability is determined by the medication's dosing frequency:
    /// - Daily medications (e.g., Liraglutide): Only support `.daily` pattern
    /// - Weekly medications (e.g., Semaglutide, Tirzepatide): Support `.weekly` and `.splitDose` patterns
    ///
    /// - Returns: Array of available `SchedulePatternType` values for this medication
    ///
    /// - Note: Custom patterns are intentionally excluded as they are not supported in the current implementation
    func availableSchedulePatterns() -> [SchedulePatternType] {
        switch frequency {
        case .daily:
            return [.daily]  // Daily medications use daily dosing pattern
        case .weekly:
            return [.weekly, .splitDose]  // Weekly medications support twice-weekly split dosing
        }
    }
}
