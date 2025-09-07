import SwiftUI

/// SwiftUI view for compounded medication reconstitution calculations
/// Uses ReconstitutionCalculator service for medical accuracy
struct ReconstitutionCalculatorView: View {
    let profile: MedicationProfile?
    @Environment(\.dismiss) private var dismiss
    @State private var vialStrength: String = ""
    @State private var targetDose: String = ""
    @State private var waterVolume: String = "10"
    @State private var calculationResult: ReconstitutionCalculator.ReconstitutionResult?
    @State private var errorMessage: String = ""
    @State private var showingError = false
    
    
    init(profile: MedicationProfile? = nil) {
        self.profile = profile
        if let profile = profile {
            self._vialStrength = State(initialValue: String(profile.vialStrength ?? 10.0))
            self._targetDose = State(initialValue: String(profile.currentDose))
            self._waterVolume = State(initialValue: String(profile.reconstitutionVolume ?? 10.0))
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
                    .accessibilityIdentifier("calculate-reconstitution")
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
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
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
}

#Preview {
    ReconstitutionCalculatorView()
}
