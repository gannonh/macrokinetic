//
//  AdherenceSection.swift
//  JabTracker
//
//  Adherence section component extracted from ShotsView.
//  Displays adherence metrics, streaks, and patterns.
//

import SwiftData
import SwiftUI

/// Section component for displaying medication adherence data
/// Handles two states: adherence cards display and no data
struct AdherenceSection: View {

    // MARK: - Properties

    /// Current user (nil triggers no data state)
    let user: User?

    /// User's medication profiles (empty triggers no data state)
    let medicationProfiles: [MedicationProfile]

    /// ViewModel for analytics data generation
    let viewModel: AnalyticsViewModel

    /// Model context for data operations
    let modelContext: ModelContext

    /// Analytics service for adherence calculations
    let analyticsService: AnalyticsService

    // MARK: - Body

    var body: some View {
        Group {
            if let user = user, !medicationProfiles.isEmpty {
                // Compute adherence once to avoid redundant calculations
                let adherence = adherenceRate(for: user)

                VStack(spacing: 16) {
                    AdherenceMetricsCard(adherenceRate: adherence)
                        .accessibilityIdentifier("adherence-metrics-card")

                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Dose Streaks")
                                .font(DesignTokens.Typography.headline)
                                .foregroundColor(.primary)

                            StreakCounterView(
                                currentStreak: user.currentStreak,
                                bestStreak: user.longestStreak
                            )
                        }
                    }
                    .accessibilityIdentifier("streak-counters-card")

                    AdherenceProgressIndicator(
                        currentAdherence: adherence,
                        targetAdherence: 0.8,
                        periodLabel: "This month"
                    )

                    AdherenceTrendChart(
                        trendData: viewModel.generateTrendData(
                            for: user,
                            profiles: medicationProfiles,
                            context: modelContext
                        ),
                        timePeriod: .weekly
                    )

                    MissedDosePatternView(
                        missedDoses: viewModel.generateMissedDosePatterns(
                            for: user,
                            profiles: medicationProfiles,
                            context: modelContext
                        ),
                        style: .calendar
                    )
                }
            } else {
                noDataSection
            }
        }
        .accessibilityIdentifier("adherence-section")
    }

    // MARK: - Helpers

    /// Calculates the overall adherence rate for the user
    private func adherenceRate(for user: User) -> Double {
        analyticsService.calculateOverallAdherence(user: user, context: modelContext)
    }

    // MARK: - Empty States

    /// View displayed when no adherence data is available
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
        .accessibilityIdentifier("adherence-no-data")
    }
}

// MARK: - Preview

#Preview("No Data State") {
    AdherenceSectionPreviewContainer(showData: false)
}

#Preview("With Adherence Data") {
    AdherenceSectionPreviewContainer(showData: true)
}

/// Container view for AdherenceSection previews that provides SwiftData context
private struct AdherenceSectionPreviewContainer: View {
    let showData: Bool

    var body: some View {
        AdherenceSectionPreviewContent(showData: showData)
            .modelContainer(for: [User.self, MedicationProfile.self, Dose.self], inMemory: true)
    }
}

private struct AdherenceSectionPreviewContent: View {
    let showData: Bool
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if showData {
            let user = User(name: "Test User")
            let profile = MedicationProfile(genericName: "semaglutide")

            AdherenceSection(
                user: user,
                medicationProfiles: [profile],
                viewModel: AnalyticsViewModel(),
                modelContext: modelContext,
                analyticsService: AnalyticsService()
            )
            .padding()
        } else {
            AdherenceSection(
                user: nil,
                medicationProfiles: [],
                viewModel: AnalyticsViewModel(),
                modelContext: modelContext,
                analyticsService: AnalyticsService()
            )
            .padding()
        }
    }
}
