//
//  PageHeader.swift
//  JabTracker
//
//  Custom page header component for compact title layout.
//

import SwiftUI

/// A custom page header that replaces the standard navigation bar title
/// with tighter vertical spacing, similar to Apple's Music/News/Podcasts apps.
struct PageHeader<TrailingContent: View>: View {
    let title: String
    let trailingContent: TrailingContent?

    init(title: String, @ViewBuilder trailing: () -> TrailingContent) {
        self.title = title
        self.trailingContent = trailing()
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: DesignTokens.Typography.pageTitleSize, weight: .bold))
            Spacer()
            if let trailing = trailingContent {
                trailing
            }
        }
        .padding(.top, DesignTokens.Spacing.pageHeaderTopPadding)
        .padding(.horizontal, DesignTokens.Spacing.pageHeaderHorizontalPadding)
    }
}

// Convenience initializer for headers without trailing content
extension PageHeader where TrailingContent == EmptyView {
    init(title: String) {
        self.title = title
        self.trailingContent = nil
    }
}

#Preview {
    List {
        Section {
            PageHeader(title: "Food Log") {
                Button {
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }
}
