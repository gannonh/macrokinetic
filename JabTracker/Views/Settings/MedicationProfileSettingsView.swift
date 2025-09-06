import SwiftData
import SwiftUI

struct MedicationProfileSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var medicationProfiles: [MedicationProfile]
    
    @State private var showingAddProfile = false
    
    private var medicationManager: MedicationManager {
        MedicationManager(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if medicationProfiles.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "pills.fill")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            
                            Text("No medication profiles yet")
                                .font(DesignTokens.Typography.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Add your first medication profile to get started with dose tracking and calculations.")
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
                        ForEach(medicationProfiles, id: \.id) { profile in
                            MedicationProfileRow(profile: profile)
                                .accessibilityIdentifier("medication-profile-\(profile.medicationType.lowercased())-\(profile.brandName.lowercased())-\(String(format: "%.2f", profile.currentDose))mg")
                        }
                        .onDelete(perform: deleteProfiles)
                    }
                }
            }
            .navigationTitle("Medication Profiles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        showingAddProfile = true
                    }
                    .accessibilityIdentifier("Add Medication Profile")
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                AddMedicationProfileView(medicationManager: medicationManager)
            }
        }
    }
    
    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            let profile = medicationProfiles[index]
            modelContext.delete(profile)
        }
        
        do {
            try modelContext.save()
        } catch {
            // Handle error appropriately
            print("Failed to delete medication profile: \(error)")
        }
    }
}

struct MedicationProfileRow: View {
    let profile: MedicationProfile
    
    var body: some View {
        NavigationLink(destination: MedicationProfileDetailView(profile: profile)) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(profile.medicationType.capitalized) (\(profile.brandName))")
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(.primary)
                        
                        if profile.isCompounded {
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
                        Text("\(String(format: "%.2f", profile.currentDose)) mg")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(frequencyDisplay)
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
    
    @State private var selectedMedication: Medication = .semaglutide
    @State private var selectedBrand = "Ozempic"
    @State private var selectedDose: Double = 0.25
    @State private var isCompounded = false
    @State private var vialStrength: Double = 10.0
    @State private var reconstitutionVolume: Double = 10.0
    @State private var notes = ""
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Type") {
                    Picker("Medication", selection: $selectedMedication) {
                        ForEach(Medication.allCases, id: \.self) { medication in
                            Text(medication.displayName)
                                .tag(medication)
                        }
                    }
                    .accessibilityIdentifier("medication-\(selectedMedication.rawValue)")
                    .onChange(of: selectedMedication) { _, newValue in
                        // Reset brand and dose when medication changes
                        selectedBrand = newValue.brands.first ?? ""
                        selectedDose = newValue.availableDoses.first ?? 0.0
                    }
                }
                
                Section("Brand") {
                    Picker("Brand", selection: $selectedBrand) {
                        ForEach(selectedMedication.brands, id: \.self) { brand in
                            Text(brand)
                                .tag(brand)
                        }
                    }
                    .accessibilityIdentifier("brand-\(selectedBrand.lowercased())")
                }
                
                Section("Dosing") {
                    Toggle("Compounded Medication", isOn: $isCompounded)
                        .accessibilityIdentifier("compounded-medication-toggle")
                    
                    if isCompounded {
                        HStack {
                            Text("Vial Strength (mg)")
                            Spacer()
                            TextField("10.0", value: $vialStrength, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .accessibilityIdentifier("vial-strength-input")
                        }
                        
                        HStack {
                            Text("Target Dose (mg)")
                            Spacer()
                            TextField("1.0", value: $selectedDose, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 80)
                                .accessibilityIdentifier("target-dose-input")
                        }
                        
                        // Show reconstitution calculation
                        if vialStrength > 0 && selectedDose > 0 {
                            Button("Calculate Reconstitution") {
                                // This will be handled by ReconstitutionCalculatorView
                            }
                            .accessibilityIdentifier("calculate-reconstitution")
                        }
                    } else {
                        Picker("Dose", selection: $selectedDose) {
                            ForEach(selectedMedication.availableDoses, id: \.self) { dose in
                                Text("\(String(format: "%.2f", dose)) mg")
                                    .tag(dose)
                            }
                        }
                        .accessibilityIdentifier("dose-button-\(String(format: "%.2f", selectedDose))")
                    }
                }
                
                Section("Notes") {
                    TextField("Optional notes about your medication...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMedicationProfile()
                    }
                    .accessibilityIdentifier("save-medication-profile")
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveMedicationProfile() {
        do {
            let profile = try medicationManager.createProfile(
                medication: selectedMedication,
                brandName: selectedBrand,
                currentDose: selectedDose,
                isCompounded: isCompounded,
                vialStrength: isCompounded ? vialStrength : nil,
                reconstitutionVolume: isCompounded ? reconstitutionVolume : nil,
                notes: notes.isEmpty ? "" : notes
            )
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct MedicationProfileDetailView: View {
    let profile: MedicationProfile
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                DesignCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Medication Details")
                            .font(DesignTokens.Typography.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(title: "Medication", value: profile.medicationType.capitalized)
                            DetailRow(title: "Brand", value: profile.brandName)
                            DetailRow(title: "Current Dose", value: "\(String(format: "%.2f", profile.currentDose)) mg")
                            
                            if let medication = Medication(rawValue: profile.medicationType) {
                                DetailRow(title: "Half-life", value: "\(String(format: "%.1f", medication.halfLifeDays)) days")
                                DetailRow(title: "Frequency", value: medication.frequency == .daily ? "Daily" : "Weekly")
                            }
                        }
                    }
                }
                
                // Calculator Tools
                if profile.isCompounded {
                    NavigationLink(destination: ReconstitutionCalculatorView(profile: profile)) {
                        CalculatorCard(
                            title: "Reconstitution Calculator",
                            description: "Calculate water volume and units per dose",
                            icon: "drop.fill"
                        )
                    }
                    .accessibilityIdentifier("reconstitution-calculator")
                } else {
                    NavigationLink(destination: PenClickCalculatorView(profile: profile)) {
                        CalculatorCard(
                            title: "Pen Click Calculator",
                            description: "Calculate pen clicks for dose adjustments",
                            icon: "syringe.fill"
                        )
                    }
                    .accessibilityIdentifier("pen-click-calculator")
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle(profile.brandName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    // TODO: Implement edit functionality
                }
                .accessibilityIdentifier("edit-medication-profile")
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
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
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(DesignTokens.Colors.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
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

#Preview {
    MedicationProfileSettingsView()
        .modelContainer(DataController.preview.container)
}
