//
//  PermissionActionButtons.swift
//  JabTracker
//
//  Reusable action buttons for permission step views.
//

import SwiftUI

/// Primary/secondary button pair for permission step views.
///
/// Used in permission step views (HealthKit, Face ID, Notifications)
/// to provide Enable and Not Now actions.
struct PermissionActionButtons: View {
    /// Title for the primary enable button
    let primaryTitle: String

    /// Optional loading state title (shown while requesting permission)
    let loadingTitle: String?

    /// Whether a permission request is in progress
    let isLoading: Bool

    /// Accessibility identifier for the enable button
    let enableIdentifier: String

    /// Accessibility identifier for the skip button
    let skipIdentifier: String

    /// Called when user taps the enable button
    let onEnable: () -> Void

    /// Called when user taps the skip button
    let onSkip: () -> Void

    init(
        primaryTitle: String,
        loadingTitle: String? = nil,
        isLoading: Bool = false,
        enableIdentifier: String,
        skipIdentifier: String,
        onEnable: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.primaryTitle = primaryTitle
        self.loadingTitle = loadingTitle
        self.isLoading = isLoading
        self.enableIdentifier = enableIdentifier
        self.skipIdentifier = skipIdentifier
        self.onEnable = onEnable
        self.onSkip = onSkip
    }

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onEnable) {
                Text(isLoading ? (loadingTitle ?? primaryTitle) : primaryTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
            .accessibilityIdentifier(enableIdentifier)

            Button(action: onSkip) {
                Text("Not Now")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isLoading)
            .accessibilityIdentifier(skipIdentifier)
        }
    }
}

#Preview {
    PermissionActionButtons(
        primaryTitle: "Enable Feature",
        loadingTitle: "Enabling...",
        isLoading: false,
        enableIdentifier: "enable-button",
        skipIdentifier: "skip-button",
        onEnable: {},
        onSkip: {}
    )
    .padding()
}
