//
//  HistorySection.swift
//  JabTracker
//
//  History section component extracted from ShotsView.
//  Displays dose history in list or calendar format.
//

import SwiftUI

/// Mode for displaying dose history
enum HistoryMode: String, CaseIterable {
    case list = "List"
    case calendar = "Calendar"

    var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .calendar: return "calendar"
        }
    }
}

/// Reusable history section displaying dose history in list or calendar format
struct HistorySection: View {

    // MARK: - Properties

    /// Selected view mode (list or calendar)
    let selectedMode: HistoryMode

    // MARK: - Body

    var body: some View {
        Group {
            switch selectedMode {
            case .list:
                DoseHistoryView()
                    .accessibilityIdentifier("dose-history-container")
            case .calendar:
                DoseCalendarView()
                    .accessibilityIdentifier("dose-calendar-container")
            }
        }
        .accessibilityIdentifier("history-section")
    }
}

// MARK: - Preview

#Preview("List Mode") {
    HistorySection(selectedMode: .list)
        .modelContainer(DataController.preview.container)
}

#Preview("Calendar Mode") {
    HistorySection(selectedMode: .calendar)
        .modelContainer(DataController.preview.container)
}
