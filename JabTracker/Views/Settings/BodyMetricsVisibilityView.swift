//
//  BodyMetricsVisibilityView.swift
//  JabTracker
//
//  Settings screen for configuring body metrics and photo visibility.
//

import SwiftData
import SwiftUI

struct BodyMetricsVisibilityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    private var user: User? { users.first }

    var body: some View {
        List {
            descriptionSection
            weightSection
            progressPhotosSection
            upperBodySection
            armsSection
            legsSection
            ratiosSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Body Metrics Visibility")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("body-metrics-visibility-view")
    }

    // MARK: - Sections

    private var descriptionSection: some View {
        Section {
            Text(
                "Toggling a body metric will control its visibility in your Dashboard and editors "
                    + "without deleting any existing data. When hidden, you won't see this metric going "
                    + "forward, but your historical data will remain unaffected. You can always come back "
                    + "and toggle the metric back on."
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
    }

    private var weightSection: some View {
        Section("Weight & Body Fat") {
            defaultRow("Scale Weight")
            defaultRow("Visual Body Fat")
        }
    }

    private var progressPhotosSection: some View {
        Section("Progress Photos") {
            photoToggleRow("Front Photo", key: .front)
            photoToggleRow("Side Photo", key: .side)
            photoToggleRow("Back Photo", key: .back)
        }
    }

    private var upperBodySection: some View {
        Section("Upper Body") {
            metricToggleRow("Neck", key: .neck)
            metricToggleRow("Shoulders", key: .shoulders)
            metricToggleRow("Bust", key: .bust)
            metricToggleRow("Chest", key: .chest)
            metricToggleRow("Waist", key: .waist)
            metricToggleRow("Hips", key: .hip)
        }
    }

    private var armsSection: some View {
        Section("Arms") {
            metricToggleRow("Left Bicep", key: .leftBicep)
            metricToggleRow("Right Bicep", key: .rightBicep)
            metricToggleRow("Left Forearm", key: .leftForearm)
            metricToggleRow("Right Forearm", key: .rightForearm)
            metricToggleRow("Left Wrist", key: .leftWrist)
            metricToggleRow("Right Wrist", key: .rightWrist)
        }
    }

    private var legsSection: some View {
        Section("Legs") {
            metricToggleRow("Left Thigh", key: .leftThigh)
            metricToggleRow("Right Thigh", key: .rightThigh)
            metricToggleRow("Left Calf", key: .leftCalf)
            metricToggleRow("Right Calf", key: .rightCalf)
            metricToggleRow("Left Ankle", key: .leftAnkle)
            metricToggleRow("Right Ankle", key: .rightAnkle)
        }
    }

    private var ratiosSection: some View {
        Section("Ratios") {
            metricToggleRow("Waist to Height", key: .waistToHeight)
            metricToggleRow("Waist to Hip", key: .waistToHip)
        }
    }

    // MARK: - Row Builders

    private func defaultRow(_ label: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("Default")
                .foregroundColor(.secondary)
        }
    }

    private func metricToggleRow(_ label: String, key: MetricKey) -> some View {
        toggleRow(
            label,
            key: key.rawValue,
            category: "metric",
            isEnabled: { user?.isMetricEnabled($0) ?? false },
            toggle: { user?.toggleMetric($0) }
        )
    }

    private func photoToggleRow(_ label: String, key: PhotoTypeKey) -> some View {
        toggleRow(
            label,
            key: key.rawValue,
            category: "photo",
            isEnabled: { user?.isPhotoTypeEnabled($0) ?? false },
            toggle: { user?.togglePhotoType($0) }
        )
    }

    /// Generic toggle row builder to avoid duplication
    private func toggleRow(
        _ label: String,
        key: String,
        category: String,
        isEnabled: @escaping (String) -> Bool,
        toggle: @escaping (String) -> Void
    ) -> some View {
        Toggle(
            label,
            isOn: Binding(
                get: { isEnabled(key) },
                set: { _ in
                    toggle(key)
                    try? modelContext.save()
                }
            )
        )
        .accessibilityIdentifier("\(category)-toggle-\(key)")
    }
}

#Preview {
    NavigationStack {
        BodyMetricsVisibilityView()
    }
    .modelContainer(for: User.self, inMemory: true)
}
