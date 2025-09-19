//
//  ConcentrationCard.swift
//  JabTracker
//
//  UI component for displaying current drug concentration and pharmacokinetic data
//  Shows current level, peak/trough timing, and steady-state progress
//

import SwiftUI

/// Main card component for displaying concentration information on the dashboard
/// Enhanced with real-time updates when dose data changes
struct ConcentrationCard: View {
    let user: User
    let medicationProfile: MedicationProfile
    let pkEngine: PharmacokineticsEngine

    // Optional dose service for real-time updates
    let doseService: DoseService?

    @State private var currentConcentration: Double = 0.0
    @State private var peakLevel: (level: Double, time: Date)?
    @State private var troughLevel: (level: Double, time: Date)?
    @State private var steadyStateProgress: Double = 0.0

    // MARK: - Initialization

    init(
        user: User,
        medicationProfile: MedicationProfile,
        pkEngine: PharmacokineticsEngine,
        doseService: DoseService? = nil
    ) {
        self.user = user
        self.medicationProfile = medicationProfile
        self.pkEngine = pkEngine
        self.doseService = doseService
    }

    var body: some View {
        DesignCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header with medication name
                headerView

                // Current concentration display
                currentConcentrationView

                // Peak and trough levels
                peakTroughView

                // Steady state progress
                steadyStateView
            }
        }
        .accessibilityIdentifier("concentration-card")
        .onAppear {
            updateConcentrationData()
        }
        .onChange(of: medicationProfile.doses) { _, _ in
            updateConcentrationData()
        }
        .onChange(of: doseService?.lastDoseUpdateTime) { _, _ in
            updateConcentrationData()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Drug Concentration")
                    .font(DesignTokens.Typography.headline)
                    .accessibilityIdentifier("concentration-card-title")

                if let medication = medicationProfile.medication {
                    Text(medication.displayName)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("concentration-card-medication")
                }
            }

            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(DesignTokens.Colors.primary)
                .font(.title2)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Current Concentration View

    private var currentConcentrationView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Level")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("current-level-label")

            ConcentrationDisplay(
                concentration: currentConcentration,
                isCurrentLevel: true
            )
            .accessibilityIdentifier("current-concentration-value")

            if currentConcentration == 0.0 {
                Text("No recent doses recorded")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .accessibilityIdentifier("no-doses-message")
            }
        }
    }

    // MARK: - Peak and Trough View

    private var peakTroughView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let peak = peakLevel {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Peak")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        ConcentrationDisplay(
                            concentration: peak.level,
                            isCurrentLevel: false
                        )

                        Spacer()

                        Text(timeDisplayText(for: peak.time))
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityIdentifier("peak-level-section")
            }

            if let trough = troughLevel {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Trough")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        ConcentrationDisplay(
                            concentration: trough.level,
                            isCurrentLevel: false
                        )

                        Spacer()

                        Text(timeDisplayText(for: trough.time))
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityIdentifier("trough-level-section")
            }
        }
    }

    // MARK: - Steady State View

    private var steadyStateView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Steady State Progress")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(Int(steadyStateProgress * 100))%")
                    .font(DesignTokens.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(steadyStateProgress >= 0.95 ? DesignTokens.Colors.success : .primary)
            }
            .accessibilityIdentifier("steady-state-header")

            ProgressView(value: steadyStateProgress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(steadyStateProgress >= 0.95 ? DesignTokens.Colors.success : DesignTokens.Colors.primary)
                .accessibilityIdentifier("steady-state-progress")
                .accessibilityValue("\(Int(steadyStateProgress * 100)) percent")

            if steadyStateProgress < 0.95 {
                Text("Steady state typically reached after 4-5 weeks of consistent dosing")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("steady-state-explanation")
            } else {
                Text("Steady state achieved")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.success)
                    .accessibilityIdentifier("steady-state-achieved")
            }
        }
    }

    // MARK: - Helper Methods

    private func updateConcentrationData() {
        Task { @MainActor in
            // Calculate current concentration
            currentConcentration = pkEngine.calculateCurrentConcentration(
                for: user,
                medication: medicationProfile
            )

            // Calculate peak level from most recent dose
            if let lastDose = medicationProfile.doses?.max(by: { $0.timestamp < $1.timestamp }) {
                peakLevel = pkEngine.calculatePeakLevel(for: lastDose, medication: medicationProfile)
            } else {
                peakLevel = nil
            }

            // Calculate trough level
            troughLevel = pkEngine.calculateTroughLevel(for: medicationProfile)

            // Calculate steady state progress
            steadyStateProgress = pkEngine.calculateSteadyStateProgress(for: medicationProfile)
        }
    }

    private func timeDisplayText(for date: Date) -> String {
        let now = Date()
        let timeInterval = date.timeIntervalSince(now)

        if timeInterval < 0 {
            // Past time
            let pastInterval = -timeInterval
            if pastInterval < 3600 {
                let minutes = Int(pastInterval / 60)
                return "\(minutes)m ago"
            } else if pastInterval < 86400 {
                let hours = Int(pastInterval / 3600)
                return "\(hours)h ago"
            } else {
                let days = Int(pastInterval / 86400)
                return "\(days)d ago"
            }
        } else {
            // Future time
            if timeInterval < 3600 {
                let minutes = Int(timeInterval / 60)
                return "in \(minutes)m"
            } else if timeInterval < 86400 {
                let hours = Int(timeInterval / 3600)
                return "in \(hours)h"
            } else {
                let days = Int(timeInterval / 86400)
                return "in \(days)d"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var container = DataController.preview.container

    ConcentrationCard(
        user: createPreviewUser(),
        medicationProfile: createPreviewMedicationProfile(),
        pkEngine: PharmacokineticsEngine(),
        doseService: nil
    )
    .padding()
    .modelContainer(container)
}

private func createPreviewUser() -> User {
    User(
        email: "preview@example.com",
        name: "Preview User",
        appleUserId: "preview-user"
    )
}

private func createPreviewMedicationProfile() -> MedicationProfile {
    MedicationProfile(
        genericName: "semaglutide",
        brandName: "Ozempic",
        currentDose: 1.0,
        startDate: Date().addingTimeInterval(-30 * 24 * 3600),
        medicationType: "semaglutide"
    )
}
