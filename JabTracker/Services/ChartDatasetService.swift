//
//  ChartDatasetService.swift
//  JabTracker
//
//  Service for generating chart datasets from user medication data
//  Handles multiple profiles and provides safe error handling
//

import Foundation
import OSLog

/// Service responsible for generating chart datasets from user medication data
/// Provides safe handling of multiple profiles, invalid data filtering, and proper time range calculation
@Observable
class ChartDatasetService {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "JabTracker",
        category: "ChartDatasetService")

    private let chartDataProcessor: ChartDataProcessor

    init(chartDataProcessor: ChartDataProcessor = ChartDataProcessor()) {
        self.chartDataProcessor = chartDataProcessor
    }

    /// Generates chart dataset from user medication data
    /// Handles multiple profiles and provides safe error handling
    /// - Parameters:
    ///   - user: The user whose data to chart
    ///   - profiles: Medication profiles with pre-loaded doses
    ///   - timePeriod: Selected time period for the chart
    /// - Returns: Chart dataset configured for the selected time period
    func generateChartDataset(
        for user: User,
        profiles: [MedicationProfile],
        timePeriod: ChartDataProcessor.TimePeriod = .last30Days
    ) -> ConcentrationChartDataset? {
        let validProfiles = extractValidProfiles(from: profiles)
        guard !validProfiles.isEmpty else { return nil }

        let timeRange = calculateTimeRange(from: validProfiles)
        guard let timeRange = timeRange else { return nil }

        let (concentrationCurves, allMarkers) = processProfiles(validProfiles, timeRange: timeRange)

        guard !concentrationCurves.isEmpty, !allMarkers.isEmpty else {
            return nil
        }

        // Convert TimePeriod to TimeRange for chart configuration
        let chartTimeRange = convertToTimeRange(timePeriod)

        // Extract therapeutic window from first profile's medication
        let concentrationRange = extractTherapeuticRange(from: validProfiles)

        return ConcentrationChartDataset(
            concentrationCurves: concentrationCurves,
            doseMarkers: allMarkers,
            configuration: .default
                .withTimeRange(chartTimeRange)
                .withConcentrationRange(concentrationRange)
        )
    }

    /// Generates chart dataset from profiles with pre-filtered doses
    /// This method avoids SwiftData relationship mutation by accepting doses directly
    /// - Parameters:
    ///   - user: The user whose data to chart
    ///   - profilesWithDoses: Tuples of medication profiles paired with their filtered doses
    ///   - timePeriod: Selected time period for the chart
    /// - Returns: Chart dataset configured for the selected time period
    func generateChartDataset(
        for user: User,
        profilesWithDoses: [(MedicationProfile, [Dose])],
        timePeriod: ChartDataProcessor.TimePeriod = .last30Days
    ) -> ConcentrationChartDataset? {
        // Filter out profiles with no doses
        let validProfiles = profilesWithDoses.filter { !$0.1.isEmpty }
        guard !validProfiles.isEmpty else { return nil }

        let timeRange = calculateTimeRange(from: validProfiles)
        guard let timeRange = timeRange else { return nil }

        let (concentrationCurves, allMarkers) = processProfiles(validProfiles, timeRange: timeRange)

        guard !concentrationCurves.isEmpty, !allMarkers.isEmpty else {
            return nil
        }

        // Convert TimePeriod to TimeRange for chart configuration
        let chartTimeRange = convertToTimeRange(timePeriod)

        // Extract therapeutic window from first profile's medication
        let concentrationRange = extractTherapeuticRange(from: validProfiles)

        return ConcentrationChartDataset(
            concentrationCurves: concentrationCurves,
            doseMarkers: allMarkers,
            configuration: .default
                .withTimeRange(chartTimeRange)
                .withConcentrationRange(concentrationRange)
        )
    }

    /// Converts ChartDataProcessor.TimePeriod to TimeRange for chart configuration
    private func convertToTimeRange(_ timePeriod: ChartDataProcessor.TimePeriod) -> TimeRange {
        switch timePeriod {
        case .last7Days:
            return .lastWeek
        case .last30Days:
            return .lastMonth
        case .last90Days:
            return .lastQuarter
        case .lastYear:
            return .lastYear
        case .all:
            return .automatic
        }
    }

    /// Extracts therapeutic range from first medication profile for chart configuration
    /// - Parameter profiles: Array of medication profiles with doses
    /// - Returns: ConcentrationRange configured with therapeutic window, or .automatic if no medication found
    private func extractTherapeuticRange(from profiles: [(MedicationProfile, [Dose])]) -> ConcentrationRange {
        guard let firstProfile = profiles.first?.0,
            let medication = firstProfile.medication
        else {
            return .automatic
        }

        // Get therapeutic window values from medication
        let minConcentration = medication.therapeuticMinConcentration
        let maxConcentration = medication.therapeuticMaxConcentration
        // Optimal is midpoint of therapeutic range
        let optimalConcentration = (minConcentration + maxConcentration) / 2.0

        return .therapeuticWindow(
            min: minConcentration,
            max: maxConcentration,
            optimal: optimalConcentration
        )
    }

    // MARK: - Private Helper Methods

    /// Extract profiles that have valid doses
    private func extractValidProfiles(from profiles: [MedicationProfile]) -> [(MedicationProfile, [Dose])] {
        profiles.compactMap { profile -> (MedicationProfile, [Dose])? in
            guard let doses = profile.doses, !doses.isEmpty else {
                return nil
            }
            return (profile, doses)
        }
    }

    /// Calculate overall time range from all profile doses
    private func calculateTimeRange(from validProfiles: [(MedicationProfile, [Dose])]) -> ClosedRange<Date>? {
        let allDoses = validProfiles.flatMap { $0.1 }
        guard let minDate = allDoses.map(\.timestamp).min(),
            let maxDate = allDoses.map(\.timestamp).max()
        else {
            return nil
        }
        return minDate...max(maxDate, Date())
    }

    /// Process all profiles to generate concentration curves and dose markers
    private func processProfiles(
        _ validProfiles: [(MedicationProfile, [Dose])],
        timeRange: ClosedRange<Date>
    ) -> ([ConcentrationCurve], [AdvancedDoseMarker]) {
        Self.logger.debug("🔧 processProfiles() called with \(validProfiles.count, privacy: .public) profiles")
        var concentrationCurves: [ConcentrationCurve] = []
        var allMarkers: [AdvancedDoseMarker] = []

        for (profile, doses) in validProfiles {
            Self.logger.debug(
                """
                  🔍 Processing '\(profile.genericName, privacy: .public)': tuple=\(doses.count, privacy: .public), \
                relationship=\(profile.doses?.count ?? 0, privacy: .public)
                """
            )

            let validMarkers = createValidDoseMarkers(from: doses)
            allMarkers.append(contentsOf: validMarkers)
            Self.logger.debug(
                "  ✅ Created \(validMarkers.count, privacy: .public) markers from \(doses.count, privacy: .public)"
            )

            // Use doses from tuple instead of profile.doses relationship
            if let curve = createConcentrationCurve(for: profile, doses: doses, timeRange: timeRange) {
                concentrationCurves.append(curve)
                Self.logger.debug("  ✅ Generated curve with \(curve.points.count, privacy: .public) points")
            } else {
                Self.logger.warning("  ⚠️  Failed to generate curve for '\(profile.genericName, privacy: .public)'")
            }
        }

        Self.logger.info(
            "✅ Processed \(concentrationCurves.count, privacy: .public) curves, \(allMarkers.count, privacy: .public)"
        )
        return (concentrationCurves, allMarkers)
    }

    /// Create valid dose markers with error handling
    private func createValidDoseMarkers(from doses: [Dose]) -> [AdvancedDoseMarker] {
        doses.compactMap { dose -> AdvancedDoseMarker? in
            guard dose.amount >= 0, dose.amount.isFinite else {
                return nil
            }
            return AdvancedDoseMarker(from: dose)
        }
    }

    /// Create concentration curve for a profile with safe error handling
    private func createConcentrationCurve(
        for profile: MedicationProfile,
        doses: [Dose],
        timeRange: ClosedRange<Date>
    ) -> ConcentrationCurve? {
        let concentrationPoints = chartDataProcessor.generateConcentrationTimeline(
            for: profile,
            doses: doses,  // Use explicit doses instead of profile.doses
            timeRange: timeRange
        )

        let validPoints = concentrationPoints.compactMap { point -> AdvancedConcentrationPoint? in
            guard point.concentration >= 0, point.concentration.isFinite else {
                return nil
            }
            return AdvancedConcentrationPoint(from: point)
        }

        guard !validPoints.isEmpty else {
            return nil
        }

        return ConcentrationCurve(
            points: validPoints,
            medication: profile.genericName
        )
    }
}
