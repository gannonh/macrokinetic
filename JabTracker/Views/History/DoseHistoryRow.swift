//
//  DoseHistoryRow.swift
//  JabTracker
//
//  Individual dose list item component with visual indicators and accessibility support
//

import SwiftUI

struct DoseHistoryRow: View {
    let dose: Dose

    var body: some View {
        HStack(spacing: 12) {
            // Left indicator circle
            self.doseStatusIndicator

            // Main content
            VStack(alignment: .leading, spacing: 4) {
                // Primary row - dose amount and medication
                HStack {
                    self.doseAmountText
                    Spacer()
                    self.timeText
                }

                // Secondary row - medication and injection site
                HStack {
                    self.medicationText
                    Spacer()
                    self.injectionSiteText
                }

                // Notes preview if available
                if let notes = dose.notes, !notes.isEmpty {
                    self.notesPreview(notes)
                }
            }

            // Right indicators
            VStack(spacing: 4) {
                if self.dose.imageData != nil {
                    self.photoIndicator
                }

                if self.dose.skipped {
                    self.skippedIndicator
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())  // Makes entire row tappable
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.accessibilityLabel)
        .accessibilityHint(
            "Swipe left for edit and delete actions, swipe right for duplicate and skip actions")
    }

    // MARK: - Subviews

    private var doseStatusIndicator: some View {
        Circle()
            .fill(
                self.dose.skipped
                    ? AnyShapeStyle(Color.orange.opacity(0.3))
                    : AnyShapeStyle(DesignTokens.Colors.primaryGradient)
            )
            .frame(width: 12, height: 12)
            .accessibilityHidden(true)
    }

    private var doseAmountText: some View {
        Text(self.dose.formattedAmount)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(self.dose.skipped ? .secondary : .primary)
            .accessibilityIdentifier("dose-amount")
    }

    private var timeText: some View {
        Text(self.dose.timestamp, style: .time)
            .font(.caption)
            .foregroundColor(.secondary)
            .accessibilityIdentifier("dose-timestamp")
    }

    private var medicationText: some View {
        Group {
            if let medication = dose.medication {
                Text(medication.displayName)
                    .font(.subheadline)
                    .foregroundColor(self.dose.skipped ? .secondary : .primary)
            } else {
                Text("Unknown Medication")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .accessibilityIdentifier("dose-medication")
    }

    @ViewBuilder
    private var injectionSiteText: some View {
        if let site = dose.site, !site.isEmpty {
            Text(site)
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("injection-site")
        } else {
            Text("No site")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
                .accessibilityIdentifier("injection-site-none")
        }
    }

    private func notesPreview(_ notes: String) -> some View {
        Text(notes.prefix(50) + (notes.count > 50 ? "..." : ""))
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(1)
            .accessibilityIdentifier("dose-notes")
    }

    private var photoIndicator: some View {
        Image(systemName: "camera.fill")
            .font(.caption)
            .foregroundColor(.blue)
            .accessibilityLabel("Photo attached")
            .accessibilityIdentifier("dose-photo-indicator")
    }

    private var skippedIndicator: some View {
        Image(systemName: "xmark.circle.fill")
            .font(.caption)
            .foregroundColor(.orange)
            .accessibilityLabel("Dose skipped")
            .accessibilityIdentifier("skipped-dose-indicator")
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var components: [String] = []

        // Dose amount
        components.append(String(format: "%.2f milligrams", self.dose.amount))

        // Medication
        if let medication = dose.medication {
            components.append(medication.displayName)
        }

        // Time
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        components.append("at \(timeFormatter.string(from: self.dose.timestamp))")

        // Status
        if self.dose.skipped {
            components.append("skipped")
        }

        // Injection site
        if let site = dose.site, !site.isEmpty {
            components.append("injection site \(site)")
        }

        // Photo
        if self.dose.imageData != nil {
            components.append("with photo")
        }

        // Notes
        if let notes = dose.notes, !notes.isEmpty {
            components.append("with notes")
        }

        return components.joined(separator: ", ")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        List {
            // Sample doses for preview
            DoseHistoryRow(dose: previewDose1)
            DoseHistoryRow(dose: previewDose2)
            DoseHistoryRow(dose: previewDose3)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Dose History")
    }
    .modelContainer(DataController.preview.container)
}

// MARK: - Preview Data

private let previewDose1: Dose = {
    let dose = Dose(
        amount: 1.0,
        timestamp: Date(),
        site: "Left thigh",
        notes: "Feeling good today, no side effects",
        skipped: false)
    return dose
}()

private let previewDose2: Dose = {
    let dose = Dose(
        amount: 0.5,
        timestamp: Date().addingTimeInterval(-86400),  // Yesterday
        site: "Right arm",
        notes: nil,
        skipped: true)
    return dose
}()

private let previewDose3: Dose = {
    let dose = Dose(
        amount: 2.4,
        timestamp: Date().addingTimeInterval(-172_800),  // Two days ago
        site: "Abdomen",
        notes: "Quick dose after breakfast",
        imageData: Data(),  // Simulate photo data
        skipped: false)
    return dose
}()
