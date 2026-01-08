//
//  HeroWidgetContainer.swift
//  JabTracker
//
//  Swipeable carousel container for hero dashboard widgets.
//  Displays large, prominent widgets with page indicator dots.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftUI

/// Swipeable carousel container for hero dashboard widgets.
///
/// Features:
/// - TabView-based page navigation
/// - Custom page indicator dots
/// - Smooth animation between pages
/// - DesignCard-style container styling
///
/// Example usage:
/// ```swift
/// HeroWidgetContainer(
///     pages: [
///         AnyView(WeeklyNutritionWidget()),
///         AnyView(EnergyBalanceWidget()),
///         AnyView(DailyNutritionWidget())
///     ]
/// )
/// ```
struct HeroWidgetContainer: View {
    let pages: [AnyView]
    @State private var selectedIndex: Int = 0

    init(pages: [AnyView]) {
        self.pages = pages
    }

    var body: some View {
        if pages.isEmpty {
            EmptyView()
        } else {
            heroContent
        }
    }

    private var heroContent: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    page
                        .tag(index)
                        .padding(.horizontal, 4)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: selectedIndex)
            .frame(height: 360)

            // Custom page indicator dots
            pageIndicator
                .padding(.top, 16)
                .padding(.bottom, 20)
        }
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("hero-widget-container")
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Circle()
                    .fill(index == selectedIndex ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedIndex = index
                        }
                    }
                    .accessibilityLabel("Page \(index + 1) of \(pages.count)")
                    .accessibilityAddTraits(index == selectedIndex ? .isSelected : [])
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            HeroWidgetContainer(
                pages: [
                    AnyView(previewPage(title: "Weekly Nutrition", color: .blue)),
                    AnyView(previewPage(title: "Energy Balance", color: .green)),
                    AnyView(previewPage(title: "Daily Nutrition", color: .orange)),
                ]
            )
        }
        .padding()
    }
    .background(DesignTokens.Colors.groupedBackground)
}

@ViewBuilder
private func previewPage(title: String, color: Color) -> some View {
    VStack(spacing: 16) {
        Text(title)
            .font(DesignTokens.Typography.headline)
            .foregroundColor(.primary)

        Circle()
            .fill(color.opacity(0.3))
            .frame(width: 200, height: 200)
            .overlay {
                Text("Chart")
                    .foregroundColor(color)
            }

        Text("Sample content for \(title)")
            .font(DesignTokens.Typography.body)
            .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding()
}
