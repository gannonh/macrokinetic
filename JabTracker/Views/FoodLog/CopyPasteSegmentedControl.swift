//
//  CopyPasteSegmentedControl.swift
//  JabTracker
//
//  Segmented control for copy/paste actions in the Food Log header.
//

import SwiftUI

/// Segmented control with copy and paste buttons for the Food Log header
struct CopyPasteSegmentedControl: View {
    let hasEntries: Bool
    let hasClipboard: Bool
    let onCopy: () -> Void
    let onPaste: () -> Void

    var body: some View {
        // Only show if there's something to copy or paste
        if hasEntries || hasClipboard {
            HStack(spacing: 0) {
                // Copy button
                Button {
                    onCopy()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(hasEntries ? .primary : .secondary.opacity(0.5))
                        .frame(width: 44, height: 36)
                }
                .disabled(!hasEntries)
                .accessibilityIdentifier("copy-day-button")
                .accessibilityLabel("Copy all foods")

                Divider()
                    .frame(height: 22)

                // Paste button
                Button {
                    onPaste()
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(hasClipboard ? .primary : .secondary.opacity(0.5))
                        .frame(width: 44, height: 36)
                }
                .disabled(!hasClipboard)
                .accessibilityIdentifier("paste-button")
                .accessibilityLabel("Paste foods")
            }
            .background(DesignTokens.HeaderButton.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
