//
//  QuickWeightSheet.swift
//  JabTracker
//
//  Quick weight entry sheet accessible from ShortcutsSheet.
//

import OSLog
import SwiftData
import SwiftUI

/// Quick weight entry sheet for logging weight via shortcuts
struct QuickWeightSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    // MARK: - State

    @State private var weightWhole: Int = 150
    @State private var weightDecimal: Int = 0
    @State private var weightUnit: String = unitLbs
    @State private var bodyFatInput: String = ""
    @State private var timestamp: Date = Date()
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false

    // MARK: - Constants

    private static let unitKg = "kg"
    private static let unitLbs = "lbs"
    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "QuickWeightSheet"
    )

    // MARK: - Computed Properties

    private var metricsService: MetricsService? {
        AppServices.shared.metricsService
    }

    private var canSave: Bool {
        // Weight picker always has a valid value
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

    private var weightInKg: Double {
        let weight = Double(weightWhole) + Double(weightDecimal) / 10.0

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
    static let saveButtonIdentifier = "save-weight-button"

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                weightSection
                bodyFatSection
                dateSection
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
            VStack(spacing: 12) {
                WeightPickerView(
                    weightWhole: $weightWhole,
                    weightDecimal: $weightDecimal,
                    unit: weightUnit
                )
                .accessibilityIdentifier(Self.weightInputIdentifier)

                Picker("Unit", selection: $weightUnit) {
                    Text("kg").tag(Self.unitKg)
                    Text("lbs").tag(Self.unitLbs)
                }
                .pickerStyle(.segmented)
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

    // MARK: - Actions

    private func loadDefaults() {
        // Set weight unit from user preference
        if let user = users.first {
            weightUnit = user.weightUnit
        }

        // Try to load last weight entry as default
        Task {
            if let service = metricsService {
                do {
                    if let lastEntry = try await service.getLatestWeightEntry() {
                        // Format based on current unit
                        let currentUnit = weightUnit
                        let weightValue =
                            currentUnit == Self.unitLbs
                            ? lastEntry.weightInLbs
                            : lastEntry.weightKg

                        await MainActor.run {
                            weightWhole = Int(weightValue)
                            weightDecimal = Int(((weightValue - Double(Int(weightValue))) * 10).rounded())
                        }
                    }
                } catch {
                    Self.logger.warning("Failed to load last weight entry: \(error.localizedDescription)")
                }
            }
        }
    }

    @MainActor
    private func save() async {
        guard let user = users.first else {
            errorMessage = "No user found"
            showingError = true
            return
        }

        let weightKg = weightInKg

        // Update user's preferred unit if changed
        if user.weightUnit != weightUnit {
            user.weightUnit = weightUnit
            do {
                try modelContext.save()
            } catch {
                Self.logger.error("Failed to save weight unit preference: \(error.localizedDescription)")
            }
        }

        // Save weight (MetricsService respects healthSyncEnabled setting)
        await saveWeightEntry(weightKg: weightKg, for: user)
    }

    @MainActor
    private func saveWeightEntry(weightKg: Double, for user: User) async {
        guard let service = metricsService else {
            Self.logger.error("MetricsService not initialized - AppServices.initialize may not have been called")
            errorMessage = "Unable to save weight. Please restart the app and try again."
            showingError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            // Log weight entry (also updates User.weight and syncs to HealthKit if enabled)
            _ = try await service.logWeight(
                weightKg: weightKg,
                bodyFat: parsedBodyFat,
                for: user,
                timestamp: timestamp
            )

            Self.logger.info("Logged weight entry: \(weightKg) kg")
            dismiss()
        } catch {
            Self.logger.error("Failed to log weight: \(error.localizedDescription)")
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
