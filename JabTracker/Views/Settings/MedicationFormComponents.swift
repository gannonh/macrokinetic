import SwiftUI

// MARK: - Shared Medication Form Components

struct MedicationBrandSection: View {
    let selectedMedication: Medication
    @Binding var selectedBrand: String
    let isCompounded: Bool
    let accessibilityPrefix: String
    
    var body: some View {
        Section("Brand") {
            if isCompounded {
                HStack {
                    Text("Brand")
                    Spacer()
                    Text("Generic")
                        .foregroundColor(.secondary)
                }
            } else {
                Picker("Brand", selection: $selectedBrand) {
                    ForEach(selectedMedication.brands, id: \.self) { brand in
                        Text(brand)
                            .tag(brand)
                            .accessibilityIdentifier("\(accessibilityPrefix)-brand-\(brand.lowercased())")
                    }
                }
                .accessibilityIdentifier("\(accessibilityPrefix)-brand-picker")
            }
        }
    }
}

struct MedicationDosingSection: View {
    let selectedMedication: Medication
    @Binding var selectedDose: Double
    @Binding var isCompounded: Bool
    @Binding var vialStrength: Double
    let accessibilityPrefix: String
    let onCalculateReconstitution: () -> Void
    
    var body: some View {
        Section("Dosing") {
            Toggle("Compounded Medication", isOn: $isCompounded)
                .accessibilityIdentifier("\(accessibilityPrefix)-compounded-medication-toggle")
                .accessibilityLabel("Compounded Medication")
                .accessibilityValue(isCompounded ? "On" : "Off")
            
            if isCompounded {
                HStack {
                    Text("Vial Strength (mg)")
                    Spacer()
                    TextField("10.0", value: $vialStrength, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .accessibilityIdentifier("\(accessibilityPrefix)-vial-strength-input")
                }
                
                HStack {
                    Text("Target Dose (mg)")
                    Spacer()
                    TextField("1.0", value: $selectedDose, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .accessibilityIdentifier("\(accessibilityPrefix)-target-dose-input")
                }
                
                // Show reconstitution calculation
                if vialStrength > 0, selectedDose > 0 {
                    Button("Calculate Reconstitution") {
                        onCalculateReconstitution()
                    }
                    .accessibilityIdentifier("\(accessibilityPrefix)-calculate-reconstitution")
                }
            } else {
                Picker("Dose", selection: $selectedDose) {
                    ForEach(selectedMedication.availableDoses, id: \.self) { dose in
                        Text("\(String(format: "%.2f", dose)) mg")
                            .tag(dose)
                            .accessibilityIdentifier("\(accessibilityPrefix)-dose-option-\(String(format: "%.2f", dose))")
                    }
                }
                .accessibilityIdentifier("\(accessibilityPrefix)-dose-picker")
            }
        }
    }
}