//
//  NotificationsStepView.swift
//  JabTracker
//
//  Permission screen for push notifications during onboarding.
//  Explains benefits and allows users to toggle notifications.
//

import SwiftUI
import UserNotifications

/// Notifications permission screen for onboarding.
///
/// Displays benefits of push notifications and provides a toggle to enable/disable.
/// Uses standard navigation (Back/Continue) from parent OnboardingView.
struct NotificationsStepView: View {
    /// UserDefaults key matching NotificationService+Persistence for later pickup
    private static let notificationsEnabledKey = "notificationsEnabled"

    /// Tracks user's notification preference
    @State private var isEnabled: Bool = false

    /// Shows activity indicator while requesting authorization
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

            // Large icon with state-dependent color
            Image(systemName: "bell.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    isEnabled
                        ? DesignTokens.Colors.accent
                        : DesignTokens.Colors.inactive
                )
                .accessibilityHidden(true)
                .animation(.easeInOut(duration: 0.2), value: isEnabled)
                .padding(.bottom, 32)

            // Benefits list
            BenefitsCard(benefits: benefits)
                .padding(.horizontal, 24)

            // Toggle row
            toggleRow
                .padding(.horizontal, 24)
                .padding(.top, 24)

            Spacer()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding-notifications-step")
        .onAppear {
            // Load saved preference (if user navigated back)
            isEnabled = UserDefaults.standard.bool(forKey: Self.notificationsEnabledKey)
        }
    }

    // MARK: - Toggle Row

    private var toggleRow: some View {
        VStack(spacing: 0) {
            HStack {
                Label {
                    Text("Notifications")
                        .font(.body)
                } icon: {
                    Image(systemName: "bell.fill")
                        .foregroundStyle(DesignTokens.Colors.accent)
                }

                Spacer()

                if isRequesting {
                    ProgressView()
                        .accessibilityIdentifier("notifications-requesting")
                } else {
                    Toggle("", isOn: $isEnabled)
                        .labelsHidden()
                        .accessibilityIdentifier("notifications-toggle")
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

    // MARK: - Actions

    private func handleToggleChange(_ enabled: Bool) {
        if enabled {
            requestNotificationAuthorization()
        } else {
            // Save preference - NotificationService will pick this up when initialized
            UserDefaults.standard.set(false, forKey: Self.notificationsEnabledKey)
        }
    }

    private func requestNotificationAuthorization() {
        isRequesting = true

        Task { @MainActor in
            let center = UNUserNotificationCenter.current()

            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                // Update toggle based on actual authorization result
                isEnabled = granted
                // Save preference - NotificationService will pick this up when initialized
                UserDefaults.standard.set(granted, forKey: Self.notificationsEnabledKey)
            } catch {
                // Authorization failed - reset toggle
                isEnabled = false
                UserDefaults.standard.set(false, forKey: Self.notificationsEnabledKey)
            }

            isRequesting = false
        }
    }
}

#Preview {
    NotificationsStepView()
}
