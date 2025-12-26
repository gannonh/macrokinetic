//
//  MoreView.swift
//  JabTracker
//
//  Overflow menu containing Settings and future items.
//

import SwiftUI

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                }

                Section("Feature Settings") {
                    NavigationLink(destination: BodyMetricsVisibilityView()) {
                        Label("Body Metrics Visibility", systemImage: "figure.arms.open")
                    }
                    .accessibilityIdentifier("body-metrics-visibility-link")

                    NavigationLink(destination: UnitsOfMeasureView()) {
                        Label("Units of Measure", systemImage: "ruler")
                    }
                    .accessibilityIdentifier("units-of-measure-link")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
        }
        .accessibilityIdentifier("more-view")
    }
}

#Preview {
    MoreView()
}
