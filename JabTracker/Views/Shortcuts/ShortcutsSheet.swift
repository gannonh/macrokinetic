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

    var isEnabled: Bool {
        switch self {
        case .quickPhoto:
            return ReleasePolicy.isEnabled(.progressPhotos)
        case .foodSearch, .quickDose, .barcodeScan, .foodLibrary, .quickAdd, .quickWeight, .quickMetrics:
            return true
        }
    }
}

/// Data model for a shortcut item
struct ShortcutItem: Identifiable {
    let icon: String
    let label: String
    let requiredFeature: ReleaseFeature?

    var id: String { label }

    var isEnabled: Bool {
        requiredFeature.map { ReleasePolicy.isEnabled($0) } ?? true
    }

    init(icon: String, label: String, requiredFeature: ReleaseFeature? = nil) {
        self.icon = icon
        self.label = label
        self.requiredFeature = requiredFeature
    }
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

    /// Accessibility identifier for the sheet
    static let accessibilityIdentifierValue = "shortcuts-sheet"

    /// Top row shortcuts configuration (Search, Barcode, AI, Shots)
    static let topRowShortcuts: [ShortcutItem] = [
        ShortcutItem(icon: "magnifyingglass", label: "Search"),
        ShortcutItem(icon: "barcode.viewfinder", label: "Barcode"),
        ShortcutItem(icon: "camera.fill", label: "AI", requiredFeature: .aiFoodCapture),
        ShortcutItem(icon: "syringe.fill", label: "Shots"),
    ]

    /// List row shortcuts configuration
    static let listRowShortcuts: [ShortcutItem] = [
        ShortcutItem(icon: "scalemass.fill", label: "Weight"),
        ShortcutItem(icon: "plus.circle.fill", label: "Quick Add"),
        ShortcutItem(icon: "chart.bar.fill", label: "Metrics"),
        ShortcutItem(icon: "camera.fill", label: "Progress Photos", requiredFeature: .progressPhotos),
        ShortcutItem(icon: "star.fill", label: "Your Foods"),
        ShortcutItem(icon: "book.fill", label: "Recipes", requiredFeature: .recipes),
        ShortcutItem(icon: "calendar.badge.plus", label: "Edit Days", requiredFeature: .shortcutCustomization),
    ]

    static var visibleTopRowShortcuts: [ShortcutItem] {
        topRowShortcuts.filter { $0.isEnabled }
    }

    static var visibleListRowShortcuts: [ShortcutItem] {
        listRowShortcuts.filter { $0.isEnabled }
    }

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

                if ReleasePolicy.isEnabled(.shortcutCustomization) {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.secondary)
                        }
                        .disabled(true)
                        .accessibilityIdentifier("shortcuts-customize-button")
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.55)])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier(Self.accessibilityIdentifierValue)
    }

    // MARK: - Top Row Section

    private var topRowSection: some View {
        HStack(spacing: 16) {
            ForEach(Self.visibleTopRowShortcuts) { shortcut in
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
            ForEach(Array(Self.visibleListRowShortcuts.enumerated()), id: \.element.id) { index, shortcut in
                ShortcutRowButton(
                    icon: shortcut.icon,
                    label: shortcut.label,
                    isEnabled: shortcut.isEnabled
                ) {
                    handleListRowAction(shortcut)
                }

                if index < Self.visibleListRowShortcuts.count - 1 {
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
        guard destination.isEnabled else { return }
        dismiss()
        // Small delay to allow sheet dismissal before presenting new sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + SheetTransitionTiming.delay) {
            guard destination.isEnabled else { return }
            activeSheet = destination
        }
    }

    private func handleTopRowAction(_ shortcut: ShortcutItem) {
        guard shortcut.isEnabled else { return }
        switch shortcut.label {
        case "Search":
            dismissAndPresent(.foodSearch)
        case "Barcode":
            dismissAndPresent(.barcodeScan)
        case "Shots":
            dismissAndPresent(.quickDose)
        default:
            return
        }
    }

    private func handleListRowAction(_ shortcut: ShortcutItem) {
        guard shortcut.isEnabled else { return }
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
            return
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
