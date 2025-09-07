// swiftlint:disable file_length
import SwiftData
import SwiftUI

struct MedicationProfileSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    @Query(sort: \MedicationProfile.startDate, order: .reverse) private var allMedicationProfiles: [MedicationProfile]

    private var medicationProfiles: [MedicationProfile] {
        guard let currentUser = authManager.currentUser else { return [] }
        return self.allMedicationProfiles.filter { $0.user?.id == currentUser.id }
    }

    @State private var showingAddProfile = false

    private var medicationManager: MedicationManager {
        MedicationManager(modelContext: self.modelContext)
    }

    var body: some View {
        NavigationStack {
            List {
                if self.medicationProfiles.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "pills.fill")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)

                            Text("No medication profiles yet")
                                .font(DesignTokens.Typography.headline)
                                .foregroundColor(.secondary)

                            Text("Add your first medication profile to get started with " +
                                "dose tracking and calculations.")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                } else {
                    Section("Your Medications") {
                        ForEach(self.medicationProfiles, id: \.id) { profile in
                            MedicationProfileRow(profile: profile)
                                .accessibilityIdentifier(
                                    "medication-profile-\(profile.medicationType.lowercased())-" +
                                        "\(profile.brandName.lowercased())-\(String(format: "%.2f", profile.currentDose))mg"
                                )
                        }
                        .onDelete(perform: self.deleteProfiles)
                    }
                }
            }
            .navigationTitle("Medication Profiles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        self.showingAddProfile = true
                    }
                    .accessibilityIdentifier("Add Medication Profile")
                }
            }
            .sheet(isPresented: self.$showingAddProfile) {
                if let currentUser = authManager.currentUser {
                    AddMedicationProfileView(medicationManager: self.medicationManager, currentUser: currentUser)
                }
            }
        }
    }

    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            let profile = self.medicationProfiles[index]
            self.modelContext.delete(profile)
        }

        do {
            try self.modelContext.save()
        } catch {
            // Handle error appropriately
            print("Failed to delete medication profile: \(error)")
        }
    }
}

struct MedicationProfileRow: View {
    let profile: MedicationProfile

    var body: some View {
        NavigationLink(destination: MedicationProfileDetailView(profile: self.profile)) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(self.profile.medicationType.capitalized) (\(self.profile.brandName))")
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(.primary)

                        if self.profile.isCompounded {
                            Text("Compounded")
                                .font(DesignTokens.Typography.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(DesignTokens.Colors.info.opacity(0.1))
                                .foregroundColor(DesignTokens.Colors.info)
                                .cornerRadius(4)
                        }
                    }

                    HStack {
                        Text("\(String(format: "%.2f", self.profile.currentDose)) mg")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(self.frequencyDisplay)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var frequencyDisplay: String {
        guard let medication = Medication(rawValue: profile.medicationType) else {
            return "Unknown"
        }

        switch medication.frequency {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        }
    }
}

struct AddMedicationProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let medicationManager: MedicationManager
    let currentUser: User

    @State private var selectedMedication: Medication = .semaglutide
    @State private var selectedBrand: String = Medication.semaglutide.brands.first ?? ""
    @State private var selectedDose: Double = Medication.semaglutide.availableDoses.first ?? 0.25
    @State private var isInitialized = false
    @State private var isCompounded = false
    @State private var vialStrength: Double = 10.0
    @State private var reconstitutionVolume: Double = 10.0
    @State private var notes = ""

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingReconstitutionCalculator = false

    // Computed properties to ensure valid selections
    private var validBrand: String {
        if self.selectedMedication.brands.contains(self.selectedBrand) {
            return self.selectedBrand
        } else {
            return self.selectedMedication.brands.first ?? ""
        }
    }

    private var validDose: Double {
        if self.selectedMedication.availableDoses.contains(where: { abs($0 - selectedDose) < 0.01 }) {
            return self.selectedDose
        } else {
            return self.selectedMedication.availableDoses.first ?? 0.0
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Type") {
                    Picker("Medication", selection: self.$selectedMedication) {
                        ForEach(Medication.allCases, id: \.self) { medication in
                            Text(medication.displayName)
                                .tag(medication)
                                .accessibilityIdentifier("medication-\(medication.rawValue)")
                        }
                    }
                    .accessibilityIdentifier("medication-picker")
                    .onChange(of: self.selectedMedication) { _, newValue in
                        // Reset brand and dose when medication changes to prevent invalid picker selections
                        DispatchQueue.main.async {
                            self.selectedBrand = newValue.brands.first ?? ""
                            self.selectedDose = newValue.availableDoses.first ?? 0.0
                        }
                    }
                }

                Section("Brand") {
                    Picker("Brand", selection: Binding(
                        get: { self.validBrand },
                        set: { self.selectedBrand = $0 }))
                    {
                        ForEach(self.selectedMedication.brands, id: \.self) { brand in
                            Text(brand)
                                .tag(brand)
                                .accessibilityIdentifier("brand-\(brand.lowercased())")
                        }
                    }
                    .accessibilityIdentifier("brand-picker")
                }

                Section("Dosing") {
                    Toggle("Compounded Medication", isOn: self.$isCompounded)
                        .accessibilityIdentifier("compounded-medication-toggle")
                        .accessibilityLabel("Compounded Medication")
                        .accessibilityValue(self.isCompounded ? "On" : "Off")

                    if self.isCompounded {
                        HStack {
                            Text("Vial Strength (mg)")
                            Spacer()
                            TextField("10.0", value: self.$vialStrength, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .accessibilityIdentifier("vial-strength-input")
                        }

                        HStack {
                            Text("Target Dose (mg)")
                            Spacer()
                            TextField("1.0", value: self.$selectedDose, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .accessibilityIdentifier("target-dose-input")
                        }

                        // Show reconstitution calculation
                        if self.vialStrength > 0, self.selectedDose > 0 {
                            Button("Calculate Reconstitution") {
                                self.showingReconstitutionCalculator = true
                            }
                            .accessibilityIdentifier("calculate-reconstitution")
                        }
                    } else {
                        Picker("Dose", selection: Binding(
                            get: { self.validDose },
                            set: { self.selectedDose = $0 }))
                        {
                            ForEach(self.selectedMedication.availableDoses, id: \.self) { dose in
                                Text("\(String(format: "%.2f", dose)) mg")
                                    .tag(dose)
                                    .accessibilityIdentifier("dose-option-\(String(format: "%.2f", dose))")
                            }
                        }
                        .accessibilityIdentifier("dose-picker")
                    }
                }

                Section("Notes") {
                    TextField("Optional notes about your medication...", text: self.$notes, axis: .vertical)
                        .lineLimit(3 ... 6)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        self.saveMedicationProfile()
                    }
                    .accessibilityIdentifier("save-medication-profile")
                }
            }
            .alert("Error", isPresented: self.$showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(self.errorMessage)
            }
            .sheet(isPresented: self.$showingReconstitutionCalculator) {
                ReconstitutionCalculatorView()
            }
        }
    }

    private func saveMedicationProfile() {
        do {
            _ = try self.medicationManager.createProfile(
                for: self.currentUser,
                medication: self.selectedMedication,
                brandName: self.selectedBrand,
                currentDose: self.selectedDose,
                isCompounded: self.isCompounded,
                vialStrength: self.isCompounded ? self.vialStrength : nil,
                reconstitutionVolume: self.isCompounded ? self.reconstitutionVolume : nil,
                notes: self.notes.isEmpty ? "" : self.notes)

            self.dismiss()
        } catch {
            self.errorMessage = error.localizedDescription
            self.showingError = true
        }
    }
}

struct MedicationProfileDetailView: View {
    let profile: MedicationProfile
    @State private var showingEditSheet = false
    @Environment(\.modelContext) private var modelContext

    private var medicationManager: MedicationManager {
        MedicationManager(modelContext: self.modelContext)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                DesignCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Medication Details")
                            .font(DesignTokens.Typography.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(title: "Medication", value: self.profile.medicationType.capitalized)
                            DetailRow(title: "Brand", value: self.profile.brandName)
                            DetailRow(title: "Current Dose", value: "\(String(format: "%.2f", self.profile.currentDose)) mg")

                            if let medication = Medication(rawValue: profile.medicationType) {
                                DetailRow(title: "Half-life", value: "\(String(format: "%.1f", medication.halfLifeDays)) days")
                                DetailRow(title: "Frequency", value: medication.frequency == .daily ? "Daily" : "Weekly")
                            }
                        }
                    }
                }

                // Calculator Tools
                if self.profile.isCompounded {
                    NavigationLink(destination: ReconstitutionCalculatorView(profile: self.profile)) {
                        CalculatorCard(
                            title: "Reconstitution Calculator",
                            description: "Calculate water volume and units per dose",
                            icon: "drop.fill")
                    }
                    .accessibilityIdentifier("reconstitution-calculator")
                } else {
                    NavigationLink(destination: PenClickCalculatorView(profile: self.profile)) {
                        CalculatorCard(
                            title: "Pen Click Calculator",
                            description: "Calculate pen clicks for dose adjustments",
                            icon: "syringe.fill")
                    }
                    .accessibilityIdentifier("pen-click-calculator")
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle(self.profile.brandName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    self.showingEditSheet = true
                }
                .accessibilityIdentifier("edit-medication-profile")
            }
        }
        .sheet(isPresented: self.$showingEditSheet) {
            EditMedicationProfileView(profile: self.profile, medicationManager: self.medicationManager)
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(self.title)
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)

            Spacer()

            Text(self.value)
                .font(DesignTokens.Typography.body)
                .foregroundColor(.primary)
        }
    }
}

struct CalculatorCard: View {
    let title: String
    let description: String
    let icon: String

    var body: some View {
        DesignCard {
            HStack {
                Image(systemName: self.icon)
                    .font(.title2)
                    .foregroundColor(DesignTokens.Colors.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(self.title)
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(.primary)

                    Text(self.description)
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
}

struct EditMedicationProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: MedicationProfile
    let medicationManager: MedicationManager

    @State private var selectedMedication: Medication
    @State private var selectedBrand: String
    @State private var selectedDose: Double
    @State private var isCompounded: Bool
    @State private var notes: String
    @State private var vialStrength: Double
    @State private var reconstitutionVolume: Double

    @State private var showingError = false
    @State private var errorMessage = ""

    init(profile: MedicationProfile, medicationManager: MedicationManager) {
        self.profile = profile
        self.medicationManager = medicationManager
        self._selectedMedication = State(initialValue: Medication(rawValue: profile.medicationType) ?? .semaglutide)
        self._selectedBrand = State(initialValue: profile.brandName)
        self._selectedDose = State(initialValue: profile.currentDose)
        self._isCompounded = State(initialValue: profile.isCompounded)
        self._notes = State(initialValue: profile.notes)
        self._vialStrength = State(initialValue: profile.vialStrength ?? 10.0)
        self._reconstitutionVolume = State(initialValue: profile.reconstitutionVolume ?? 10.0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Information") {
                    Picker("Medication", selection: self.$selectedMedication) {
                        ForEach(Medication.allCases, id: \.self) { medication in
                            Text(medication.displayName)
                                .tag(medication)
                        }
                    }
                    .accessibilityIdentifier("edit-medication-picker")
                    .onChange(of: self.selectedMedication) { _, newValue in
                        // Reset brand and dose when medication changes to prevent invalid picker selections
                        let newBrand = newValue.brands.first ?? ""
                        let newDose = newValue.availableDoses.first ?? 0.0

                        // Update immediately to prevent console errors
                        self.selectedBrand = newBrand
                        self.selectedDose = newDose
                    }

                    Picker("Brand", selection: self.$selectedBrand) {
                        ForEach(self.selectedMedication.brands, id: \.self) { brand in
                            Text(brand)
                                .tag(brand)
                        }
                    }
                    .accessibilityIdentifier("edit-brand-picker")

                    Toggle("Compounded Medication", isOn: self.$isCompounded)
                        .accessibilityIdentifier("edit-compounded-toggle")
                }

                Section("Dosing") {
                    if self.isCompounded {
                        HStack {
                            Text("Vial Strength (mg)")
                            Spacer()
                            TextField("10.0", value: self.$vialStrength, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .accessibilityIdentifier("edit-vial-strength-input")
                        }

                        HStack {
                            Text("Target Dose (mg)")
                            Spacer()
                            TextField("1.0", value: self.$selectedDose, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .accessibilityIdentifier("edit-target-dose-input")
                        }
                    } else {
                        Picker("Current Dose", selection: self.$selectedDose) {
                            ForEach(self.selectedMedication.availableDoses, id: \.self) { dose in
                                Text("\(String(format: "%.2f", dose)) mg")
                                    .tag(dose)
                                    .accessibilityIdentifier("edit-dose-option-\(String(format: "%.2f", dose))")
                            }
                        }
                        .accessibilityIdentifier("edit-dose-picker")
                    }
                }

                Section("Notes") {
                    TextField("Optional notes about your medication...", text: self.$notes, axis: .vertical)
                        .lineLimit(3 ... 6)
                        .accessibilityIdentifier("edit-notes-field")
                }
            }
            .navigationTitle("Edit Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                    .accessibilityIdentifier("edit-cancel-button")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        self.updateMedicationProfile()
                    }
                    .accessibilityIdentifier("edit-save-button")
                }
            }
            .alert("Error", isPresented: self.$showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(self.errorMessage)
            }
        }
    }

    private func updateMedicationProfile() {
        do {
            try self.medicationManager.updateProfile(
                self.profile,
                medication: self.selectedMedication,
                brandName: self.selectedBrand,
                currentDose: self.selectedDose,
                isCompounded: self.isCompounded,
                vialStrength: self.isCompounded ? self.vialStrength : nil,
                reconstitutionVolume: self.isCompounded ? self.reconstitutionVolume : nil,
                notes: self.notes.isEmpty ? "" : self.notes)

            self.dismiss()
        } catch {
            self.errorMessage = error.localizedDescription
            self.showingError = true
        }
    }
}

#Preview {
    MedicationProfileSettingsView()
        .modelContainer(DataController.preview.container)
}
