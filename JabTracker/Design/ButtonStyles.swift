import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(DesignTokens.Typography.headline)
      .foregroundColor(.white)
      .padding(.horizontal, 24)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(DesignTokens.Colors.primaryGradient)
      )
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}

struct SecondaryButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(DesignTokens.Typography.headline)
      .foregroundColor(DesignTokens.Colors.primary)
      .padding(.horizontal, 24)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .strokeBorder(DesignTokens.Colors.primary, lineWidth: 2)
      )
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}
