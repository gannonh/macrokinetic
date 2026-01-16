//
//  QuickDoseButton.swift
//  JabTracker
//

import OSLog
import SwiftData
import SwiftUI

/// Self-contained SwiftUI component for quick dose entry with smart defaults
/// Presents a sheet for streamlined dose logging when tapped
/// Enhanced with pharmacokinetics integration for automatic dashboard updates
struct QuickDoseButton: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = QuickDoseViewModel()
    @State private var pkEngine: PharmacokineticsEngine
    @State private var doseService: DoseService
    @State private var showingQuickDoseSheet = false
    @State private var showingTitrationDialog = false
    @State private var pendingTitration: DoseTitration?
    @State private var showingSuccessMessage = false
    @State private var titrationError: String?
    @State private var showingTitrationError = false

    // Dashboard update callbacks
    let onDoseSaved: (() -> Void)?
    let onCalculationsUpdated: (() -> Void)?

    // MARK: - Constants

    private enum UITiming {
        /// Duration to display success message after dose save
        static let successMessageDuration: TimeInterval = 2.0
    }

    // MARK: - Logger

    private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "QuickDoseButton")

    // MARK: - Initialization

    init(
        onDoseSaved: (() -> Void)? = nil,
        onCalculationsUpdated: (() -> Void)? = nil
    ) {
        self.onDoseSaved = onDoseSaved
        self.onCalculationsUpdated = onCalculationsUpdated

        let pkEngine = PharmacokineticsEngine()
        self._pkEngine = State(wrappedValue: pkEngine)
        self._doseService = State(wrappedValue: DoseService(pkEngine: pkEngine))
    }

    var body: some View {
        Button(
            action: handleButtonTap,
            label: {
                Label("Quick Add Dose", systemImage: "plus.circle.fill")
            }
        )
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("quick-add-dose-button")
        .sheet(
            isPresented: self.$showingQuickDoseSheet,
            onDismiss: {
                // Clear pending titration state to avoid stale references
                self.pendingTitration = nil
            },
            content: {
                QuickDoseSheet(
                    viewModel: self.viewModel,
                    doseService: self.doseService,
                    showingSuccessMessage: self.$showingSuccessMessage,
                    onDoseSaved: self.onDoseSaved,
                    onCalculationsUpdated: self.onCalculationsUpdated)
            }
        )
        .sheet(
            isPresented: self.$showingTitrationDialog,
            content: {
                if let titration = pendingTitration {
                    TitrationConfirmationDialog(
                        titration: titration,
                        onComplete: handleTitrationComplete,
                        onReschedule: handleTitrationReschedule,
                        onRemindLater: handleTitrationRemindLater
                    )
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
                }
            }
        )
        .onAppear {
            self.viewModel.loadSmartDefaults(context: self.modelContext)
        }
        .alert("Titration Error", isPresented: self.$showingTitrationError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = titrationError {
                Text(error)
            }
        }
        .overlay(alignment: .top) {
            if self.showingSuccessMessage {
                Text("Dose logged successfully!")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignTokens.Colors.success.opacity(0.9))
                    .cornerRadius(8)
                    .accessibilityIdentifier("dose-logged-success")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        // Auto-dismiss success message after configured duration
                        DispatchQueue.main.asyncAfter(deadline: .now() + UITiming.successMessageDuration) {
                            withAnimation {
                                self.showingSuccessMessage = false
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Actions

    private func handleButtonTap() {
        // Check if there's a pending titration that should trigger dialog
        logger.debug("QuickDoseButton.handleButtonTap called")
        logger.debug("Checking shouldShowTitrationDialog()...")

        let shouldShow = viewModel.shouldShowTitrationDialog()
        logger.debug("shouldShowTitrationDialog() returned: \(shouldShow)")

        if shouldShow {
            pendingTitration = viewModel.getPendingTitration()
            logger.debug("Got pending titration: \(pendingTitration?.id.uuidString ?? "nil")")
            logger.debug("Setting showingTitrationDialog = true")
            showingTitrationDialog = true
        } else {
            logger.debug("No pending titration, showing QuickDoseSheet")
            showingQuickDoseSheet = true
        }
    }

    private func handleTitrationComplete() {
        guard let titration = pendingTitration else { return }

        do {
            // Business logic in ViewModel
            try viewModel.completeTitration(titration, context: modelContext)
            logger.info("Titration completed successfully")

            // UI state: show quick dose sheet with new dose amount on success
            showingQuickDoseSheet = true
        } catch {
            // Surface error to user and log failure
            logger.error("Failed to complete titration: \(error.localizedDescription)")
            titrationError = TitrationErrorMessages.completionFailed(error)
            showingTitrationError = true
        }
    }

    private func handleTitrationReschedule(_ newDate: Date) {
        guard let titration = pendingTitration else { return }

        do {
            // Business logic in ViewModel
            try viewModel.rescheduleTitration(titration, to: newDate, context: modelContext)
            logger.info("Titration rescheduled successfully to \(newDate)")

            // UI state: dismiss dialog only on success
            showingTitrationDialog = false
        } catch {
            // Surface error to user and keep dialog open
            logger.error("Failed to reschedule titration: \(error.localizedDescription)")
            titrationError = TitrationErrorMessages.rescheduleFailed(error)
            showingTitrationError = true
        }
    }

    private func handleTitrationRemindLater() {
        // Set flag to skip titration dialog for this dose entry
        // Note: Flag will be reset in saveDose() after successful dose entry
        // This ensures single source of truth and avoids race conditions
        viewModel.setTitrationRemindLater(true)
        logger.debug("Titration reminder deferred - flag will reset after dose save")

        // UI state: show quick dose sheet
        showingQuickDoseSheet = true
    }
}

/// Sheet component for streamlined dose entry with minimal required fields
/// Enhanced with pharmacokinetics integration and dose service coordination
struct QuickDoseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "QuickDoseSheet")

    @ObservedObject var viewModel: QuickDoseViewModel
    let doseService: DoseService
    @Binding var showingSuccessMessage: Bool

    // Dashboard update callbacks
    let onDoseSaved: (() -> Void)?
    let onCalculationsUpdated: (() -> Void)?

    // Edit mode support
    let editingDose: DoseEditData?
    let onSave: ((DoseEditData) -> Void)?
    let onCancel: (() -> Void)?

    // Convenience initializer for create mode with PK integration
    init(
        viewModel: QuickDoseViewModel,
        doseService: DoseService,
        showingSuccessMessage: Binding<Bool>,
        onDoseSaved: (() -> Void)? = nil,
        onCalculationsUpdated: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.doseService = doseService
        self._showingSuccessMessage = showingSuccessMessage
        self.onDoseSaved = onDoseSaved
        self.onCalculationsUpdated = onCalculationsUpdated
        self.editingDose = nil
        self.onSave = nil
        self.onCancel = nil
    }

    // Full initializer for edit mode
    init(
        editingDose: DoseEditData, onSave: @escaping (DoseEditData) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.editingDose = editingDose
        self.onSave = onSave
        self.onCancel = onCancel

        // Create a temporary view model and dose service for edit mode
        self.viewModel = QuickDoseViewModel()
        let pkEngine = PharmacokineticsEngine()
        self.doseService = DoseService(pkEngine: pkEngine)
        self._showingSuccessMessage = .constant(false)
        self.onDoseSaved = nil
        self.onCalculationsUpdated = nil
    }

    private var isEditMode: Bool {
        self.editingDose != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Medication Selection
                    Picker("Medication", selection: self.$viewModel.selectedMedicationProfile) {
                        ForEach(self.viewModel.medicationProfiles, id: \.id) { profile in
                            Text("\(profile.brandName) (\(profile.currentDose, specifier: "%.2f") mg)")
                                .tag(profile as MedicationProfile?)
                        }
                    }
                    .accessibilityIdentifier("quick-dose-medication-picker")
                    .accessibilityLabel("Select medication")

                    // Dose Amount (editable with stepper for per-dose adjustments)
                    HStack {
                        Text("Dose Amount")
                        Spacer()
                        Text("\(self.viewModel.doseAmount, specifier: "%.2f") mg")
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("quick-dose-amount")
                        Stepper(
                            "",
                            value: self.$viewModel.doseAmount,
                            in: self.viewModel.doseAmountRange,
                            step: self.viewModel.doseAmountStep
                        )
                        .labelsHidden()
                        .accessibilityIdentifier("quick-dose-amount-stepper")
                    }

                    // Injection Site Selection
                    Picker("Injection Site", selection: self.$viewModel.selectedInjectionSite) {
                        ForEach(self.viewModel.recommendedInjectionSites, id: \.self) { site in
                            Text(site).tag(site)
                        }
                    }
                    .accessibilityIdentifier("quick-dose-site-picker")
                    .accessibilityLabel("Select injection site")

                    // Date/Time picker for all doses (new and editing)
                    DatePicker(
                        "Date",
                        selection: self.$viewModel.doseTime,
                        in: (Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .accessibilityIdentifier("quick-dose-datetime-picker")
                    .accessibilityLabel("Select dose date and time")
                    .accessibilityHint(
                        "Choose when the dose was administered. Defaults to current date and time.")
                } header: {
                    Text("Dose Details")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .accessibilityIdentifier("quick-dose-view-model-error")
                        }
                        if let serviceError = doseService.lastError {
                            Text(serviceError.localizedDescription)
                                .foregroundColor(.red)
                                .accessibilityIdentifier("dose-save-error")
                        }
                    }
                }

                // Optional Notes Section (streamlined)
                Section {
                    TextField("Notes (Optional)", text: self.$viewModel.notes, axis: .vertical)
                        .lineLimit(2)
                        .accessibilityIdentifier("quick-dose-notes")
                        .accessibilityLabel("Optional notes")
                } header: {
                    Text("Additional Information")
                }
            }
            .navigationTitle(self.isEditMode ? "Edit Dose" : "Quick Add Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if let onCancel {
                            onCancel()
                        } else {
                            self.dismiss()
                        }
                    }
                    .accessibilityIdentifier("quick-dose-cancel-button")
                    .accessibilityLabel("Cancel dose entry")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if self.isEditMode {
                            self.handleEditSave()
                        } else {
                            Task {
                                await self.saveDose()
                            }
                        }
                    }
                    .disabled(!self.viewModel.canSaveDose || self.doseService.isProcessingDose)
                    .accessibilityIdentifier("quick-dose-save-button")
                    .accessibilityLabel("Save dose")
                }
            }
            .onAppear {
                if self.isEditMode, let editData = editingDose {
                    self.viewModel.loadEditData(editData, context: self.modelContext)
                } else {
                    self.viewModel.loadSmartDefaults(context: self.modelContext)
                }
            }
        }
        .accessibilityIdentifier("quick-dose-sheet")
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func handleEditSave() {
        guard let editData = editingDose,
            let onSave,
            let selectedProfile = self.viewModel.selectedMedicationProfile
        else {
            logger.error("Edit save failed: missing editData, onSave callback, or selectedProfile")
            viewModel.errorMessage = "Unable to save changes. Please try again."
            return
        }

        // Create updated dose data from current view model state
        let updatedDose = DoseEditData(
            id: editData.id,
            amount: self.viewModel.doseAmount,
            timestamp: self.viewModel.doseTime,
            site: self.viewModel.selectedInjectionSite.isEmpty
                ? nil : self.viewModel.selectedInjectionSite,
            notes: self.viewModel.notes.isEmpty ? nil : self.viewModel.notes,
            imageData: editData.imageData,  // Keep existing image data
            skipped: editData.skipped,  // Keep existing skipped status
            medicationProfile: selectedProfile)

        onSave(updatedDose)
    }

    @MainActor
    private func saveDose() async {
        guard let profile = self.viewModel.selectedMedicationProfile else {
            return
        }

        do {
            // Save dose through dose service (which handles PK integration)
            _ = try await self.doseService.saveDose(
                amount: self.viewModel.doseAmount,
                timestamp: self.viewModel.doseTime,
                medicationProfile: profile,
                site: self.viewModel.selectedInjectionSite.isEmpty
                    ? nil : self.viewModel.selectedInjectionSite,
                notes: self.viewModel.notes.isEmpty ? nil : self.viewModel.notes,
                context: self.modelContext)

            // Provide haptic feedback for successful save
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            // Show success message
            withAnimation {
                self.showingSuccessMessage = true
            }

            // Trigger callbacks for dashboard updates
            self.onDoseSaved?()
            self.onCalculationsUpdated?()

            // Reset "Remind Me Later" flag so dialog shows next time if needed
            self.viewModel.resetRemindLaterFlag()

            // Dismiss sheet
            self.dismiss()

        } catch {
            // Error is stored in doseService.lastError and displayed in form footer
            logger.error("Failed to save dose: \(error.localizedDescription)")
        }
    }
}

#Preview {
    QuickDoseButton(
        onDoseSaved: { print("Dose saved") },
        onCalculationsUpdated: { print("Calculations updated") }
    )
    .modelContainer(DataController.preview.container)
}

#Preview("Sheet") {
    @Previewable @State var showingSuccess = false
    let viewModel = QuickDoseViewModel()
    let pkEngine = PharmacokineticsEngine()
    let doseService = DoseService(pkEngine: pkEngine)

    return QuickDoseSheet(
        viewModel: viewModel,
        doseService: doseService,
        showingSuccessMessage: $showingSuccess,
        onDoseSaved: { print("Dose saved") },
        onCalculationsUpdated: { print("Calculations updated") }
    )
    .modelContainer(DataController.preview.container)
}
