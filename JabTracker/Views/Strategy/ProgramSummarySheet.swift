//
//  ProgramSummarySheet.swift
//  JabTracker
//
//  Sheet displaying current program settings after Edit Goal flow.
//  User can choose "Looks Good" to keep or "Set New Program" to change.
//

import SwiftUI

// MARK: - Program Summary Sheet

/// Sheet showing current program configuration with options to keep or change
struct ProgramSummarySheet: View {
    @Environment(\.dismiss) private var dismiss

    let program: NutritionProgram
    let onLooksGood: () -> Void
    let onSetNewProgram: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    programDetailsGrid

                    actionButtonsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Current Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .accessibilityIdentifier("program-summary-sheet")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green.gradient)

            Text("Goal Updated!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Review your current program settings below.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Program Details Grid

    private var programDetailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            programDetailCard(
                title: "Style",
                value: program.style.displayName,
                icon: "person.fill.viewfinder",
                color: .blue
            )

            programDetailCard(
                title: "Diet",
                value: program.diet.displayName,
                icon: "leaf.fill",
                color: .green
            )

            programDetailCard(
                title: "Calorie Floor",
                value: program.calorieFloor.displayName,
                icon: "flame.fill",
                color: .orange
            )

            programDetailCard(
                title: "Training",
                value: program.training.displayName,
                icon: "figure.run",
                color: .purple
            )

            programDetailCard(
                title: "Distribution",
                value: program.distributionMode.displayName,
                icon: "calendar",
                color: .teal
            )

            programDetailCard(
                title: "Protein",
                value: program.protein.displayName,
                icon: "p.circle.fill",
                color: DesignTokens.Colors.protein
            )
        }
    }

    private func programDetailCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: "Looks Good") {
                onLooksGood()
            }
            .accessibilityIdentifier("looks-good-button")

            SecondaryButton(title: "Set New Program") {
                onSetNewProgram()
            }
            .accessibilityIdentifier("set-new-program-button")
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview("Program Summary Sheet") {
    ProgramSummarySheet(
        program: NutritionProgram(
            style: .coached,
            diet: .balanced,
            calorieFloor: .standard,
            trainingLevel: .none,
            distributionMode: .even,
            proteinLevel: .moderate
        ),
        onLooksGood: {},
        onSetNewProgram: {}
    )
}
