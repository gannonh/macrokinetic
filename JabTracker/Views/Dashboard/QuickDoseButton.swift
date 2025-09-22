//
//  QuickDoseButton.swift
//  JabTracker
//

import SwiftData
import SwiftUI

/// Self-contained SwiftUI component for quick dose entry with smart defaults
/// Presents as a sheet from the Add tab button for streamlined dose logging
/// Enhanced with pharmacokinetics integration for automatic dashboard updates
struct QuickDoseButton: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @StateObject private var viewModel = QuickDoseViewModel()
  @State private var pkEngine: PharmacokineticsEngine
  @State private var doseService: DoseService
  @State private var showingQuickDoseSheet = false
  @State private var showingSuccessMessage = false

  // Dashboard update callbacks
  let onDoseSaved: (() -> Void)?
  let onCalculationsUpdated: (() -> Void)?

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
      action: {
        self.showingQuickDoseSheet = true
      },
      label: {
        Label("Quick Add Dose", systemImage: "plus.circle.fill")
      }
    )
    .buttonStyle(.borderedProminent)
    .accessibilityIdentifier("quick-add-dose-button")
    .sheet(
      isPresented: self.$showingQuickDoseSheet,
      content: {
        QuickDoseSheet(
          viewModel: self.viewModel,
          doseService: self.doseService,
          showingSuccessMessage: self.$showingSuccessMessage,
          onDoseSaved: self.onDoseSaved,
          onCalculationsUpdated: self.onCalculationsUpdated)
      }
    )
    .onAppear {
      self.viewModel.loadSmartDefaults(context: self.modelContext)
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
          .accessibilityIdentifier("dose-logged-success")
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
  }
}

/// Sheet component for streamlined dose entry with minimal required fields
/// Enhanced with pharmacokinetics integration and dose service coordination
struct QuickDoseSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

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

          // Dose Amount (from selected medication profile)
          HStack {
            Text("Dose Amount")
            Spacer()
            Text("\(self.viewModel.doseAmount, specifier: "%.2f") mg")
              .foregroundColor(.secondary)
              .accessibilityIdentifier("quick-dose-amount")
          }

          // Injection Site Selection
          Picker("Injection Site", selection: self.$viewModel.selectedInjectionSite) {
            ForEach(self.viewModel.recommendedInjectionSites, id: \.self) { site in
              Text(site).tag(site)
            }
          }
          .accessibilityIdentifier("quick-dose-site-picker")
          .accessibilityLabel("Select injection site")

          // Time Display/Picker
          if self.isEditMode {
            // Date/Time picker for editing
            DatePicker(
              "Date",
              selection: self.$viewModel.doseTime,
              displayedComponents: [.date, .hourAndMinute]
            )
            .accessibilityIdentifier("quick-dose-datetime-picker")
            .accessibilityLabel("Select dose date and time")
          } else {
            // Read-only time display for new doses
            HStack {
              Text("Time")
              Spacer()
              Text(self.viewModel.doseTime.formatted(date: .omitted, time: .shortened))
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
            print("🔍 QuickDoseSheet: Save button tapped!")
            if self.isEditMode {
              print("🔍 QuickDoseSheet: Handling edit save")
              self.handleEditSave()
            } else {
              print("🔍 QuickDoseSheet: Handling new dose save")
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
    else { return }

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
      print("🔍 QuickDoseSheet.saveDose: No selected medication profile")
      return
    }

    print("🔍 QuickDoseSheet.saveDose called with:")
    print("  - amount: \(self.viewModel.doseAmount)")
    let siteDescription =
      self.viewModel.selectedInjectionSite.isEmpty ? "nil" : self.viewModel.selectedInjectionSite
    print("  - site: \(siteDescription)")
    print("  - notes: \(self.viewModel.notes.isEmpty ? "nil" : self.viewModel.notes)")

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

      print("🔍 QuickDoseSheet.saveDose: Successfully saved dose")

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

      // Dismiss sheet
      self.dismiss()

    } catch {
      // Error is handled by doseService and displayed in UI
      print("Error saving dose with PK integration: \(error)")
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
