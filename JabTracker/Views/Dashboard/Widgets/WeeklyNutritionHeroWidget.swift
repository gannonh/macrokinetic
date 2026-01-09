//
//  WeeklyNutritionHeroWidget.swift
//  JabTracker
//
//  Weekly nutrition hero widget showing 7-day macro grid with compact layout.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftUI

// MARK: - Grid Layout Constants

/// Shared layout constants for weekly nutrition grid components
private enum GridLayout {
    static let cellWidth: CGFloat = 26
    static let cellHeight: CGFloat = 38
    static let cellSpacing: CGFloat = 14
    static let dayCount: Int = 7
}

// MARK: - MacroType

/// Macro types with their display symbols
enum MacroType {
    case calories
    case protein
    case fat
    case carbs

    var symbol: String {
        switch self {
        case .calories: return "flame.fill"  // SF Symbol
        case .protein: return "P"
        case .fat: return "F"
        case .carbs: return "C"
        }
    }

    var isSystemImage: Bool {
        self == .calories
    }
}

// MARK: - WeeklyMacroRow

/// Compact row of 7 day cells for one macro
struct WeeklyMacroRow: View {
    let macroType: MacroType
    let macroColor: Color
    let dailyValues: [Double]  // 7 values for Mon-Sun
    let target: Double
    let todayIndex: Int  // 0-6 for Mon-Sun
    let displayMode: HeroDisplayMode

    var body: some View {
        HStack(spacing: 0) {
            // Day cells - rectangles with fill from bottom
            HStack(spacing: GridLayout.cellSpacing) {
                ForEach(0..<GridLayout.dayCount, id: \.self) { dayIndex in
                    dayCellView(for: dayIndex)
                }
            }

            Spacer(minLength: 20)

            // Today's value summary (LEFT-aligned, 2 lines with symbol)
            summaryView
                .frame(width: 55, alignment: .leading)
        }
    }

    private var summaryView: some View {
        // Safe bounds check for todayIndex
        let todayConsumed =
            (todayIndex >= 0 && todayIndex < dailyValues.count)
            ? dailyValues[todayIndex]
            : 0
        let todayRemaining = max(0, target - todayConsumed)
        let displayValue = displayMode == .consumed ? todayConsumed : todayRemaining

        return VStack(alignment: .leading, spacing: 0) {
            // Value with symbol - LEFT aligned
            HStack(spacing: 3) {
                Text("\(Int(displayValue))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(macroColor)

                if macroType.isSystemImage {
                    Image(systemName: macroType.symbol)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(macroColor)
                } else {
                    Text(macroType.symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(macroColor)
                }
            }

            Text(displayMode == .consumed ? "of \(formattedTarget)" : "left")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
    }

    private var formattedTarget: String {
        if target >= 1000 {
            return String(format: "%.1fk", target / 1000)
                .replacingOccurrences(of: ".0k", with: "k")
        }
        return "\(Int(target))"
    }

    private func dayCellView(for index: Int) -> some View {
        // Safe bounds check for dailyValues array
        let consumed = (index >= 0 && index < dailyValues.count) ? dailyValues[index] : 0
        let remaining = max(0, target - consumed)
        let displayValue = displayMode == .consumed ? consumed : remaining
        let isToday = index == todayIndex
        let isFuture = index > todayIndex

        // Calculate fill percentage with division by zero protection
        let fillPercentage: CGFloat
        if isFuture || target <= 0 {
            fillPercentage = 0
        } else {
            fillPercentage = min(1.0, CGFloat(displayValue / target))
        }

        let fillHeight = GridLayout.cellHeight * fillPercentage

        return ZStack(alignment: .bottom) {
            // Background cell - darker for more contrast
            RoundedRectangle(cornerRadius: 4)
                .fill(DesignTokens.Colors.inactive)
                .frame(width: GridLayout.cellWidth, height: GridLayout.cellHeight)

            // Fill from bottom - fixed height calculation
            if !isFuture && fillPercentage > 0 {
                RoundedRectangle(cornerRadius: 3)
                    .fill(macroColor)
                    .frame(width: GridLayout.cellWidth - 4, height: max(4, fillHeight - 4))
                    .padding(.bottom, 2)
            }
        }
        .frame(width: GridLayout.cellWidth, height: GridLayout.cellHeight)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isToday ? macroColor : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - WeeklyNutritionHeroWidget

/// Hero widget displaying 7-day macro grid in compact layout
struct WeeklyNutritionHeroWidget: View, DashboardWidget {
    let id = "weekly-nutrition"
    let title = "Weekly Nutrition"

    @Environment(\.heroDisplayMode) private var displayMode

    // MARK: - Mock Data

    private let mockData = WeeklyMockData.sample
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        content
    }

    var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            // Grid section
            VStack(alignment: .leading, spacing: 6) {
                // Day labels header row
                dayHeaderRow

                // Macro rows - no dot indicator
                WeeklyMacroRow(
                    macroType: .calories,
                    macroColor: DesignTokens.Colors.calories,
                    dailyValues: mockData.calories,
                    target: mockData.caloriesTarget,
                    todayIndex: mockData.todayIndex,
                    displayMode: displayMode
                )

                WeeklyMacroRow(
                    macroType: .protein,
                    macroColor: DesignTokens.Colors.protein,
                    dailyValues: mockData.protein,
                    target: mockData.proteinTarget,
                    todayIndex: mockData.todayIndex,
                    displayMode: displayMode
                )

                WeeklyMacroRow(
                    macroType: .fat,
                    macroColor: DesignTokens.Colors.fat,
                    dailyValues: mockData.fat,
                    target: mockData.fatTarget,
                    todayIndex: mockData.todayIndex,
                    displayMode: displayMode
                )

                WeeklyMacroRow(
                    macroType: .carbs,
                    macroColor: DesignTokens.Colors.carbs,
                    dailyValues: mockData.carbs,
                    target: mockData.carbsTarget,
                    todayIndex: mockData.todayIndex,
                    displayMode: displayMode
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .accessibilityIdentifier("weekly-nutrition-hero-widget")
    }

    /// Day labels header row aligned with cells
    private var dayHeaderRow: some View {
        HStack(spacing: 0) {
            // Day labels aligned with cells
            HStack(spacing: GridLayout.cellSpacing) {
                ForEach(0..<GridLayout.dayCount, id: \.self) { index in
                    Text(dayLabels[index])
                        .font(.system(size: 10, weight: mockData.todayIndex == index ? .bold : .regular))
                        .foregroundColor(mockData.todayIndex == index ? .primary : .secondary)
                        .frame(width: GridLayout.cellWidth)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Mock Data

private struct WeeklyMockData {
    let calories: [Double]
    let protein: [Double]
    let fat: [Double]
    let carbs: [Double]

    let caloriesTarget: Double
    let proteinTarget: Double
    let fatTarget: Double
    let carbsTarget: Double

    let todayIndex: Int

    static var sample: WeeklyMockData {
        // Calculate today's weekday index (0=Monday, 6=Sunday)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        // Convert from Apple's 1=Sunday format to 0=Monday format
        let todayIndex = weekday == 1 ? 6 : weekday - 2

        return WeeklyMockData(
            // Sample consumed values for each day (Mon-Sun)
            // Past days: varied fill (60-100%), today: partial, future: 0
            calories: generateSampleData(
                todayIndex: todayIndex,
                target: 1395,
                minPercent: 0.6,
                maxPercent: 1.0
            ),
            protein: generateSampleData(
                todayIndex: todayIndex,
                target: 113,
                minPercent: 0.65,
                maxPercent: 0.95
            ),
            fat: generateSampleData(
                todayIndex: todayIndex,
                target: 49,
                minPercent: 0.55,
                maxPercent: 0.9
            ),
            carbs: generateSampleData(
                todayIndex: todayIndex,
                target: 125,
                minPercent: 0.7,
                maxPercent: 1.05
            ),
            caloriesTarget: 1395,
            proteinTarget: 113,
            fatTarget: 49,
            carbsTarget: 125,
            todayIndex: todayIndex
        )
    }

    private static func generateSampleData(
        todayIndex: Int,
        target: Double,
        minPercent: Double,
        maxPercent: Double
    ) -> [Double] {
        var values = [Double]()
        for day in 0..<7 {
            if day < todayIndex {
                // Past days: random fill between min and max
                let percent = minPercent + Double.random(in: 0...(maxPercent - minPercent))
                values.append(target * percent)
            } else if day == todayIndex {
                // Today: partial fill (40-60%)
                let percent = 0.4 + Double.random(in: 0...0.2)
                values.append(target * percent)
            } else {
                // Future: empty
                values.append(0)
            }
        }
        return values
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            HeroWidgetContainer(
                pages: [
                    AnyView(WeeklyNutritionHeroWidget())
                ]
            )
        }
        .padding()
    }
    .background(DesignTokens.Colors.groupedBackground)
}
