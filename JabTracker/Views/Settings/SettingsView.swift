import OSLog
import StoreKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var dataController = DataController.shared
    // Use real environment for Settings so status reflects actual entitlements during UI tests
    @StateObject private var subscriptionManager = SubscriptionManager(isTestEnvironment: false)
    @StateObject private var medicationManager: MedicationManager
    @ObservedObject private var appServices = AppServices.shared

    private let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "SettingsView")

    init() {
        let context = DataController.shared.container.mainContext
        let manager = MedicationManager(modelContext: context)
        self._medicationManager = StateObject(wrappedValue: manager)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User Profile Section
                    UserProfileView()

                    // Medication Profiles Section
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Medication Management")
                                .font(DesignTokens.Typography.headline)
                                .accessibilityIdentifier("medication-management-header")

                            NavigationLink(
                                destination: MedicationProfileSettingsView(
                                    medicationManager: self.medicationManager)
                            ) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Medication Profiles")
                                            .font(DesignTokens.Typography.body)
                                            .foregroundColor(.primary)

                                        Text("Manage your medications and calculations")
                                            .font(DesignTokens.Typography.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .accessibilityIdentifier("Medication Profiles")
                        }
                    }

                    // Subscription Status Section (added to support UI tests)
                    DesignCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Subscription")
                                .font(DesignTokens.Typography.headline)
                                .accessibilityIdentifier("subscription-section-header")

                            HStack(alignment: .firstTextBaseline) {
                                Text("Status:")
                                    .font(DesignTokens.Typography.body)
                                    .foregroundColor(.secondary)

                                Text(self.subscriptionStatusDisplay)
                                    .font(DesignTokens.Typography.body)
                                    .accessibilityIdentifier("subscription-status")

                                Spacer()
                            }

                            if case .trialActive = self.subscriptionManager.subscriptionStatus {
                                // Provide trial days remaining element (optional for tests)
                                Text("\(self.subscriptionManager.trialDaysRemaining()) days remaining")
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(.secondary)
                                    .accessibilityIdentifier("trial-days-remaining")
                            }
                        }
                        .task {
                            // Load products (safe either way) and refresh entitlement status
                            // so UI reflects latest state.
                            await self.subscriptionManager.loadProducts()
                            await self.subscriptionManager.checkSubscriptionStatus()
                        }
                    }

                    // Subscription Management Section
                    DesignCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Manage Subscription")
                                .font(DesignTokens.Typography.headline)
                                .accessibilityIdentifier("subscription-management-header")

                            Text(
                                "Your subscription is managed through the Apple App Store. "
                                    + "You can cancel, upgrade, or modify your subscription at any time."
                            )
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("subscription-management-description")

                            Button("Manage Subscription") {
                                // Open App Store subscription management
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.primary)
                            .accessibilityIdentifier("manage-subscription-link")
                        }
                    }

                    // Design System Demo Section
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Design System Demo")
                                .font(DesignTokens.Typography.headline)
                                .accessibilityIdentifier("design-system-headline")

                            Text("Typography and Colors")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("design-system-body")

                            Text("Sample caption text")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("design-system-caption")

                            VStack(spacing: 12) {
                                PrimaryButton(title: "Primary Button") {
                                    // Demo action
                                }

                                SecondaryButton(title: "Secondary Button") {
                                    // Demo action
                                }
                            }
                        }
                    }

                    // Sync Status Section
                    SyncStatusCard(dataController: self.dataController)

                    // Notification Settings Section
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notifications")
                                .font(DesignTokens.Typography.headline)
                                .accessibilityIdentifier("notifications-section-header")

                            // Enable/Disable Toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dose Reminders")
                                        .font(DesignTokens.Typography.body)
                                    Text("Get notified when it's time for your dose")
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if let notificationService = appServices.notificationService {
                                    Toggle(
                                        "",
                                        isOn: Binding(
                                            get: { notificationService.notificationsEnabled },
                                            set: { newValue in
                                                Task {
                                                    if newValue {
                                                        await activateNotifications()
                                                    } else {
                                                        await deactivateNotifications()
                                                    }
                                                }
                                            }
                                        )
                                    )
                                    .accessibilityIdentifier("notifications-toggle")
                                }
                            }

                            if let notificationService = appServices.notificationService,
                                notificationService.notificationsEnabled
                            {
                                // Reminder Timing Picker
                                ReminderTimingPicker(
                                    selectedMinutes: Binding(
                                        get: { notificationService.reminderMinutesBefore },
                                        set: { newValue in
                                            notificationService.reminderMinutesBefore = newValue
                                            Task {
                                                try? await notificationService.updateReminderTiming(newValue)
                                            }
                                        }
                                    )
                                )

                                // Authorization Status Display
                                NotificationAuthorizationStatus(
                                    status: notificationService.authorizationStatus
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Settings")
            .environmentObject(self.subscriptionManager)
        }
    }
}

extension SettingsView {
    fileprivate var subscriptionStatusDisplay: String {
        switch self.subscriptionManager.subscriptionStatus {
        case .trialActive: return "Trial Active"
        case .premiumActive: return "Premium Active"
        case .notSubscribed, .expired: return "Not Subscribed"
        }
    }

    // MARK: - Notification Activation

    /**
     * Activate notifications by calling NotificationService.enable().
     *
     * Handles authorization requests and error states.
     */
    private func activateNotifications() async {
        guard let notificationService = appServices.notificationService else {
            logger.error("NotificationService not initialized")
            return
        }

        do {
            try await notificationService.enable()
            logger.info("Notifications enabled successfully")
        } catch {
            logger.error("Failed to enable notifications: \(error.localizedDescription)")
            // Revert toggle state on failure
            await MainActor.run {
                notificationService.notificationsEnabled = false
            }
        }
    }

    /**
     * Deactivate notifications by calling NotificationService.disable().
     *
     * Cancels all pending notifications and clears the queue.
     */
    private func deactivateNotifications() async {
        guard let notificationService = appServices.notificationService else {
            logger.error("NotificationService not initialized")
            return
        }

        await notificationService.disable()
        logger.info("Notifications disabled successfully")
    }
}

struct SyncStatusCard: View {
    @ObservedObject var dataController: DataController

    var body: some View {
        DesignCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: self.syncStatusIcon)
                        .foregroundColor(self.syncStatusColor)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sync Status")
                            .font(DesignTokens.Typography.headline)

                        Text(self.dataController.syncStatusMessage)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if self.dataController.syncStatus == .accountNotSignedIn {
                        Button("Settings") {
                            // Open iOS Settings app
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .font(DesignTokens.Typography.body)
                        .buttonStyle(.bordered)
                    } else if self.dataController.syncStatus == .noNetwork
                        || self.dataController.syncStatus == .unknown
                    {
                        Button("Retry") {
                            self.dataController.retryCloudKitSetup()
                        }
                        .font(DesignTokens.Typography.body)
                        .buttonStyle(.bordered)
                    }
                }

                if !self.dataController.willSyncAcrossDevices {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Your data won't sync across devices")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(
                            "Data is stored locally on this device only. Sign in to iCloud to sync across your devices."
                        )
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    private var syncStatusIcon: String {
        switch self.dataController.syncStatus {
        case .available:
            return "icloud.fill"
        case .accountNotSignedIn:
            return "person.crop.circle.badge.exclamationmark"
        case .restricted:
            return "lock.icloud"
        case .noNetwork:
            return "wifi.slash"
        case .unavailable:
            return "icloud.slash"
        case .unknown:
            return "questionmark.circle"
        }
    }

    private var syncStatusColor: Color {
        switch self.dataController.syncStatus {
        case .available:
            return DesignTokens.Colors.success
        case .accountNotSignedIn, .noNetwork:
            return DesignTokens.Colors.warning
        case .restricted, .unavailable:
            return DesignTokens.Colors.danger
        case .unknown:
            return DesignTokens.Colors.info
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(DataController.preview.container)
}
