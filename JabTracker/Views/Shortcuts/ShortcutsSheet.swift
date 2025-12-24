//
//  ShortcutsSheet.swift
//  JabTracker
//
//  A quarter-sheet modal with quick action shortcuts.
//

import SwiftUI

/// Data model for a shortcut item
struct ShortcutItem: Identifiable {
    let icon: String
    let label: String
    let isEnabled: Bool

    var id: String { label }
}

/// Timing constants for sheet transitions
private enum SheetTransitionTiming {
    /// Delay required for SwiftUI sheet dismissal before presenting new sheet
    static let delay: TimeInterval = 0.3
}

/// A quarter-sheet modal displaying shortcuts for common actions.
/// Shows when the user taps the "+" tab button.
struct ShortcutsSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// Binding to trigger food search sheet
    @Binding var showingFoodSearch: Bool

    /// Binding to trigger quick dose sheet
    @Binding var showingQuickDose: Bool

    /// Binding to trigger food search sheet with scanner pre-selected
    @Binding var showingFoodSearchWithScan: Bool

    /// Binding to trigger food search sheet with library pre-selected
    @Binding var showingFoodLibrary: Bool

    /// State for "Coming Soon" alert
    @State private var showingComingSoon = false
    @State private var comingSoonFeature = ""

    /// Accessibility identifier for the sheet
    static let accessibilityIdentifierValue = "shortcuts-sheet"

    /// Top row shortcuts configuration (Search, Barcode, Photo, Shots)
    static let topRowShortcuts: [ShortcutItem] = [
        ShortcutItem(icon: "magnifyingglass", label: "Search", isEnabled: true),
        ShortcutItem(icon: "barcode.viewfinder", label: "Barcode", isEnabled: true),
        ShortcutItem(icon: "camera.fill", label: "Photo", isEnabled: false),
        ShortcutItem(icon: "syringe.fill", label: "Shots", isEnabled: true),
    ]

    /// List row shortcuts configuration
    static let listRowShortcuts: [ShortcutItem] = [
        ShortcutItem(icon: "scalemass.fill", label: "Weight", isEnabled: false),
        ShortcutItem(icon: "plus.circle.fill", label: "Quick Add", isEnabled: false),
        ShortcutItem(icon: "chart.bar.fill", label: "Metrics", isEnabled: false),
        ShortcutItem(icon: "star.fill", label: "Your Foods", isEnabled: true),
        ShortcutItem(icon: "book.fill", label: "Recipes", isEnabled: false),
        ShortcutItem(icon: "calendar.badge.plus", label: "Edit Days", isEnabled: false),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Top row of circular buttons
                topRowSection

                // List rows
                listRowsSection
            }
            .padding(.top, 8)
            .navigationTitle("Shortcuts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("shortcuts-close-button")
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Placeholder for future customization
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.secondary)
                    }
                    .disabled(true)
                    .accessibilityIdentifier("shortcuts-customize-button")
                    .accessibilityHint("Customization coming soon")
                }
            }
        }
        .presentationDetents([.fraction(0.55)])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier(Self.accessibilityIdentifierValue)
        .alert("Coming Soon", isPresented: $showingComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(comingSoonFeature) will be available in a future update.")
        }
    }

    // MARK: - Top Row Section

    private var topRowSection: some View {
        HStack(spacing: 16) {
            ForEach(Self.topRowShortcuts) { shortcut in
                ShortcutButton(
                    icon: shortcut.icon,
                    label: shortcut.label,
                    isEnabled: shortcut.isEnabled
                ) {
                    handleTopRowAction(shortcut)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - List Rows Section

    private var listRowsSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(Self.listRowShortcuts.enumerated()), id: \.element.id) { index, shortcut in
                ShortcutRowButton(
                    icon: shortcut.icon,
                    label: shortcut.label,
                    isEnabled: shortcut.isEnabled
                ) {
                    handleListRowAction(shortcut)
                }

                if index < Self.listRowShortcuts.count - 1 {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .cardStyle(cornerRadius: 12)
        .padding(.horizontal, 16)
    }

    // MARK: - Action Handlers

    /// Dismiss sheet and present a new sheet after transition delay
    private func dismissAndPresent(_ binding: Binding<Bool>) {
        dismiss()
        // Small delay to allow sheet dismissal before presenting new sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + SheetTransitionTiming.delay) {
            binding.wrappedValue = true
        }
    }

    private func handleTopRowAction(_ shortcut: ShortcutItem) {
        switch shortcut.label {
        case "Search":
            dismissAndPresent($showingFoodSearch)
        case "Barcode":
            dismissAndPresent($showingFoodSearchWithScan)
        case "Shots":
            dismissAndPresent($showingQuickDose)
        default:
            comingSoonFeature = shortcut.label
            showingComingSoon = true
        }
    }

    private func handleListRowAction(_ shortcut: ShortcutItem) {
        switch shortcut.label {
        case "Your Foods":
            dismissAndPresent($showingFoodLibrary)
        default:
            comingSoonFeature = shortcut.label
            showingComingSoon = true
        }
    }
}

// MARK: - Preview

#Preview("Shortcuts Sheet") {
    struct PreviewWrapper: View {
        @State private var showingFoodSearch = false
        @State private var showingQuickDose = false
        @State private var showingFoodSearchWithScan = false
        @State private var showingFoodLibrary = false

        var body: some View {
            Color.clear
                .sheet(isPresented: .constant(true)) {
                    ShortcutsSheet(
                        showingFoodSearch: $showingFoodSearch,
                        showingQuickDose: $showingQuickDose,
                        showingFoodSearchWithScan: $showingFoodSearchWithScan,
                        showingFoodLibrary: $showingFoodLibrary
                    )
                }
        }
    }

    return PreviewWrapper()
}
