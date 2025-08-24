import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("design-system-primary-button")
            .accessibilityLabel(title)
            .accessibilityHint("Primary action button")
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityIdentifier("design-system-secondary-button")
            .accessibilityLabel(title)
            .accessibilityHint("Secondary action button")
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton(title: "Primary Action") {}
        SecondaryButton(title: "Secondary Action") {}
    }
    .padding()
}
