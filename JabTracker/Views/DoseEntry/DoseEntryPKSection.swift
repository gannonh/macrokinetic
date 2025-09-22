//
//  DoseEntryPKSection.swift
//  JabTracker
//
//  Pharmacokinetics integration section for dose entry sheet
//  Shows impact preview and concentration calculation information
//

import SwiftUI

/// Pharmacokinetics impact section showing dose effects and calculations
struct DoseEntryPKSection: View {
  let medicationProfile: MedicationProfile
  let isSkipped: Bool

  var body: some View {
    Section {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Image(systemName: "chart.line.uptrend.xyaxis")
            .foregroundColor(.blue)
          Text("Pharmacokinetics Impact")
            .font(.subheadline)
            .fontWeight(.medium)
          Spacer()
        }

        self.impactDetails
      }
    } header: {
      Text("Impact Preview")
    }
    .accessibilityIdentifier("pk-impact-section")
  }

  @ViewBuilder
  private var impactDetails: some View {
    if !self.isSkipped, let medication = medicationProfile.medication {
      VStack(alignment: .leading, spacing: 6) {
        Text("• Peak concentration in ~\(Int(medication.peakTimeHours)) hours")
        Text("• Calculations will update dashboard automatically")
        Text("• Half-life: \(medication.halfLifeDays, specifier: "%.1f") days")
      }
      .font(.caption)
      .foregroundColor(.secondary)
    } else if self.isSkipped {
      Text("Skipped doses don't affect concentration calculations")
        .font(.caption)
        .foregroundColor(.secondary)
        .italic()
    }
  }
}
