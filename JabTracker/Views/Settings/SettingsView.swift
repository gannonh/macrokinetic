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

                    // Health Integration Section
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Health Integration")
                                .font(DesignTokens.Typography.headline)
                                .accessibilityIdentifier("health-integration-header")

                            NavigationLink(destination: HealthIntegrationView()) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Profile & HealthKit")
                                            .font(DesignTokens.Typography.body)
                                            .foregroundColor(.primary)

                                        Text("Manage profile data for calorie calculations")
                                            .font(DesignTokens.Typography.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .accessibilityIdentifier("health-integration-link")
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

                    // Sync Status Section
                    SyncStatusCard(dataController: self.dataController)

                    // Notification Settings Section
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Notifications")
                                .font(DesignTokens.Typography.headline)
                                .accessibilityIdentifier("notifications-section-header")

                            // Enable/Disable Toggle
                            if let notificationService = appServices.notificationService {
                                NotificationToggleRow(notificationService: notificationService, logger: self.logger)
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
}

/// Notification toggle row with proper @Bindable pattern
struct NotificationToggleRow: View {
    @Bindable var notificationService: NotificationService
    let logger: Logger

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dose Reminders")
                    .font(DesignTokens.Typography.body)
                Text("Get notified when it's time for your dose")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle(
                "",
                isOn: $notificationService.notificationsEnabled
            )
            .accessibilityIdentifier("notifications-toggle")
            .onChange(of: notificationService.notificationsEnabled) { oldValue, newValue in
                // In UI testing mode, skip async operations for faster test execution
                let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")
                guard !isUITesting else {
                    logger.info("UI testing mode: Skipping async notification operations")
                    return
                }

                Task {
                    do {
                        if newValue {
                            try await notificationService.enable()
                        } else {
                            await notificationService.disable()
                        }
                    } catch {
                        // Revert toggle on error
                        logger.error("Failed to update notifications: \(error.localizedDescription)")
                        await MainActor.run {
                            notificationService.notificationsEnabled = oldValue
                        }
                    }
                }
            }
        }
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
