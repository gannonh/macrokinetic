import SwiftUI

/// Placeholder view for onboarding steps.
/// Will be replaced with actual step implementations in Phases 26-29.
struct PlaceholderStepView: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: iconName(for: step))
                .font(.system(size: 64))
                .foregroundStyle(DesignTokens.Colors.primaryGradient)
                .accessibilityHidden(true)

            Text(step.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(step.subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Coming in Phase \(phaseNumber(for: step))")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 8)

            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(step.title). \(step.subtitle). Coming in Phase \(phaseNumber(for: step))")
        .accessibilityIdentifier("onboarding-\(accessibilityIdentifier(for: step))-step")
    }

    private func iconName(for step: OnboardingStep) -> String {
        switch step {
        case .welcome:
            return "hand.wave"
        case .uspShowcase:
            return "star.fill"
        case .goalSetup:
            return "target"
        case .programSetup:
            return "list.bullet.clipboard"
        case .healthKit:
            return "heart.fill"
        case .faceID:
            return "faceid"
        case .notifications:
            return "bell.fill"
        case .completion:
            return "checkmark.circle.fill"
        }
    }

    private func phaseNumber(for step: OnboardingStep) -> Int {
        switch step {
        case .welcome, .uspShowcase:
            return 26
        case .goalSetup, .programSetup:
            return 27
        case .healthKit, .faceID, .notifications:
            return 28
        case .completion:
            return 29
        }
    }

    private func accessibilityIdentifier(for step: OnboardingStep) -> String {
        switch step {
        case .welcome:
            return "welcome"
        case .uspShowcase:
            return "uspShowcase"
        case .goalSetup:
            return "goalSetup"
        case .programSetup:
            return "programSetup"
        case .healthKit:
            return "healthKit"
        case .faceID:
            return "faceID"
        case .notifications:
            return "notifications"
        case .completion:
            return "completion"
        }
    }
}
