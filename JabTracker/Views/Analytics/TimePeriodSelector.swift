//
//  TimePeriodSelector.swift
//  JabTracker
//

import SwiftUI

/// A segmented control for selecting time periods in chart displays
/// Provides accessible time period selection with proper visual feedback
struct TimePeriodSelector: View {
  @Binding var selectedPeriod: ChartDataProcessor.TimePeriod

  init(selectedPeriod: Binding<ChartDataProcessor.TimePeriod>) {
    self._selectedPeriod = selectedPeriod
  }

  var body: some View {
    HStack(spacing: 0) {
      ForEach(timePeriods, id: \.self) { period in
        Button {
          selectedPeriod = period
        } label: {
          Text(period.displayName)
            .font(.caption.weight(.medium))
            .foregroundColor(selectedPeriod == period ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(selectedPeriod == period ? Color.blue : Color.clear)
            )
        }
        .accessibilityIdentifier("\(period.accessibilityIdentifier)-button")
        .accessibilityLabel("\(period.displayName) time period")
        .accessibilityHint("Tap to change chart to \(period.displayName) view")
        .accessibilityAddTraits(selectedPeriod == period ? [.isSelected] : [])
      }
    }
    .padding(4)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.systemGray6))
    )
    .accessibilityElement(children: .contain)
    .accessibilityIdentifier("time-period-selector")
    .accessibilityLabel("Time period selector")
    .accessibilityHint("Select time period for chart display")
  }

  private var timePeriods: [ChartDataProcessor.TimePeriod] {
    [.last7Days, .last30Days, .last90Days, .lastYear]
  }
}

// MARK: - ChartDataProcessor.TimePeriod Extensions

extension ChartDataProcessor.TimePeriod {

  /// Display name for UI presentation
  var displayName: String {
    switch self {
    case .last7Days:
      return "7d"
    case .last30Days:
      return "30d"
    case .last90Days:
      return "90d"
    case .lastYear:
      return "1y"
    case .all:
      return "All"
    }
  }

  /// Accessibility identifier for UI testing
  var accessibilityIdentifier: String {
    switch self {
    case .last7Days:
      return "7d"
    case .last30Days:
      return "30d"
    case .last90Days:
      return "90d"
    case .lastYear:
      return "1y"
    case .all:
      return "all"
    }
  }
}

// MARK: - Preview

#Preview {
  @Previewable @State var selectedPeriod: ChartDataProcessor.TimePeriod = .last30Days

  return VStack {
    TimePeriodSelector(selectedPeriod: $selectedPeriod)

    Text("Selected: \(selectedPeriod.displayName)")
      .padding()
  }
  .padding()
}
