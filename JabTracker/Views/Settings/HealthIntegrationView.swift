//
//  HealthIntegrationView.swift
//  JabTracker
//
//  Settings view for managing HealthKit integration and manual biometric data entry.
//

import HealthKit
import SwiftData
import SwiftUI

/// View for managing HealthKit integration and manual profile data entry.
///
/// Provides:
/// - HealthKit authorization status and sync controls
/// - Display of current profile data (height, sex, DOB)
/// - Manual entry fallback for when HealthKit is unavailable
struct HealthIntegrationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    @State private var healthKitService: HealthKitService?
    @State private var isAuthorized = false
    @State private var isSyncing = false
    @State private var errorMessage: String?
    @State private var showingError = false

    // Manual entry fields (fallback when HealthKit unavailable/declined)
    @State private var manualHeightCm: Double = 170.0
    @State private var manualGender: String = ""
    @State private var manualDateOfBirth: Date =
        Calendar.current.date(
            byAdding: .year, value: -30, to: Date()
        ) ?? Date()

    var body: some View {
        Form {
            // Section 1: HealthKit Status
            Section {
                healthKitStatusRow
                if healthKitService?.isAvailable == false {
                    Text("HealthKit is not available on this device.")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                } else if !isAuthorized {
                    Button("Request HealthKit Access") {
                        Task { await requestAuthorization() }
                    }
                    .accessibilityIdentifier("request-healthkit-access-button")
                } else {
                    Button {
                        Task { await syncFromHealthKit() }
                    } label: {
                        HStack {
                            Text("Sync from HealthKit")
                            if isSyncing {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isSyncing)
                    .accessibilityIdentifier("sync-healthkit-button")
                }
            } header: {
                Text("HealthKit")
            } footer: {
                Text(
                    "Import your height, biological sex, and date of birth for accurate calorie calculations."
                )
            }

            // Section 2: Current Profile Data (read-only display)
            if let user = users.first {
                Section("Current Profile Data") {
                    LabeledContent("Height", value: formatHeight(user.heightCm))
                        .accessibilityIdentifier("current-height-label")
                    LabeledContent("Biological Sex", value: formatGender(user.gender))
                        .accessibilityIdentifier("current-gender-label")
                    LabeledContent("Date of Birth", value: formatDOB(user.dateOfBirth))
                        .accessibilityIdentifier("current-dob-label")
                    LabeledContent("Age", value: formatAge(user.age))
                        .accessibilityIdentifier("current-age-label")
                }
            }

            // Section 3: Manual Entry (fallback)
            Section {
                // Height picker
                Stepper(
                    "Height: \(Int(manualHeightCm)) cm",
                    value: $manualHeightCm,
                    in: 100...250,
                    step: 1
                )
                .accessibilityIdentifier("manual-height-stepper")

                // Gender picker
                Picker("Biological Sex", selection: $manualGender) {
                    Text("Not Set").tag("")
                    Text("Male").tag("male")
                    Text("Female").tag("female")
                }
                .accessibilityIdentifier("manual-gender-picker")

                // DOB picker
                DatePicker(
                    "Date of Birth",
                    selection: $manualDateOfBirth,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .accessibilityIdentifier("manual-dob-picker")

                Button("Save Manual Entry") {
                    saveManualEntry()
                }
                .accessibilityIdentifier("save-manual-entry-button")
            } header: {
                Text("Manual Entry")
            } footer: {
                Text(
                    "Enter your data manually if HealthKit is unavailable or you prefer not to sync."
                )
            }
        }
        .navigationTitle("Health Integration")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { initializeService() }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .accessibilityIdentifier("health-integration-view")
    }

    // MARK: - Views

    private var healthKitStatusRow: some View {
        HStack {
            Text("Status")
            Spacer()
            if healthKitService?.isAvailable == false {
                Label("Unavailable", systemImage: "xmark.circle")
                    .foregroundColor(.red)
            } else if isAuthorized {
                Label("Authorized", systemImage: "checkmark.circle")
                    .foregroundColor(.green)
            } else {
                Label("Not Authorized", systemImage: "exclamationmark.triangle")
                    .foregroundColor(.orange)
            }
        }
        .accessibilityIdentifier("healthkit-status-row")
    }

    // MARK: - Actions

    private func initializeService() {
        healthKitService = HealthKitService(context: modelContext)

        // Pre-populate manual entry fields with existing user data
        if let user = users.first {
            if let height = user.heightCm {
                manualHeightCm = height
            }
            manualGender = user.gender
            if let dob = user.dateOfBirth {
                manualDateOfBirth = dob
            }
        }
    }

    private func requestAuthorization() async {
        guard let service = healthKitService else { return }
        do {
            isAuthorized = try await service.requestReadAuthorization()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func syncFromHealthKit() async {
        guard let service = healthKitService, let user = users.first else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            try await service.fetchAndPopulateUserProfile(user: user)
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func saveManualEntry() {
        guard let user = users.first else { return }
        user.heightCm = manualHeightCm
        user.gender = manualGender
        user.dateOfBirth = manualDateOfBirth
        try? modelContext.save()
    }

    // MARK: - Formatters

    private func formatHeight(_ height: Double?) -> String {
        guard let height else { return "Not set" }
        return "\(Int(height)) cm"
    }

    private func formatGender(_ gender: String) -> String {
        switch gender {
        case "male": return "Male"
        case "female": return "Female"
        default: return "Not set"
        }
    }

    private func formatDOB(_ date: Date?) -> String {
        guard let date else { return "Not set" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private func formatAge(_ age: Int?) -> String {
        guard let age else { return "Not set" }
        return "\(age) years"
    }
}

#Preview {
    NavigationStack {
        HealthIntegrationView()
            .modelContainer(DataController.preview.container)
    }
}
