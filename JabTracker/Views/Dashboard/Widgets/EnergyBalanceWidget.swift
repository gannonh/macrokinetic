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
    let dailyBalances: [Double]  // 7 days: negative = deficit, positive = surplus
    let netBalance: Int  // Total deficit/surplus over period
    let isDeficit: Bool

    static let mock = EnergyBalanceWidgetData(
        dailyBalances: [-250, -300, -200, -280, -320, -210, -233],
        netBalance: 1793,
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

    private var dailyBalances: [Double] {
        useMockData ? EnergyBalanceWidgetData.mock.dailyBalances : (viewModel?.dailyBalances ?? [])
    }

    private var netBalance: Int {
        useMockData ? EnergyBalanceWidgetData.mock.netBalance : (viewModel?.netBalance ?? 0)
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
        VStack(alignment: .leading, spacing: 6) {
            if hasData {
                // Orange dots representing daily balance (intake vs expenditure)
                HStack(spacing: 6) {
                    ForEach(0..<min(dailyBalances.count, 7), id: \.self) { _ in
                        Circle()
                            .fill(DesignTokens.Colors.expenditure)
                            .frame(width: 8, height: 8)
                    }
                }

                // Colored bar showing net deficit/surplus
                let barColor = isDeficit ? DesignTokens.Colors.deficit : DesignTokens.Colors.success
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor)
                    .frame(width: 40, height: 6)
            } else {
                // Empty state
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { _ in
                        Circle()
                            .fill(DesignTokens.Colors.inactive.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignTokens.Colors.inactive.opacity(0.3))
                    .frame(width: 40, height: 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 30)
    }

    private var valueSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if hasData {
                Text("\(netBalance)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("kcal \(isDeficit ? "deficit" : "surplus")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("--")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                Text("kcal")
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
