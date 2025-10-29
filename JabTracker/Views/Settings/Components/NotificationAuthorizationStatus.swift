import SwiftUI
import UserNotifications

/// A status display component showing the current notification authorization state.
///
/// Displays the user's notification permission status with:
/// - Status icon (checkmark, xmark, questionmark)
/// - Status text (Enabled, Disabled, Not Configured)
/// - Descriptive message
/// - Settings button (when authorization is denied)
///
/// Usage:
/// ```swift
/// NotificationAuthorizationStatus(
///     status: notificationService.authorizationStatus
/// )
/// ```
struct NotificationAuthorizationStatus: View {
    /// Current notification authorization status from UNUserNotificationCenter
    let status: UNAuthorizationStatus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(DesignTokens.Typography.body)
                Text(statusDescription)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if status == .denied {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(DesignTokens.Typography.body)
                .buttonStyle(.bordered)
                .accessibilityIdentifier("notification-settings-button")
            }
        }
        .padding()
        .background(statusBackgroundColor)
        .cornerRadius(8)
    }

    // MARK: - Computed Properties

    /// SF Symbol icon name based on authorization status
    private var statusIcon: String {
        switch status {
        case .authorized: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        case .provisional, .ephemeral: return "bell.badge.fill"
        @unknown default: return "bell.slash.fill"
        }
    }

    /// Color for status icon based on authorization status
    private var statusColor: Color {
        switch status {
        case .authorized: return DesignTokens.Colors.success
        case .denied: return DesignTokens.Colors.danger
        case .notDetermined: return DesignTokens.Colors.info
        default: return DesignTokens.Colors.warning
        }
    }

    /// Primary status text label
    private var statusText: String {
        switch status {
        case .authorized: return "Enabled"
        case .denied: return "Disabled"
        case .notDetermined: return "Not Configured"
        default: return "Limited"
        }
    }

    /// Descriptive message explaining the current status
    private var statusDescription: String {
        switch status {
        case .authorized: return "You'll receive dose reminders"
        case .denied: return "Enable notifications in Settings"
        case .notDetermined: return "Tap toggle above to enable"
        default: return "Partial notification access"
        }
    }

    /// Background color for status card
    private var statusBackgroundColor: Color {
        Color(.systemGray6)
    }
}

#Preview("Authorized") {
    DesignCard {
        NotificationAuthorizationStatus(status: .authorized)
    }
    .padding()
}

#Preview("Denied") {
    DesignCard {
        NotificationAuthorizationStatus(status: .denied)
    }
    .padding()
}

#Preview("Not Determined") {
    DesignCard {
        NotificationAuthorizationStatus(status: .notDetermined)
    }
    .padding()
}
