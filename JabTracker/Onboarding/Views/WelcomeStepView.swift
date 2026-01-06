//
//  WelcomeStepView.swift
//  JabTracker
//
//  Welcome screen for v0.6.0 onboarding flow.
//  Pure presentation view - no ViewModel required.
//

import SwiftUI

/// Welcome screen that introduces MacroKinetic to new users.
///
/// Displays the app icon, name, tagline, and a brief value proposition.
/// Navigation is handled by the parent OnboardingView.
struct WelcomeStepView: View {
    private static let valueProposition = """
        Your complete companion for nutrition tracking, \
        smart calorie adjustments, and GLP-1 medication support.
        """

    private var accessibilityDescription: String {
        "Welcome to MacroKinetic. " + "\(OnboardingStep.welcome.subtitle). " + Self.valueProposition
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App logo
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .accessibilityHidden(true)

            // App name
            Text("MacroKinetic")
                .font(DesignTokens.Typography.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            // Tagline from OnboardingStep
            Text(OnboardingStep.welcome.subtitle)
                .font(DesignTokens.Typography.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            // Value proposition
            Text(Self.valueProposition)
                .font(DesignTokens.Typography.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityIdentifier("onboarding-welcome-step")
    }
}

#Preview {
    WelcomeStepView()
}
