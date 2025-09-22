//
//  HistoryView.swift
//  JabTracker
//
//  Comprehensive history view with integrated list and calendar modes
//  Features segmented control to toggle between list and calendar views
//

import SwiftUI

/// Main history view that integrates list and calendar viewing modes
/// Provides a segmented control to switch between different data presentations
struct HistoryView: View {
  // MARK: - View Modes

  /// Available view modes for history display
  enum ViewMode: String, CaseIterable {
    case list = "List"
    case calendar = "Calendar"

    var systemImage: String {
      switch self {
      case .list:
        return "list.bullet"
      case .calendar:
        return "calendar"
      }
    }
  }

  // MARK: - State

  /// Currently selected view mode
  @State private var selectedViewMode: ViewMode = .list

  // MARK: - Body

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // View mode selector
        self.viewModePickerView

        // Content based on selected mode
        self.contentView
      }
      .navigationTitle("History")
      .navigationBarTitleDisplayMode(.large)
    }
  }

  // MARK: - Subviews

  /// Segmented picker for switching between list and calendar views
  private var viewModePickerView: some View {
    Picker("View Mode", selection: self.$selectedViewMode) {
      ForEach(ViewMode.allCases, id: \.self) { mode in
        Label(mode.rawValue, systemImage: mode.systemImage)
          .tag(mode)
          .accessibilityIdentifier("history-\(mode.rawValue.lowercased())-toggle")
      }
    }
    .pickerStyle(.segmented)
    .padding(.horizontal)
    .padding(.vertical, 8)
    .accessibilityIdentifier("history-view-mode-picker")
  }

  /// Main content view that switches based on selected mode
  private var contentView: some View {
    Group {
      switch self.selectedViewMode {
      case .list:
        DoseHistoryView()
          .accessibilityIdentifier("dose-history-list")
      case .calendar:
        DoseCalendarView()
          .accessibilityIdentifier("dose-calendar-view")
      }
    }
    .animation(.easeInOut(duration: 0.3), value: self.selectedViewMode)
  }
}

#Preview {
  NavigationStack {
    HistoryView()
  }
  .modelContainer(DataController.preview.container)
}
