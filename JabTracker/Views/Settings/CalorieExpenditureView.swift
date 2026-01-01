//
//  CalorieExpenditureView.swift
//  JabTracker
//
//  Calorie expenditure settings (mock screen for Phase 17-03).
//

import SwiftUI

struct CalorieExpenditureView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Coming Soon")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
                .padding(.top, 24)

            DesignCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Calorie Expenditure")
                        .font(DesignTokens.Typography.headline)

                    Text("Track burned calories and activity to adjust your nutrition targets automatically.")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.secondary)

                    Text("This feature is not yet available.")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }

            Spacer()

            Text("This is a preview")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .navigationTitle("Calorie Expenditure")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("calorie-expenditure-view")
    }
}

#Preview {
    NavigationStack {
        CalorieExpenditureView()
    }
}
