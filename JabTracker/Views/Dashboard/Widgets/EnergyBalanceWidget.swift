//
//  EnergyBalanceWidget.swift
//  JabTracker
//
//  Standard widget showing 7-day energy balance with deficit/surplus display.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftData
import SwiftUI

/// Mock data for energy balance widget - used for previews
struct EnergyBalanceWidgetData {
    let dailyIntake: [Double]  // 7 days of calorie intake
    let dailyBalances: [Double]  // 7 days: negative = deficit, positive = surplus
    let tdee: Double  // Reference line value
    let averageDailyBalance: Int  // Average daily deficit/surplus (signed)
    let isDeficit: Bool

    static let mock = EnergyBalanceWidgetData(
        dailyIntake: [1750, 1700, 1800, 1720, 1680, 1790, 1767],
        dailyBalances: [-250, -300, -200, -280, -320, -210, -233],
        tdee: 2000,
        averageDailyBalance: -256,  // Negative for deficit
        isDeficit: true
    )
}

/// Standard widget displaying 7-day energy balance with deficit/surplus indicator.
struct EnergyBalanceWidget: View {
    @Environment(\.modelContext) private var modelContext

    /// ViewModel for live data - initialized lazily on first access
    @State private var viewModel: EnergyBalanceWidgetViewModel?

    /// Whether to use mock data (for previews)
    private let useMockData: Bool

    var onTap: (() -> Void)?

    /// Whether data is currently loading
    private var isLoading: Bool {
        viewModel?.isLoading ?? (!useMockData && viewModel == nil)
    }

    // MARK: - Initialization

    /// Initialize with live data (default for production)
    init(onTap: (() -> Void)? = nil) {
        self.useMockData = false
        self.onTap = onTap
    }

    /// Initialize with mock data flag (for previews)
    init(useMockData: Bool, onTap: (() -> Void)? = nil) {
        self.useMockData = useMockData
        self.onTap = onTap
    }

    var body: some View {
        WidgetCard(title: nil) {
            VStack(alignment: .leading, spacing: 8) {
                headerSection
                visualizationSection
                valueSection
            }
        } onTap: {
            onTap?()
        }
        .redacted(reason: isLoading ? .placeholder : [])
        .accessibilityIdentifier("energy-balance-widget")
        .task {
            await loadDataIfNeeded()
        }
    }

    // MARK: - Data Loading

    private func loadDataIfNeeded() async {
        guard !useMockData else { return }

        if viewModel == nil {
            let mealLogService = AppServices.shared.mealLogService ?? MealLogService(context: modelContext)
            viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: modelContext)
        }
        await viewModel?.loadData()
    }

    // MARK: - Data Accessors

    private var dailyIntake: [Double] {
        useMockData ? EnergyBalanceWidgetData.mock.dailyIntake : (viewModel?.dailyIntake ?? [])
    }

    private var dailyBalances: [Double] {
        useMockData ? EnergyBalanceWidgetData.mock.dailyBalances : (viewModel?.dailyBalances ?? [])
    }

    private var tdee: Double {
        useMockData ? EnergyBalanceWidgetData.mock.tdee : (viewModel?.tdee ?? 0)
    }

    private var averageDailyBalance: Int {
        useMockData ? EnergyBalanceWidgetData.mock.averageDailyBalance : (viewModel?.averageDailyBalance ?? 0)
    }

    private var isDeficit: Bool {
        useMockData ? EnergyBalanceWidgetData.mock.isDeficit : (viewModel?.isDeficit ?? true)
    }

    private var hasData: Bool {
        useMockData ? true : (viewModel?.hasData ?? false)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Energy Balance")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            Text("Last 7 Days")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var visualizationSection: some View {
        Group {
            if hasData {
                // Bar chart with TDEE reference line
                GeometryReader { geometry in
                    let chartHeight: CGFloat = 30
                    let barSpacing: CGFloat = 4
                    let barWidth = (geometry.size.width - barSpacing * 6) / 7
                    let maxValue = max(tdee * 1.15, dailyIntake.max() ?? tdee)
                    let tdeeY = chartHeight * (1 - tdee / maxValue)

                    ZStack(alignment: .topLeading) {
                        // Intake bars
                        HStack(alignment: .bottom, spacing: barSpacing) {
                            ForEach(0..<min(dailyIntake.count, 7), id: \.self) { index in
                                let intake = dailyIntake[index]
                                let barHeight = chartHeight * (intake / maxValue)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(DesignTokens.Colors.deficit)
                                    .frame(width: barWidth, height: max(barHeight, 2))
                            }
                        }
                        .frame(height: chartHeight, alignment: .bottom)

                        // TDEE reference line (dashed orange)
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: tdeeY))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: tdeeY))
                        }
                        .stroke(
                            DesignTokens.Colors.expenditure,
                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                        )
                    }
                }
                .frame(height: 30)
            } else {
                // Empty state - placeholder bars
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DesignTokens.Colors.inactive.opacity(0.3))
                            .frame(height: 14)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 30)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 30)
    }

    private var valueSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if hasData {
                // Show signed value (negative for deficit)
                Text("\(averageDailyBalance)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("kcal/day")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("--")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Text("kcal/day")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - DashboardWidget Conformance

extension EnergyBalanceWidget: DashboardWidget {
    var id: String { "energy-balance-standard" }
    var title: String { "Energy Balance" }
    var content: some View { body }
}

// MARK: - Preview

#Preview("Deficit") {
    VStack(spacing: 16) {
        EnergyBalanceWidget(useMockData: true)
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}

#Preview("Empty State") {
    VStack(spacing: 16) {
        EnergyBalanceWidget(useMockData: false)
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}
