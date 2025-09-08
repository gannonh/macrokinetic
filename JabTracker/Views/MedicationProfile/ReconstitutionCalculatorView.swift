import SwiftUI

/// SwiftUI view for compounded medication reconstitution calculations
/// Uses ReconstitutionCalculator service for medical accuracy
struct ReconstitutionCalculatorView: View {
    let profile: MedicationProfile?
    let onSave: ((Double, Double, Double) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var vialStrength: String = ""
    @State private var targetDose: String = ""
    @State private var waterVolume: String = "1"
    @State private var calculationResult: ReconstitutionCalculator.ReconstitutionResult?
    @State private var errorMessage: String = ""
    @State private var showingError = false
    
    init(profile: MedicationProfile? = nil, vialStrength: Double? = nil, targetDose: Double? = nil, waterVolume: Double? = nil, onSave: ((Double, Double, Double) -> Void)? = nil) {
        self.profile = profile
        self.onSave = onSave
        
        // Initialize with provided values, profile values, or defaults
        if let vialStrength = vialStrength {
            self._vialStrength = State(initialValue: String(vialStrength))
        } else if let profile = profile {
            self._vialStrength = State(initialValue: String(profile.vialStrength ?? 10.0))
        } else {
            self._vialStrength = State(initialValue: "")
        }
        
        if let targetDose = targetDose {
            self._targetDose = State(initialValue: String(targetDose))
        } else if let profile = profile {
            self._targetDose = State(initialValue: String(profile.currentDose))
        } else {
            self._targetDose = State(initialValue: "")
        }
        
        if let waterVolume = waterVolume {
            self._waterVolume = State(initialValue: String(waterVolume))
        } else if let profile = profile {
            self._waterVolume = State(initialValue: String(profile.reconstitutionVolume ?? 1.0))
        } else {
            self._waterVolume = State(initialValue: "1")
        }
    }
    
    var body: some View {
        NavigationStack {
        Form {
                if let profile = profile {
                    Section(header: Text("Medication Profile")) {
                        if let medication = profile.medication {
                            Text("Medication: \(medication.displayName)")
                                .font(.body)
                        }
                        Text("Brand: \(profile.brandName)")
                            .font(.body)
                        Text("Current Dose: \(String(format: "%.2f", profile.currentDose)) mg")
                            .font(.body)
                    }
                }
                
                Section(header: Text("Reconstitution Parameters")) {
                    HStack {
                        Text("Vial Strength (mg)")
                        TextField("Enter vial strength", text: $vialStrength)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("vial-strength-input")
                    }
                    
                    HStack {
                        Text("Target Dose (mg)")
                        TextField("Enter target dose", text: $targetDose)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("target-dose-input")
                    }
                    
                    HStack {
                        Text("Water Volume (ml)")
                        TextField("Enter water volume", text: $waterVolume)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section {
                    Button(action: calculateReconstitution) {
                        Text("Calculate Reconstitution")
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("calculate-reconstitution-sheet")
                    .buttonStyle(.borderedProminent)
                }
                
                if let result = calculationResult {
                    Section(header: Text("Reconstitution Instructions")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(result.displayText)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Units per dose: \(String(format: "%.1f", result.unitsPerDose))")
                                .font(.body)
                            
                            Text("Concentration: \(String(format: "%.2f", result.concentration)) mg/ml")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Text("Total units: \(String(format: "%.1f", result.totalUnits))")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Reconstitution Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Close button for sheet presentation
                if onSave != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
                
                // Save button when calculation is complete and presented as sheet
                if let result = calculationResult, onSave != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveCalculationToProfile(result: result)
                        }
                        .accessibilityIdentifier("save-reconstitution-calculation")
                    }
                }
            }
            .alert("Calculation Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func calculateReconstitution() {
        guard let vialStrengthValue = Double(vialStrength),
              let targetDoseValue = Double(targetDose),
              let waterVolumeValue = Double(waterVolume) else {
            showError("Please enter valid numeric values for all fields")
            return
        }
        
        do {
            let result = try ReconstitutionCalculator.calculate(
                vialStrength: vialStrengthValue,
                targetDose: targetDoseValue,
                waterVolume: waterVolumeValue
            )
            calculationResult = result
            errorMessage = ""
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        calculationResult = nil
    }
    
    private func saveCalculationToProfile(result: ReconstitutionCalculator.ReconstitutionResult) {
        guard let vialStrengthValue = Double(vialStrength),
              let targetDoseValue = Double(targetDose),
              let waterVolumeValue = Double(waterVolume) else {
            showError("Invalid calculation values")
            return
        }
        
        if let profile = profile {
            // Update existing profile
            profile.currentDose = targetDoseValue
            profile.vialStrength = vialStrengthValue
            profile.reconstitutionVolume = waterVolumeValue
            
            // Save calculated reconstitution values
            profile.concentration = result.concentration
            profile.unitsPerDose = result.unitsPerDose
            
            profile.updatedAt = Date()
            
            // Force Generic brand for compounded medications
            if profile.isCompounded {
                profile.brandName = "Generic"
            }
            
            do {
                try modelContext.save()
                dismiss()
            } catch {
                showError("Failed to save: \(error.localizedDescription)")
            }
        } else if let onSave = onSave {
            // Callback to parent form with calculated values
            onSave(vialStrengthValue, targetDoseValue, waterVolumeValue)
            dismiss()
        } else {
            showError("No save action available")
        }
    }
}

#Preview {
    ReconstitutionCalculatorView()
}
