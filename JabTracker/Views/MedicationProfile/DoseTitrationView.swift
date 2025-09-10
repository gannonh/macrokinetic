//
//  DoseTitrationView.swift
//  JabTracker
//

import SwiftData
import SwiftUI

/// View for managing dose titration plans for medication profiles
struct DoseTitrationView: View {
    let profile: MedicationProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingCreateTitration = false
    @State private var showingDeleteConfirmation = false
    @State private var titrationToDelete: DoseTitration?

    // Get current titrations from the profile
    private var titrations: [DoseTitration] {
        self.profile.doseTitrations?.sorted { $0.scheduledDate < $1.scheduledDate } ?? []
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Dose Header
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Current Dose")
                                .font(DesignTokens.Typography.headline)

                            HStack {
                                Text("\(String(format: "%.2f", self.profile.currentDose)) mg")
                                    .font(DesignTokens.Typography.largeTitle)
                                    .foregroundColor(.primary)

                                Spacer()

                                Text(self.profile.brandName)
                                    .font(DesignTokens.Typography.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Titration Timeline
                    if !self.titrations.isEmpty {
                        DesignCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Escalation Timeline")
                                    .font(DesignTokens.Typography.headline)

                                ForEach(self.titrations, id: \.id) { titration in
                                    TitrationRowView(
                                        titration: titration,
                                        onMarkComplete: { self.markTitrationCompleted(titration) },
                                        onDelete: {
                                            self.titrationToDelete = titration
                                            self.showingDeleteConfirmation = true
                                        })

                                    if titration.id != self.titrations.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    } else {
                        DesignCard {
                            VStack(spacing: 16) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)

                                Text("No Escalation Plans")
                                    .font(DesignTokens.Typography.headline)
                                    .foregroundColor(.secondary)

                                Text("Create an escalation plan to schedule your dose increases.")
                                    .font(DesignTokens.Typography.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 16)
                        }
                    }

                    // Create New Titration Button
                    Button {
                        self.showingCreateTitration = true
                    } label: {
                        DesignCard {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(DesignTokens.Colors.primary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Create Escalation Plan")
                                        .font(DesignTokens.Typography.headline)
                                        .foregroundColor(.primary)

                                    Text("Schedule your next dose increase")
                                        .font(DesignTokens.Typography.body)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                    .accessibilityIdentifier("create-escalation-plan")

                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Dose Escalation Plan")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        self.dismiss()
                    }
                }
            }
            .sheet(isPresented: self.$showingCreateTitration) {
                CreateTitrationView(profile: self.profile)
            }
            .alert("Delete Titration", isPresented: self.$showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    self.titrationToDelete = nil
                }
                Button("Confirm Delete", role: .destructive) {
                    if let titration = titrationToDelete {
                        self.deleteTitration(titration)
                        self.titrationToDelete = nil
                    }
                }
            } message: {
                if let titration = titrationToDelete {
                    Text("Are you sure you want to delete the titration to \(String(format: "%.2f", titration.toDose)) mg?")
                }
            }
        }
    }

    // MARK: - Business Logic

    private func markTitrationCompleted(_ titration: DoseTitration) {
        titration.markCompleted()

        do {
            try self.modelContext.save()
        } catch {
            print("Failed to mark titration as completed: \(error)")
        }
    }

    private func deleteTitration(_ titration: DoseTitration) {
        self.modelContext.delete(titration)

        do {
            try self.modelContext.save()
        } catch {
            print("Failed to delete titration: \(error)")
        }
    }
}

// MARK: - Supporting Views

struct TitrationRowView: View {
    let titration: DoseTitration
    let onMarkComplete: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.titration.statusText)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(self.titration.isCompleted ? .secondary : .primary)

                HStack {
                    Text("Escalation Date")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)

                    Text(self.titration.scheduledDate.formatted(date: .abbreviated, time: .omitted))
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if !self.titration.isCompleted {
                HStack(spacing: 8) {
                    Button("Complete") {
                        self.onMarkComplete()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("mark-escalation-complete")

                    Button {
                        self.onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .accessibilityIdentifier("delete-escalation-\(String(format: "%.2f", self.titration.toDose))mg")
                }
            }
        }
    }
}

struct CreateTitrationView: View {
    let profile: MedicationProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var targetDose: Double
    @State private var scheduledDate = Calendar.current.date(byAdding: .weekOfYear, value: 4, to: Date()) ?? Date()
    @State private var notes = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    // Available dose options based on medication type
    private var availableDoses: [Double] {
        guard let medication = Medication(rawValue: profile.medicationType) else { return [] }
        return medication.availableDoses(for: self.profile.brandName)
            .filter { $0 > self.profile.currentDose } // Only show higher doses
    }

    init(profile: MedicationProfile) {
        self.profile = profile
        // Initialize with next available dose higher than current
        let medication = Medication(rawValue: profile.medicationType)
        let nextDose = medication?.availableDoses(for: profile.brandName)
            .first { $0 > profile.currentDose } ?? profile.currentDose + 0.25
        self._targetDose = State(initialValue: nextDose)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Escalation Details") {
                    HStack {
                        Text("From Dose")
                        Spacer()
                        Text("\(String(format: "%.2f", self.profile.currentDose)) mg")
                            .foregroundColor(.secondary)
                    }

                    Picker("Target Dose", selection: self.$targetDose) {
                        ForEach(self.availableDoses, id: \.self) { dose in
                            Text("\(String(format: "%.2f", dose)) mg")
                                .tag(dose)
                                .accessibilityIdentifier("escalation-dose-option-\(String(format: "%.2f", dose))")
                        }
                    }
                    .accessibilityIdentifier("escalation-target-dose-picker")

                    DatePicker("Scheduled Date", selection: self.$scheduledDate, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    TextField("Notes (optional)", text: self.$notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("New Escalation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        self.saveTitration()
                    }
                    .accessibilityIdentifier("save-escalation-plan")
                }
            }
            .alert("Error", isPresented: self.$showingError) {
                Button("OK") {}
            } message: {
                Text(self.errorMessage)
            }
        }
    }

    private func saveTitration() {
        // Validate input
        guard self.targetDose > self.profile.currentDose else {
            self.errorMessage = "Target dose must be higher than current dose."
            self.showingError = true
            return
        }

        guard self.scheduledDate >= Date() else {
            self.errorMessage = "Scheduled date must be in the future."
            self.showingError = true
            return
        }

        // Create new titration
        let titration = DoseTitration(
            fromDose: profile.currentDose,
            toDose: self.targetDose,
            scheduledDate: self.scheduledDate,
            notes: self.notes,
            medicationProfile: self.profile)

        self.modelContext.insert(titration)

        do {
            try self.modelContext.save()
            self.dismiss()
        } catch {
            self.errorMessage = "Failed to save titration plan: \(error.localizedDescription)"
            self.showingError = true
        }
    }
}

#Preview {
    @Previewable @State var sampleProfile = MedicationProfile(
        genericName: "Semaglutide",
        brandName: "Ozempic", 
        currentDose: 0.25,
        medicationType: "semaglutide"
    )
    
    DoseTitrationView(profile: sampleProfile)
}
