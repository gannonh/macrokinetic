//
//  SecurityPrivacyView.swift
//  JabTracker
//
//  Security and privacy settings: Face ID/Touch ID, Health integration, local data storage.
//

import OSLog
import SwiftData
import SwiftUI

struct SecurityPrivacyView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var biometricManager: BiometricAuthManager

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

            // MARK: - Data Storage Section
            Section {
                HStack {
                    Image(systemName: "iphone")
                        .foregroundColor(DesignTokens.Colors.info)
                        .font(.title2)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your data")
                            .font(.body)

                        Text("Stored on this iPhone")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("local-storage-section")
            } header: {
                Text("Data Storage")
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
}

#Preview {
    NavigationStack {
        SecurityPrivacyView()
            .modelContainer(DataController.preview.container)
            .environmentObject(BiometricAuthManager())
    }
}
