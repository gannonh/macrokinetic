import SwiftUI

struct AdherenceMetricsCard: View {
    let adherenceRate: Double

    private var adherencePercentage: String {
        String(format: "%.0f%%", adherenceRate * 100)
    }

    private var adherenceColor: Color {
        switch adherenceRate {
        case 0.9...1.0:
            return .green
        case 0.7..<0.9:
            return .orange
        default:
            return .red
        }
    }

    private var adherenceQuality: String {
        switch adherenceRate {
        case 0.9...1.0:
            return "Excellent"
        case 0.7..<0.9:
            return "Good"
        default:
            return "Needs Improvement"
        }
    }

    var body: some View {
        DesignCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Adherence Rate")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(.primary)

                HStack {
                    Text(adherencePercentage)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(adherenceColor)

                    Spacer()

                    Text(adherenceQuality)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(adherenceColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(adherenceColor.opacity(0.1))
                        )
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Adherence rate: \(adherencePercentage), \(adherenceQuality) adherence")
        .accessibilityValue(adherencePercentage)
        .accessibilityIdentifier("adherence-metrics-card")
    }
}

#Preview {
    VStack(spacing: 16) {
        AdherenceMetricsCard(adherenceRate: 0.95)
        AdherenceMetricsCard(adherenceRate: 0.75)
        AdherenceMetricsCard(adherenceRate: 0.45)
        AdherenceMetricsCard(adherenceRate: 0.0)
        AdherenceMetricsCard(adherenceRate: 1.0)
    }
    .padding()
}
