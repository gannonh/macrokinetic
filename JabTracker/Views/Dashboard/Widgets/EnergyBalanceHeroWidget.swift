//
//  EnergyBalanceHeroWidget.swift
//  JabTracker
//
//  Energy balance hero widget showing 30-day calorie intake bar chart with
//  expenditure/targets reference line and summary equation.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftData
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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.selectedHeroPageIndex) private var selectedPageIndex

    /// This widget's page index in the carousel
    private let pageIndex = 2

    /// ViewModel for live data - initialized lazily on first access
    @State private var viewModel: EnergyBalanceHeroViewModel?

    /// Animation state for "grow in" effect
    @State private var isAnimated = false

    /// Whether to use mock data (for previews)
    private let useMockData: Bool

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
            }
            .onChange(of: selectedPageIndex) { _, newIndex in
                // Animate when this page becomes selected (only once)
                guard newIndex == pageIndex, !isAnimated else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        isAnimated = true
                    }
                }
            }
    }

    var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            // Bar chart with reference line
            energyBalanceChart
                .frame(height: 140)

            // "Last 30 Days" label - right aligned
            HStack {
                Spacer()
                Text("Last 30 Days")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            // Summary equation row - closer to segment control
            summaryEquationRow

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityIdentifier("energy-balance-hero-widget")
    }

    // MARK: - Data Loading

    private func loadDataIfNeeded() async {
        guard !useMockData else { return }

        if viewModel == nil {
            let mealLogService = AppServices.shared.mealLogService ?? MealLogService(context: modelContext)
            viewModel = EnergyBalanceHeroViewModel(mealLogService: mealLogService, context: modelContext)
        }
        await viewModel?.loadData()
    }

    // MARK: - Data Accessors

    private var dailyCalories: [DayCalories] {
        if useMockData {
            return EnergyBalanceMockData.sample.dailyCalories
        }
        return viewModel?.dailyCalories ?? []
    }

    private var averageExpenditure: Double {
        useMockData ? EnergyBalanceMockData.sample.averageExpenditure : (viewModel?.averageExpenditure ?? 2000)
    }

    private var averageTargets: Double {
        useMockData ? EnergyBalanceMockData.sample.averageTargets : (viewModel?.averageTargets ?? 1800)
    }

    private var totalNutrition: Int {
        useMockData ? EnergyBalanceMockData.sample.totalNutrition : (viewModel?.totalNutrition ?? 0)
    }

    /// Maximum Y value for fixed chart scale (prevents axis animation)
    private var chartYMax: Double {
        let maxCalories = dailyCalories.map(\.value).max() ?? 0
        let maxReference = max(averageExpenditure, averageTargets)
        // Use 10% headroom above the larger of max calories or reference line
        // Minimum of 100 to prevent 0...0 domain when data is empty
        return max(max(maxCalories, maxReference) * 1.1, 100)
    }

    // MARK: - Bar Chart (Custom SwiftUI for reliable animation)

    private var energyBalanceChart: some View {
        let referenceValue =
            displayMode == .expenditure
            ? averageExpenditure
            : averageTargets

        // Calculate reference line position as percentage of max
        let baseReferencePercent = chartYMax > 0 ? referenceValue / chartYMax : 0
        let referencePercent = baseReferencePercent * (isAnimated ? 1.0 : 0.0)

        return GeometryReader { geometry in
            let barWidth: CGFloat = 6
            let spacing: CGFloat =
                (geometry.size.width - barWidth * CGFloat(dailyCalories.count))
                / CGFloat(max(1, dailyCalories.count - 1))

            ZStack(alignment: .bottom) {
                // Bars
                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(dailyCalories) { day in
                        let baseHeightPercent = chartYMax > 0 ? day.value / chartYMax : 0
                        let heightPercent = baseHeightPercent * (isAnimated ? 1.0 : 0.0)
                        let barHeight = geometry.size.height * heightPercent

                        RoundedRectangle(cornerRadius: 2)
                            .fill(DesignTokens.Colors.calories)
                            .frame(width: barWidth, height: max(0, barHeight))
                            .animation(.easeOut(duration: 0.6), value: heightPercent)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // Reference line (dotted)
                let lineY = geometry.size.height * (1 - referencePercent)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: lineY))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: lineY))
                }
                .stroke(
                    displayMode == .expenditure
                        ? DesignTokens.Colors.expenditure
                        : DesignTokens.Colors.targets,
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                )
                .animation(.easeOut(duration: 0.6), value: referencePercent)
            }
        }
        .accessibilityLabel("Energy balance chart showing last 30 days")
    }

    // MARK: - Summary Equation Row

    private var summaryEquationRow: some View {
        // All values are daily averages
        let avgNutrition = totalNutrition / 30
        let avgReference =
            displayMode == .expenditure
            ? Int(averageExpenditure)
            : Int(averageTargets)
        let avgDifference = avgNutrition - avgReference

        return HStack(spacing: 0) {
            // Nutrition value (daily average)
            summaryValue(
                value: avgNutrition,
                label: "Nutrition",
                icon: "chart.bar.fill",
                color: DesignTokens.Colors.calories
            )

            // Minus operator
            Text("-")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)

            // Expenditure/Targets value (daily average)
            summaryValue(
                value: avgReference,
                label: displayMode == .expenditure ? "Expenditure" : "Targets",
                icon: "checkmark",
                color: displayMode == .expenditure ? DesignTokens.Colors.expenditure : DesignTokens.Colors.targets
            )

            // Equals operator
            Text("=")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)

            // Difference value (daily average)
            differenceValue(value: avgDifference)
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
    // Uses DayCalories from EnergyBalanceHeroViewModel
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
            EnergyBalanceHeroWidget(useMockData: true)
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
                    AnyView(WeeklyNutritionHeroWidget(useMockData: true)),
                    AnyView(DailyNutritionHeroWidget(useMockData: true)),
                    AnyView(EnergyBalanceHeroWidget(useMockData: true)),
                ]
            )
        }
        .padding()
    }
    .background(DesignTokens.Colors.groupedBackground)
}
