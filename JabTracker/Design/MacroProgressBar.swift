//
//  MacroProgressBar.swift
//  JabTracker
//
//  Compact horizontal progress bar for macro tracking with label and remaining value.
//

import SwiftUI

/// Compact macro progress bar showing remaining/consumed with visual progress
struct MacroProgressBar: View {
    // MARK: - Properties

    /// Short label (e.g., "Cal", "P", "F", "C")
    let label: String

    /// Current consumed value
    let current: Double

    /// Target value
    let target: Double

    /// Progress bar fill color
    let color: Color

    /// Display mode for the value text
    enum DisplayMode {
        case remaining  // "550 left"
        case consumed  // "1450"
        case fraction  // "1450/2000"
    }

    /// How to display the value
    let displayMode: DisplayMode

    /// Whether to invert the progress bar (show remaining instead of consumed)
    let invertProgress: Bool

    /// Optional icon (e.g., "flame.fill" for calories)
    let icon: String?

    /// Whether to show remaining value below the progress bar
    let showRemainingBelow: Bool

    /// Accessibility identifier for testing
    let accessibilityIdentifier: String

    // MARK: - Computed Properties

    /// Progress ratio (0.0 to 1.0+)
    private var progress: Double {
        guard target > 0 else { return 0 }
        if invertProgress {
            // Show remaining as progress (full when nothing consumed, empty when target reached)
            return max(0, (target - current) / target)
        }
        return current / target
    }

    /// Whether target is exceeded (consumed > target)
    private var isOver: Bool {
        current > target
    }

    /// Remaining amount (negative if over)
    private var remaining: Double {
        target - current
    }

    /// Text for the remaining value below progress bar
    private var remainingText: String {
        if isOver {
            return "-\(Int(abs(remaining).rounded()))"
        } else {
            return "\(Int(remaining.rounded())) left"
        }
    }

    /// Display text for the value
    private var valueText: String {
        switch displayMode {
        case .remaining:
            if isOver {
                return "+\(Int(abs(remaining).rounded()))"
            } else {
                return "\(Int(remaining.rounded())) left"
            }
        case .consumed:
            return "\(Int(current.rounded()))"
        case .fraction:
            return "\(Int(current.rounded()))/\(Int(target.rounded()))"
        }
    }

    // MARK: - Initialization

    init(
        label: String,
        current: Double,
        target: Double,
        color: Color,
        displayMode: DisplayMode = .remaining,
        invertProgress: Bool = false,
        icon: String? = nil,
        showRemainingBelow: Bool = false,
        accessibilityIdentifier: String = "macro-progress"
    ) {
        self.label = label
        self.current = current
        self.target = target
        self.color = color
        self.displayMode = displayMode
        self.invertProgress = invertProgress
        self.icon = icon
        self.showRemainingBelow = showRemainingBelow
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label/icon and value row
            HStack(spacing: 2) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundColor(color)
                }

                if !label.isEmpty {
                    Text(label)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                }

                Text(valueText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .lineLimit(1)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                        .fill(color.opacity(0.2))

                    // Fill
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small)
                        .fill(color)
                        .frame(width: geometry.size.width * min(progress, 1.0))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)

            // Remaining value below progress bar
            if showRemainingBelow {
                Text(remainingText)
                    .font(.caption2)
                    .foregroundColor(isOver ? .red : .secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(valueText)")
    }
}

// MARK: - Preview

#Preview("Various States") {
    VStack(spacing: 24) {
        // Normal progress
        HStack(spacing: 12) {
            MacroProgressBar(
                label: "Cal",
                current: 1450,
                target: 2000,
                color: DesignTokens.Colors.calories,
                accessibilityIdentifier: "macro-progress-cal"
            )
            MacroProgressBar(
                label: "P",
                current: 89,
                target: 125,
                color: DesignTokens.Colors.protein,
                accessibilityIdentifier: "macro-progress-protein"
            )
            MacroProgressBar(
                label: "F",
                current: 51,
                target: 65,
                color: DesignTokens.Colors.fat,
                accessibilityIdentifier: "macro-progress-fat"
            )
            MacroProgressBar(
                label: "C",
                current: 136,
                target: 200,
                color: DesignTokens.Colors.carbs,
                accessibilityIdentifier: "macro-progress-carbs"
            )
        }
        .padding()
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(DesignTokens.CornerRadius.card)

        // Over target
        HStack(spacing: 12) {
            MacroProgressBar(
                label: "Cal",
                current: 2200,
                target: 2000,
                color: DesignTokens.Colors.calories
            )
            MacroProgressBar(
                label: "P",
                current: 140,
                target: 125,
                color: DesignTokens.Colors.protein
            )
        }
        .padding()
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(DesignTokens.CornerRadius.card)

        // Fraction mode with flame icon
        HStack(spacing: 12) {
            MacroProgressBar(
                label: "Cal",
                current: 1450,
                target: 2000,
                color: DesignTokens.Colors.calories,
                displayMode: .fraction,
                icon: "flame.fill"
            )
            MacroProgressBar(
                label: "P",
                current: 89,
                target: 125,
                color: DesignTokens.Colors.protein,
                displayMode: .fraction
            )
        }
        .padding()
        .background(DesignTokens.Colors.cardBackground)
        .cornerRadius(DesignTokens.CornerRadius.card)
    }
    .padding()
}
