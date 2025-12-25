//
//  QuickAddSheet.swift
//  JabTracker
//
//  Sheet for quick macro-only food logging without food lookup.
//

import OSLog
import SwiftUI

/// Sheet for quick macro-only food logging
struct QuickAddSheet: View {
    // MARK: - Logger

    private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "QuickAddSheet")

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var viewModel: QuickAddViewModel
    @State private var selectedMeal: MealSection
    @State private var selectedTime: Date

    // MARK: - Callbacks

    let onComplete: () -> Void

    // MARK: - Accessibility Identifiers

    static let sheetIdentifier = "quick-add-sheet"
    static let nameInputIdentifier = "quick-add-name-input"
    static let caloriesInputIdentifier = "quick-add-calories-input"
    static let proteinInputIdentifier = "quick-add-protein-input"
    static let carbsInputIdentifier = "quick-add-carbs-input"
    static let fatInputIdentifier = "quick-add-fat-input"
    static let notesInputIdentifier = "quick-add-notes-input"
    static let saveButtonIdentifier = "quick-add-save-button"
    static let cancelButtonIdentifier = "quick-add-cancel-button"
    static let mealPickerIdentifier = "quick-add-meal-picker"

    // MARK: - Initialization

    init(
        mealLogService: MealLogService,
        selectedMeal: MealSection,
        selectedTime: Date,
        onComplete: @escaping () -> Void
    ) {
        self._viewModel = State(wrappedValue: QuickAddViewModel(mealLogService: mealLogService))
        self._selectedMeal = State(wrappedValue: selectedMeal)
        self._selectedTime = State(wrappedValue: selectedTime)
        self.onComplete = onComplete
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                macrosSection
                notesSection
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier(Self.cancelButtonIdentifier)
                }
            }
            .safeAreaInset(edge: .bottom) {
                footerSection
            }
            .overlay {
                if viewModel.isSaving {
                    savingOverlay
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier(Self.sheetIdentifier)
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        Section {
            TextField("Food Name", text: $viewModel.name)
                .textContentType(.none)
                .autocorrectionDisabled()
                .accessibilityIdentifier(Self.nameInputIdentifier)
        } header: {
            Text("Basic Information")
        } footer: {
            if viewModel.name.isEmpty {
                Text("Give your entry a name (required)")
            }
        }
    }

    // MARK: - Macros Section

    private var macrosSection: some View {
        Section {
            macroRow(
                label: "Calories",
                value: $viewModel.calories,
                unit: "kcal",
                identifier: Self.caloriesInputIdentifier
            )

            macroRow(
                label: "Protein",
                value: $viewModel.protein,
                unit: "g",
                identifier: Self.proteinInputIdentifier
            )

            macroRow(
                label: "Carbohydrates",
                value: $viewModel.carbs,
                unit: "g",
                identifier: Self.carbsInputIdentifier
            )

            macroRow(
                label: "Fat",
                value: $viewModel.fat,
                unit: "g",
                identifier: Self.fatInputIdentifier
            )
        } header: {
            Text("Macros")
        } footer: {
            Text("Enter the total macros for this entry")
        }
    }

    private func macroRow(
        label: String,
        value: Binding<Double>,
        unit: String,
        identifier: String
    ) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)

            Spacer()

            TextField("0", value: value, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .accessibilityIdentifier(identifier)

            Text(unit)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section {
            TextField("Notes (optional)", text: $viewModel.notes)
                .textContentType(.none)
                .accessibilityIdentifier(Self.notesInputIdentifier)
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 12) {
                // Meal picker
                Picker("Meal", selection: $selectedMeal) {
                    ForEach(MealSection.allCases) { section in
                        Text(section.displayName).tag(section)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier(Self.mealPickerIdentifier)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(8)

                // Add button
                Button {
                    Task {
                        await saveEntry()
                    }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Add")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSave)
                .accessibilityIdentifier(Self.saveButtonIdentifier)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Saving Overlay

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Saving...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Saving quick add entry")
        }
    }

    // MARK: - Actions

    private func saveEntry() async {
        do {
            _ = try await viewModel.save(mealSection: selectedMeal, loggedAt: selectedTime)
            dismiss()
            onComplete()
        } catch {
            // Error is handled by viewModel (sets errorMessage which triggers showingError)
            logger.error("Save failed - viewModel should display error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

#Preview("Quick Add Sheet") {
    Text("Tap to present")
        .sheet(isPresented: .constant(true)) {
            Text("Preview requires full app context")
        }
}
