//
//  ShortcutsSheet.swift
//  JabTracker
//
//  A quarter-sheet modal with quick action shortcuts.
//

import SwiftUI

/// Destination sheets that can be presented from shortcuts
enum ShortcutDestination: String, Identifiable {
    case foodSearch
    case quickDose
    case barcodeScan
    case foodLibrary
    case quickAdd
    case quickWeight
    case quickMetrics
    case quickPhoto

    var id: String { rawValue }
}

/// Data model for a shortcut item
struct ShortcutItem: Identifiable {
    let icon: String
    let label: String
    let isEnabled: Bool

    var id: String { label }
}

/// Timing constants for sheet transitions
enum SheetTransitionTiming {
    /// Delay required for SwiftUI sheet dismissal before presenting new sheet
    static let delay: TimeInterval = 0.3
}

/// A quarter-sheet modal displaying shortcuts for common actions.
/// Shows when the user taps the "+" tab button.
struct ShortcutsSheet: View {
    @Environment(\.dismiss) private var dismiss

    /// Binding to the active sheet destination
    @Binding var activeSheet: ShortcutDestination?

    /// State for "Coming Soon" alert
    @State private var showingComingSoon = false
    @State private var comingSoonFeature = ""

    /// Accessibility identifier for the sheet
    static let accessibilityIdentifierValue = "shortcuts-sheet"

    /// Top row shortcuts configuration (Search, Barcode, AI, Shots)
    static let topRowShortcuts: [ShortcutItem] = [
        ShortcutItem(icon: "magnifyingglass", label: "Search", isEnabled: true),
        ShortcutItem(icon: "barcode.viewfinder", label: "Barcode", isEnabled: true),
        ShortcutItem(icon: "camera.fill", label: "AI", isEnabled: false),
        ShortcutItem(icon: "syringe.fill", label: "Shots", isEnabled: true),
    ]

    /// List row shortcuts configuration
    static let listRowShortcuts: [ShortcutItem] = [
        ShortcutItem(icon: "scalemass.fill", label: "Weight", isEnabled: true),
        ShortcutItem(icon: "plus.circle.fill", label: "Quick Add", isEnabled: true),
        ShortcutItem(icon: "chart.bar.fill", label: "Metrics", isEnabled: true),
        ShortcutItem(icon: "camera.fill", label: "Progress Photos", isEnabled: true),
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
    private func dismissAndPresent(_ destination: ShortcutDestination) {
        dismiss()
        // Small delay to allow sheet dismissal before presenting new sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + SheetTransitionTiming.delay) {
            activeSheet = destination
        }
    }

    private func handleTopRowAction(_ shortcut: ShortcutItem) {
        switch shortcut.label {
        case "Search":
            dismissAndPresent(.foodSearch)
        case "Barcode":
            dismissAndPresent(.barcodeScan)
        case "Shots":
            dismissAndPresent(.quickDose)
        default:
            comingSoonFeature = shortcut.label
            showingComingSoon = true
        }
    }

    private func handleListRowAction(_ shortcut: ShortcutItem) {
        switch shortcut.label {
        case "Your Foods":
            dismissAndPresent(.foodLibrary)
        case "Quick Add":
            dismissAndPresent(.quickAdd)
        case "Weight":
            dismissAndPresent(.quickWeight)
        case "Metrics":
            dismissAndPresent(.quickMetrics)
        case "Progress Photos":
            dismissAndPresent(.quickPhoto)
        default:
            comingSoonFeature = shortcut.label
            showingComingSoon = true
        }
    }
}

// MARK: - Preview

#Preview("Shortcuts Sheet") {
    struct PreviewWrapper: View {
        @State private var activeSheet: ShortcutDestination?

        var body: some View {
            Color.clear
                .sheet(isPresented: .constant(true)) {
                    ShortcutsSheet(activeSheet: $activeSheet)
                }
        }
    }

    return PreviewWrapper()
}
