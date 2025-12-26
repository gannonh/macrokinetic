//
//  QuickWeightSheet.swift
//  JabTracker
//
//  Quick weight entry sheet accessible from ShortcutsSheet.
//

import HealthKit
import OSLog
import SwiftData
import SwiftUI

/// Quick weight entry sheet for logging weight via shortcuts
struct QuickWeightSheet: View {
    // MARK: - Constants

    private static let unitKg = "kg"
    private static let unitLbs = "lbs"

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    // MARK: - State

    @State private var weightInput: String = ""
    @State private var weightUnit: String = unitKg
    @State private var bodyFatInput: String = ""
    @State private var timestamp: Date = Date()
    @State private var syncToHealthKit: Bool = true
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false

    // MARK: - Logger

    private let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "QuickWeightSheet"
    )

    // MARK: - Computed Properties

    private var weightService: WeightService? {
        AppServices.shared.weightService
    }

    private var canSave: Bool {
        guard let weight = Double(weightInput), weight > 0 else {
            return false
        }
        guard bodyFatInput.isEmpty || parsedBodyFat != nil else {
            return false
        }
        return true
    }

    /// Parsed body fat percentage, or nil if empty or invalid
    private var parsedBodyFat: Double? {
        guard !bodyFatInput.isEmpty,
            let bodyFat = Double(bodyFatInput),
            bodyFat >= 0 && bodyFat <= 100
        else {
            return nil
        }
        return bodyFat
    }

    private var weightInKg: Double? {
        guard let weight = Double(weightInput), weight > 0 else {
            return nil
        }

        if weightUnit == Self.unitLbs {
            return weight / WeightEntry.kgToLbsConversion
        }
        return weight
    }

    // MARK: - Accessibility Identifiers

    static let sheetIdentifier = "quick-weight-sheet"
    static let weightInputIdentifier = "weight-input"
    static let weightUnitPickerIdentifier = "weight-unit-picker"
    static let bodyFatInputIdentifier = "body-fat-input"
    static let datePickerIdentifier = "weight-date-picker"
    static let healthKitToggleIdentifier = "healthkit-sync-toggle"
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
        .errorAlert(isPresented: $showingError, message: errorMessage)
    }

    // MARK: - Sections

    private var weightSection: some View {
        Section("Weight") {
            HStack {
                TextField("Enter weight", text: $weightInput)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier(Self.weightInputIdentifier)

                Picker("Unit", selection: $weightUnit) {
                    Text("kg").tag(Self.unitKg)
                    Text("lbs").tag(Self.unitLbs)
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
            .accessibilityIdentifier(Self.datePickerIdentifier)
        }
    }

    private var healthKitSection: some View {
        Section {
            Toggle("Sync to Apple Health", isOn: $syncToHealthKit)
                .accessibilityIdentifier(Self.healthKitToggleIdentifier)
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
            if let service = weightService {
                do {
                    if let lastEntry = try await service.getLatestEntry() {
                        // Format based on current unit
                        let currentUnit = weightUnit
                        let weightValue =
                            currentUnit == Self.unitLbs
                            ? lastEntry.weightInLbs
                            : lastEntry.weightKg

                        await MainActor.run {
                            weightInput = String(format: "%.1f", weightValue)
                        }
                    }
                } catch {
                    logger.warning("Failed to load last weight entry: \(error.localizedDescription)")
                }

                // Set HealthKit sync toggle based on availability
                await MainActor.run {
                    syncToHealthKit = service.isHealthKitAvailable
                }
            }
        }
    }

    @MainActor
    private func save() async {
        guard let service = weightService else {
            logger.error("WeightService not initialized - AppServices.initialize may not have been called")
            errorMessage = "Unable to save weight. Please restart the app and try again."
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
            // Log weight entry
            let entry = try await service.logWeight(
                weightKg: weightKg,
                bodyFat: parsedBodyFat,
                timestamp: timestamp
            )

            logger.info("Logged weight entry: \(weightKg) kg")

            // Sync to HealthKit if enabled (service handles auth internally)
            if syncToHealthKit {
                await service.syncToHealthKitWithAuth(entry)
            }

            // Update User.weight with latest entry
            do {
                try await service.updateUserWeight()
            } catch {
                logger.error("Failed to update User.weight: \(error.localizedDescription)")
                // Non-fatal: local entry saved, just profile sync failed
            }

            dismiss()
        } catch {
            logger.error("Failed to log weight: \(error.localizedDescription)")
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
