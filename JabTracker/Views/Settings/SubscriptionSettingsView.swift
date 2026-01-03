//
//  SubscriptionSettingsView.swift
//  JabTracker
//
//  Subscription management mock screen showing plan details and management options.
//

import SwiftUI

struct SubscriptionSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Coming Soon Banner
                Text("Coming Soon")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                // Active Subscription Card
                DesignCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Subscription")
                            .font(DesignTokens.Typography.headline)

                        HStack {
                            Text("Plan")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("12 Months")
                                .font(DesignTokens.Typography.body)
                        }

                        HStack {
                            Text("Price")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("$59.99 (50% off monthly)")
                                .font(DesignTokens.Typography.body)
                        }

                        HStack {
                            Text("Renews")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("May 8, 2026")
                                .font(DesignTokens.Typography.body)
                        }
                    }
                }
                .accessibilityIdentifier("subscription-plan-card")

                // Restore Purchases Card
                DesignCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Restore Purchases")
                            .font(DesignTokens.Typography.headline)

                        Text(
                            "If you've previously subscribed, you can restore your purchase to regain access."
                        )
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.secondary)

                        Button(
                            action: {},
                            label: {
                                Text("Restore Purchases")
                                    .font(DesignTokens.Typography.body)
                                    .frame(maxWidth: .infinity)
                            }
                        )
                        .buttonStyle(.bordered)
                        .foregroundColor(.secondary)
                        .disabled(true)
                        .accessibilityIdentifier("restore-purchases-button")
                    }
                }

                // Manage Subscription Card
                DesignCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Manage Subscription")
                            .font(DesignTokens.Typography.headline)

                        Text(
                            "Your subscription is managed through the Apple App Store. "
                                + "You can cancel, upgrade, or modify your subscription at any time."
                        )
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.secondary)

                        Button(
                            action: {
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            },
                            label: {
                                Text("Manage Subscription")
                                    .font(DesignTokens.Typography.body)
                                    .frame(maxWidth: .infinity)
                            }
                        )
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("manage-subscription-button")

                        Text(
                            "Subscriptions automatically renew unless auto-renew is turned off "
                                + "at least 24-hours before the end of the current period."
                        )
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Preview notice
                Text("This is a preview")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("subscription-settings-view")
    }
}

#Preview {
    NavigationStack {
        SubscriptionSettingsView()
    }
}
