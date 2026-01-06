import SwiftUI

/// Placeholder view for Goal Setup onboarding step.
/// Will be replaced with actual implementation in Phase 27.
struct GoalSetupStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "target")
                .font(.system(size: 64))
                .foregroundColor(DesignTokens.Colors.primary)
                .accessibilityHidden(true)

            Text(OnboardingStep.goalSetup.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(OnboardingStep.goalSetup.subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Coming in Phase 27")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)

            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("goalSetup-placeholder-view")
    }
}
