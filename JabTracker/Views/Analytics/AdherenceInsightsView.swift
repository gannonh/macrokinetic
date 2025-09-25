import SwiftData
import SwiftUI

struct AdherenceInsightsView: View {
    @Query private var users: [User]
    @State private var analyticsService = AnalyticsService()

    private var currentUser: User? {
        users.first
    }

    private var adherenceRate: Double {
        guard let user = currentUser else { return 0.0 }
        let context = ModelContext(DataController.shared.container)
        return analyticsService.calculateOverallAdherence(user: user, context: context)
    }

    private var currentStreak: Int {
        currentUser?.currentStreak ?? 0
    }

    private var bestStreak: Int {
        currentUser?.longestStreak ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if currentUser != nil {
                        // Adherence Metrics Card
                        AdherenceMetricsCard(adherenceRate: adherenceRate)

                        // Streak Counters Card
                        DesignCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Dose Streaks")
                                    .font(DesignTokens.Typography.headline)
                                    .foregroundColor(.primary)

                                StreakCounterView(
                                    currentStreak: currentStreak,
                                    bestStreak: bestStreak
                                )
                            }
                        }

                        // Insights Placeholder (for future implementation)
                        DesignCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Adherence Insights")
                                    .font(DesignTokens.Typography.headline)
                                    .foregroundColor(.primary)

                                Text("Personalized insights and recommendations will appear here.")
                                    .font(DesignTokens.Typography.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        // Empty State
                        DesignCard {
                            VStack(alignment: .center, spacing: 12) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)

                                Text("No Adherence Data")
                                    .font(DesignTokens.Typography.headline)
                                    .foregroundColor(.primary)

                                Text("Start logging doses to see your adherence insights.")
                                    .font(DesignTokens.Typography.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Adherence Insights")
            .navigationBarTitleDisplayMode(.large)
        }
        .accessibilityIdentifier("adherence-insights-view")
    }
}

#Preview {
    AdherenceInsightsView()
        .modelContainer(DataController.preview.container)
}
