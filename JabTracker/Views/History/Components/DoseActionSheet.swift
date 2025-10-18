//
//  DoseActionSheet.swift
//  JabTracker
//
//  Action sheet for managing scheduled doses (log, reschedule, skip)
//  Stream B: Action Sheet UI & Dose Management (Issue #178)
//

import OSLog
import SwiftData
import SwiftUI

/// Action sheet for managing scheduled doses with log, reschedule, and skip actions
///
/// Presents actions for scheduled doses accessed via long-press from calendar view.
/// Integrates with QuickDoseSheet for logging and RescheduleDoseSheet for rescheduling.
struct DoseActionSheet: View {
    let event: DoseEvent
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showQuickDoseSheet = false
    @State private var showRescheduleSheet = false
    @State private var isSkipping = false

    private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "DoseActionSheet")

    var body: some View {
        NavigationStack {
            List {
                // Event details section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.medicationBrandName ?? "Medication")
                            .font(.headline)
                            .foregroundColor(event.medicationBrandName == nil ? .secondary : .primary)
                            .accessibilityIdentifier("dose-action-medication-name")

                        Text("Scheduled for \(event.timestamp.formatted(date: .long, time: .shortened))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("dose-action-scheduled-time")

                        Text("\(event.doseAmount, specifier: "%.2f") mg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("dose-action-amount")
                    }
                    .onAppear {
                        if event.medicationBrandName == nil {
                            logger.error("Missing medication brand name for dose event")
                        }
                    }
                }

                // Actions section
                Section("Actions") {
                    // Log Dose action
                    Button {
                        showQuickDoseSheet = true
                    } label: {
                        Label("Log Dose Now", systemImage: "checkmark.circle")
                            .foregroundColor(.green)
                    }
                    .accessibilityIdentifier("dose-action-log")
                    .accessibilityLabel("Log dose now")
                    .accessibilityHint("Opens quick dose entry with pre-populated details")

                    // Reschedule action
                    Button {
                        showRescheduleSheet = true
                    } label: {
                        Label("Reschedule", systemImage: "calendar")
                            .foregroundColor(.blue)
                    }
                    .accessibilityIdentifier("dose-action-reschedule")
                    .accessibilityLabel("Reschedule dose")
                    .accessibilityHint("Choose a new date and time for this dose")

                    // Skip action
                    Button(role: .destructive) {
                        skipDose()
                    } label: {
                        if isSkipping {
                            HStack {
                                Label("Skip This Dose", systemImage: "xmark.circle")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            Label("Skip This Dose", systemImage: "xmark.circle")
                        }
                    }
                    .disabled(isSkipping)
                    .accessibilityIdentifier("dose-action-skip")
                    .accessibilityLabel("Skip this dose")
                    .accessibilityHint("Mark dose as intentionally skipped")
                }

                // Cancel section
                Section {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("dose-action-cancel")
                    .accessibilityLabel("Cancel")
                }
            }
            .navigationTitle("Manage Dose")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .accessibilityIdentifier("dose-action-sheet")
        .sheet(isPresented: $showQuickDoseSheet) {
            // Query for the medication profile using stored medication names
            if let brandName = event.medicationBrandName {
                let descriptor = FetchDescriptor<MedicationProfile>(
                    predicate: #Predicate { profile in
                        profile.brandName == brandName
                    }
                )

                if let profile = try? modelContext.fetch(descriptor).first {
                    QuickDoseEntrySheet(
                        preSelectedProfile: profile,
                        prePopulatedAmount: event.doseAmount,
                        prePopulatedTimestamp: event.timestamp,
                        onDoseLogged: {
                            dismiss()
                        }
                    )
                } else {
                    EmptyView()
                }
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $showRescheduleSheet) {
            if let scheduledDose = event.scheduledDose {
                RescheduleDoseSheet(
                    scheduledDose: scheduledDose,
                    onRescheduled: {
                        dismiss()
                    }
                )
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Actions

    private func skipDose() {
        guard let scheduledDose = event.scheduledDose else { return }

        isSkipping = true

        // Create a persisted skipped Dose entity to track this skip
        // Query for the medication profile using stored medication names
        if let brandName = event.medicationBrandName {
            let descriptor = FetchDescriptor<MedicationProfile>(
                predicate: #Predicate { profile in
                    profile.brandName == brandName
                }
            )

            if let profile = try? modelContext.fetch(descriptor).first {
                // Create skipped dose with scheduled time
                let skippedDose = Dose(
                    amount: scheduledDose.doseAmount,
                    timestamp: scheduledDose.scheduledTime,
                    site: nil,
                    notes: "Skipped from calendar",
                    imageData: nil,
                    skipped: true,
                    user: profile.user,
                    medication: profile
                )

                modelContext.insert(skippedDose)

                do {
                    try modelContext.save()
                } catch {
                    logger.error("Failed to save skipped dose: \(error)")
                }
            }
        }

        // Small delay for UI feedback using structured concurrency
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            await MainActor.run {
                isSkipping = false
                dismiss()
            }
        }
    }
}

// MARK: - QuickDoseEntrySheet Wrapper

/// Wrapper for QuickDoseEntry sheet with pre-population support
private struct QuickDoseEntrySheet: View {
    let preSelectedProfile: MedicationProfile
    let prePopulatedAmount: Double
    let prePopulatedTimestamp: Date?
    let onDoseLogged: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = QuickDoseViewModel()

    private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "QuickDoseEntrySheet")

    /// Date range for dose logging (30 days past to 30 days future)
    private var dateRange: ClosedRange<Date> {
        let now = Date()
        let pastDate = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: now) ?? now
        return pastDate...futureDate
    }

    init(
        preSelectedProfile: MedicationProfile,
        prePopulatedAmount: Double,
        prePopulatedTimestamp: Date? = nil,
        onDoseLogged: @escaping () -> Void
    ) {
        self.preSelectedProfile = preSelectedProfile
        self.prePopulatedAmount = prePopulatedAmount
        self.prePopulatedTimestamp = prePopulatedTimestamp
        self.onDoseLogged = onDoseLogged
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Medication (pre-selected, read-only)
                    HStack {
                        Text("Medication")
                        Spacer()
                        Text(preSelectedProfile.brandName)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("quick-dose-entry-medication")

                    // Dose Amount (pre-populated)
                    HStack {
                        Text("Dose Amount")
                        Spacer()
                        Text("\(prePopulatedAmount, specifier: "%.2f") mg")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("quick-dose-entry-amount")

                    // Injection Site Selection
                    Picker("Injection Site", selection: $viewModel.selectedInjectionSite) {
                        ForEach(viewModel.recommendedInjectionSites, id: \.self) { site in
                            Text(site).tag(site)
                        }
                    }
                    .accessibilityIdentifier("quick-dose-entry-site-picker")

                    // Date Selection
                    // Allow past dates (30 days) and future dates (30 days) for logging scheduled doses
                    DatePicker(
                        "Date",
                        selection: $viewModel.doseDate,
                        in: dateRange,
                        displayedComponents: .date
                    )
                    .accessibilityIdentifier("quick-dose-entry-date-picker")

                    // Time Selection
                    DatePicker(
                        "Time",
                        selection: $viewModel.doseTime,
                        displayedComponents: .hourAndMinute
                    )
                    .accessibilityIdentifier("quick-dose-entry-time-picker")
                } header: {
                    Text("Dose Details")
                }

                // Optional Notes Section
                Section {
                    TextField("Notes (Optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(2)
                        .accessibilityIdentifier("quick-dose-entry-notes")
                } header: {
                    Text("Additional Information")
                }
            }
            .navigationTitle("Log Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("quick-dose-entry-cancel")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveDose()
                        }
                    }
                    .accessibilityIdentifier("quick-dose-entry-save")
                }
            }
            .onAppear {
                // Pre-select medication profile
                viewModel.selectedMedicationProfile = preSelectedProfile

                // Load smart defaults with pre-populated timestamp if provided
                viewModel.loadSmartDefaults(
                    context: modelContext,
                    prePopulatedTimestamp: prePopulatedTimestamp
                )
            }
        }
        .presentationDetents([.medium, .large])
    }

    @MainActor
    private func saveDose() async {
        // Create dose with pre-populated data
        let dose = Dose(
            amount: prePopulatedAmount,
            timestamp: viewModel.doseDateTime,
            site: viewModel.selectedInjectionSite.isEmpty ? nil : viewModel.selectedInjectionSite,
            notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
            imageData: nil,
            skipped: false,
            user: preSelectedProfile.user,
            medication: preSelectedProfile
        )

        modelContext.insert(dose)

        do {
            try modelContext.save()
            onDoseLogged()
            dismiss()
        } catch {
            logger.error("Failed to save dose: \(error.localizedDescription)")
            // TODO: Show error alert to user
        }
    }
}

#Preview {
    let user = User(email: "test@test.com", name: "Test User", weight: 70)
    let profile = MedicationProfile(
        genericName: "semaglutide",
        brandName: "Ozempic",
        currentDose: 0.5
    )
    profile.user = user

    let schedule = DoseSchedule(
        medicationProfile: profile,
        patternType: .weekly
    )

    let scheduledTime = Date()
    let scheduledDose = ScheduledDose(
        scheduledTime: scheduledTime,
        doseAmount: 0.5,
        windowStart: scheduledTime.addingTimeInterval(-2 * 60 * 60),
        windowEnd: scheduledTime.addingTimeInterval(2 * 60 * 60)
    )
    scheduledDose.schedule = schedule

    let event = DoseEvent.from(
        scheduledDose: scheduledDose,
        medicationBrandName: "Ozempic",
        medicationGenericName: "semaglutide"
    )

    return DoseActionSheet(event: event)
        .modelContainer(DataController.preview.container)
}
