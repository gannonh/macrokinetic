import SwiftUI
import StoreKit
import OSLog

struct SubscriptionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @StateObject private var subscriptionManager = SubscriptionManager()
    
    // MARK: - Logger
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "JabTracker", 
        category: "SubscriptionView")
    
    private var isTestEnvironment: Bool {
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
    }

    private let premiumFeatures = [
        "Unlimited medication tracking",
        "Advanced analytics and insights",
        "PDF reports for healthcare providers",
        "Priority customer support",
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

                // Pricing and purchase section
                VStack(spacing: 20) {
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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Subscription pricing: $4.99 per month with 2-week free trial")
                    
                    // Purchase button
                    PrimaryButton(title: subscriptionManager.isLoading ? "Loading..." : "Start Free Trial") {
                        Task {
                            await purchaseSubscription()
                        }
                    }
                    .disabled(subscriptionManager.isLoading || (!isTestEnvironment && subscriptionManager.availableProducts.isEmpty))
                    .accessibilityIdentifier("purchase-subscription-button")
                    
                    // Restore button
                    Button("Restore Purchases") {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    }
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .disabled(subscriptionManager.isLoading)
                    .accessibilityIdentifier("restore-purchases-button")
                }
                .padding(.horizontal, 24)

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
        .accessibilityIdentifier("subscription-view")
        .onAppear {
            Task {
                Self.logger.info("🛒 SubscriptionView: Loading subscription products...")
                await subscriptionManager.loadProducts()
                Self.logger.info("🛒 SubscriptionView: Products loaded: \(subscriptionManager.availableProducts.count, privacy: .public)")
                if !subscriptionManager.availableProducts.isEmpty {
                    Self.logger.info("🛒 SubscriptionView: Product IDs: \(subscriptionManager.availableProducts.map { $0.id }, privacy: .public)")
                }
                if let error = subscriptionManager.errorMessage {
                    Self.logger.error("🛒 SubscriptionView: Error: \(error, privacy: .public)")
                } else {
                    Self.logger.info("🛒 SubscriptionView: No errors")
                }
            }
        }
        .alert("Subscription Error", isPresented: .constant(subscriptionManager.errorMessage != nil)) {
            Button("OK") {
                subscriptionManager.errorMessage = nil
            }
        } message: {
            if let errorMessage = subscriptionManager.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func purchaseSubscription() async {
        do {
            if isTestEnvironment {
                // In test environment, simulate successful purchase
                try await viewModel.completeOnboarding()
            } else {
                // Purchase the monthly subscription product
                try await subscriptionManager.purchase(productId: SubscriptionProducts.monthly)
                
                // If purchase succeeds, complete onboarding
                try await viewModel.completeOnboarding()
            }
        } catch {
            subscriptionManager.errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }
}
