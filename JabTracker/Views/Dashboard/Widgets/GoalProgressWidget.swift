//
//  GoalProgressWidget.swift
//  JabTracker
//
//  Standard widget showing daily goal progress with progress bar.
//  Part of v0.7.0 Dashboard Widget UX milestone.
//

import SwiftUI

/// Mock data for goal progress widget - will be replaced with live data in Phase 34
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
    let data: GoalProgressWidgetData
    var onTap: (() -> Void)?

    init(data: GoalProgressWidgetData = .mock, onTap: (() -> Void)? = nil) {
        self.data = data
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
        .accessibilityIdentifier("goal-progress-widget")
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
            let progressWidth = width * min(data.progressPercentage, 1.0)
            let targetPosition = width * min(data.targetPercentage, 1.0) - 2  // -2 for marker width offset

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
        .frame(height: 16)
    }

    private var valueSection: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("\(data.displayPercentage)")
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

#Preview {
    VStack(spacing: 16) {
        GoalProgressWidget()
        GoalProgressWidget(
            data: GoalProgressWidgetData(
                progressPercentage: 0.68,
                targetPercentage: 1.0
            ))
        GoalProgressWidget(
            data: GoalProgressWidgetData(
                progressPercentage: 1.0,
                targetPercentage: 1.0
            ))
    }
    .padding()
    .background(DesignTokens.Colors.groupedBackground)
}
