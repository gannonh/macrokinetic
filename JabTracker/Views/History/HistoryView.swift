//
//  HistoryView.swift
//  JabTracker
//
//  Comprehensive history view that will replace the basic placeholder in ContentView.swift
//

import SwiftUI

struct HistoryView: View {
    var body: some View {
        DoseHistoryView()
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
    .modelContainer(DataController.preview.container)
}
