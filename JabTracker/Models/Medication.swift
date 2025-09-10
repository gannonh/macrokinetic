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
        switch (self, brand) {
        // Semaglutide - brand-specific pen doses
        case (.semaglutide, "Ozempic"):
            return [0.25, 0.5, 1.0, 2.0] // Multi-dose adjustable pens
        case (.semaglutide, "Wegovy"):
            return [0.25, 0.5, 1.0, 1.7, 2.4] // Single-dose fixed pens
        case (.semaglutide, "Generic"):
            return [0.25, 0.5, 1.0, 1.5, 2.0, 2.5] // Compounded - flexible dosing
        // Tirzepatide - all fixed-dose pens
        case (.tirzepatide, "Mounjaro"):
            return [2.5, 5.0, 7.5, 10.0, 12.5, 15.0] // Fixed-dose single-use pens
        case (.tirzepatide, "Zepbound"):
            return [2.5, 5.0, 7.5, 10.0, 12.5, 15.0] // Fixed-dose single-use pens
        case (.tirzepatide, "Generic"):
            return [2.5, 5.0, 7.5, 10.0, 12.5, 15.0] // Compounded - match clinical doses
        // Liraglutide - dial-based dose selection
        case (.liraglutide, "Victoza"):
            return [0.6, 1.2, 1.8] // Dial-selected doses
        case (.liraglutide, "Saxenda"):
            return [0.6, 1.2, 1.8, 2.4, 3.0] // Extended dial-selected doses
        case (.liraglutide, "Generic"):
            return [0.6, 1.2, 1.8, 2.4, 3.0] // Compounded - full range
        // Dulaglutide - all fixed-dose auto-injectors
        case (.dulaglutide, "Trulicity"):
            return [0.75, 1.5, 3.0, 4.5] // Fixed-dose auto-injectors
        case (.dulaglutide, "Generic"):
            return [0.75, 1.5, 3.0, 4.5] // Compounded - match clinical doses
        // Fallback for unknown brands - use medication defaults
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
}
