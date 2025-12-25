//
//  QuickAddContentView.swift
//  JabTracker
//
//  Quick Add form content for embedding in FoodSearchSheet.
//

import SwiftUI

/// Quick Add form content view for embedding in FoodSearchSheet
struct QuickAddContentView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @Bindable var viewModel: QuickAddViewModel
    let selectedMeal: MealSection
    let selectedTime: Date
    let onComplete: () -> Void

    // MARK: - Accessibility Identifiers

    static let energyInputIdentifier = "quick-add-energy-input"
    static let proteinInputIdentifier = "quick-add-protein-input"
    static let fatInputIdentifier = "quick-add-fat-input"
    static let carbsInputIdentifier = "quick-add-carbs-input"
    static let addButtonIdentifier = "quick-add-add-button"

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Energy section
            energySection

            // Macro sum indicator
            macroSumSection

            // Protein/Fat/Carbs row
            macrosRow

            Spacer()

            // Add button
            addButtonSection
        }
        .padding(16)
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Energy Section

    private var energySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Energy")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                // Energy input field with prominent styling
                TextField("", value: $viewModel.energy, format: .number.precision(.fractionLength(0)))
                    .keyboardType(.numberPad)
                    .font(.title2)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(8)
                    .accessibilityIdentifier(Self.energyInputIdentifier)

                // kcal unit indicator
                Text("kcal")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.tertiarySystemFill))
                    .cornerRadius(8)
            }
        }
    }

    // MARK: - Macro Sum Section

    private var macroSumSection: some View {
        Text("Macro sum is \(Int(viewModel.macroSum)) kcal")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Macros Row

    private var macrosRow: some View {
        HStack(spacing: 12) {
            macroInput(label: "Protein", value: $viewModel.protein, identifier: Self.proteinInputIdentifier)
            macroInput(label: "Fat", value: $viewModel.fat, identifier: Self.fatInputIdentifier)
            macroInput(label: "Carbs", value: $viewModel.carbs, identifier: Self.carbsInputIdentifier)
        }
    }

    private func macroInput(label: String, value: Binding<Double>, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 4) {
                TextField("", value: value, format: .number.precision(.fractionLength(0)))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .accessibilityIdentifier(identifier)

                Text("g")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.tertiarySystemFill))
            .cornerRadius(8)
        }
    }

    // MARK: - Add Button Section

    private var addButtonSection: some View {
        Button {
            Task {
                await saveEntry()
            }
        } label: {
            if viewModel.isSaving {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            } else {
                Text("Add")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canSave)
        .accessibilityIdentifier(Self.addButtonIdentifier)
    }

    // MARK: - Actions

    private func saveEntry() async {
        do {
            _ = try await viewModel.save(mealSection: selectedMeal, loggedAt: selectedTime)
            viewModel.reset()
            onComplete()
            dismiss()
        } catch {
            // Error is handled by viewModel (sets errorMessage which triggers showingError)
        }
    }
}
