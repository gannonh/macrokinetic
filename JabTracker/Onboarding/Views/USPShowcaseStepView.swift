//
//  USPShowcaseStepView.swift
//  JabTracker
//
//  Carousel view showcasing MacroKinetic's key features.
//  Part of the v0.6.0 onboarding flow.
//

import SwiftUI

/// Carousel view showcasing MacroKinetic's unique selling propositions.
///
/// Displays 4 key features with swipeable pages and custom page indicators.
/// Navigation is handled by the parent OnboardingView.
struct USPShowcaseStepView: View {
    @State private var currentPage: Int = 0

    private static let features: [USPFeature] = [
        USPFeature(
            icon: "chart.line.uptrend.xyaxis",
            title: "Adaptive TDEE",
            headline: "Your metabolism adapts. So does MacroKinetic.",
            description: "Learn your body's true calorie needs as you progress."
        ),
        USPFeature(
            icon: "barcode.viewfinder",
            title: "Precision Tracking",
            headline: "Track every macro with confidence",
            description: "1.7M+ foods, barcode scanning, custom foods."
        ),
        USPFeature(
            icon: "flame.fill",
            title: "Calorie Adjustments",
            headline: "Smart adjustments for real results",
            description: "Activity-based recommendations that evolve with you."
        ),
        USPFeature(
            icon: "syringe.fill",
            title: "GLP-1 Support",
            headline: "Made for your medication journey",
            description: "Optional GLP-1 tracking with dose reminders."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(Self.features.enumerated()), id: \.offset) { index, feature in
                    featureCard(feature: feature, index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Custom page indicators
            HStack(spacing: 12) {
                ForEach(0..<Self.features.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? DesignTokens.Colors.accent : DesignTokens.Colors.inactive)
                        .frame(width: 12, height: 12)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                currentPage = index
                            }
                        }
                        .accessibilityLabel("Page \(index + 1) of \(Self.features.count)")
                }
            }
            .padding(.bottom, 24)
        }
        .accessibilityIdentifier("onboarding-usp-showcase-step")
    }

    @ViewBuilder
    private func featureCard(feature: USPFeature, index: Int) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // Feature icon
            Image(systemName: feature.icon)
                .font(.system(size: 72))
                .foregroundStyle(DesignTokens.Colors.accent)
                .accessibilityHidden(true)

            // Content
            VStack(spacing: 16) {
                Text(feature.title)
                    .font(DesignTokens.Typography.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(feature.headline)
                    .font(DesignTokens.Typography.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text(feature.description)
                    .font(DesignTokens.Typography.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature.title). \(feature.headline). \(feature.description)")
        .accessibilityIdentifier("usp-feature-\(index)")
    }
}

// MARK: - Supporting Types

private struct USPFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let headline: String
    let description: String
}

#Preview {
    USPShowcaseStepView()
}
