//
//  BenefitsCard.swift
//  JabTracker
//
//  Reusable benefits list card for permission step views.
//

import SwiftUI

/// A card displaying a list of benefits with checkmark icons.
///
/// Used in permission step views (HealthKit, Face ID, Notifications)
/// to show users the advantages of enabling each feature.
struct BenefitsCard: View {
    /// The list of benefit strings to display
    let benefits: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(benefits, id: \.self) { benefit in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DesignTokens.Colors.accent)
                        .accessibilityHidden(true)

                    Text(benefit)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card))
    }
}

#Preview {
    BenefitsCard(benefits: [
        "First benefit",
        "Second benefit",
        "Third benefit",
    ])
    .padding()
}
