//
//  GoalProgressWidget.swift
//  JabTracker
//
//  Standard widget showing daily goal progress with progress bar.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftData
import SwiftUI

/// Mock data for goal progress widget - used for previews
struct GoalProgressWidgetData {
    let progressPercentage: Double  // 0.0 to 1.0
    let targetPercentage: Double  // Where the target marker sits (usually 1.0)

    var displayPercentage: Int {
        Int(progressPercentage * 100)
    }

    static let mock = GoalProgressWidgetData(
        progressPercentage: 0.20,
        targetPercentage: 1.0
    )
}

/// Standard widget displaying daily goal progress with progress bar.
struct GoalProgressWidget: View {
    @Environment(\.modelContext) private var modelContext

    /// ViewModel for live data - initialized lazily on first access
    @State private var viewModel: GoalProgressWidgetViewModel?

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
                progressBarSection
                valueSection
            }
        } onTap: {
            onTap?()
        }
        .redacted(reason: isLoading ? .placeholder : [])
        .accessibilityIdentifier("goal-progress-widget")
        .task {
            await loadDataIfNeeded()
        }
    }

    // MARK: - Data Loading

    private func loadDataIfNeeded() async {
        guard !useMockData else { return }

        if viewModel == nil {
            let mealLogService = AppServices.shared.mealLogService ?? MealLogService(context: modelContext)
            viewModel = GoalProgressWidgetViewModel(mealLogService: mealLogService, context: modelContext)
        }
        await viewModel?.loadData()
    }

    // MARK: - Data Accessors

    private var progressPercentage: Double {
        useMockData ? GoalProgressWidgetData.mock.progressPercentage : (viewModel?.progressPercentage ?? 0)
    }

    private var targetPercentage: Double {
        useMockData ? GoalProgressWidgetData.mock.targetPercentage : (viewModel?.targetPercentage ?? 1.0)
    }

    private var displayPercentage: Int {
        useMockData ? GoalProgressWidgetData.mock.displayPercentage : (viewModel?.displayPercentage ?? 0)
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Goal Progress")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            Text("Today")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var progressBarSection: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let progressWidth = width * min(progressPercentage, 1.0)
            let targetPosition = width * min(targetPercentage, 1.0) - 2  // -2 for marker width offset

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.inactive)
                    .frame(height: 12)

                // Progress fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.Colors.success)
                    .frame(width: max(progressWidth, 0), height: 12)

                // Target marker (white vertical line)
                Rectangle()
                    .fill(DesignTokens.Colors.background)
                    .frame(width: 3, height: 16)
                    .offset(x: max(targetPosition, 0))
            }
        }
        .frame(height: 30)
    }

    private var valueSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(displayPercentage)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text("%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - DashboardWidget Conformance

extension GoalProgressWidget: DashboardWidget {
    var id: String { "goal-progress" }
    var title: String { "Goal Progress" }
    var content: some View { body }
}

// MARK: - Preview

#Preview("With Mock Data") {
    VStack(spacing: 16) {
        GoalProgressWidget(useMockData: true)
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}

#Preview("Empty State") {
    VStack(spacing: 16) {
        GoalProgressWidget(useMockData: false)
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}
