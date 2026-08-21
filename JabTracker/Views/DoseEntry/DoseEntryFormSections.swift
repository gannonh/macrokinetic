//
//  DoseEntryFormSections.swift
//  JabTracker
//
//  Form section views for dose entry sheet to maintain separation of concerns
//  Contains medication selection, dose details, timing, and additional info sections
//

import PhotosUI
import SwiftData
import SwiftUI

/// Contains form section views for dose entry to reduce main view complexity
enum DoseEntryFormSections {
    // MARK: - Medication Section

    struct MedicationSection: View {
        @Binding var selectedMedicationProfile: MedicationProfile?
        let medicationProfiles: [MedicationProfile]
        let errorMessage: String?
        let serviceError: Error?

        var body: some View {
            Section {
                Picker("Medication", selection: self.$selectedMedicationProfile) {
                    ForEach(self.medicationProfiles, id: \.id) { profile in
                        Text("\(profile.displayName) (\(profile.currentDose, specifier: "%.2f") mg)")
                            .tag(profile as MedicationProfile?)
                    }
                }
                .accessibilityIdentifier("dose-entry-medication-picker")

                if self.medicationProfiles.isEmpty {
                    Text("No medication profiles found")
                        .foregroundColor(.secondary)
                        .italic()
                        .accessibilityIdentifier("no-medications-message")
                }
            } header: {
                Text("Medication")
            } footer: {
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .accessibilityIdentifier("dose-entry-error")
                }

                if let serviceError {
                    Text(serviceError.localizedDescription)
                        .foregroundColor(.red)
                        .accessibilityIdentifier("dose-service-error")
                }
            }
        }
    }

    // MARK: - Dose Details Section

    struct DoseDetailsSection: View {
        @Binding var doseAmount: Double
        @Binding var selectedInjectionSite: String
        @Binding var isSkipped: Bool
        @Binding var dosePhotoData: Data?
        @Binding var selectedPhotoItem: PhotosPickerItem?

        var body: some View {
            Section {
                // Dose Amount
                HStack {
                    Text("Amount")
                    Spacer()
                    TextField(
                        "Amount", value: self.$doseAmount, format: .number.precision(.fractionLength(2))
                    )
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("dose-entry-amount-field")
                    Text("mg")
                        .foregroundColor(.secondary)
                }

                // Injection Site
                if !self.isSkipped {
                    Picker("Injection Site", selection: self.$selectedInjectionSite) {
                        ForEach(DoseDefaults.allInjectionSites, id: \.self) { site in
                            Text(site).tag(site)
                        }
                    }
                    .accessibilityIdentifier("dose-entry-site-picker")
                }

                // Skipped toggle
                Toggle("Missed/Skipped Dose", isOn: self.$isSkipped)
                    .accessibilityIdentifier("dose-entry-skipped-toggle")
                    .onChange(of: self.isSkipped) { _, skipped in
                        if skipped {
                            self.selectedInjectionSite = ""
                            self.dosePhotoData = nil
                            self.selectedPhotoItem = nil
                        }
                    }
            } header: {
                Text("Dose Details")
            } footer: {
                if self.isSkipped {
                    Text(
                        "Skipped doses are recorded for tracking but don't affect concentration calculations"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("skipped-dose-explanation")
                }
            }
        }
    }

    // MARK: - Timing Section

    struct TimingSection: View {
        @Binding var doseTime: Date

        var body: some View {
            Section {
                DatePicker(
                    "Date & Time",
                    selection: self.$doseTime,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .accessibilityIdentifier("dose-entry-datetime-picker")
            } header: {
                Text("Timing")
            }
        }
    }

    // MARK: - Additional Info Section

    struct AdditionalInfoSection: View {
        @Binding var notes: String

        var body: some View {
            Section {
                TextField("Notes (Optional)", text: self.$notes, axis: .vertical)
                    .lineLimit(3...6)
                    .accessibilityIdentifier("dose-entry-notes")
            } header: {
                Text("Additional Information")
            }
        }
    }
}
