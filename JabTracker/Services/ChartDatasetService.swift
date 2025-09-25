//
//  ChartDatasetService.swift
//  JabTracker
//
//  Service for generating chart datasets from user medication data
//  Handles multiple profiles and provides safe error handling
//

import Foundation

/// Service responsible for generating chart datasets from user medication data
/// Provides safe handling of multiple profiles, invalid data filtering, and proper time range calculation
@Observable
class ChartDatasetService {

    private let chartDataProcessor: ChartDataProcessor

    init(chartDataProcessor: ChartDataProcessor = ChartDataProcessor()) {
        self.chartDataProcessor = chartDataProcessor
    }

    /// Generates chart dataset from user medication data
    /// Handles multiple profiles and provides safe error handling
    func generateChartDataset(for user: User, profiles: [MedicationProfile])
        -> ConcentrationChartDataset?
    {
        let validProfiles = extractValidProfiles(from: profiles)
        guard !validProfiles.isEmpty else { return nil }

        let timeRange = calculateTimeRange(from: validProfiles)
        guard let timeRange = timeRange else { return nil }

        let (concentrationCurves, allMarkers) = processProfiles(validProfiles, timeRange: timeRange)

        guard !concentrationCurves.isEmpty, !allMarkers.isEmpty else {
            return nil
        }

        return ConcentrationChartDataset(
            concentrationCurves: concentrationCurves,
            doseMarkers: allMarkers,
            configuration: .default
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
        var concentrationCurves: [ConcentrationCurve] = []
        var allMarkers: [AdvancedDoseMarker] = []

        for (profile, doses) in validProfiles {
            let validMarkers = createValidDoseMarkers(from: doses)
            allMarkers.append(contentsOf: validMarkers)

            if let curve = createConcentrationCurve(for: profile, timeRange: timeRange) {
                concentrationCurves.append(curve)
            }
        }

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
        timeRange: ClosedRange<Date>
    ) -> ConcentrationCurve? {
        let concentrationPoints = chartDataProcessor.generateConcentrationTimeline(
            for: profile,
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
