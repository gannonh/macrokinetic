import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Logo with Animation
            VStack(spacing: 16) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .scaleEffect(self.isAnimating ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: self.isAnimating)

                Text("MacroKinetic")
                    .font(DesignTokens.Typography.largeTitle)
                    .bold()
                    .opacity(self.isAnimating ? 1.0 : 0.7)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: self.isAnimating)
            }

            Spacer()

            // Loading Indicator
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Color(hex: "667eea"))

                Text("Loading...")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .onAppear {
            self.isAnimating = true
        }
    }
}

#Preview {
    SplashView()
}
