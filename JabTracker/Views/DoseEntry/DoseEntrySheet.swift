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
    @StateObject private var doseService: DoseService

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
        self._doseService = StateObject(wrappedValue: DoseService(pkEngine: engine))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Medication Selection Section
                medicationSection

                // Dose Details Section
                doseDetailsSection

                // Timing Section
                timingSection

                // Additional Information Section
                additionalInfoSection

                // Photo Section
                photoSection

                // PK Integration Info
                if let selectedProfile = selectedMedicationProfile {
                    pkIntegrationSection(for: selectedProfile)
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

    // MARK: - Form Sections

    @ViewBuilder
    private var medicationSection: some View {
        Section {
            Picker("Medication", selection: $selectedMedicationProfile) {
                ForEach(medicationProfiles, id: \.id) { profile in
                    Text("\(profile.brandName) (\(profile.currentDose, specifier: "%.2f") mg)")
                        .tag(profile as MedicationProfile?)
                }
            }
            .accessibilityIdentifier("dose-entry-medication-picker")

            if medicationProfiles.isEmpty {
                Text("No medication profiles found")
                    .foregroundColor(.secondary)
                    .italic()
                    .accessibilityIdentifier("no-medications-message")
            }
        } header: {
            Text("Medication")
        } footer: {
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .accessibilityIdentifier("dose-entry-error")
            }

            if let serviceError = doseService.lastError {
                Text(serviceError.localizedDescription)
                    .foregroundColor(.red)
                    .accessibilityIdentifier("dose-service-error")
            }
        }
    }

    @ViewBuilder
    private var doseDetailsSection: some View {
        Section {
            // Dose Amount
            HStack {
                Text("Amount")
                Spacer()
                TextField("Amount", value: $doseAmount, format: .number.precision(.fractionLength(2)))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("dose-entry-amount-field")
                Text("mg")
                    .foregroundColor(.secondary)
            }

            // Injection Site
            if !isSkipped {
                Picker("Injection Site", selection: $selectedInjectionSite) {
                    ForEach(DoseDefaults.allInjectionSites, id: \.self) { site in
                        Text(site).tag(site)
                    }
                }
                .accessibilityIdentifier("dose-entry-site-picker")
            }

            // Skipped toggle
            Toggle("Missed/Skipped Dose", isOn: $isSkipped)
                .accessibilityIdentifier("dose-entry-skipped-toggle")
                .onChange(of: isSkipped) { _, skipped in
                    if skipped {
                        selectedInjectionSite = ""
                        dosePhotoData = nil
                        selectedPhotoItem = nil
                    }
                }
        } header: {
            Text("Dose Details")
        } footer: {
            if isSkipped {
                Text("Skipped doses are recorded for tracking but don't affect concentration calculations")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("skipped-dose-explanation")
            }
        }
    }

    @ViewBuilder
    private var timingSection: some View {
        Section {
            DatePicker(
                "Date & Time",
                selection: $doseTime,
                displayedComponents: [.date, .hourAndMinute]
            )
            .accessibilityIdentifier("dose-entry-datetime-picker")
        } header: {
            Text("Timing")
        }
    }

    @ViewBuilder
    private var additionalInfoSection: some View {
        Section {
            TextField("Notes (Optional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .accessibilityIdentifier("dose-entry-notes")
        } header: {
            Text("Additional Information")
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        if !isSkipped {
            Section {
                if let photoData = dosePhotoData, let uiImage = UIImage(data: photoData) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                            .accessibilityIdentifier("dose-entry-photo-preview")

                        Button("Change Photo") {
                            showingPhotoOptions = true
                        }
                        .accessibilityIdentifier("dose-entry-change-photo")

                        Button("Remove Photo", role: .destructive) {
                            dosePhotoData = nil
                            selectedPhotoItem = nil
                        }
                        .accessibilityIdentifier("dose-entry-remove-photo")
                    }
                } else {
                    Button("Add Photo") {
                        showingPhotoOptions = true
                    }
                    .accessibilityIdentifier("dose-entry-add-photo")
                }
            } header: {
                Text("Photo (Optional)")
            }
            .photosPicker(isPresented: $showingPhotoOptions, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        dosePhotoData = data
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func pkIntegrationSection(for profile: MedicationProfile) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                    Text("Pharmacokinetics Impact")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }

                if !isSkipped, let medication = profile.medication {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("• Peak concentration in ~\(Int(medication.peakTimeHours)) hours")
                        Text("• Calculations will update dashboard automatically")
                        Text("• Half-life: \(medication.halfLifeDays, specifier: "%.1f") days")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                } else if isSkipped {
                    Text("Skipped doses don't affect concentration calculations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        } header: {
            Text("Impact Preview")
        }
        .accessibilityIdentifier("pk-impact-section")
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
        appleUserId: "preview-user",
        email: "preview@example.com",
        name: "Preview User"
    )

    let medicationProfile = MedicationProfile(
        user: user,
        medicationName: "semaglutide",
        dosage: 1.0,
        frequency: .weekly,
        startDate: Date().addingTimeInterval(-30 * 24 * 3600)
    )

    context.insert(user)
    context.insert(medicationProfile)

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

    return DoseEntrySheet.edit(
        dose: editData,
        onDoseSaved: { print("Dose updated") },
        onCalculationsUpdated: { print("Calculations updated") }
    )
    .modelContainer(container)
}
