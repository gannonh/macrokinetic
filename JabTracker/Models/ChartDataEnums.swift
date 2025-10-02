//
//  ChartDataEnums.swift
//  JabTracker
//

import Foundation
import SwiftUI

/// Visual styles for dose markers in Swift Charts
enum DoseMarkerStyle: String, CaseIterable, Codable {
    case standard
    case emphasized
    case skipped
    case withSite
    case firstDose
    case milestone

    var color: Color {
        switch self {
        case .standard: return .blue
        case .emphasized: return .green
        case .skipped: return .gray
        case .withSite: return .purple
        case .firstDose: return .orange
        case .milestone: return .red
        }
    }

    var size: CGFloat {
        switch self {
        case .standard: return 8
        case .emphasized: return 12
        case .skipped: return 6
        case .withSite: return 10
        case .firstDose: return 14
        case .milestone: return 16
        }
    }

    var symbol: String {
        switch self {
        case .standard: return "circle.fill"
        case .emphasized: return "star.fill"
        case .skipped: return "xmark.circle"
        case .withSite: return "mappin.circle.fill"
        case .firstDose: return "1.circle.fill"
        case .milestone: return "flag.fill"
        }
    }
}

/// Alert levels for dose markers to indicate timing or adherence issues
enum DoseAlertLevel: String, CaseIterable, Codable {
    case normal
    case info
    case warning
    case critical

    var color: Color {
        switch self {
        case .normal: return .primary
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }

    var opacity: Double {
        switch self {
        case .normal: return 1.0
        case .info: return 0.8
        case .warning: return 0.9
        case .critical: return 1.0
        }
    }
}

/// Adherence status classifications for dose timing analysis
enum AdherenceStatus: String, CaseIterable, Codable {
    case early
    case onTime
    case late
    case missed

    var displayName: String {
        switch self {
        case .early: return "Early"
        case .onTime: return "On Time"
        case .late: return "Late"
        case .missed: return "Missed"
        }
    }

    var color: Color {
        switch self {
        case .early: return .blue
        case .onTime: return .green
        case .late: return .orange
        case .missed: return .red
        }
    }
}

/// Timing accuracy levels for dose administration precision
enum TimingAccuracy: String, CaseIterable, Codable {
    case exact
    case approximate
    case estimated
    case unknown

    var displayName: String {
        switch self {
        case .exact: return "Exact"
        case .approximate: return "Approximate"
        case .estimated: return "Estimated"
        case .unknown: return "Unknown"
        }
    }
}
