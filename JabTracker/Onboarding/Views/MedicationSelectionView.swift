import SwiftUI

struct MedicationSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Text("Select Your Medication")
                        .font(DesignTokens.Typography.largeTitle)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Choose the GLP-1 medication you're currently taking")
                        .font(DesignTokens.Typography.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                // Medication options
                LazyVStack(spacing: 16) {
                    ForEach(Medication.allCases) { medication in
                        MedicationCard(
                            medication: medication,
                            isSelected: viewModel.selectedMedication == medication
                        ) {
                            withAnimation(.spring()) {
                                viewModel.selectMedication(medication)
                            }
                        }
                        .accessibilityIdentifier("medication-\(medication.rawValue)")
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 100) // Space for navigation buttons
            }
        }
        .background(DesignTokens.Colors.background)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("medication-selection-view")
    }
}

struct MedicationCard: View {
    let medication: Medication
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            DesignCard {
                HStack(spacing: 16) {
                    // Selection indicator
                    Circle()
                        .fill(isSelected ? DesignTokens.Colors.primary : Color(.systemGray4))
                        .frame(width: 20, height: 20)
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .accessibilityHidden(true)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // Medication name
                        Text(medication.displayName)
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(.primary)
                        
                        // Brand names
                        Text(medication.brands.joined(separator: ", "))
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.secondary)
                        
                        // Properties
                        HStack {
                            Label("\(medication.frequency.displayName)", systemImage: "clock")
                            
                            Label("\(medication.halfLifeDays, specifier: "%.1f") days", systemImage: "timer")
                        }
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(4) // Extra padding for touch target
            }
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? DesignTokens.Colors.primary : Color.clear, lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityLabel("\(medication.displayName) - \(medication.brands.joined(separator: ", "))")
    }
}