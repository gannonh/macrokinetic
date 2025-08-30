import SwiftUI

struct InitialDoseSetupView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showingDatePicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Text("Set Up Your First Dose")
                        .font(DesignTokens.Typography.largeTitle)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    
                    if let medication = viewModel.selectedMedication {
                        Text("Configure your starting dose for \(medication.displayName)")
                            .font(DesignTokens.Typography.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                // Dose configuration
                VStack(spacing: 24) {
                    // Dose amount with frequency indication
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            if let medication = viewModel.selectedMedication {
                                let frequencyText = medication.frequency == .daily ? "Daily" : "Weekly"
                                Text("\(frequencyText) Dose Amount")
                                    .font(DesignTokens.Typography.headline)
                                
                                DoseSelector(
                                    selectedDose: $viewModel.selectedDose,
                                    availableDoses: medication.availableDoses,
                                    unit: medication.unit
                                )
                            }
                        }
                    }
                    .accessibilityIdentifier("dose-amount-card")
                    
                    // Starting date
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Starting Date")
                                .font(DesignTokens.Typography.headline)
                            
                            Button(action: { showingDatePicker = true }) {
                                HStack {
                                    Text(viewModel.selectedStartDate, style: .date)
                                        .font(DesignTokens.Typography.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "calendar")
                                        .foregroundColor(DesignTokens.Colors.primary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .accessibilityIdentifier("starting-date-button")
                            .accessibilityLabel("Set starting date")
                            .accessibilityValue(viewModel.selectedStartDate.formatted(date: .complete, time: .omitted))
                        }
                    }
                    
                    // Injection sites (plural)
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Preferred Injection Sites")
                                .font(DesignTokens.Typography.headline)
                            
                            InjectionSiteSelector(selectedSites: $viewModel.selectedSites, onToggleSite: viewModel.toggleInjectionSite)
                        }
                    }
                    .accessibilityIdentifier("injection-sites-card")
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 100) // Space for navigation buttons
            }
        }
        .background(DesignTokens.Colors.background)
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(selectedDate: $viewModel.selectedStartDate, isPresented: $showingDatePicker)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("initial-dose-setup-view")
    }
}

struct DoseSelector: View {
    @Binding var selectedDose: Double
    let availableDoses: [Double]
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ForEach(availableDoses.prefix(3), id: \.self) { dose in
                    DoseButton(dose: dose, unit: unit, isSelected: selectedDose == dose) {
                        selectedDose = dose
                    }
                }
            }
            
            if availableDoses.count > 3 {
                HStack {
                    ForEach(Array(availableDoses.dropFirst(3)), id: \.self) { dose in
                        DoseButton(dose: dose, unit: unit, isSelected: selectedDose == dose) {
                            selectedDose = dose
                        }
                    }
                    Spacer()
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("dose-selector")
    }
}

struct DoseButton: View {
    let dose: Double
    let unit: String
    let isSelected: Bool
    let onTap: () -> Void
    
    private var formattedDose: String {
        // Format to remove unnecessary trailing zeros
        if dose.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", dose)
        } else {
            return String(format: "%.2f", dose).replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            Text("\(formattedDose) \(unit)")
                .font(DesignTokens.Typography.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isSelected ? DesignTokens.Colors.primary : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .accessibilityIdentifier("dose-button-\(dose)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

struct InjectionSiteSelector: View {
    @Binding var selectedSites: Set<String>
    let onToggleSite: (String) -> Void
    private let sites = ["Thigh", "Abdomen", "Arm", "Other"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select one or more sites for rotation")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 12) {
                ForEach(sites, id: \.self) { site in
                    Button(action: { onToggleSite(site) }) {
                        Text(site)
                            .font(DesignTokens.Typography.body)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                    }
                    .background(selectedSites.contains(site) ? DesignTokens.Colors.primary : Color(.systemGray6))
                    .foregroundColor(selectedSites.contains(site) ? .white : .primary)
                    .cornerRadius(8)
                    .accessibilityIdentifier("injection-site-\(site.lowercased())")
                    .accessibilityValue(selectedSites.contains(site) ? "Selected" : "Not selected")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Injection sites selection - multiple sites can be selected")
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Starting Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .accessibilityIdentifier("date-picker")
                
                Spacer()
            }
            .padding()
            .navigationTitle("Starting Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .accessibilityIdentifier("date-picker-done")
                }
            }
        }
    }
}