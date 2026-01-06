//
//  HealthKitStepView.swift
//  JabTracker
//
//  Permission screen for HealthKit integration during onboarding.
//  Explains benefits and allows users to enable or skip.
//

import HealthKit
import OSLog
import SwiftUI

/// HealthKit permission screen for onboarding.
///
/// Displays benefits of HealthKit integration and provides Enable/Skip buttons.
/// Navigation is handled via the onContinue callback.
struct HealthKitStepView: View {
    /// Callback to enable HealthKit sync (uses OnboardingViewModel)
    let onEnableHealthKit: () async -> Bool

    /// Callback when user completes this step (enable or skip)
    let onContinue: () -> Void

    @State private var isRequesting = false

    private let step = OnboardingStep.healthKit

    private let benefits = [
        "Sync your weight automatically",
        "Track burned calories from workouts",
        "Keep your health data in one place",
    ]

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: step.title, subtitle: step.subtitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Apple Health app icon style
            appleHealthIcon
                .padding(.bottom, 32)

            // Benefits list
            benefitsCard
                .padding(.horizontal, 24)

            Spacer()

            // Action buttons
            actionButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-healthKit-step")
    }

    // MARK: - Apple Health Icon

    private var appleHealthIcon: some View {
        ZStack {
            // White rounded square background (like the Health app icon)
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

            // Pink/red heart
            Image(systemName: "heart.fill")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Color(red: 1.0, green: 0.23, blue: 0.35))  // Apple Health pink/red
        }
        .accessibilityHidden(true)
    }

    // MARK: - Benefits Card

    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(benefits, id: \.self) { benefit in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DesignTokens.Colors.accent)
                        .accessibilityHidden(true)

                    Text(benefit)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                enableHealthKit()
            } label: {
                Text(isRequesting ? "Connecting..." : "Connect to Apple Health")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isRequesting)
            .accessibilityIdentifier("healthkit-enable-button")

            Button {
                onContinue()
            } label: {
                Text("Not Now")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isRequesting)
            .accessibilityIdentifier("healthkit-skip-button")
        }
    }

    // MARK: - Actions

    private let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "HealthKitStepView"
    )

    private func enableHealthKit() {
        logger.info("enableHealthKit() called")

        // Check if HealthKit is available on this device
        let isAvailable = HKHealthStore.isHealthDataAvailable()
        logger.info("HealthKit available: \(isAvailable)")
        guard isAvailable else {
            logger.warning("HealthKit not available, skipping")
            onContinue()
            return
        }

        isRequesting = true
        logger.info("Starting HealthKit authorization request...")

        Task { @MainActor in
            logger.info("Calling onEnableHealthKit callback...")
            // Use the OnboardingViewModel's method which properly sets user.healthSyncEnabled
            let result = await onEnableHealthKit()
            logger.info("onEnableHealthKit returned: \(result)")
            isRequesting = false
            logger.info("Calling onContinue...")
            onContinue()
        }
    }
}

#Preview {
    HealthKitStepView(
        onEnableHealthKit: {
            print("Enable HealthKit tapped")
            return true
        },
        onContinue: {
            print("Continue tapped")
        }
    )
}
