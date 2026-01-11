//
//  DailyNutritionHeroWidget.swift
//  JabTracker
//
//  Daily nutrition hero widget showing circular calorie ring and macro progress bars.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftData
import SwiftUI

// MARK: - DailyNutritionHeroWidget

/// Hero widget displaying today's nutrition with circular calorie ring and macro bars
struct DailyNutritionHeroWidget: View, DashboardWidget {
    let id = "daily-nutrition"
    let title = "Daily Nutrition"

    @Environment(\.heroDisplayMode) private var displayMode
    @Environment(\.modelContext) private var modelContext

    /// ViewModel for live data - initialized lazily on first access
    @State private var viewModel: DailyNutritionHeroViewModel?

    /// Animation state for "grow in" effect
    @State private var isAnimated = false

    /// Whether to use mock data (for previews)
    private let useMockData: Bool

    // MARK: - Constants

    private enum Layout {
        static let ringDiameter: CGFloat = 130
    }

    // MARK: - Initialization

    /// Initialize with live data (default for production)
    init() {
        self.useMockData = false
    }

    /// Initialize with mock data flag (for previews)
    init(useMockData: Bool) {
        self.useMockData = useMockData
    }

    var body: some View {
        content
            .task {
                await loadDataIfNeeded()
                // Trigger grow-in animation after data loads
                try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1s delay
                withAnimation(.easeOut(duration: 0.6)) {
                    isAnimated = true
                }
            }
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

    // MARK: - Data Loading

    private func loadDataIfNeeded() async {
        guard !useMockData else { return }

        if viewModel == nil {
            let mealLogService = AppServices.shared.mealLogService ?? MealLogService(context: modelContext)
            viewModel = DailyNutritionHeroViewModel(mealLogService: mealLogService, context: modelContext)
        }
        await viewModel?.loadData()
    }

    // MARK: - Data Accessors

    private var caloriesConsumed: Int {
        useMockData ? DailyMockData.sample.caloriesConsumed : (viewModel?.caloriesConsumed ?? 0)
    }

    private var caloriesTarget: Int {
        useMockData ? DailyMockData.sample.caloriesTarget : (viewModel?.caloriesTarget ?? 2000)
    }

    private var caloriesRemaining: Int {
        useMockData ? DailyMockData.sample.caloriesRemaining : (viewModel?.caloriesRemaining ?? caloriesTarget)
    }

    private var proteinConsumed: Int {
        useMockData ? DailyMockData.sample.proteinConsumed : (viewModel?.proteinConsumed ?? 0)
    }

    private var proteinTarget: Int {
        useMockData ? DailyMockData.sample.proteinTarget : (viewModel?.proteinTarget ?? 150)
    }

    private var fatConsumed: Int {
        useMockData ? DailyMockData.sample.fatConsumed : (viewModel?.fatConsumed ?? 0)
    }

    private var fatTarget: Int {
        useMockData ? DailyMockData.sample.fatTarget : (viewModel?.fatTarget ?? 65)
    }

    private var carbsConsumed: Int {
        useMockData ? DailyMockData.sample.carbsConsumed : (viewModel?.carbsConsumed ?? 0)
    }

    private var carbsTarget: Int {
        useMockData ? DailyMockData.sample.carbsTarget : (viewModel?.carbsTarget ?? 200)
    }

    // MARK: - Calorie Ring Section

    private var calorieRingSection: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left stat
            leftStatView
                .frame(maxWidth: .infinity)

            // Center ring
            calorieRing
                .frame(width: Layout.ringDiameter, height: Layout.ringDiameter)

            // Right stat
            rightStatView
                .frame(maxWidth: .infinity)
        }
    }

    private func statView(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private var leftStatView: some View {
        statView(value: leftValue, label: leftLabel)
    }

    private var rightStatView: some View {
        statView(value: caloriesTarget, label: "Target")
    }

    /// Value shown in the left stat (opposite of center)
    private var leftValue: Int {
        switch displayMode {
        case .consumed:
            return caloriesRemaining
        case .remaining:
            return caloriesConsumed
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
        // In Consumed mode: show consumed/target (how full)
        // In Remaining mode: show remaining/target (how much left)
        let baseProgress: Double = {
            guard caloriesTarget > 0 else { return 0 }
            switch displayMode {
            case .consumed:
                return Double(caloriesConsumed) / Double(caloriesTarget)
            case .remaining:
                return Double(caloriesRemaining) / Double(caloriesTarget)
            }
        }()
        let progress = baseProgress * (isAnimated ? 1.0 : 0.0)

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
            return caloriesConsumed
        case .remaining:
            return caloriesRemaining
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
                consumed: proteinConsumed,
                target: proteinTarget,
                color: DesignTokens.Colors.protein
            )

            macroBar(
                label: "Fat",
                consumed: fatConsumed,
                target: fatTarget,
                color: DesignTokens.Colors.fat
            )

            macroBar(
                label: "Carbs",
                consumed: carbsConsumed,
                target: carbsTarget,
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
        let remaining = max(0, target - consumed)

        // In Consumed mode: show consumed/target (how full)
        // In Remaining mode: show remaining/target (how much left)
        let baseProgress: Double = {
            guard target > 0 else { return 0 }
            switch displayMode {
            case .consumed:
                return Double(consumed) / Double(target)
            case .remaining:
                return Double(remaining) / Double(target)
            }
        }()
        let progress = baseProgress * (isAnimated ? 1.0 : 0.0)

        // Display value and text based on mode
        let displayValue = displayMode == .consumed ? consumed : remaining
        let valueText = displayMode == .consumed ? "\(consumed) / \(target)g" : "\(remaining)g left"

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
            Text(valueText)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(displayValue) \(displayMode == .consumed ? "of" : "left of") \(target) grams")
        .accessibilityValue(String(format: "%.0f percent", progress * 100))
    }
}

// MARK: - Mock Data

struct DailyMockData {
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
            DailyNutritionHeroWidget(useMockData: true)
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
            DailyNutritionHeroWidget(useMockData: true)
                .environment(\.heroDisplayMode, .remaining)
                .cardStyle()
        }
        .padding()
    }
    .background(DesignTokens.Colors.groupedBackground)
}
