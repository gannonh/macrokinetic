import SwiftUI

/// SwiftUI view for branded medication pen click calculations
/// Uses PenClickCalculator service for medical accuracy
struct PenClickCalculatorView: View {
    let profile: MedicationProfile
    @Environment(\.dismiss) private var dismiss
    @State private var targetDose: Double
    @State private var selectedPenType: PenClickCalculator.PenType?
    @State private var calculationResult: PenClickCalculator.PenClickResult?
    @State private var errorMessage: String = ""
    @State private var showingError = false
    
    init(profile: MedicationProfile) {
        self.profile = profile
        self._targetDose = State(initialValue: profile.currentDose)
        let initialPenType = profile.penType.flatMap { PenClickCalculator.PenType(rawValue: $0) }
        self._selectedPenType = State(initialValue: initialPenType)
    }
    
    var availablePens: [PenClickCalculator.PenType] {
        guard let medication = profile.medication else { return [] }
        return PenClickCalculator.pensForMedication(medication)
    }
    
    @ViewBuilder
    var currentProfileSection: some View {
        Section {
            if let medication = profile.medication {
                Text("Medication: \(medication.displayName)")
                    .font(.body)
            }
            Text("Current Dose: \(String(format: "%.2f", profile.currentDose)) mg")
                .font(.body)
            if let penTypeString = profile.penType,
               let penType = PenClickCalculator.PenType(rawValue: penTypeString) {
                Text("Pen Type: \(penType.rawValue)")
                    .font(.body)
            }
        } header: {
            Text("Current Profile")
        }
    }
    
    @ViewBuilder
    var penSelectionSection: some View {
        Section {
            Picker("Pen Type", selection: $selectedPenType) {
                Text("Select Pen Type").tag(nil as PenClickCalculator.PenType?)
                ForEach(availablePens, id: \.self) { penType in
                    Text(penType.rawValue).tag(penType as PenClickCalculator.PenType?)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Pen Selection")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                currentProfileSection
                penSelectionSection
                
                Section(header: Text("Target Dose")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Dose: \(String(format: "%.2f", targetDose)) mg")
                            .font(.headline)
                        
                        Slider(value: $targetDose, in: 0.25...3.0, step: 0.25)
                            .accessibilityIdentifier("target-dose-slider")
                        
                        HStack {
                            Text("0.25 mg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("3.0 mg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let result = calculationResult {
                    Section(header: Text("Pen Click Instructions")) {
                        VStack(alignment: .leading, spacing: 8) {
                            if result.clicks > 0 {
                                Text("Dial to \(result.clicks) clicks for your " +
                                     "\(String(format: "%.2f", result.actualDose)) mg dose")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            } else {
                                Text(result.displayText)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            if let penType = selectedPenType {
                                Text("Maximum dose: \(String(format: "%.2f", penType.maximumDose)) mg")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                if penType.isAdjustable {
                                    Text("Click size: \(String(format: "%.2f", penType.dosePerClick)) mg per click")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Fixed-dose pen")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Pen Click Calculator")
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
            .onChange(of: targetDose) { _, _ in
                if selectedPenType != nil {
                    calculatePenClicks()
                }
            }
            .onChange(of: selectedPenType) { _, _ in
                if selectedPenType != nil {
                    calculatePenClicks()
                }
            }
        }
    }
    
    private func calculatePenClicks() {
        guard let penType = selectedPenType else {
            showError("Please select a pen type")
            return
        }
        
        do {
            let result = try PenClickCalculator.calculate(
                penType: penType,
                targetDose: targetDose
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
    let previewProfile = MedicationProfile(
        brandName: "Ozempic",
        currentDose: 0.5,
        medicationType: "semaglutide"
    )
    PenClickCalculatorView(profile: previewProfile)
}
