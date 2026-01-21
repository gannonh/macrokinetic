//
//  FoodLogCopyPasteMenu.swift
//  JabTracker
//
//  Context menu content for copy/paste actions on meals and days.
//

import SwiftUI

/// Context menu content for copy/paste actions
struct FoodLogCopyPasteMenu: View {
    let entries: [FoodEntry]
    let section: MealSection?
    let selectedDate: Date
    let onPaste: () -> Void
    var onClearDay: (() -> Void)?

    var body: some View {
        // Copy option (only when there are entries)
        if !entries.isEmpty {
            Button {
                if let section = section {
                    AppServices.shared.foodClipboardService?.copyMeal(
                        date: selectedDate,
                        meal: section,
                        entries: entries
                    )
                } else {
                    AppServices.shared.foodClipboardService?.copyDay(
                        date: selectedDate,
                        entries: entries
                    )
                }
            } label: {
                if let section = section {
                    Label("Copy \(section.displayName)", systemImage: "doc.on.doc")
                } else {
                    Label("Copy All Foods", systemImage: "doc.on.doc")
                }
            }
        }

        // Paste (only when clipboard has content)
        if AppServices.shared.foodClipboardService?.hasContent == true {
            Button {
                onPaste()
            } label: {
                Label("Paste", systemImage: "doc.on.clipboard")
            }
        }

        // Clear Day option (only for day-level menu with entries)
        if section == nil && !entries.isEmpty {
            Button(role: .destructive) {
                onClearDay?()
            } label: {
                Label("Clear Day (\(entries.count) items)", systemImage: "trash")
            }
        }
    }
}
