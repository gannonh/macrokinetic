//
//  EnergyBalanceHeroWidget.swift
//  JabTracker
//
//  Energy balance hero widget showing 30-day calorie intake bar chart with
//  expenditure/targets reference line and summary equation.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import Charts
import SwiftUI

// MARK: - EnergyDisplayMode

/// Display mode toggle for energy balance widget (Expenditure vs Targets)
enum EnergyDisplayMode: String, CaseIterable {
    case expenditure = "Expenditure"
    case targets = "Targets"
}

// MARK: - EnergyBalanceHeroWidget

/// Hero widget displaying 30-day energy balance with bar chart and reference line
struct EnergyBalanceHeroWidget: View, DashboardWidget {
    let id = "energy-balance"
    let title = "Energy Balance"

    @Environment(\.energyDisplayMode) private var displayMode

    // MARK: - Mock Data

    private let mockData = EnergyBalanceMockData.sample

    var body: some View {
        content
    }

    var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            // Bar chart with reference line
            energyBalanceChart
                .frame(height: 100)

            // "Last 30 Days" label - right aligned
            HStack {
                Spacer()
                Text("Last 30 Days")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // Summary equation row
            summaryEquationRow

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityIdentifier("energy-balance-hero-widget")
    }

    // MARK: - Bar Chart

    private var energyBalanceChart: some View {
        let referenceValue =
            displayMode == .expenditure
            ? mockData.averageExpenditure
            : mockData.averageTargets

        return Chart {
            // Blue bars for daily calories
            ForEach(mockData.dailyCalories) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Calories", day.value)
                )
                .foregroundStyle(DesignTokens.Colors.calories)
                .cornerRadius(2)
            }

            // Reference line (dotted) for expenditure/target
            RuleMark(y: .value("Reference", referenceValue))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                .foregroundStyle(displayMode == .expenditure ? Color.orange : Color.yellow)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .accessibilityLabel("Energy balance chart showing last 30 days")
    }

    // MARK: - Summary Equation Row

    private var summaryEquationRow: some View {
        let referenceValue =
            displayMode == .expenditure
            ? mockData.averageExpenditure
            : mockData.averageTargets
        let difference = mockData.totalNutrition - Int(referenceValue * 30)

        return HStack(spacing: 0) {
            // Nutrition value
            summaryValue(
                value: mockData.totalNutrition,
                label: "Nutrition",
                icon: "chart.bar.fill",
                color: DesignTokens.Colors.calories
            )

            // Minus operator
            Text("–")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)

            // Expenditure/Targets value
            summaryValue(
                value: Int(referenceValue * 30),
                label: displayMode == .expenditure ? "Expenditure" : "Targets",
                icon: "checkmark",
                color: displayMode == .expenditure ? Color.orange : Color.yellow
            )

            // Equals operator
            Text("=")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)

            // Difference value
            differenceValue(value: difference)
        }
    }

    private func summaryValue(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            HStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func differenceValue(value: Int) -> some View {
        let color: Color = value < 0 ? DesignTokens.Colors.success : DesignTokens.Colors.danger

        return VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text("Difference")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

}

// MARK: - Mock Data

struct EnergyBalanceMockData {
    struct DayCalories: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    let dailyCalories: [DayCalories]
    let averageExpenditure: Double
    let averageTargets: Double
    let totalNutrition: Int

    static var sample: EnergyBalanceMockData {
        // Generate 30 days of mock data
        let calendar = Calendar.current
        let today = Date()

        var dailyData: [DayCalories] = []

        for daysAgo in (0..<30).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                continue
            }

            // Generate varied calorie intake (500-1500 range)
            // More recent days have higher values to simulate recent activity
            let baseValue: Double
            if daysAgo < 7 {
                // Last week - more varied with some higher values
                baseValue = Double.random(in: 600...1400)
            } else if daysAgo < 14 {
                // 2 weeks ago - moderate values
                baseValue = Double.random(in: 500...1200)
            } else {
                // Older - lower values (less tracking)
                baseValue = Double.random(in: 400...900)
            }

            dailyData.append(DayCalories(date: date, value: baseValue))
        }

        // Calculate totals
        let totalCalories = dailyData.reduce(0) { $0 + Int($1.value) }

        return EnergyBalanceMockData(
            dailyCalories: dailyData,
            averageExpenditure: 1893,  // Average daily expenditure
            averageTargets: 1429,  // Average daily target (deficit goal)
            totalNutrition: totalCalories
        )
    }
}

// MARK: - Preview

#Preview("Expenditure Mode") {
    ScrollView {
        VStack(spacing: 16) {
            EnergyBalanceHeroWidget()
                .cardStyle()
        }
        .padding()
    }
    .background(DesignTokens.Colors.groupedBackground)
}

#Preview("In Carousel") {
    ScrollView {
        VStack(spacing: 16) {
            HeroWidgetContainer(
                pages: [
                    AnyView(WeeklyNutritionHeroWidget()),
                    AnyView(DailyNutritionHeroWidget()),
                    AnyView(EnergyBalanceHeroWidget()),
                ]
            )
        }
        .padding()
    }
    .background(DesignTokens.Colors.groupedBackground)
}
