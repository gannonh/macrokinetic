import SwiftUI

struct AdherenceMetricsCard: View {
    let adherenceRate: Double

    private var roundedPercent: Int {
        Int((adherenceRate * 100).rounded())
    }

    private var adherencePercentage: String {
        "\(roundedPercent)%"
    }

    private var adherenceColor: Color {
        switch roundedPercent {
        case 90...100:
            return .green
        case 70..<90:
            return .orange
        default:
            return .red
        }
    }

    private var adherenceQuality: String {
        switch roundedPercent {
        case 90...100:
            return "Excellent"
        case 70..<90:
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
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(adherenceColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(adherenceColor.opacity(0.05))
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
