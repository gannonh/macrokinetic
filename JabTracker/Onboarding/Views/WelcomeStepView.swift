import SwiftUI

/// Placeholder view for Welcome onboarding step.
/// Will be replaced with actual implementation in Phase 26.
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "hand.wave")
                .font(.system(size: 64))
                .foregroundColor(DesignTokens.Colors.primary)
                .accessibilityHidden(true)

            Text(OnboardingStep.welcome.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(OnboardingStep.welcome.subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Coming in Phase 26")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)

            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("welcome-placeholder-view")
    }
}
