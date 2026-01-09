//
//  DailyNutritionHeroWidget.swift
//  JabTracker
//
//  Daily nutrition hero widget showing circular calorie ring and macro progress bars.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftUI

// MARK: - DailyNutritionHeroWidget

/// Hero widget displaying today's nutrition with circular calorie ring and macro bars
struct DailyNutritionHeroWidget: View, DashboardWidget {
    let id = "daily-nutrition"
    let title = "Daily Nutrition"

    @Environment(\.heroDisplayMode) private var displayMode

    // MARK: - Mock Data

    private let mockData = DailyMockData.sample

    var body: some View {
        content
    }

    var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            // Circular ring section with flanking stats
            calorieRingSection

            // Macro progress bars
            macroBarSection
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .accessibilityIdentifier("daily-nutrition-hero-widget")
    }

    // MARK: - Calorie Ring Section

    private var calorieRingSection: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left stat
            leftStatView
                .frame(maxWidth: .infinity)

            // Center ring
            calorieRing
                .frame(width: 130, height: 130)

            // Right stat
            rightStatView
                .frame(maxWidth: .infinity)
        }
    }

    private var leftStatView: some View {
        VStack(spacing: 2) {
            Text("\(leftValue)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(leftLabel)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(leftValue) \(leftLabel)")
    }

    private var rightStatView: some View {
        VStack(spacing: 2) {
            Text("\(mockData.caloriesTarget)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text("Target")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mockData.caloriesTarget) Target")
    }

    /// Value shown in the left stat (opposite of center)
    private var leftValue: Int {
        switch displayMode {
        case .consumed:
            return mockData.caloriesRemaining
        case .remaining:
            return mockData.caloriesConsumed
        }
    }

    /// Label shown in the left stat
    private var leftLabel: String {
        switch displayMode {
        case .consumed:
            return "Remaining"
        case .remaining:
            return "Consumed"
        }
    }

    // MARK: - Calorie Ring

    private var calorieRing: some View {
        let progress = Double(mockData.caloriesConsumed) / Double(mockData.caloriesTarget)

        return ZStack {
            // Background track
            Circle()
                .stroke(
                    DesignTokens.Colors.calories.opacity(0.2),
                    lineWidth: 12
                )

            // Progress fill
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    DesignTokens.Colors.calories,
                    style: StrokeStyle(
                        lineWidth: 12,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            // Center text
            VStack(spacing: 2) {
                Text("\(centerValue)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(centerLabel)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Calories: \(centerValue) \(centerLabel)")
        .accessibilityValue(String(format: "%.0f percent of target", progress * 100))
    }

    /// Value shown in the center of the ring
    private var centerValue: Int {
        switch displayMode {
        case .consumed:
            return mockData.caloriesConsumed
        case .remaining:
            return mockData.caloriesRemaining
        }
    }

    /// Label shown below the center value
    private var centerLabel: String {
        switch displayMode {
        case .consumed:
            return "Consumed"
        case .remaining:
            return "Remaining"
        }
    }

    // MARK: - Macro Bar Section

    private var macroBarSection: some View {
        HStack(spacing: 16) {
            macroBar(
                label: "Protein",
                consumed: mockData.proteinConsumed,
                target: mockData.proteinTarget,
                color: DesignTokens.Colors.protein
            )

            macroBar(
                label: "Fat",
                consumed: mockData.fatConsumed,
                target: mockData.fatTarget,
                color: DesignTokens.Colors.fat
            )

            macroBar(
                label: "Carbs",
                consumed: mockData.carbsConsumed,
                target: mockData.carbsTarget,
                color: DesignTokens.Colors.carbs
            )
        }
    }

    private func macroBar(
        label: String,
        consumed: Int,
        target: Int,
        color: Color
    ) -> some View {
        let progress = target > 0 ? Double(consumed) / Double(target) : 0

        return VStack(alignment: .leading, spacing: 4) {
            // Label
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.inactive)
                        .frame(height: 8)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                        .animation(.easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 8)

            // Value text
            Text("\(consumed) / \(target)g")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(consumed) of \(target) grams")
        .accessibilityValue(String(format: "%.0f percent", progress * 100))
    }
}

// MARK: - Mock Data

private struct DailyMockData {
    let caloriesConsumed: Int
    let caloriesTarget: Int
    let proteinConsumed: Int
    let proteinTarget: Int
    let fatConsumed: Int
    let fatTarget: Int
    let carbsConsumed: Int
    let carbsTarget: Int

    var caloriesRemaining: Int {
        max(0, caloriesTarget - caloriesConsumed)
    }

    static var sample: DailyMockData {
        // Partial day consumption (40-60% filled for demo)
        DailyMockData(
            caloriesConsumed: 698,  // ~50% of target
            caloriesTarget: 1395,
            proteinConsumed: 56,  // ~50% of target
            proteinTarget: 113,
            fatConsumed: 24,  // ~49% of target
            fatTarget: 49,
            carbsConsumed: 62,  // ~50% of target
            carbsTarget: 125
        )
    }
}

// MARK: - Preview

#Preview("Consumed Mode") {
    ScrollView {
        VStack(spacing: 16) {
            DailyNutritionHeroWidget()
                .environment(\.heroDisplayMode, .consumed)
                .cardStyle()
        }
        .padding()
    }
    .background(DesignTokens.Colors.groupedBackground)
}

#Preview("Remaining Mode") {
    ScrollView {
        VStack(spacing: 16) {
            DailyNutritionHeroWidget()
                .environment(\.heroDisplayMode, .remaining)
                .cardStyle()
        }
        .padding()
    }
    .background(DesignTokens.Colors.groupedBackground)
}
