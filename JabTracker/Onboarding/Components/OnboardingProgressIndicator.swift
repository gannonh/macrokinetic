import SwiftUI

struct OnboardingProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            ProgressView(value: Double(currentStep - 1), total: Double(totalSteps - 1))
                .tint(DesignTokens.Colors.primary)
                .accessibilityIdentifier("onboarding-progress-bar")
            
            // Step indicator
            HStack {
                Text("\(currentStep) of \(totalSteps)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Page dots
                HStack(spacing: 8) {
                    ForEach(1...totalSteps, id: \.self) { step in
                        Circle()
                            .fill(step <= currentStep ? DesignTokens.Colors.primary : Color(.systemGray4))
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