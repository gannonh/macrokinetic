//
//  StepHeader.swift
//  JabTracker
//
//  Reusable step header component for wizard and onboarding flows.
//

import SwiftUI

/// A consistent header component for wizard and onboarding step views.
///
/// Displays a title and subtitle in a left-aligned vertical stack.
/// Used across onboarding steps, goal wizard, and program wizard.
struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}

#Preview {
    VStack {
        StepHeader(
            title: "Set Your Goals",
            subtitle: "Tell us what you want to achieve"
        )
        Spacer()
    }
}
