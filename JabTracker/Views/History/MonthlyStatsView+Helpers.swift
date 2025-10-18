//
//  MonthlyStatsView+Helpers.swift
//  JabTracker
//
//  Extension containing helper views for MonthlyStatsView
//

import SwiftUI

// MARK: - Helper Views

extension MonthlyStatsView {
    @ViewBuilder
    func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14, weight: .medium))

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    var adherenceRateBadge: some View {
        Text(self.statistics.adherenceRatePercentage)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(self.adherenceColor.opacity(0.2))
            )
            .foregroundColor(self.adherenceColor)
    }
}
