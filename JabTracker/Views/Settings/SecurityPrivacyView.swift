//
//  SecurityPrivacyView.swift
//  JabTracker
//
//  Security and privacy settings: Face ID/Touch ID, Health integration, iCloud sync.
//

import OSLog
import SwiftData
import SwiftUI

struct SecurityPrivacyView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var biometricManager: BiometricAuthManager
    @ObservedObject private var dataController = DataController.shared

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "SecurityPrivacyView"
    )

    @Query private var users: [User]

    @State private var showingDisableHealthSync = false
    @State private var errorMessage: String?
    @State private var showingError = false

    private var metricsService: MetricsService? {
        AppServices.shared.metricsService
    }

    var body: some View {
        List {
            // MARK: - Security Section
            if biometricManager.isAvailable {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: biometricManager.biometricType == .faceID ? "faceid" : "touchid")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .frame(width: 28)
                        Text(biometricManager.biometricTypeDisplayName)
                            .font(.body)
                        Spacer()
                        Toggle("", isOn: $biometricManager.isBiometricEnabled)
                            .labelsHidden()
                    }
                    .accessibilityIdentifier("biometric-toggle")
                } header: {
                    Text("Security")
                } footer: {
                    Text(
                        "Use \(biometricManager.biometricTypeDisplayName) to protect your data "
                            + "and require authentication when opening the app."
                    )
                }
            }

            // MARK: - Integrations Section
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .frame(width: 28)
                    Text("Health")
                        .font(.body)
                    Spacer()
                    Toggle("", isOn: healthToggleBinding)
                        .labelsHidden()
                }
                .accessibilityIdentifier("health-toggle")
            } header: {
                Text("Integrations")
            } footer: {
                Text("Sync weight, height, and biometrics from the Health app to keep your profile up to date.")
            }

            // MARK: - iCloud Sync Section
            Section {
                HStack {
                    Image(systemName: syncStatusIcon)
                        .foregroundColor(syncStatusColor)
                        .font(.title2)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("iCloud Sync")
                            .font(.body)

                        Text(dataController.syncStatusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if dataController.syncStatus == .accountNotSignedIn {
                        Button("Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    } else if dataController.syncStatus == .noNetwork
                        || dataController.syncStatus == .unknown
                    {
                        Button("Retry") {
                            dataController.retryCloudKitSetup()
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
                .accessibilityIdentifier("sync-status-section")

                if !dataController.willSyncAcrossDevices {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your data won't sync across devices")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(
                                "Data is stored locally on this device only. "
                                    + "Sign in to iCloud to sync across your devices."
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Cloud Storage")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Security & Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Disable Health Sync", isPresented: $showingDisableHealthSync) {
            Button("Disable", role: .destructive) {
                Task { await disableHealthSync() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This will stop syncing your health data with Apple Health. "
                    + "To completely revoke permissions, open Health → Sharing → Apps → MacroKinetic."
            )
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .accessibilityIdentifier("security-privacy-view")
    }

    // MARK: - Health Toggle Binding

    private var healthToggleBinding: Binding<Bool> {
        Binding(
            get: { users.first?.healthSyncEnabled ?? false },
            set: { newValue in
                if newValue {
                    Task { await enableHealthSync() }
                } else {
                    showingDisableHealthSync = true
                }
            }
        )
    }

    @MainActor
    private func enableHealthSync() async {
        guard let user = users.first, let service = metricsService else { return }

        do {
            let success = try await service.setHealthSyncEnabled(true, for: user)
            if !success {
                errorMessage = "Could not enable Health sync. Please allow access in Settings."
                showingError = true
            }
        } catch {
            errorMessage = "Could not enable Health sync: \(error.localizedDescription)"
            showingError = true
        }
    }

    @MainActor
    private func disableHealthSync() async {
        guard let user = users.first, let service = metricsService else { return }

        do {
            _ = try await service.setHealthSyncEnabled(false, for: user)
        } catch {
            errorMessage = "Could not disable Health sync: \(error.localizedDescription)"
            showingError = true
        }
    }

    // MARK: - Sync Status Helpers

    private var syncStatusIcon: String {
        switch dataController.syncStatus {
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
        switch dataController.syncStatus {
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
    NavigationStack {
        SecurityPrivacyView()
            .modelContainer(DataController.preview.container)
            .environmentObject(BiometricAuthManager())
    }
}
