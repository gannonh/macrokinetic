//
//  NotificationsStepView.swift
//  JabTracker
//
//  Permission screen for push notifications during onboarding.
//  Explains benefits and allows users to enable or skip.
//

import SwiftUI
import UserNotifications

/// Notifications permission screen for onboarding.
///
/// Displays benefits of push notifications and provides Enable/Skip buttons.
/// Navigation is handled via the onContinue callback.
struct NotificationsStepView: View {
    /// Callback when user completes this step (enable or skip)
    let onContinue: () -> Void

    @State private var isRequesting = false

    private let step = OnboardingStep.notifications

    private let benefits = [
        "Get reminders when it's time for your dose",
        "Never miss a weigh-in or meal log",
        "Stay on track with your nutrition goals",
    ]

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(title: step.title, subtitle: step.subtitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Large icon
            Image(systemName: "bell.fill")
                .font(.system(size: 64))
                .foregroundStyle(DesignTokens.Colors.accent)
                .accessibilityHidden(true)
                .padding(.bottom, 32)

            // Benefits list
            BenefitsCard(benefits: benefits)
                .padding(.horizontal, 24)

            Spacer()

            // Action buttons
            PermissionActionButtons(
                primaryTitle: "Enable Notifications",
                loadingTitle: "Requesting...",
                isLoading: isRequesting,
                enableIdentifier: "notifications-enable-button",
                skipIdentifier: "notifications-skip-button",
                onEnable: enableNotifications,
                onSkip: onContinue
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-notifications-step")
    }

    // MARK: - Actions

    private func enableNotifications() {
        isRequesting = true

        Task { @MainActor in
            defer {
                isRequesting = false
                onContinue()
            }

            // Request notification authorization directly (AppServices not available during onboarding)
            let center = UNUserNotificationCenter.current()

            do {
                _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                // Authorization requested - result handled by system dialog
            } catch {
                // Proceed regardless of error - user can enable later in settings
            }
        }
    }
}

#Preview {
    NotificationsStepView {}
}
