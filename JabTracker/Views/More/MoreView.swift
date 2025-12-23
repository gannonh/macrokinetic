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
