//
//  DoseEntrySheet.swift
//  JabTracker
//
//  Comprehensive dose entry and editing sheet with full form capabilities
//  Supports both creating new doses and editing existing doses
//

import SwiftUI
import SwiftData
import PhotosUI

/// Comprehensive dose entry sheet that supports both add and edit modes
/// Pre-populates form data when editing existing doses
struct DoseEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Configuration
    
    /// Determines if this is edit mode or add mode
    let editMode: Bool
    
    /// Dose being edited (nil for new doses)
    let doseToEdit: Dose?
    
    /// Edit data for pre-populating form
    let editData: DoseEditData?
    
    /// Success message binding
    @Binding var showingSuccessMessage: Bool
    
    /// Success message text
    let successMessage: String
    
    // MARK: - Form State
    
    @State private var selectedMedicationProfile: MedicationProfile?
    @State private var doseAmount: String = ""
    @State private var selectedInjectionSite: String = "Thigh"
    @State private var doseTimestamp: Date = Date()
    @State private var notes: String = ""
    @State private var isSkipped: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    
    // MARK: - UI State
    
    @State private var medicationProfiles: [MedicationProfile] = []
    @State private var availableInjectionSites: [String] = [
        "Thigh", "Abdomen", "Upper Arm", "Buttock"
    ]
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    
    // MARK: - Computed Properties
    
    private var navigationTitle: String {
        editMode ? "Edit Dose" : "Add Dose"
    }
    
    private var saveButtonText: String {
        editMode ? "Update" : "Save"
    }
    
    private var canSave: Bool {
        selectedMedicationProfile != nil &&
        !doseAmount.isEmpty &&
        Double(doseAmount) != nil &&
        !selectedInjectionSite.isEmpty
    }
    
    // MARK: - Initializers
    
    /// Initialize for adding new dose
    init(showingSuccessMessage: Binding<Bool>) {
        self.editMode = false
        self.doseToEdit = nil
        self.editData = nil
        self._showingSuccessMessage = showingSuccessMessage
        self.successMessage = "Dose logged successfully!"
    }
    
    /// Initialize for editing existing dose
    init(
        doseToEdit: Dose,
        editData: DoseEditData,
        showingSuccessMessage: Binding<Bool>
    ) {
        self.editMode = true
        self.doseToEdit = doseToEdit
        self.editData = editData
        self._showingSuccessMessage = showingSuccessMessage
        self.successMessage = "Dose updated successfully!"
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                medicationSection
                doseDetailsSection
                timingSection
                additionalInfoSection
                if editMode {
                    statusSection
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("dose-entry-cancel-button")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(saveButtonText) {
                        Task {
                            await saveDose()
                        }
                    }
                    .disabled(!canSave || isLoading)
                    .accessibilityIdentifier("dose-entry-save-button")
                }
            }
            .onAppear {
                loadInitialData()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
        .accessibilityIdentifier("dose-entry-sheet")
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Form Sections
    
    private var medicationSection: some View {
        Section {
            Picker("Medication", selection: $selectedMedicationProfile) {
                Text("Select Medication")
                    .tag(nil as MedicationProfile?)
                
                ForEach(medicationProfiles, id: \.id) { profile in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.brandName)
                                .font(.headline)
                            Text(profile.genericName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(profile.currentDose, specifier: "%.2f") mg")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(profile as MedicationProfile?)
                }
            }
            .accessibilityIdentifier("medication-picker")
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        } header: {
            Text("Medication")
        } footer: {
            if medicationProfiles.isEmpty {
                Text("No medication profiles found. Add a medication profile in Settings first.")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var doseDetailsSection: some View {
        Section {
            HStack {
                Text("Amount")
                Spacer()
                TextField("0.0", text: $doseAmount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .accessibilityIdentifier("dose-amount-field")
                Text("mg")
                    .foregroundColor(.secondary)
            }
            
            Picker("Injection Site", selection: $selectedInjectionSite) {
                ForEach(availableInjectionSites, id: \.self) { site in
                    Text(site).tag(site)
                }
            }
            .accessibilityIdentifier("injection-site-picker")
        } header: {
            Text("Dose Details")
        }
    }
    
    private var timingSection: some View {
        Section {
            DatePicker(
                "Date & Time",
                selection: $doseTimestamp,
                displayedComponents: [.date, .hourAndMinute]
            )
            .accessibilityIdentifier("dose-timestamp-picker")
        } header: {
            Text("Timing")
        }
    }
    
    private var additionalInfoSection: some View {
        Section {
            TextField("Notes (Optional)", text: $notes, axis: .vertical)
                .lineLimit(3...6)
                .accessibilityIdentifier("dose-notes-field")
            
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: photoData != nil ? "photo.fill" : "photo")
                        .foregroundColor(photoData != nil ? .blue : .secondary)
                    Text(photoData != nil ? "Photo Selected" : "Add Photo")
                        .foregroundColor(photoData != nil ? .blue : .primary)
                    Spacer()
                    if photoData != nil {
                        Button("Remove") {
                            photoData = nil
                            selectedPhotoItem = nil
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
            }
            .accessibilityIdentifier("photo-picker")
        } header: {
            Text("Additional Information")
        }
    }
    
    private var statusSection: some View {
        Section {
            Toggle("Mark as Skipped", isOn: $isSkipped)
                .accessibilityIdentifier("dose-skipped-toggle")
        } header: {
            Text("Status")
        } footer: {
            Text("Skipped doses are tracked but don't contribute to medication level calculations.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() {
        loadMedicationProfiles()
        
        if editMode, let editData = editData {
            // Pre-populate form with edit data
            selectedMedicationProfile = editData.medicationProfile
            doseAmount = String(editData.amount)
            selectedInjectionSite = editData.site ?? "Thigh"
            doseTimestamp = editData.timestamp
            notes = editData.notes ?? ""
            isSkipped = editData.skipped
            photoData = editData.imageData
        } else {
            // Load smart defaults for new dose
            loadSmartDefaults()
        }
    }
    
    private func loadMedicationProfiles() {
        do {
            let descriptor = FetchDescriptor<MedicationProfile>(
                sortBy: [SortDescriptor(\MedicationProfile.brandName)]
            )
            medicationProfiles = try modelContext.fetch(descriptor)
            
            // Auto-select first profile if adding new dose and no current selection
            if !editMode && selectedMedicationProfile == nil && !medicationProfiles.isEmpty {
                selectedMedicationProfile = medicationProfiles.first
            }
        } catch {
            errorMessage = "Failed to load medication profiles: \(error.localizedDescription)"
        }
    }
    
    private func loadSmartDefaults() {
        // Set default amount from selected medication profile
        if let profile = selectedMedicationProfile {
            doseAmount = String(profile.currentDose)
        }
        
        // Smart injection site rotation could be implemented here
        // For now, keep default "Thigh"
        
        // Default to current time
        doseTimestamp = Date()
    }
    
    // MARK: - Save Operations
    
    @MainActor
    private func saveDose() async {
        guard canSave else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let amount = Double(doseAmount) ?? 0.0
            
            if editMode {
                try await updateExistingDose(amount: amount)
            } else {
                try await createNewDose(amount: amount)
            }
            
            // Provide haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Show success message
            withAnimation {
                showingSuccessMessage = true
            }
            
            // Dismiss sheet
            dismiss()
            
        } catch {
            errorMessage = "Failed to save dose: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func createNewDose(amount: Double) async throws {
        // Create new dose
        let dose = Dose(
            amount: amount,
            timestamp: doseTimestamp,
            site: selectedInjectionSite,
            notes: notes.isEmpty ? nil : notes,
            imageData: photoData,
            skipped: isSkipped
        )
        
        // Set relationships
        dose.medication = selectedMedicationProfile
        
        // Get current user (in real implementation, this would come from auth manager)
        let userDescriptor = FetchDescriptor<User>()
        let users = try modelContext.fetch(userDescriptor)
        dose.user = users.first
        
        // Save to context
        modelContext.insert(dose)
        try modelContext.save()
    }
    
    private func updateExistingDose(amount: Double) async throws {
        guard let doseToEdit = doseToEdit else {
            throw DoseEntryError.missingDoseToEdit
        }
        
        // Update existing dose
        doseToEdit.amount = amount
        doseToEdit.timestamp = doseTimestamp
        doseToEdit.site = selectedInjectionSite
        doseToEdit.notes = notes.isEmpty ? nil : notes
        doseToEdit.imageData = photoData
        doseToEdit.skipped = isSkipped
        doseToEdit.medication = selectedMedicationProfile
        
        // Save changes
        try modelContext.save()
    }
}

// MARK: - Supporting Types

enum DoseEntryError: LocalizedError {
    case missingDoseToEdit
    case invalidAmount
    case missingMedication
    
    var errorDescription: String? {
        switch self {
        case .missingDoseToEdit:
            return "No dose selected for editing"
        case .invalidAmount:
            return "Invalid dose amount"
        case .missingMedication:
            return "Please select a medication"
        }
    }
}

// MARK: - Preview Support

#Preview("Add Mode") {
    @Previewable @State var showingSuccess = false
    
    return DoseEntrySheet(showingSuccessMessage: $showingSuccess)
        .modelContainer(DataController.preview.container)
}

#Preview("Edit Mode") {
    @Previewable @State var showingSuccess = false
    
    // Create sample edit data
    let sampleDose = Dose(
        amount: 1.5,
        timestamp: Date(),
        site: "Thigh",
        notes: "Sample dose for editing",
        skipped: false
    )
    
    let editData = DoseEditData(
        id: sampleDose.id,
        amount: sampleDose.amount,
        timestamp: sampleDose.timestamp,
        site: sampleDose.site,
        notes: sampleDose.notes,
        imageData: sampleDose.imageData,
        skipped: sampleDose.skipped,
        medicationProfile: nil
    )
    
    return DoseEntrySheet(
        doseToEdit: sampleDose,
        editData: editData,
        showingSuccessMessage: $showingSuccess
    )
    .modelContainer(DataController.preview.container)
}
