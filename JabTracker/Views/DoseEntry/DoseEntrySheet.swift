//
//  DoseEntrySheet.swift
//  JabTracker
//
//  Comprehensive dose entry sheet with full editing capabilities and PK integration
//  Supports creating new doses, editing existing doses, and triggering dashboard updates
//

import SwiftData
import SwiftUI
import PhotosUI

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
    @State private var doseTime: Date = Date()
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
                    selectedMedicationProfile: $selectedMedicationProfile,
                    medicationProfiles: medicationProfiles,
                    errorMessage: errorMessage,
                    serviceError: doseService.lastError
                )

                // Dose Details Section
                DoseEntryFormSections.DoseDetailsSection(
                    doseAmount: $doseAmount,
                    selectedInjectionSite: $selectedInjectionSite,
                    isSkipped: $isSkipped,
                    dosePhotoData: $dosePhotoData,
                    selectedPhotoItem: $selectedPhotoItem
                )

                // Timing Section
                DoseEntryFormSections.TimingSection(doseTime: $doseTime)

                // Additional Information Section
                DoseEntryFormSections.AdditionalInfoSection(notes: $notes)

                // Photo Section
                DoseEntryPhotoSection(
                    dosePhotoData: $dosePhotoData,
                    selectedPhotoItem: $selectedPhotoItem,
                    showingPhotoOptions: $showingPhotoOptions,
                    isSkipped: isSkipped
                )

                // PK Integration Info
                if let selectedProfile = selectedMedicationProfile {
                    DoseEntryPKSection(
                        medicationProfile: selectedProfile,
                        isSkipped: isSkipped
                    )
                }
            }
            .navigationTitle(mode == .create ? "Add Dose" : "Edit Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("dose-entry-cancel")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(mode == .create ? "Save" : "Update") {
                        Task {
                            await saveDose()
                        }
                    }
                    .disabled(!canSaveDose || isSubmitting)
                    .accessibilityIdentifier("dose-entry-save")
                }
            }
            .onAppear {
                loadData()
            }
        }
        .accessibilityIdentifier("dose-entry-sheet")
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Computed Properties

    private var canSaveDose: Bool {
        guard selectedMedicationProfile != nil else { return false }
        guard doseAmount > 0 || isSkipped else { return false }
        guard !selectedInjectionSite.isEmpty || isSkipped else { return false }
        guard !doseService.isProcessingDose else { return false }
        return true
    }

    // MARK: - Data Loading

    private func loadData() {
        Task { @MainActor in
            do {
                // Fetch medication profiles
                let profileDescriptor = FetchDescriptor<MedicationProfile>()
                medicationProfiles = try modelContext.fetch(profileDescriptor)

                if mode == .edit, let editData = editingDose {
                    // Load editing data
                    selectedMedicationProfile = editData.medicationProfile
                    doseAmount = editData.amount
                    doseTime = editData.timestamp
                    selectedInjectionSite = editData.site ?? ""
                    notes = editData.notes ?? ""
                    isSkipped = editData.skipped
                    dosePhotoData = editData.imageData
                } else {
                    // Set defaults for new dose
                    selectedMedicationProfile = medicationProfiles.first
                    if let profile = selectedMedicationProfile {
                        doseAmount = profile.currentDose
                        selectedInjectionSite = DoseDefaults.nextRecommendedSite(
                            for: profile.medication ?? .semaglutide,
                            recentDoses: Array((profile.doses ?? []).suffix(5)),
                            preferredSites: profile.preferredInjectionSites
                        )
                    }
                }

                if medicationProfiles.isEmpty {
                    errorMessage = "No medication profiles found. Please create a medication profile first."
                }

            } catch {
                errorMessage = "Failed to load medication profiles: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Dose Saving

    @MainActor
    private func saveDose() async {
        guard let profile = selectedMedicationProfile else { return }

        isSubmitting = true
        errorMessage = nil

        do {
            if mode == .edit, let editData = editingDose {
                // Update existing dose
                let updatedEditData = DoseEditData(
                    id: editData.id,
                    amount: doseAmount,
                    timestamp: doseTime,
                    site: isSkipped ? nil : selectedInjectionSite,
                    notes: notes.isEmpty ? nil : notes,
                    imageData: dosePhotoData,
                    skipped: isSkipped,
                    medicationProfile: profile
                )

                try await doseService.updateDose(with: updatedEditData, context: modelContext)
            } else {
                // Create new dose
                _ = try await doseService.saveDose(
                    amount: doseAmount,
                    timestamp: doseTime,
                    medicationProfile: profile,
                    site: isSkipped ? nil : selectedInjectionSite,
                    notes: notes.isEmpty ? nil : notes,
                    skipped: isSkipped,
                    imageData: dosePhotoData,
                    context: modelContext
                )
            }

            // Success - trigger callbacks and dismiss
            onDoseSaved?()
            onCalculationsUpdated?()

            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

            dismiss()

        } catch {
            errorMessage = "Failed to save dose: \(error.localizedDescription)"
        }

        isSubmitting = false
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
            onCalculationsUpdated: onCalculationsUpdated
        )
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
            onCalculationsUpdated: onCalculationsUpdated
        )
    }
}

// MARK: - Preview

#Preview("Create Dose") {
    DoseEntrySheet.create(
        onDoseSaved: { print("Dose saved") },
        onCalculationsUpdated: { print("Calculations updated") }
    )
    .modelContainer(DataController.preview.container)
}

#Preview("Edit Dose") {
    let container = DataController.preview.container
    let context = container.mainContext

    // Create sample data for editing preview
    let user = User(
        email: "preview@example.com",
        name: "Preview User",
        appleUserId: "preview-user"
    )

    let medicationProfile = MedicationProfile(
        genericName: "semaglutide",
        brandName: "Ozempic",
        currentDose: 1.0,
        startDate: Date().addingTimeInterval(-30 * 24 * 3600),
        medicationType: "semaglutide"
    )

    // context.insert(user)
    // context.insert(medicationProfile)

    let editData = DoseEditData(
        id: UUID(),
        amount: 1.0,
        timestamp: Date().addingTimeInterval(-3600),
        site: "Abdomen",
        notes: "Preview dose for editing",
        imageData: nil,
        skipped: false,
        medicationProfile: medicationProfile
    )

    DoseEntrySheet.edit(
        dose: editData,
        onDoseSaved: { print("Dose updated") },
        onCalculationsUpdated: { print("Calculations updated") }
    )
    .modelContainer(container)
}
