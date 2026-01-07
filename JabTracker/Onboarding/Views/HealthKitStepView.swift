//
//  HealthKitStepView.swift
//  JabTracker
//
//  Permission screen for HealthKit integration during onboarding.
//  Explains benefits and allows users to toggle HealthKit sync.
//

import HealthKit
import OSLog
import SwiftUI

/// HealthKit permission screen for onboarding.
///
/// Displays benefits of HealthKit integration and provides a toggle to enable/disable.
/// Uses standard navigation (Back/Continue) from parent OnboardingView.
struct HealthKitStepView: View {
    /// ViewModel for enabling HealthKit sync
    let viewModel: OnboardingViewModel

    /// Tracks user's HealthKit preference
    @State private var isEnabled: Bool = false

    /// Shows activity indicator while requesting authorization
    @State private var isRequesting = false

    /// Whether HealthKit is available on this device
    private var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private let step = OnboardingStep.healthKit

    private let benefits = [
        "Sync your weight automatically",
        "Track burned calories from workouts",
        "Keep your health data in one place",
    ]

    private let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "HealthKitStepView"
    )

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: step.title, subtitle: step.subtitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            if isAvailable {
                availableContent
            } else {
                unavailableContent
            }

            Spacer()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-healthkit-step")
    }

    // MARK: - Available Content

    private var availableContent: some View {
        VStack(spacing: 32) {
            // Apple Health app icon style with state-dependent opacity
            appleHealthIcon
                .opacity(isEnabled ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.2), value: isEnabled)

            // Benefits list
            BenefitsCard(benefits: benefits)
                .padding(.horizontal, 24)

            // Toggle row
            toggleRow
                .padding(.horizontal, 24)
        }
    }

    // MARK: - Toggle Row

    private var toggleRow: some View {
        VStack(spacing: 0) {
            HStack {
                Label {
                    Text("Apple Health")
                        .font(.body)
                } icon: {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Color(red: 1.0, green: 0.23, blue: 0.35))
                }

                Spacer()

                if isRequesting {
                    ProgressView()
                        .accessibilityIdentifier("healthkit-requesting")
                } else {
                    Toggle("", isOn: $isEnabled)
                        .labelsHidden()
                        .accessibilityIdentifier("healthkit-toggle")
                        .onChange(of: isEnabled) { _, newValue in
                            handleToggleChange(newValue)
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Unavailable Content

    private var unavailableContent: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.5))
                    .frame(width: 80, height: 80)

                Image(systemName: "heart.fill")
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(DesignTokens.Colors.inactive)
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Apple Health Not Available")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("HealthKit is not available on this device.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Text("You can continue without Health sync.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
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
                .foregroundStyle(Color(red: 1.0, green: 0.23, blue: 0.35))
        }
        .accessibilityHidden(true)
    }

    // MARK: - Actions

    private func handleToggleChange(_ enabled: Bool) {
        if enabled {
            requestHealthKitAuthorization()
        }
        // When disabled, just leave it off - no action needed
    }

    private func requestHealthKitAuthorization() {
        logger.info("Requesting HealthKit authorization...")
        isRequesting = true

        Task { @MainActor in
            let granted = await viewModel.enableHealthKitSync()
            logger.info("HealthKit authorization result: \(granted)")

            // Update toggle based on actual authorization result
            isEnabled = granted
            isRequesting = false
        }
    }
}

// Preview not available - requires OnboardingViewModel with DataController and AuthenticationManager
