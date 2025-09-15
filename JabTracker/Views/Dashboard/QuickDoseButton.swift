//
//  QuickDoseButton.swift
//  JabTracker
//

import SwiftUI
import SwiftData

/// Self-contained SwiftUI component for quick dose entry with smart defaults
/// Presents as a sheet from the Add tab button for streamlined dose logging
struct QuickDoseButton: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = QuickDoseViewModel()
    @State private var showingQuickDoseSheet = false
    @State private var showingSuccessMessage = false
    
    var body: some View {
        Button(action: {
            showingQuickDoseSheet = true
        }, label: {
            Label("Quick Add Dose", systemImage: "plus.circle.fill")
        })
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("quick-add-dose-button")
        .sheet(isPresented: $showingQuickDoseSheet,
               content: {
            QuickDoseSheet(
                viewModel: viewModel,
                showingSuccessMessage: $showingSuccessMessage
            )
        })
        .onAppear {
            viewModel.loadSmartDefaults(context: modelContext)
        }
        .overlay(alignment: .top) {
            if showingSuccessMessage {
                Text("Dose logged successfully!")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.9))
                    .cornerRadius(8)
                    .accessibilityIdentifier("dose-logged-success")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        // Auto-dismiss success message after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showingSuccessMessage = false
                            }
                        }
                    }
            }
        }
    }
}

/// Sheet component for streamlined dose entry with minimal required fields
struct QuickDoseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @ObservedObject var viewModel: QuickDoseViewModel
    @Binding var showingSuccessMessage: Bool

    // Edit mode support
    let editingDose: DoseEditData?
    let onSave: ((DoseEditData) -> Void)?
    let onCancel: (() -> Void)?

    // Convenience initializer for create mode (existing behavior)
    init(viewModel: QuickDoseViewModel, showingSuccessMessage: Binding<Bool>) {
        self.viewModel = viewModel
        self._showingSuccessMessage = showingSuccessMessage
        self.editingDose = nil
        self.onSave = nil
        self.onCancel = nil
    }

    // Full initializer for edit mode
    init(editingDose: DoseEditData, onSave: @escaping (DoseEditData) -> Void, onCancel: @escaping () -> Void) {
        self.editingDose = editingDose
        self.onSave = onSave
        self.onCancel = onCancel

        // Create a temporary view model for edit mode
        self.viewModel = QuickDoseViewModel()
        self._showingSuccessMessage = .constant(false)
    }

    private var isEditMode: Bool {
        editingDose != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Medication Selection
                    Picker("Medication", selection: $viewModel.selectedMedicationProfile) {
                        ForEach(viewModel.medicationProfiles, id: \.id) { profile in
                            Text("\(profile.brandName) (\(profile.currentDose, specifier: "%.2f") mg)")
                                .tag(profile as MedicationProfile?)
                        }
                    }
                    .accessibilityIdentifier("quick-dose-medication-picker")
                    .accessibilityLabel("Select medication")
                    
                    // Dose Amount (from selected medication profile)
                    HStack {
                        Text("Dose Amount")
                        Spacer()
                        Text("\(viewModel.doseAmount, specifier: "%.2f") mg")
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("quick-dose-amount")
                    }
                    
                    // Injection Site Selection
                    Picker("Injection Site", selection: $viewModel.selectedInjectionSite) {
                        ForEach(viewModel.recommendedInjectionSites, id: \.self) { site in
                            Text(site).tag(site)
                        }
                    }
                    .accessibilityIdentifier("quick-dose-site-picker")
                    .accessibilityLabel("Select injection site")
                    
                    // Time Display/Picker
                    if isEditMode {
                        // Date/Time picker for editing
                        DatePicker(
                            "Date",
                            selection: $viewModel.doseTime,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .accessibilityIdentifier("quick-dose-datetime-picker")
                        .accessibilityLabel("Select dose date and time")
                    } else {
                        // Read-only time display for new doses
                        HStack {
                            Text("Time")
                            Spacer()
                            Text(viewModel.doseTime.formatted(date: .omitted, time: .shortened))
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("quick-dose-time")
                        }
                    }
                } header: {
                    Text("Dose Details")
                } footer: {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .accessibilityIdentifier("no-medication-profiles-error")
                    }
                }
                
                // Optional Notes Section (streamlined)
                Section {
                    TextField("Notes (Optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(2)
                        .accessibilityIdentifier("quick-dose-notes")
                        .accessibilityLabel("Optional notes")
                } header: {
                    Text("Additional Information")
                }
            }
            .navigationTitle(isEditMode ? "Edit Dose" : "Quick Add Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if let onCancel = onCancel {
                            onCancel()
                        } else {
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("quick-dose-cancel-button")
                    .accessibilityLabel("Cancel dose entry")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if isEditMode {
                            handleEditSave()
                        } else {
                            Task {
                                await saveDose()
                            }
                        }
                    }
                    .disabled(!viewModel.canSaveDose)
                    .accessibilityIdentifier("quick-dose-save-button")
                    .accessibilityLabel("Save dose")
                }
            }
            .onAppear {
                if isEditMode, let editData = editingDose {
                    viewModel.loadEditData(editData, context: modelContext)
                } else {
                    viewModel.loadSmartDefaults(context: modelContext)
                }
            }
        }
        .accessibilityIdentifier("quick-dose-sheet")
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func handleEditSave() {
        guard let editData = editingDose, let onSave = onSave else { return }

        // Create updated dose data from current view model state
        let updatedDose = DoseEditData(
            id: editData.id,
            amount: viewModel.doseAmount,
            timestamp: viewModel.doseTime,
            site: viewModel.selectedInjectionSite.isEmpty ? nil : viewModel.selectedInjectionSite,
            notes: viewModel.notes.isEmpty ? nil : viewModel.notes,
            imageData: editData.imageData, // Keep existing image data
            skipped: editData.skipped, // Keep existing skipped status
            medicationProfile: viewModel.selectedMedicationProfile
        )

        onSave(updatedDose)
    }

    @MainActor
    private func saveDose() async {
        do {
            try await viewModel.saveDose(context: modelContext)
            
            // Provide haptic feedback for successful save
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Show success message
            withAnimation {
                showingSuccessMessage = true
            }
            
            // Dismiss sheet
            dismiss()
            
        } catch {
            // Error is handled by viewModel and displayed in UI
            print("Error saving dose: \(error)")
        }
    }
}

#Preview {
    QuickDoseButton()
        .modelContainer(DataController.preview.container)
}

#Preview("Sheet") {
    @Previewable @State var showingSuccess = false
    let viewModel = QuickDoseViewModel()
    
    return QuickDoseSheet(
        viewModel: viewModel,
        showingSuccessMessage: $showingSuccess
    )
    .modelContainer(DataController.preview.container)
}
