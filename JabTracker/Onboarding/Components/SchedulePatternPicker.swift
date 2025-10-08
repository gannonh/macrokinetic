//
//  SchedulePatternPicker.swift
//  JabTracker
//
//  Schedule pattern selection component for onboarding
//

import SwiftUI

/// Picker component for selecting medication dosing schedule pattern
///
/// Displays available schedule patterns as cards and handles selection state.
/// Notifies parent view when pattern changes for concentration preview updates.
struct SchedulePatternPicker: View {
    @Binding var selectedPattern: SchedulePatternType
    let onPatternChange: (SchedulePatternType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Schedule")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ForEach([SchedulePatternType.weekly, .splitDose, .custom], id: \.self) { pattern in
                    SchedulePatternCard(
                        pattern: pattern,
                        isSelected: selectedPattern == pattern,
                        onSelect: {
                            selectedPattern = pattern
                            onPatternChange(pattern)
                        }
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Schedule pattern picker")
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedPattern: SchedulePatternType = .weekly

    SchedulePatternPicker(
        selectedPattern: $selectedPattern,
        onPatternChange: { pattern in
            print("Pattern changed to: \(pattern)")
        }
    )
    .padding()
}
