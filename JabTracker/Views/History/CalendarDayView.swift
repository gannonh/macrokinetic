//
//  CalendarDayView.swift
//  JabTracker
//
//  Individual calendar day cell component
//

import SwiftUI

/// Individual calendar day cell that displays dose indicators and handles interaction
struct CalendarDayView: View {
  let date: Date
  let doses: [Dose]
  let isToday: Bool
  let isSelected: Bool
  let onTap: () -> Void

  private let calendar = Calendar.current

  var body: some View {
    Button(action: self.onTap) {
      ZStack {
        // Background
        self.backgroundView

        VStack(spacing: 2) {
          // Day number
          Text("\(self.dayNumber)")
            .font(.system(.body, design: .rounded))
            .fontWeight(self.isToday ? .bold : .medium)
            .foregroundColor(self.textColor)

          // Dose indicators
          self.doseIndicatorView
        }
      }
    }
    .buttonStyle(.plain)
    .frame(height: 44)
    .accessibilityIdentifier("calendar-day-\(self.dayNumber)")
    .accessibilityLabel(self.accessibilityLabel)
    .accessibilityHint(self.accessibilityHint)
  }

  // MARK: - Subviews

  private var backgroundView: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(self.backgroundColor)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(self.borderColor, lineWidth: self.borderWidth)
      )
  }

  private var doseIndicatorView: some View {
    HStack(spacing: 2) {
      if self.doses.isEmpty {
        // No indicator for days without doses
        Color.clear
          .frame(height: 4)
      } else if self.doses.count == 1 {
        // Single dose indicator
        if let firstDose = self.doses.first {
          self.singleDoseIndicator(dose: firstDose)
        }
      } else {
        // Multiple doses indicator
        self.multipleDoseIndicator()
      }
    }
    .frame(height: 4)
  }

  private func singleDoseIndicator(dose: Dose) -> some View {
    Circle()
      .fill(self.indicatorColor(for: dose))
      .frame(width: 6, height: 6)
      .accessibilityIdentifier("calendar-dose-indicator")
  }

  private func multipleDoseIndicator() -> some View {
    HStack(spacing: 1) {
      ForEach(0..<min(self.doses.count, 3), id: \.self) { index in
        Circle()
          .fill(self.indicatorColor(for: self.doses[index]))
          .frame(width: 4, height: 4)
          .accessibilityIdentifier("calendar-dose-indicator")
      }
      if self.doses.count > 3 {
        Text("+")
          .font(.system(size: 8, weight: .bold))
          .foregroundColor(.secondary)
      }
    }
    .accessibilityIdentifier("calendar-multiple-dose-indicator")
  }

  // MARK: - Computed Properties

  private var dayNumber: Int {
    self.calendar.component(.day, from: self.date)
  }

  private var backgroundColor: Color {
    if self.isSelected {
      return .accentColor.opacity(0.2)
    } else if self.isToday {
      return .accentColor.opacity(0.1)
    } else {
      return Color.clear
    }
  }

  private var textColor: Color {
    if self.isSelected {
      return .accentColor
    } else if self.isToday {
      return .accentColor
    } else {
      return .primary
    }
  }

  private var borderColor: Color {
    if self.isSelected {
      return .accentColor
    } else if self.isToday {
      return .accentColor.opacity(0.5)
    } else {
      return Color.clear
    }
  }

  private var borderWidth: CGFloat {
    if self.isSelected {
      return 2
    } else if self.isToday {
      return 1
    } else {
      return 0
    }
  }

  private var accessibilityLabel: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    let dateString = formatter.string(from: self.date)

    var label = dateString
    if self.isToday {
      label += ", today"
    }
    if !self.doses.isEmpty {
      label += ", \(self.doses.count) dose\(self.doses.count == 1 ? "" : "s")"
    }
    return label
  }

  private var accessibilityHint: String {
    if self.doses.isEmpty {
      return "No doses recorded for this date"
    } else {
      return "Tap to view dose details"
    }
  }

  // MARK: - Helper Methods

  private func indicatorColor(for dose: Dose) -> Color {
    if dose.skipped {
      return .orange.opacity(0.7)  // Missed dose indicator
    }

    // Color coding based on injection site
    switch dose.site?.lowercased() {
    case "abdomen":
      return .blue
    case "thigh":
      return .green
    case "arm":
      return .purple
    default:
      return .accentColor  // Default color for unknown or nil sites
    }
  }
}

#Preview {
  let calendar = Calendar.current
  let today = Date()
  let mockDose = Dose(
    amount: 1.0,
    timestamp: today,
    site: "Abdomen",
    notes: "Morning dose",
    imageData: nil,
    skipped: false,
    user: nil,
    medication: nil)

  VStack {
    CalendarDayView(
      date: today,
      doses: [mockDose],
      isToday: true,
      isSelected: false
    ) {
      print("Tapped today")
    }

    CalendarDayView(
      date: calendar.date(byAdding: .day, value: 1, to: today) ?? today,
      doses: [],
      isToday: false,
      isSelected: false
    ) {
      print("Tapped tomorrow")
    }

    CalendarDayView(
      date: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
      doses: [mockDose, mockDose],
      isToday: false,
      isSelected: true
    ) {
      print("Tapped yesterday")
    }
  }
  .padding()
}
