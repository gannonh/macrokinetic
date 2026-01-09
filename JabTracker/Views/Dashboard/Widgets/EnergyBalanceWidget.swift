//
//  EnergyBalanceWidget.swift
//  JabTracker
//
//  Standard widget showing 7-day energy balance with deficit/surplus display.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftUI

/// Mock data for energy balance widget - will be replaced with live data in Phase 34
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
    let data: EnergyBalanceWidgetData
    var onTap: (() -> Void)?

    init(data: EnergyBalanceWidgetData = .mock, onTap: (() -> Void)? = nil) {
        self.data = data
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
            // Orange dots representing daily balance (intake vs expenditure)
            HStack(spacing: 6) {
                ForEach(0..<data.dailyBalances.count, id: \.self) { _ in
                    Circle()
                        .fill(DesignTokens.Colors.expenditure)
                        .frame(width: 8, height: 8)
                }
                Spacer()
            }

            // Blue bar showing net deficit
            let barColor = data.isDeficit ? DesignTokens.Colors.deficit : DesignTokens.Colors.success
            RoundedRectangle(cornerRadius: 2)
                .fill(barColor)
                .frame(width: 40, height: 6)
        }
        .frame(height: 30)
    }

    private var valueSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(data.netBalance)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text("kcal \(data.isDeficit ? "deficit" : "surplus")")
                .font(.caption)
                .foregroundColor(.secondary)
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

#Preview {
    VStack(spacing: 16) {
        EnergyBalanceWidget()
        EnergyBalanceWidget(
            data: EnergyBalanceWidgetData(
                dailyBalances: [150, 200, 100, 180, 220, 190, 160],
                netBalance: 1200,
                isDeficit: false
            ))
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}
