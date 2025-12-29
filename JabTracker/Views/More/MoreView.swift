//
//  MoreView.swift
//  JabTracker
//
//  More tab with account, settings, and feature configuration.
//

import SwiftData
import SwiftUI

struct MoreView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Query private var users: [User]

    var body: some View {
        NavigationStack {
            List {
                // User Header
                userHeaderSection

                // General Section
                Section("General") {
                    NavigationLink(destination: AccountView()) {
                        Label("Account", systemImage: "person.circle")
                    }
                    .accessibilityIdentifier("account-link")

                    NavigationLink(destination: SettingsView()) {
                        Label("Subscription", systemImage: "tag")
                    }
                    .accessibilityIdentifier("subscription-link")

                    NavigationLink(destination: UnitsOfMeasureView()) {
                        Label("Units", systemImage: "ruler")
                    }
                    .accessibilityIdentifier("units-link")
                }

                // Feature Settings Section
                Section("Feature Settings") {
                    NavigationLink(destination: BodyMetricsVisibilityView()) {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }
                    .accessibilityIdentifier("dashboard-settings-link")

                    NavigationLink(destination: StrategyView()) {
                        Label("Food Log", systemImage: "leaf")
                    }
                    .accessibilityIdentifier("food-log-settings-link")

                    NavigationLink(destination: SettingsView()) {
                        Label("Shortcuts", systemImage: "bolt.horizontal")
                    }
                    .accessibilityIdentifier("shortcuts-settings-link")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
        .accessibilityIdentifier("more-view")
    }

    // MARK: - User Header Section

    private var userHeaderSection: some View {
        Section {
            HStack(spacing: 16) {
                // Avatar with initials
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 56, height: 56)

                    Text(userInitials)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(users.first?.name ?? "Guest")
                        .font(.headline)

                    Text(memberSinceText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 8)
        }
        .accessibilityIdentifier("user-header-section")
    }

    private var userInitials: String {
        guard let name = users.first?.name, !name.isEmpty else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }

    private var memberSinceText: String {
        guard let user = users.first else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return "Member Since \(formatter.string(from: user.createdAt))"
    }
}

#Preview {
    MoreView()
        .modelContainer(DataController.preview.container)
        .environmentObject(AuthenticationManager())
}
