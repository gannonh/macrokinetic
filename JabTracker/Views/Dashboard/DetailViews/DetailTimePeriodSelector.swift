//
//  DetailTimePeriodSelector.swift
//  JabTracker
//
//  Reusable time period selector component for detail views.
//  Part of v0.7.0 Dashboard Widget UX milestone (Phase 33).
//

import SwiftUI

// MARK: - Detail Time Period Selector

/// Reusable time period selector for detail views.
/// Includes time period buttons (1W, 1M, 3M, 6M, 1Y, All) and optional detailed date toggle (D button).
struct DetailTimePeriodSelector: View {
    @Binding var selectedPeriod: DetailTimePeriod
    @Binding var showDetailedDates: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Time period buttons
            ForEach(DetailTimePeriod.allCases) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.displayName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(selectedPeriod == period ? .white : .primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedPeriod == period ? DesignTokens.Colors.accent : Color.clear)
                        )
                }
                .accessibilityIdentifier("\(period.rawValue.lowercased())-period-button")
                .accessibilityLabel(period.accessibilityLabel)
                .accessibilityAddTraits(selectedPeriod == period ? [.isSelected] : [])
            }

            Spacer()

            // Detail toggle (D button)
            Button {
                showDetailedDates.toggle()
            } label: {
                Text("D")
                    .font(.caption.weight(.medium))
                    .foregroundColor(showDetailedDates ? .white : .primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(showDetailedDates ? DesignTokens.Colors.accent : Color.clear)
                    )
            }
            .accessibilityIdentifier("detail-toggle-button")
            .accessibilityLabel("Toggle detailed dates")
            .accessibilityAddTraits(showDetailedDates ? [.isSelected] : [])
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.secondaryBackground)
        )
        .accessibilityIdentifier("detail-time-period-selector")
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedPeriod: DetailTimePeriod = .oneYear
        @State private var showDetailedDates = false

        var body: some View {
            VStack(spacing: 20) {
                DetailTimePeriodSelector(
                    selectedPeriod: $selectedPeriod,
                    showDetailedDates: $showDetailedDates
                )

                Text("Selected: \(selectedPeriod.displayName)")
                Text("Detailed: \(showDetailedDates ? "Yes" : "No")")
            }
            .padding()
            .background(DesignTokens.Colors.groupedBackground)
        }
    }

    return PreviewWrapper()
}
