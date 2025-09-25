//
//  AdherenceTrendData.swift
//  JabTracker
//
//  Data models for adherence trend visualization and missed dose pattern analysis.
//

import Foundation

// MARK: - Adherence Trend Models

/// Represents a single point in an adherence trend chart
struct AdherenceTrendPoint {
    /// Date for this trend point
    let date: Date

    /// Adherence rate for this period (0.0 to 1.0)
    let adherenceRate: Double

    /// Human-readable period label (e.g., "Week 1", "Month 1")
    let period: String
}

/// Enum for chart time period settings
enum ChartTimePeriod: CaseIterable {
    case weekly
    case monthly
    case quarterly

    var displayName: String {
        switch self {
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .quarterly:
            return "Quarterly"
        }
    }
}

/// Enum for trend direction analysis
enum TrendDirection: CaseIterable {
    case improving
    case declining
    case stable

    var displayName: String {
        switch self {
        case .improving:
            return "Improving"
        case .declining:
            return "Declining"
        case .stable:
            return "Stable"
        }
    }

    var systemImageName: String {
        switch self {
        case .improving:
            return "arrow.up.circle.fill"
        case .declining:
            return "arrow.down.circle.fill"
        case .stable:
            return "minus.circle.fill"
        }
    }
}

// MARK: - Missed Dose Pattern Models

/// Represents missed dose patterns for visualization
struct MissedDosePattern {
    /// Date of the missed dose occurrence
    let date: Date

    /// Day of the week when doses were missed
    let dayOfWeek: String

    /// Number of missed doses for this day/period
    let missedCount: Int
}

/// Enum for missed dose visualization styles
enum MissedDoseVisualizationStyle: CaseIterable {
    case heatmap
    case barChart
    case calendar

    var displayName: String {
        switch self {
        case .heatmap:
            return "Heat Map"
        case .barChart:
            return "Bar Chart"
        case .calendar:
            return "Calendar View"
        }
    }
}

// MARK: - Helper Extensions

extension AdherenceTrendPoint: Equatable {
    static func == (lhs: AdherenceTrendPoint, rhs: AdherenceTrendPoint) -> Bool {
        lhs.date == rhs.date && lhs.adherenceRate == rhs.adherenceRate && lhs.period == rhs.period
    }
}

extension MissedDosePattern: Equatable {
    static func == (lhs: MissedDosePattern, rhs: MissedDosePattern) -> Bool {
        lhs.date == rhs.date && lhs.dayOfWeek == rhs.dayOfWeek && lhs.missedCount == rhs.missedCount
    }
}

extension AdherenceTrendPoint: Identifiable {
    var id: Date { date }
}

extension MissedDosePattern: Identifiable {
    var id: Date { date }
}
