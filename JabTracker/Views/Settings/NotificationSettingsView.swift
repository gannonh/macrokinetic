//
//  NotificationSettingsView.swift
//  JabTracker
//
//  Notification settings (stub for Phase 17-02).
//

import SwiftUI

struct NotificationSettingsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Coming Soon")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
                .padding(.top, 24)

            DesignCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notifications")
                        .font(DesignTokens.Typography.headline)

                    Text("Configure reminders for weigh-ins, food logging, and medication doses.")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.secondary)

                    Text("This feature will be implemented in Phase 17-02.")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("notification-settings-view")
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
