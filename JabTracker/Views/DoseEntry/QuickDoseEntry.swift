//
//  QuickDoseEntry.swift
//  JabTracker
//
//  Enhanced quick dose entry component with pharmacokinetics integration
//  Wraps existing QuickDoseButton with PK recalculation triggers
//

import SwiftData
import SwiftUI

/// Enhanced quick dose entry with pharmacokinetics engine integration
/// Triggers PK recalculation and dashboard updates after successful dose save
struct QuickDoseEntry: View {
    @Environment(\.modelContext) private var modelContext

    // PK Engine and Dose Service
    @State private var pkEngine: PharmacokineticsEngine
    @State private var doseService: DoseService

    // UI State
    @State private var showingQuickDoseSheet = false
    @State private var showingSuccessMessage = false
    @State private var isProcessing = false

    // Dashboard Update Triggers
    let onDoseSaved: (() -> Void)?
    let onCalculationsUpdated: (() -> Void)?

    // MARK: - Initialization

    init(
        onDoseSaved: (() -> Void)? = nil,
        onCalculationsUpdated: (() -> Void)? = nil
    ) {
        self.onDoseSaved = onDoseSaved
        self.onCalculationsUpdated = onCalculationsUpdated

        // Initialize PK engine and dose service
        let pkEngine = PharmacokineticsEngine()
        self._pkEngine = State(wrappedValue: pkEngine)
        self._doseService = State(wrappedValue: DoseService(pkEngine: pkEngine))
    }

    var body: some View {
        Button(
            action: {
                self.showingQuickDoseSheet = true
            },
            label: {
                HStack {
                    if self.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }

                    Text("Quick Add Dose")
                }
            }
        )
        .buttonStyle(.borderedProminent)
        .disabled(self.isProcessing)
        .accessibilityIdentifier("quick-dose-entry-button")
        .accessibilityLabel("Quick add dose with PK calculations")
        .sheet(isPresented: self.$showingQuickDoseSheet) {
            QuickDoseEntrySheet(
                doseService: self.doseService,
                onDoseSaved: self.handleDoseSaved,
                onCancel: {
                    self.showingQuickDoseSheet = false
                })
        }
        .overlay(alignment: .top) {
            if self.showingSuccessMessage {
                Text("Dose logged successfully!")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.9))
                    .cornerRadius(8)
                    .accessibilityIdentifier("dose-logged-success-pk")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        // Auto-dismiss success message after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                self.showingSuccessMessage = false
                            }
                        }
                    }
            }
        }
        .onChange(of: self.doseService.isProcessingDose) { _, processing in
            self.isProcessing = processing
        }
    }

    // MARK: - Event Handlers

    private func handleDoseSaved() {
        // Close sheet
        self.showingQuickDoseSheet = false

        // Show success message
        withAnimation {
            self.showingSuccessMessage = true
        }

        // Trigger haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Notify parent components
        self.onDoseSaved?()
        self.onCalculationsUpdated?()
    }
}

/// Sheet component for quick dose entry with PK engine integration
private struct QuickDoseEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Dependencies
    let doseService: DoseService

    // Event handlers
    let onDoseSaved: () -> Void
    let onCancel: () -> Void

    // View model and UI state
    @StateObject private var viewModel = QuickDoseViewModel()
    @State private var isSubmitting = false

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
                    .accessibilityIdentifier("quick-dose-entry-medication-picker")

                    // Dose Amount (from selected medication profile)
                    HStack {
                        Text("Dose Amount")
                        Spacer()
                        Text("\(self.viewModel.doseAmount, specifier: "%.2f") mg")
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("quick-dose-entry-amount")
                    }

                    // Injection Site Selection
                    Picker("Injection Site", selection: self.$viewModel.selectedInjectionSite) {
                        ForEach(self.viewModel.recommendedInjectionSites, id: \.self) { site in
                            Text(site).tag(site)
                        }
                    }
                    .accessibilityIdentifier("quick-dose-entry-site-picker")

                    // Date Selection
                    DatePicker(
                        "Date",
                        selection: self.$viewModel.doseDate,
                        in: (Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date())...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .accessibilityIdentifier("quick-dose-entry-date-picker")

                    // Time Selection
                    DatePicker(
                        "Time",
                        selection: self.$viewModel.doseTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .accessibilityIdentifier("quick-dose-entry-time-picker")
                } header: {
                    Text("Dose Details")
                } footer: {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .accessibilityIdentifier("quick-dose-entry-error")
                    }

                    if let serviceError = doseService.lastError {
                        Text(serviceError.localizedDescription)
                            .foregroundColor(.red)
                            .accessibilityIdentifier("dose-service-error")
                    }
                }

                // Optional Notes Section
                Section {
                    TextField("Notes (Optional)", text: self.$viewModel.notes, axis: .vertical)
                        .lineLimit(2)
                        .accessibilityIdentifier("quick-dose-entry-notes")
                } header: {
                    Text("Additional Information")
                }

                // PK Integration Info Section
                if let selectedProfile = viewModel.selectedMedicationProfile {
                    Section {
                        self.pkIntegrationInfo(for: selectedProfile)
                    } header: {
                        Text("Pharmacokinetics Impact")
                    }
                }
            }
            .navigationTitle("Quick Add Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.onCancel()
                    }
                    .accessibilityIdentifier("quick-dose-entry-cancel")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await self.saveDoseWithPKIntegration()
                        }
                    }
                    .disabled(!self.canSaveDose || self.isSubmitting)
                    .accessibilityIdentifier("quick-dose-entry-save")
                }
            }
            .onAppear {
                self.viewModel.loadSmartDefaults(context: self.modelContext)
            }
        }
        .accessibilityIdentifier("quick-dose-entry-sheet")
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - PK Integration Info

    @ViewBuilder
    private func pkIntegrationInfo(for profile: MedicationProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("This dose will update your concentration levels")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }

            if let medication = profile.medication {
                Text("Peak level expected in ~\(Int(medication.peakTimeHours)) hours")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("pk-peak-time-info")
            }
        }
        .accessibilityIdentifier("pk-integration-info")
    }

    // MARK: - Computed Properties

    private var canSaveDose: Bool {
        self.viewModel.canSaveDose && !self.doseService.isProcessingDose
    }

    // MARK: - Dose Saving with PK Integration

    @MainActor
    private func saveDoseWithPKIntegration() async {
        guard let profile = viewModel.selectedMedicationProfile else { return }

        self.isSubmitting = true
        defer {
            self.isSubmitting = false
        }

        do {
            // Save dose through dose service (which handles PK integration)
            _ = try await self.doseService.saveDose(
                amount: self.viewModel.doseAmount,
                timestamp: self.viewModel.doseDateTime,
                medicationProfile: profile,
                site: self.viewModel.selectedInjectionSite.isEmpty
                    ? nil : self.viewModel.selectedInjectionSite,
                notes: self.viewModel.notes.isEmpty ? nil : self.viewModel.notes,
                context: self.modelContext)

            // Reset form for next use
            self.viewModel.resetForm()

            // Notify success
            self.onDoseSaved()

        } catch {
            // Error is handled by doseService and displayed in UI
            print("Error saving dose with PK integration: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    QuickDoseEntry(
        onDoseSaved: { print("Dose saved") },
        onCalculationsUpdated: { print("Calculations updated") }
    )
    .modelContainer(DataController.preview.container)
}
