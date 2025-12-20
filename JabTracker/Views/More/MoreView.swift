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
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("More")
        }
        .accessibilityIdentifier("more-view")
    }
}

#Preview {
    MoreView()
}
