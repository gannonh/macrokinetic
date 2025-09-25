import SwiftUI

struct StreakCounterView: View {
    let currentStreak: Int
    let bestStreak: Int

    private func formatStreakText(_ count: Int) -> String {
        let dayText = count == 1 ? "day" : "days"
        return "\(count) \(dayText)"
    }

    var body: some View {
        HStack(spacing: 20) {
            // Current Streak
            VStack(alignment: .center, spacing: 4) {
                Text("\(currentStreak)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Current Streak")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text(formatStreakText(currentStreak))
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Current streak: \(formatStreakText(currentStreak))")
            .accessibilityIdentifier("current-streak-counter")

            Divider()
                .frame(height: 40)

            // Best Streak
            VStack(alignment: .center, spacing: 4) {
                Text("\(bestStreak)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text("Best Streak")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Text(formatStreakText(bestStreak))
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Best streak: \(formatStreakText(bestStreak))")
            .accessibilityIdentifier("best-streak-counter")
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 20) {
        DesignCard {
            StreakCounterView(currentStreak: 12, bestStreak: 28)
        }

        DesignCard {
            StreakCounterView(currentStreak: 0, bestStreak: 15)
        }

        DesignCard {
            StreakCounterView(currentStreak: 1, bestStreak: 1)
        }

        DesignCard {
            StreakCounterView(currentStreak: 5, bestStreak: 12)
        }
    }
    .padding()
}
