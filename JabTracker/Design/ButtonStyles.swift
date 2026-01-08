import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    private var buttonColor: Color {
        DesignTokens.Colors.accent
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isEnabled ? buttonColor : buttonColor.opacity(0.5))
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    private var buttonColor: Color {
        DesignTokens.Colors.accent
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(isEnabled ? buttonColor : buttonColor.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(DesignTokens.Colors.background)
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isEnabled ? buttonColor : buttonColor.opacity(0.5),
                        lineWidth: 1
                    )
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
