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
                        .font(.system(size: DesignTokens.HeaderButton.iconSize, weight: .semibold))
                        .foregroundColor(hasEntries ? DesignTokens.HeaderButton.iconColor : .secondary.opacity(0.4))
                        .frame(height: DesignTokens.HeaderButton.buttonSize)
                        .padding(.horizontal, 12)
                }
                .disabled(!hasEntries)
                .accessibilityIdentifier("copy-day-button")
                .accessibilityLabel("Copy all foods")

                Divider()
                    .frame(height: DesignTokens.HeaderButton.buttonSize * 0.5)

                // Paste button
                Button {
                    onPaste()
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: DesignTokens.HeaderButton.iconSize, weight: .semibold))
                        .foregroundColor(hasClipboard ? DesignTokens.HeaderButton.iconColor : .secondary.opacity(0.4))
                        .frame(height: DesignTokens.HeaderButton.buttonSize)
                        .padding(.horizontal, 12)
                }
                .disabled(!hasClipboard)
                .accessibilityIdentifier("paste-button")
                .accessibilityLabel("Paste foods")
            }
            .background(DesignTokens.HeaderButton.backgroundColor)
            .clipShape(Capsule())
        }
    }
}
