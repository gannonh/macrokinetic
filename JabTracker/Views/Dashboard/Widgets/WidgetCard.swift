//
//  WidgetCard.swift
//  JabTracker
//
//  Card wrapper component for dashboard widgets.
//  Provides consistent styling with optional tap navigation.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftUI

/// Card wrapper that provides consistent styling for dashboard widgets.
///
/// Features:
/// - Consistent card background using DesignTokens
/// - Optional tap gesture with chevron indicator
/// - Accessibility support
///
/// Example usage:
/// ```swift
/// WidgetCard(title: "Weight Trend") {
///     Text("−2.5 lbs this week")
/// } onTap: {
///     // Navigate to detail view
/// }
/// ```
struct WidgetCard<Content: View>: View {
    let title: String?
    let content: Content
    let onTap: (() -> Void)?

    init(
        title: String? = nil,
        @ViewBuilder content: () -> Content,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.content = content()
        self.onTap = onTap
    }

    private var accessibilityID: String {
        let id = title?.lowercased().replacingOccurrences(of: " ", with: "-") ?? "untitled"
        return "widget-card-\(id)"
    }

    var body: some View {
        cardContent
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(accessibilityID)
    }

    @ViewBuilder
    private var cardContent: some View {
        if let onTap {
            Button(action: onTap) {
                cardBody
            }
            .buttonStyle(.plain)
        } else {
            cardBody
        }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title, onTap != nil {
                HStack {
                    Text(title)
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            } else if let title {
                Text(title)
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(.primary)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

#Preview("With Tap Action") {
    VStack(spacing: 16) {
        WidgetCard(title: "Weight Trend") {
            Text("−2.5 lbs this week")
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
        } onTap: {
            print("Tapped!")
        }

        WidgetCard(title: "Calories") {
            Text("2,100 / 2,400 kcal")
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
        }

        WidgetCard {
            Text("No title, no tap")
                .font(DesignTokens.Typography.body)
        }
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}
