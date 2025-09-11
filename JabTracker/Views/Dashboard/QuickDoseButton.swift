//
//  QuickDoseButton.swift
//  JabTracker
//

import SwiftUI
import SwiftData

/// Self-contained SwiftUI component for quick dose entry with smart defaults
/// Presents as a sheet from the Add tab button for streamlined dose logging
struct QuickDoseButton: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = QuickDoseViewModel()
    @State private var showingQuickDoseSheet = false
    @State private var showingSuccessMessage = false
    
    var body: some View {
        Button(action: {
            showingQuickDoseSheet = true
        }) {
            Label("Quick Add Dose", systemImage: "plus.circle.fill")
        }
        .buttonStyle(.borderedProminent)
        .accessibilityIdentifier("quick-add-dose-button")
        .sheet(isPresented: $showingQuickDoseSheet) {
            QuickDoseSheet(
                viewModel: viewModel,
                showingSuccessMessage: $showingSuccessMessage
            )
        }
        .onAppear {
            viewModel.loadSmartDefaults(context: modelContext)
        }
        .overlay(alignment: .top) {
            if showingSuccessMessage {
                Text("Dose logged successfully!")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.9))
                    .cornerRadius(8)
                    .accessibilityIdentifier("dose-logged-success")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onAppear {
                        // Auto-dismiss success message after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showingSuccessMessage = false
                            }
                        }
                    }
            }
        }
    }
}

/// Sheet component for streamlined dose entry with minimal required fields
struct QuickDoseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @ObservedObject var viewModel: QuickDoseViewModel
    @Binding var showingSuccessMessage: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Medication Selection
                    Picker("Medication", selection: $viewModel.selectedMedicationProfile) {
                        ForEach(viewModel.medicationProfiles, id: \.id) { profile in
                            Text("\(profile.brandName) (\(profile.currentDose, specifier: "%.2f") mg)")
                                .tag(profile as MedicationProfile?)
                        }
                    }
                    .accessibilityIdentifier("quick-dose-medication-picker")
                    .accessibilityLabel("Select medication")
                    
                    // Dose Amount (from selected medication profile)
                    HStack {
                        Text("Dose Amount")
                        Spacer()
                        Text("\(viewModel.doseAmount, specifier: "%.2f") mg")
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("quick-dose-amount")
                    }
                    
                    // Injection Site Selection
                    Picker("Injection Site", selection: $viewModel.selectedInjectionSite) {
                        ForEach(viewModel.recommendedInjectionSites, id: \.self) { site in
                            Text(site).tag(site)
                        }
                    }
                    .accessibilityIdentifier("quick-dose-site-picker")
                    .accessibilityLabel("Select injection site")
                    
                    // Time Display (current time)
                    HStack {
                        Text("Time")
                        Spacer()
                        Text(viewModel.doseTime.formatted(date: .omitted, time: .shortened))
                            .foregroundColor(.secondary)
                            .accessibilityIdentifier("quick-dose-time")
                    }
                } header: {
                    Text("Dose Details")
                } footer: {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .accessibilityIdentifier("no-medication-profiles-error")
                    }
                }
                
                // Optional Notes Section (streamlined)
                Section {
                    TextField("Notes (Optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(2)
                        .accessibilityIdentifier("quick-dose-notes")
                        .accessibilityLabel("Optional notes")
                } header: {
                    Text("Additional Information")
                }
            }
            .navigationTitle("Quick Add Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("quick-dose-cancel-button")
                    .accessibilityLabel("Cancel dose entry")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveDose()
                        }
                    }
                    .disabled(!viewModel.canSaveDose)
                    .accessibilityIdentifier("quick-dose-save-button")
                    .accessibilityLabel("Save dose")
                }
            }
            .onAppear {
                viewModel.loadSmartDefaults(context: modelContext)
            }
        }
        .accessibilityIdentifier("quick-dose-sheet")
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    @MainActor
    private func saveDose() async {
        do {
            try await viewModel.saveDose(context: modelContext)
            
            // Provide haptic feedback for successful save
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Show success message
            withAnimation {
                showingSuccessMessage = true
            }
            
            // Dismiss sheet
            dismiss()
            
        } catch {
            // Error is handled by viewModel and displayed in UI
            print("Error saving dose: \(error)")
        }
    }
}

#Preview {
    QuickDoseButton()
        .modelContainer(DataController.preview.container)
}

#Preview("Sheet") {
    @State var showingSuccess = false
    let viewModel = QuickDoseViewModel()
    
    return QuickDoseSheet(
        viewModel: viewModel,
        showingSuccessMessage: $showingSuccess
    )
    .modelContainer(DataController.preview.container)
}