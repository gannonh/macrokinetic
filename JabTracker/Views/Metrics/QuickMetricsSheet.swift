//
//  QuickMetricsSheet.swift
//  JabTracker
//
//  Quick body metrics entry sheet accessible from ShortcutsSheet.
//

import HealthKit
import OSLog
import SwiftData
import SwiftUI

/// Quick metrics entry sheet for logging body measurements via shortcuts
struct QuickMetricsSheet: View {
    // MARK: - Constants

    private static let unitCm = "cm"
    private static let unitIn = "in"

    /// Conversion factor: inches to centimeters
    private static let inchesToCm: Double = 2.54

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    private var user: User? { users.first }

    // MARK: - State

    @State private var waistInput: String = ""
    @State private var hipInput: String = ""
    @State private var chestInput: String = ""
    @State private var neckInput: String = ""
    @State private var unit: String = unitCm
    @State private var timestamp: Date = Date()
    @State private var notes: String = ""
    @State private var syncToHealthKit: Bool = true
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false

    // MARK: - Logger

    private let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "QuickMetricsSheet"
    )

    // MARK: - Computed Properties

    private var metricsService: MetricsService? {
        AppServices.shared.metricsService
    }

    /// Check if at least one visible measurement has valid input
    private var canSave: Bool {
        (showWaist && waistCm != nil)
            || (showHip && hipCm != nil)
            || (showChest && chestCm != nil)
            || (showNeck && neckCm != nil)
    }

    /// Convert waist input to cm based on current unit
    private var waistCm: Double? {
        convertToCm(waistInput)
    }

    /// Convert hip input to cm based on current unit
    private var hipCm: Double? {
        convertToCm(hipInput)
    }

    /// Convert chest input to cm based on current unit
    private var chestCm: Double? {
        convertToCm(chestInput)
    }

    /// Convert neck input to cm based on current unit
    private var neckCm: Double? {
        convertToCm(neckInput)
    }

    // MARK: - Visibility Preferences

    private var showWaist: Bool {
        user?.isMetricEnabled(MetricKey.waist.rawValue)
            ?? User.defaultEnabledMetrics.contains(MetricKey.waist.rawValue)
    }

    private var showHip: Bool {
        user?.isMetricEnabled(MetricKey.hip.rawValue)
            ?? User.defaultEnabledMetrics.contains(MetricKey.hip.rawValue)
    }

    private var showChest: Bool {
        user?.isMetricEnabled(MetricKey.chest.rawValue)
            ?? User.defaultEnabledMetrics.contains(MetricKey.chest.rawValue)
    }

    private var showNeck: Bool {
        user?.isMetricEnabled(MetricKey.neck.rawValue)
            ?? User.defaultEnabledMetrics.contains(MetricKey.neck.rawValue)
    }

    /// Convert input string to cm based on current unit
    private func convertToCm(_ input: String) -> Double? {
        guard let value = Double(input), value > 0 else {
            return nil
        }
        if unit == Self.unitIn {
            return value * Self.inchesToCm
        }
        return value
    }

    /// Convert cm value to display string based on current unit
    private func convertFromCm(_ cm: Double) -> String {
        if unit == Self.unitIn {
            return String(format: "%.1f", cm / Self.inchesToCm)
        }
        return String(format: "%.1f", cm)
    }

    // MARK: - Accessibility Identifiers

    static let sheetIdentifier = "quick-metrics-sheet"
    static let waistInputIdentifier = "waist-input"
    static let hipInputIdentifier = "hip-input"
    static let chestInputIdentifier = "chest-input"
    static let neckInputIdentifier = "neck-input"
    static let unitPickerIdentifier = "unit-picker"
    static let datePickerIdentifier = "date-picker"
    static let healthKitToggleIdentifier = "healthkit-toggle"
    static let saveButtonIdentifier = "save-metrics-button"
    static let cancelButtonIdentifier = "cancel-button"

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                measurementsSection
                unitSection
                dateSection
                notesSection
                if MetricsService.isHealthKitAvailable {
                    healthKitSection
                }
            }
            .navigationTitle("Log Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier(Self.cancelButtonIdentifier)
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
        .presentationDetents([.large])
        .accessibilityIdentifier(Self.sheetIdentifier)
        .onAppear { loadDefaults() }
        .errorAlert(isPresented: $showingError, message: errorMessage)
    }

    // MARK: - Sections

    @ViewBuilder
    private var measurementsSection: some View {
        if showWaist {
            Section("Waist") {
                TextField(placeholderText("waist"), text: $waistInput)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier(Self.waistInputIdentifier)
            }
        }

        if showHip {
            Section("Hip") {
                TextField(placeholderText("hip"), text: $hipInput)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier(Self.hipInputIdentifier)
            }
        }

        if showChest {
            Section("Chest") {
                TextField(placeholderText("chest"), text: $chestInput)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier(Self.chestInputIdentifier)
            }
        }

        if showNeck {
            Section("Neck") {
                TextField(placeholderText("neck"), text: $neckInput)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier(Self.neckInputIdentifier)
            }
        }
    }

    private func placeholderText(_ measurement: String) -> String {
        "Enter \(measurement) in \(unit)"
    }

    private var unitSection: some View {
        Section("Unit") {
            Picker("Measurement Unit", selection: $unit) {
                Text("cm").tag(Self.unitCm)
                Text("in").tag(Self.unitIn)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(Self.unitPickerIdentifier)
            .onChange(of: unit) { oldValue, newValue in
                convertUnits(from: oldValue, to: newValue)
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

    private var notesSection: some View {
        Section("Notes (optional)") {
            TextField("Add notes", text: $notes)
        }
    }

    private var healthKitSection: some View {
        Section {
            Toggle("Sync to Apple Health", isOn: $syncToHealthKit)
                .accessibilityIdentifier(Self.healthKitToggleIdentifier)
        } footer: {
            Text("Only waist circumference will sync to Apple Health. Other measurements are stored locally.")
        }
    }

    // MARK: - Actions

    private func loadDefaults() {
        Task {
            guard let service = metricsService else { return }

            // Try to load last entry as defaults
            do {
                if let lastEntry = try await service.getLatestEntry() {
                    await MainActor.run {
                        if let waist = lastEntry.waistCm {
                            waistInput = convertFromCm(waist)
                        }
                        if let hip = lastEntry.hipCm {
                            hipInput = convertFromCm(hip)
                        }
                        if let chest = lastEntry.chestCm {
                            chestInput = convertFromCm(chest)
                        }
                        if let neck = lastEntry.neckCm {
                            neckInput = convertFromCm(neck)
                        }
                    }
                }
            } catch {
                logger.warning("Failed to load last metrics entry: \(error.localizedDescription)")
            }

            // Set HealthKit sync toggle based on availability
            await MainActor.run {
                syncToHealthKit = MetricsService.isHealthKitAvailable
            }
        }
    }

    /// Convert input values when unit changes
    private func convertUnits(from oldUnit: String, to newUnit: String) {
        // Only convert if switching between cm and in
        guard oldUnit != newUnit else { return }

        let conversionFactor: Double
        if newUnit == Self.unitIn {
            // Converting from cm to inches
            conversionFactor = 1.0 / Self.inchesToCm
        } else {
            // Converting from inches to cm
            conversionFactor = Self.inchesToCm
        }

        // Convert each non-empty input
        waistInput = convertInputValue(waistInput, factor: conversionFactor)
        hipInput = convertInputValue(hipInput, factor: conversionFactor)
        chestInput = convertInputValue(chestInput, factor: conversionFactor)
        neckInput = convertInputValue(neckInput, factor: conversionFactor)
    }

    private func convertInputValue(_ input: String, factor: Double) -> String {
        guard let value = Double(input), value > 0 else {
            return input
        }
        return String(format: "%.1f", value * factor)
    }

    @MainActor
    private func save() async {
        guard let service = metricsService else {
            logger.error("MetricsService not initialized")
            errorMessage = "Unable to save metrics. Please restart the app and try again."
            showingError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            // Log metrics entry
            let entry = try await service.logMetrics(
                waistCm: waistCm,
                hipCm: hipCm,
                chestCm: chestCm,
                neckCm: neckCm,
                timestamp: timestamp,
                notes: notes.isEmpty ? nil : notes
            )

            logger.info("Logged metrics entry")

            // Sync to HealthKit if enabled (service handles auth internally)
            if syncToHealthKit {
                await service.syncToHealthKitWithAuth(entry)
            }

            dismiss()
        } catch {
            logger.error("Failed to log metrics: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Preview

#Preview {
    QuickMetricsSheet()
        .modelContainer(DataController.preview.container)
}
