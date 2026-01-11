//
//  ExpenditureWidget.swift
//  JabTracker
//
//  Standard widget showing TDEE expenditure with bar visualization.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftData
import SwiftUI

/// Mock data for expenditure widget - used for previews
struct ExpenditureWidgetData {
    let dailyValues: [Double]  // 7 days of expenditure values
    let averageKcal: Int

    static let mock = ExpenditureWidgetData(
        dailyValues: [1850, 2100, 1920, 1780, 2050, 1900, 1650],
        averageKcal: 1893
    )
}

/// Standard widget displaying TDEE calorie expenditure.
struct ExpenditureWidget: View {
    @Environment(\.modelContext) private var modelContext

    /// ViewModel for live data - initialized lazily on first access
    @State private var viewModel: ExpenditureWidgetViewModel?

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
        .accessibilityIdentifier("expenditure-widget")
        .task {
            await loadDataIfNeeded()
        }
    }

    // MARK: - Data Loading

    private func loadDataIfNeeded() async {
        guard !useMockData else { return }

        if viewModel == nil {
            viewModel = ExpenditureWidgetViewModel(context: modelContext)
        }
        await viewModel?.loadData()
    }

    // MARK: - Data Accessors

    private var tdeeValue: Int {
        if useMockData {
            return ExpenditureWidgetData.mock.averageKcal
        }
        return Int(viewModel?.tdee ?? 0)
    }

    private var hasData: Bool {
        useMockData ? true : (viewModel?.hasData ?? false)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Expenditure")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            Text("Daily TDEE")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var visualizationSection: some View {
        // Simple indicator bar based on TDEE range
        HStack(spacing: 4) {
            if hasData {
                // Create 7 equal bars as a simple visualization
                ForEach(0..<7, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.Colors.expenditure)
                        .frame(width: 20, height: 14)
                }
            } else {
                // Empty state
                ForEach(0..<7, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.Colors.inactive.opacity(0.3))
                        .frame(width: 20, height: 14)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 30)
    }

    private var valueSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if hasData {
                Text("\(tdeeValue)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("kcal")
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

extension ExpenditureWidget: DashboardWidget {
    var id: String { "expenditure" }
    var title: String { "Expenditure" }
    var content: some View { body }
}

// MARK: - Preview

#Preview("With Mock Data") {
    VStack(spacing: 16) {
        ExpenditureWidget(useMockData: true)
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}

#Preview("Empty State") {
    VStack(spacing: 16) {
        ExpenditureWidget(useMockData: false)
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}
