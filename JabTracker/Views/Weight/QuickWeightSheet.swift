//
//  QuickWeightSheet.swift
//  JabTracker
//
//  Quick weight entry sheet accessible from ShortcutsSheet.
//

import HealthKit
import SwiftData
import SwiftUI

/// Quick weight entry sheet for logging weight via shortcuts
struct QuickWeightSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    // MARK: - State

    @State private var weightInput: String = ""
    @State private var weightUnit: String = "kg"
    @State private var bodyFatInput: String = ""
    @State private var timestamp: Date = Date()
    @State private var syncToHealthKit: Bool = true
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    @State private var healthKitAuthorized: Bool = false

    // MARK: - Computed Properties

    private var weightService: WeightService? {
        AppServices.shared.weightService
    }

    private var canSave: Bool {
        guard let weight = Double(weightInput), weight > 0 else {
            return false
        }

        // If body fat is provided, validate it
        if !bodyFatInput.isEmpty {
            guard let bodyFat = Double(bodyFatInput),
                bodyFat >= 0 && bodyFat <= 100
            else {
                return false
            }
        }

        return true
    }

    private var weightInKg: Double? {
        guard let weight = Double(weightInput), weight > 0 else {
            return nil
        }

        if weightUnit == "lbs" {
            return weight / WeightEntry.kgToLbsConversion
        }
        return weight
    }

    // MARK: - Accessibility Identifiers

    static let sheetIdentifier = "quick-weight-sheet"
    static let weightInputIdentifier = "weight-input"
    static let weightUnitPickerIdentifier = "weight-unit-picker"
    static let bodyFatInputIdentifier = "body-fat-input"
    static let saveButtonIdentifier = "save-weight-button"

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                weightSection
                bodyFatSection
                dateSection
                if weightService?.isHealthKitAvailable == true {
                    healthKitSection
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!canSave || isSaving)
                    .accessibilityIdentifier(Self.saveButtonIdentifier)
                }
            }
        }
        .presentationDetents([.medium])
        .accessibilityIdentifier(Self.sheetIdentifier)
        .onAppear { loadDefaults() }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Sections

    private var weightSection: some View {
        Section("Weight") {
            HStack {
                TextField("Enter weight", text: $weightInput)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier(Self.weightInputIdentifier)

                Picker("Unit", selection: $weightUnit) {
                    Text("kg").tag("kg")
                    Text("lbs").tag("lbs")
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                .accessibilityIdentifier(Self.weightUnitPickerIdentifier)
            }
        }
    }

    private var bodyFatSection: some View {
        Section("Body Fat (optional)") {
            HStack {
                TextField("Enter body fat %", text: $bodyFatInput)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier(Self.bodyFatInputIdentifier)

                Text("%")
                    .foregroundColor(.secondary)
            }
        }
    }

    private var dateSection: some View {
        Section("Date & Time") {
            DatePicker(
                "When",
                selection: $timestamp,
                in: ...Date(),
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }

    private var healthKitSection: some View {
        Section {
            Toggle("Sync to Apple Health", isOn: $syncToHealthKit)
        } footer: {
            Text("Weight will also be saved to the Health app")
        }
    }

    // MARK: - Actions

    private func loadDefaults() {
        // Set weight unit from user preference
        if let user = users.first {
            weightUnit = user.weightUnit
        }

        // Try to load last weight entry as default
        Task {
            if let service = weightService,
                let lastEntry = try? await service.getLatestEntry()
            {
                // Format based on current unit
                let weightValue =
                    weightUnit == "lbs"
                    ? lastEntry.weightInLbs
                    : lastEntry.weightKg

                await MainActor.run {
                    weightInput = String(format: "%.1f", weightValue)
                }
            }

            // Check HealthKit authorization status
            if let service = weightService {
                let status = service.getAuthorizationStatus()
                await MainActor.run {
                    healthKitAuthorized = status == .sharingAuthorized
                    // Default to sync if authorized, otherwise still try (will prompt)
                    syncToHealthKit = service.isHealthKitAvailable
                }
            }
        }
    }

    private func save() async {
        guard let service = weightService else {
            errorMessage = "Weight service not available"
            showingError = true
            return
        }

        guard let weightKg = weightInKg else {
            errorMessage = "Please enter a valid weight"
            showingError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            // Parse body fat if provided
            let bodyFat: Double?
            if !bodyFatInput.isEmpty, let fat = Double(bodyFatInput) {
                bodyFat = fat
            } else {
                bodyFat = nil
            }

            // Log weight entry
            let entry = try await service.logWeight(
                weightKg: weightKg,
                bodyFat: bodyFat,
                timestamp: timestamp
            )

            // Sync to HealthKit if enabled
            if syncToHealthKit {
                // Request authorization if not already authorized
                if !healthKitAuthorized {
                    _ = try? await service.requestHealthKitAuthorization()
                }

                // Sync entry (handles auth denial gracefully)
                try? await service.syncToHealthKit(entry)
            }

            // Update User.weight with latest entry
            try? await service.updateUserWeight()

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Preview

#Preview {
    QuickWeightSheet()
        .modelContainer(DataController.preview.container)
}
