import StoreKit
import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag("home")

            AddDoseView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag("add")

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag("history")

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag("analytics")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag("settings")
        }
        .accessibilityIdentifier("main-tab-view")
    }
}

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Dashboard")
                    .font(.largeTitle)
                    .bold()
                Text("Welcome to JabTracker")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Home")
        }
    }
}

struct AddDoseView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Add Dose")
                    .font(.largeTitle)
                    .bold()
                Button("Quick Add Dose") {
                    // TODO: Implement dose addition
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("quick-add-dose-button")
            }
            .navigationTitle("Add Dose")
        }
    }
}

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Dose History")
                    .font(.largeTitle)
                    .bold()
                Text("Your medication tracking history")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("History")
        }
    }
}

struct AnalyticsView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Analytics")
                    .font(.largeTitle)
                    .bold()
                Text("Concentration levels and insights")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Analytics")
        }
    }
}

struct SettingsView: View {
    @ObservedObject private var dataController = DataController.shared
    // Use real environment for Settings so status reflects actual entitlements during UI tests
    @StateObject private var subscriptionManager = SubscriptionManager(isTestEnvironment: false)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User Profile Section
                    UserProfileView()

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

                            Text("Your subscription is managed through the Apple App Store. " +
                                 "You can cancel, upgrade, or modify your subscription at any time.")
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

                    // Settings Options
                    DesignCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Preferences")
                                .font(DesignTokens.Typography.headline)

                            VStack(spacing: 8) {
                                HStack {
                                    Text("Notifications")
                                        .font(DesignTokens.Typography.body)
                                    Spacer()
                                    Toggle("", isOn: .constant(true))
                                }

                                // Face ID toggle is handled in UserProfileView when user is authenticated
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

private extension SettingsView {
    var subscriptionStatusDisplay: String {
        switch self.subscriptionManager.subscriptionStatus {
        case .trialActive: return "Trial Active"
        case .premiumActive: return "Premium Active"
        case .notSubscribed, .expired: return "Not Subscribed"
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
                    } else if self.dataController.syncStatus == .noNetwork ||
                        self.dataController.syncStatus == .unknown
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

                        Text("Data is stored locally on this device only. Sign in to iCloud to sync across your devices.") // swiftlint:disable:this line_length
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
    ContentView()
        .modelContainer(DataController.preview.container)
}
