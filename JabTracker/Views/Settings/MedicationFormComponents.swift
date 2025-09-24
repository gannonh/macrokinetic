import SwiftUI

// MARK: - Shared Medication Form Components

struct MedicationBrandSection: View {
    let selectedMedication: Medication
    @Binding var selectedBrand: String
    let isCompounded: Bool
    let accessibilityPrefix: String

    var body: some View {
        Section("Brand") {
            if self.isCompounded {
                HStack {
                    Text("Brand")
                    Spacer()
                    Text("Generic")
                        .foregroundColor(.secondary)
                }
            } else {
                Picker("Brand", selection: self.$selectedBrand) {
                    ForEach(self.selectedMedication.brands, id: \.self) { brand in
                        Text(brand)
                            .tag(brand)
                            .accessibilityIdentifier("\(self.accessibilityPrefix)-brand-\(brand.lowercased())")
                    }
                }
                .accessibilityIdentifier("\(self.accessibilityPrefix)-brand-picker")
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
            Toggle("Compounded Medication", isOn: self.$isCompounded)
                .accessibilityIdentifier("\(self.accessibilityPrefix)-compounded-medication-toggle")
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
                        .accessibilityIdentifier("\(self.accessibilityPrefix)-vial-strength-input")
                }

                HStack {
                    Text("Target Dose (mg)")
                    Spacer()
                    TextField("1.0", value: self.$selectedDose, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                        .accessibilityIdentifier("\(self.accessibilityPrefix)-target-dose-input")
                }

                // Show reconstitution calculation
                if self.vialStrength > 0, self.selectedDose > 0 {
                    Button("Calculate Reconstitution") {
                        self.onCalculateReconstitution()
                    }
                    .accessibilityIdentifier("\(self.accessibilityPrefix)-calculate-reconstitution")
                }
            } else {
                Picker("Dose", selection: self.$selectedDose) {
                    ForEach(self.selectedMedication.availableDoses, id: \.self) { dose in
                        Text("\(String(format: "%.2f", dose)) mg")
                            .tag(dose)
                            .accessibilityIdentifier(
                                "\(self.accessibilityPrefix)-dose-option-\(String(format: "%.2f", dose))"
                            )
                    }
                }
                .accessibilityIdentifier("\(self.accessibilityPrefix)-dose-picker")
            }
        }
    }
}

struct ReconstitutionCalculatorSheet: ViewModifier {
    @Binding var isPresented: Bool
    let vialStrength: Double
    let targetDose: Double
    let waterVolume: Double
    let onSave: (Double, Double, Double) -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: self.$isPresented) {
                ReconstitutionCalculatorView(
                    vialStrength: self.vialStrength,
                    targetDose: self.targetDose,
                    waterVolume: self.waterVolume,
                    onSave: self.onSave)
            }
    }
}

extension View {
    func reconstitutionCalculatorSheet(
        isPresented: Binding<Bool>,
        vialStrength: Double,
        targetDose: Double,
        waterVolume: Double = 1.0,
        onSave: @escaping (Double, Double, Double) -> Void
    ) -> some View {
        modifier(
            ReconstitutionCalculatorSheet(
                isPresented: isPresented,
                vialStrength: vialStrength,
                targetDose: targetDose,
                waterVolume: waterVolume,
                onSave: onSave))
    }
}
