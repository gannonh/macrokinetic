//
//  DoseDayDetailView.swift
//  JabTracker
//
//  Detail view for showing all doses on a specific date
//

import SwiftUI

/// Detail view that displays all doses for a specific date with full information
struct DoseDayDetailView: View {
  let date: Date
  let doses: [Dose]

  @Environment(\.dismiss) private var dismiss

  private let calendar = Calendar.current

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        if self.doses.isEmpty {
          self.emptyStateView
        } else {
          self.doseListView
        }
      }
      .navigationTitle(self.navigationTitle)
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            self.dismiss()
          }
        }
      }
    }
    .accessibilityIdentifier("dose-day-detail-view")
  }

  // MARK: - Subviews

  private var emptyStateView: some View {
    VStack(spacing: 20) {
      Image(systemName: "calendar.badge.clock")
        .font(.system(size: 60))
        .foregroundColor(.gray)

      VStack(spacing: 8) {
        Text("No doses recorded")
          .font(.headline)
          .fontWeight(.medium)

        Text("No doses were logged for \(self.formattedDate).")
          .font(.body)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    .accessibilityIdentifier("empty-state")
  }

  private var doseListView: some View {
    List {
      Section {
        ForEach(self.sortedDoses, id: \.id) { dose in
          DoseDetailRow(dose: dose)
        }
      } header: {
        HStack {
          Text("Doses for \(self.formattedDate)")
            .font(.headline)
          Spacer()
          Text("\(self.doses.count) dose\(self.doses.count == 1 ? "" : "s")")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
    .listStyle(.insetGrouped)
    .accessibilityIdentifier("dose-list")
  }

  // MARK: - Computed Properties

  private var navigationTitle: String {
    if self.calendar.isDateInToday(self.date) {
      return "Today"
    } else {
      let formatter = DateFormatter()
      formatter.dateFormat = "MMM d"
      return formatter.string(from: self.date)
    }
  }

  private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: self.date)
  }

  private var sortedDoses: [Dose] {
    self.doses.sorted { $0.timestamp < $1.timestamp }
  }
}

// MARK: - Dose Detail Row

/// Individual dose row in the detail view
private struct DoseDetailRow: View {
  let dose: Dose

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        // Time and amount
        VStack(alignment: .leading, spacing: 2) {
          Text(self.timeString)
            .font(.headline)
            .foregroundColor(.primary)

          Text("\(self.dose.amount, specifier: "%.1f") mg")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }

        Spacer()

        // Status indicators
        HStack(spacing: 8) {
          if self.dose.skipped {
            Label("Skipped", systemImage: "xmark.circle.fill")
              .font(.caption)
              .foregroundColor(.orange)
          }

          if self.dose.imageData != nil {
            Image(systemName: "camera.fill")
              .font(.caption)
              .foregroundColor(.blue)
          }
        }
      }

      // Injection site
      if let site = dose.site {
        HStack {
          Image(systemName: "location.circle.fill")
            .foregroundColor(self.siteColor(for: site))
            .font(.caption)

          Text(site)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      // Notes
      if let notes = dose.notes, !notes.isEmpty {
        Text(notes)
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(.top, 4)
      }
    }
    .padding(.vertical, 4)
    .accessibilityIdentifier("dose-detail-row")
  }

  private var timeString: String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: self.dose.timestamp)
  }

  private func siteColor(for site: String) -> Color {
    switch site.lowercased() {
    case "abdomen":
      return .blue
    case "thigh":
      return .green
    case "arm":
      return .purple
    default:
      return .gray
    }
  }
}
