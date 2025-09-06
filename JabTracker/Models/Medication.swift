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

    var availableDoses: [Double] {
        switch self {
        case .semaglutide: return [0.25, 0.5, 1.0, 1.7, 2.0, 2.4]
        case .tirzepatide: return [2.5, 5.0, 7.5, 10.0, 12.5, 15.0]
        case .liraglutide: return [0.6, 1.2, 1.8, 2.4, 3.0]
        case .dulaglutide: return [0.75, 1.5, 3.0, 4.5]
        }
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
