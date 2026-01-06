import SwiftUI

/// Placeholder view for Notifications permission onboarding step.
/// Will be replaced with actual implementation in Phase 28.
struct NotificationsStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "bell.fill")
                .font(.system(size: 64))
                .foregroundColor(DesignTokens.Colors.primary)
                .accessibilityHidden(true)

            Text(OnboardingStep.notifications.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(OnboardingStep.notifications.subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Coming in Phase 28")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)

            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("notifications-placeholder-view")
    }
}
