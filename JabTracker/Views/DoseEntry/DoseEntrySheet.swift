//
//  DoseEntrySheet.swift
//  JabTracker
//
//  Comprehensive dose entry sheet with full editing capabilities and PK integration
//  Supports creating new doses, editing existing doses, and triggering dashboard updates
//

import PhotosUI
import SwiftData
import SwiftUI

/// Comprehensive dose entry sheet with pharmacokinetics engine integration
/// Supports both creating new doses and editing existing doses with automatic PK updates
struct DoseEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // PK Engine and Dose Service
    @State private var doseService: DoseService

    // Mode: create or edit
    private let mode: Mode
    private let editingDose: DoseEditData?

    // Event handlers
    let onDoseSaved: (() -> Void)?
    let onCalculationsUpdated: (() -> Void)?

    // UI State
    @State private var medicationProfiles: [MedicationProfile] = []
    @State private var selectedMedicationProfile: MedicationProfile?
    @State private var doseAmount: Double = 0.0
    @State private var doseTime: Date = .init()
    @State private var selectedInjectionSite: String = ""
    @State private var notes: String = ""
    @State private var isSkipped: Bool = false

    // Photo handling
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var dosePhotoData: Data?
    @State private var showingPhotoOptions = false

    // Validation and errors
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    // MARK: - Mode Enum

    enum Mode {
        case create
        case edit
    }

    // MARK: - Initialization

    init(
        mode: Mode = .create,
        editingDose: DoseEditData? = nil,
        pkEngine: PharmacokineticsEngine? = nil,
        onDoseSaved: (() -> Void)? = nil,
        onCalculationsUpdated: (() -> Void)? = nil
    ) {
        self.mode = mode
        self.editingDose = editingDose
        self.onDoseSaved = onDoseSaved
        self.onCalculationsUpdated = onCalculationsUpdated

        let engine = pkEngine ?? PharmacokineticsEngine()
        self._doseService = State(wrappedValue: DoseService(pkEngine: engine))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Medication Selection Section
                DoseEntryFormSections.MedicationSection(
                    selectedMedicationProfile: self.$selectedMedicationProfile,
                    medicationProfiles: self.medicationProfiles,
                    errorMessage: self.errorMessage,
                    serviceError: self.doseService.lastError)

                // Dose Details Section
                DoseEntryFormSections.DoseDetailsSection(
                    doseAmount: self.$doseAmount,
                    selectedInjectionSite: self.$selectedInjectionSite,
                    isSkipped: self.$isSkipped,
                    dosePhotoData: self.$dosePhotoData,
                    selectedPhotoItem: self.$selectedPhotoItem)

                // Timing Section
                DoseEntryFormSections.TimingSection(doseTime: self.$doseTime)

                // Additional Information Section
                DoseEntryFormSections.AdditionalInfoSection(notes: self.$notes)

                // Photo Section
                DoseEntryPhotoSection(
                    dosePhotoData: self.$dosePhotoData,
                    selectedPhotoItem: self.$selectedPhotoItem,
                    showingPhotoOptions: self.$showingPhotoOptions,
                    isSkipped: self.isSkipped)

                // PK Integration Info
                if let selectedProfile = selectedMedicationProfile {
                    DoseEntryPKSection(
                        medicationProfile: selectedProfile,
                        isSkipped: self.isSkipped)
                }
            }
            .navigationTitle(self.mode == .create ? "Add Dose" : "Edit Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                    .accessibilityIdentifier("dose-entry-cancel")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(self.mode == .create ? "Save" : "Update") {
                        Task {
                            await self.saveDose()
                        }
                    }
                    .disabled(!self.canSaveDose || self.isSubmitting)
                    .accessibilityIdentifier("dose-entry-save")
                }
            }
            .onAppear {
                self.loadData()
            }
        }
        .accessibilityIdentifier("dose-entry-sheet")
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Computed Properties

    private var canSaveDose: Bool {
        guard self.selectedMedicationProfile != nil else { return false }
        guard self.doseAmount > 0 || self.isSkipped else { return false }
        guard !self.selectedInjectionSite.isEmpty || self.isSkipped else { return false }
        guard !self.doseService.isProcessingDose else { return false }
        return true
    }

    // MARK: - Data Loading

    private func loadData() {
        Task { @MainActor in
            do {
                // Fetch medication profiles
                let profileDescriptor = FetchDescriptor<MedicationProfile>()
                self.medicationProfiles = try self.modelContext.fetch(profileDescriptor)

                if self.mode == .edit, let editData = editingDose {
                    // Load editing data
                    self.selectedMedicationProfile = editData.medicationProfile
                    self.doseAmount = editData.amount
                    self.doseTime = editData.timestamp
                    self.selectedInjectionSite = editData.site ?? ""
                    self.notes = editData.notes ?? ""
                    self.isSkipped = editData.skipped
                    self.dosePhotoData = editData.imageData
                } else {
                    // Set defaults for new dose
                    self.selectedMedicationProfile = self.medicationProfiles.first
                    if let profile = selectedMedicationProfile {
                        self.doseAmount = profile.currentDose
                        self.selectedInjectionSite = DoseDefaults.nextRecommendedSite(
                            for: profile.medication ?? .semaglutide,
                            recentDoses: Array((profile.doses ?? []).suffix(5)),
                            preferredSites: profile.preferredInjectionSites)
                    }
                }

                if self.medicationProfiles.isEmpty {
                    self.errorMessage =
                        "No medication profiles found. Please create a medication profile first."
                }

            } catch {
                self.errorMessage = "Failed to load medication profiles: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Dose Saving

    @MainActor
    private func saveDose() async {
        guard let profile = selectedMedicationProfile else { return }

        self.isSubmitting = true
        self.errorMessage = nil

        do {
            if self.mode == .edit, let editData = editingDose {
                // Update existing dose
                let updatedEditData = DoseEditData(
                    id: editData.id,
                    amount: self.doseAmount,
                    timestamp: self.doseTime,
                    site: self.isSkipped ? nil : self.selectedInjectionSite,
                    notes: self.notes.isEmpty ? nil : self.notes,
                    imageData: self.dosePhotoData,
                    skipped: self.isSkipped,
                    medicationProfile: profile)

                try await self.doseService.updateDose(with: updatedEditData, context: self.modelContext)
            } else {
                // Create new dose
                _ = try await self.doseService.saveDose(
                    amount: self.doseAmount,
                    timestamp: self.doseTime,
                    medicationProfile: profile,
                    site: self.isSkipped ? nil : self.selectedInjectionSite,
                    notes: self.notes.isEmpty ? nil : self.notes,
                    skipped: self.isSkipped,
                    imageData: self.dosePhotoData,
                    context: self.modelContext)
            }

            // Success - trigger callbacks and dismiss
            self.onDoseSaved?()
            self.onCalculationsUpdated?()

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            self.dismiss()

        } catch {
            self.errorMessage = "Failed to save dose: \(error.localizedDescription)"
        }

        self.isSubmitting = false
    }
}

// MARK: - Convenience Initializers

extension DoseEntrySheet {
    /// Create sheet for new dose entry
    static func create(
        pkEngine: PharmacokineticsEngine? = nil,
        onDoseSaved: (() -> Void)? = nil,
        onCalculationsUpdated: (() -> Void)? = nil
    ) -> DoseEntrySheet {
        DoseEntrySheet(
            mode: .create,
            editingDose: nil,
            pkEngine: pkEngine,
            onDoseSaved: onDoseSaved,
            onCalculationsUpdated: onCalculationsUpdated)
    }

    /// Create sheet for editing existing dose
    static func edit(
        dose: DoseEditData,
        pkEngine: PharmacokineticsEngine? = nil,
        onDoseSaved: (() -> Void)? = nil,
        onCalculationsUpdated: (() -> Void)? = nil
    ) -> DoseEntrySheet {
        DoseEntrySheet(
            mode: .edit,
            editingDose: dose,
            pkEngine: pkEngine,
            onDoseSaved: onDoseSaved,
            onCalculationsUpdated: onCalculationsUpdated)
    }
}
