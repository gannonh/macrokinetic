import SwiftUI

struct OnboardingProgressIndicator: View {
  let currentStep: Int
  let totalSteps: Int

  var body: some View {
    VStack(spacing: 12) {
      // Progress bar
      ProgressView(value: Double(self.currentStep - 1), total: Double(self.totalSteps - 1))
        .tint(DesignTokens.Colors.primary)
        .accessibilityIdentifier("onboarding-progress-bar")

      // Step indicator
      HStack {
        Text("\(self.currentStep) of \(self.totalSteps)")
          .font(DesignTokens.Typography.caption)
          .foregroundColor(.secondary)

        Spacer()

        // Page dots
        HStack(spacing: 8) {
          ForEach(1...self.totalSteps, id: \.self) { step in
            Circle()
              .fill(step <= self.currentStep ? DesignTokens.Colors.primary : Color(.systemGray4))
              .frame(width: 8, height: 8)
              .accessibilityHidden(true)
          }
        }
      }
    }
    .padding(.horizontal, 24)
    .accessibilityElement(children: .combine)
    .accessibilityIdentifier("onboarding-progress")
  }
}
