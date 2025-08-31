import SwiftUI

struct SubscriptionPlaceholderView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let premiumFeatures = [
        "Unlimited medication tracking",
        "Advanced analytics and insights",
        "PDF reports for healthcare providers",
        "Priority customer support",
        "Apple Watch companion app",
        "Data export and backup",
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(DesignTokens.Colors.primaryGradient)
                        .accessibilityHidden(true)

                    Text("JabTracker Premium")
                        .font(DesignTokens.Typography.largeTitle)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("Unlock the full potential of your medication tracking")
                        .font(DesignTokens.Typography.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

                // Pricing card
                DesignCard {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("$4.99/month")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(DesignTokens.Colors.primary)

                            Text("2-week free trial")
                                .font(DesignTokens.Typography.headline)
                                .foregroundColor(DesignTokens.Colors.success)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(DesignTokens.Colors.success.opacity(0.1))
                                .cornerRadius(16)
                        }

                        Text("Cancel anytime • No commitment")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Subscription pricing: $4.99 per month with 2-week free trial")

                // Features list
                VStack(spacing: 16) {
                    Text("Premium Features")
                        .font(DesignTokens.Typography.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVStack(spacing: 12) {
                        ForEach(self.premiumFeatures, id: \.self) { feature in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(DesignTokens.Colors.primary)
                                    .accessibilityHidden(true)

                                Text(feature)
                                    .font(DesignTokens.Typography.body)
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 120) // Space for navigation buttons
            }
        }
        .background(DesignTokens.Colors.background)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("subscription-placeholder-view")
    }
}
