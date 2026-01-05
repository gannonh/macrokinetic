//
//  ConcentrationSection.swift
//  JabTracker
//
//  Concentration section component extracted from ShotsView.
//  Displays concentration timeline chart with loading and empty states.
//

import SwiftUI

/// Section component for displaying medication concentration data
/// Handles three states: chart display, loading, and no data
struct ConcentrationSection: View {

    // MARK: - Properties

    /// Current user (nil triggers no data state)
    let user: User?

    /// User's medication profiles (empty triggers no data state)
    let medicationProfiles: [MedicationProfile]

    /// ViewModel containing chart dataset
    let viewModel: AnalyticsViewModel

    /// Whether data is currently loading
    let isLoadingData: Bool

    // MARK: - Body

    var body: some View {
        Group {
            if user != nil, !medicationProfiles.isEmpty {
                if let dataset = viewModel.chartDataset {
                    ConcentrationTimelineChart(dataset: dataset)
                } else if isLoadingData {
                    chartLoadingView()
                } else {
                    noDataSection
                }
            } else {
                noDataSection
            }
        }
        .accessibilityIdentifier("concentration-section")
    }

    // MARK: - Empty States

    /// View displayed when no concentration data is available
    private var noDataSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Data Yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Start tracking doses to see your analytics")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .cardStyle(cornerRadius: 12)
        .accessibilityIdentifier("concentration-no-data")
    }

    /// View displayed while chart data is being generated
    @ViewBuilder
    private func chartLoadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Generating Concentration Chart...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .cardStyle(cornerRadius: 12)
        .accessibilityIdentifier("chart-loading")
    }
}

// MARK: - Preview

#Preview("With Chart Data") {
    let samplePoints = [
        AdvancedConcentrationPoint(date: Date().addingTimeInterval(-24 * 3600), concentration: 0.0),
        AdvancedConcentrationPoint(date: Date().addingTimeInterval(-12 * 3600), concentration: 5.2),
        AdvancedConcentrationPoint(date: Date(), concentration: 2.1),
    ]

    let sampleMarkers = [
        AdvancedDoseMarker(
            date: Date().addingTimeInterval(-24 * 3600),
            amount: 1.0,
            markerStyle: .firstDose
        )
    ]

    let sampleCurve = ConcentrationCurve(
        points: samplePoints,
        medication: "semaglutide"
    )

    let sampleDataset = ConcentrationChartDataset(
        concentrationCurves: [sampleCurve],
        doseMarkers: sampleMarkers,
        configuration: .default
    )

    let viewModel = AnalyticsViewModel()
    viewModel.chartDataset = sampleDataset

    return ConcentrationSection(
        user: User(name: "Test User"),
        medicationProfiles: [MedicationProfile(genericName: "semaglutide")],
        viewModel: viewModel,
        isLoadingData: false
    )
    .padding()
}

#Preview("Loading State") {
    ConcentrationSection(
        user: User(name: "Test User"),
        medicationProfiles: [MedicationProfile(genericName: "semaglutide")],
        viewModel: AnalyticsViewModel(),
        isLoadingData: true
    )
    .padding()
}

#Preview("No Data State") {
    ConcentrationSection(
        user: nil,
        medicationProfiles: [],
        viewModel: AnalyticsViewModel(),
        isLoadingData: false
    )
    .padding()
}
