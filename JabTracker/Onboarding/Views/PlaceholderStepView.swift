import SwiftUI

/// Placeholder view for onboarding steps not yet implemented.
/// Used for healthKit, faceID, notifications, and completion steps.
struct PlaceholderStepView: View {
    let step: OnboardingStep

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: iconName(for: step))
                .font(.system(size: 64))
                .foregroundStyle(DesignTokens.Colors.accent)
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
        .accessibilityIdentifier("onboarding-\(step.rawValue)-step")
    }

    private func iconName(for step: OnboardingStep) -> String {
        switch step {
        case .welcome:
            return "hand.wave"
        case .uspShowcase:
            return "star.fill"
        case .healthKit:
            return "heart.fill"
        case .goalType:
            return "target"
        case .targetWeight:
            return "scalemass"
        case .profileCompletion:
            return "person.crop.circle"
        case .programStyle:
            return "gearshape.2"
        case .dietPreference:
            return "fork.knife"
        case .calorieFloor:
            return "flame"
        case .activityLevel:
            return "figure.walk"
        case .weeklyDistribution:
            return "calendar"
        case .proteinLevel:
            return "dumbbell"
        case .shiftedDaySelection:
            return "calendar.badge.plus"
        case .setupConfirmation:
            return "checkmark.seal"
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
        case .healthKit, .goalType, .targetWeight, .profileCompletion,
            .programStyle, .dietPreference, .calorieFloor, .activityLevel,
            .weeklyDistribution, .proteinLevel, .shiftedDaySelection, .setupConfirmation:
            return 27
        case .faceID, .notifications:
            return 28
        case .completion:
            return 29
        }
    }
}
