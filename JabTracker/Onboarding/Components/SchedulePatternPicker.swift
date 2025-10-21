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
/// Filters patterns based on medication frequency (weekly meds can split, daily can't).
struct SchedulePatternPicker: View {
    let medication: Medication
    @Binding var selectedPattern: SchedulePatternType
    let onPatternChange: (SchedulePatternType) -> Void

    /// Available patterns filtered by medication frequency
    var availablePatterns: [SchedulePatternType] {
        switch medication.frequency {
        case .daily:
            return [.daily]  // Daily meds use daily pattern
        case .weekly:
            return [.weekly, .splitDose]  // Weekly meds can split
        }
        // Note: .custom is removed from all UIs
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Your Schedule")
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 12) {
                ForEach(availablePatterns, id: \.self) { pattern in
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
        medication: .semaglutide,
        selectedPattern: $selectedPattern,
        onPatternChange: { pattern in
            print("Pattern changed to: \(pattern)")
        }
    )
    .padding()
}
