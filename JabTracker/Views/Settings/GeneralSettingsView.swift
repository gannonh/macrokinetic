//
//  GeneralSettingsView.swift
//  JabTracker
//
//  General app information and settings.
//

import SwiftUI

struct GeneralSettingsView: View {
    var body: some View {
        List {
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundColor(.secondary)
                }
                .accessibilityIdentifier("version-row")

                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundColor(.secondary)
                }
                .accessibilityIdentifier("build-row")
            }

            Section("Legal") {
                // Terms of Service - placeholder
                Label("Terms of Service", systemImage: "doc.text")
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("terms-placeholder")

                // Privacy Policy - placeholder
                Label("Privacy Policy", systemImage: "hand.raised")
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("privacy-placeholder")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("General")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("general-settings-view")
    }
}

#Preview {
    NavigationStack {
        GeneralSettingsView()
    }
}
