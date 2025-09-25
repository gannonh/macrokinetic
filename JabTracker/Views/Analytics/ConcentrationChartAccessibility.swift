//
//  ConcentrationChartAccessibility.swift
//  JabTracker
//

import Foundation

/// Utility class providing accessibility support for concentration timeline charts
/// Handles VoiceOver descriptions, trend analysis, and accessibility formatting
struct ConcentrationChartAccessibility {

    /// Provides accessibility value describing current chart data
    /// - Parameters:
    ///   - points: Processed concentration points for current time range
    ///   - markers: Processed dose markers for current time range
    ///   - timeRange: Current time range being displayed
    ///   - zoomLevel: Current zoom level of the chart
    /// - Returns: Descriptive string for VoiceOver describing chart contents
    static func accessibilityValue(
        for points: [AdvancedConcentrationPoint],
        markers: [AdvancedDoseMarker],
        timeRange: TimeRange,
        zoomLevel: Double
    ) -> String {
        let pointCount = points.count
        let markerCount = markers.count
        let timeRangeDisplay = timeRange.displayName
        let zoomInfo = zoomLevel != 1.0 ? ", zoomed to \(Int(zoomLevel * 100))%" : ""

        return "Chart contains \(pointCount) concentration points and \(markerCount) dose markers for "
            + "\(timeRangeDisplay)\(zoomInfo)"
    }

    /// Provides detailed accessibility description for VoiceOver users
    /// - Parameter points: Current concentration points to analyze
    /// - Returns: Accessibility hint with current level and interaction instructions
    static func accessibilityHint(for points: [AdvancedConcentrationPoint]) -> String {
        if points.isEmpty {
            return "No concentration data available. Start tracking doses to see your medication timeline."
        }

        let latestPoint = points.max(by: { $0.date < $1.date })
        let currentLevel = latestPoint?.concentration ?? 0.0
        let levelDescription = formatConcentrationForAccessibility(currentLevel)

        return "Current concentration level: \(levelDescription). Use pinch to zoom, drag to pan, "
            + "or double tap to reset view."
    }

    /// Provides spoken description of chart trend for VoiceOver
    /// - Parameter points: Concentration points to analyze for trend
    /// - Returns: Trend description suitable for VoiceOver announcement
    static func trendDescription(for points: [AdvancedConcentrationPoint]) -> String {
        guard points.count >= 2 else {
            return "Insufficient data for trend analysis"
        }

        let sortedPoints = points.sorted { $0.date < $1.date }
        let firstHalf = sortedPoints.prefix(sortedPoints.count / 2)
        let secondHalf = sortedPoints.suffix(sortedPoints.count / 2)

        let firstAverage = firstHalf.map(\.concentration).reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.map(\.concentration).reduce(0, +) / Double(secondHalf.count)

        let difference = secondAverage - firstAverage
        let percentChange = abs(difference / firstAverage) * 100

        if abs(difference) < 0.1 {
            return "Concentration levels are stable"
        } else if difference > 0 {
            return "Concentration levels are increasing by \(Int(percentChange))%"
        } else {
            return "Concentration levels are decreasing by \(Int(percentChange))%"
        }
    }

    /// Formats concentration value for accessibility with descriptive text
    /// - Parameter concentration: Concentration value to format
    /// - Returns: Human-readable description of concentration level
    static func formatConcentrationForAccessibility(_ concentration: Double) -> String {
        let formattedValue = String(format: "%.1f", concentration)
        let level: String

        switch concentration {
        case 0...1:
            level = "low"
        case 1...3:
            level = "moderate"
        case 3...5:
            level = "high"
        default:
            level = "very high"
        }

        return "\(formattedValue) units, \(level) level"
    }

    /// Formats dose amount for accessibility
    /// - Parameter amount: Dose amount to format
    /// - Returns: Formatted dose amount with units
    static func formatDoseAmount(_ amount: Double) -> String {
        String(format: "%.1f mg", amount)
    }
}
