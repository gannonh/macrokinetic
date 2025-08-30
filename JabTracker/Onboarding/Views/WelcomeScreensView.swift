import SwiftUI

struct WelcomeScreensView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var currentWelcomeStep: Int = 0

    private let welcomeScreens = [
        WelcomeScreen(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Your Progress",
            subtitle: "Monitor your medication levels, track doses, and see your progress over time",
            description: "Get insights into your medication adherence and concentration levels with easy-to-understand charts and analytics."),
        WelcomeScreen(
            icon: "brain.head.profile",
            title: "Smart Calculations",
            subtitle: "Advanced pharmacokinetics modeling shows your real-time drug concentration",
            description: "Based on proven medical research, see exactly how much medication is in your system at any time."),
        WelcomeScreen(
            icon: "lock.shield",
            title: "Private & Secure",
            subtitle: "Your health data stays private with end-to-end encryption",
            description: "All data is encrypted and stored securely on your device and iCloud. We never share your information."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: self.$currentWelcomeStep) {
                ForEach(Array(self.welcomeScreens.enumerated()), id: \.offset) { index, screen in
                    WelcomeScreenContent(screen: screen)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: self.currentWelcomeStep)

            // Custom page dots
            HStack(spacing: 12) {
                ForEach(0 ..< self.welcomeScreens.count, id: \.self) { index in
                    Circle()
                        .fill(index == self.currentWelcomeStep ? DesignTokens.Colors.primary : Color(.systemGray4))
                        .frame(width: 12, height: 12)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                self.currentWelcomeStep = index
                            }
                        }
                        .accessibilityLabel("Page \(index + 1) of \(self.welcomeScreens.count)")
                }
            }
            .padding(.bottom, 24)

            // Skip button
            Button("Skip") {
                withAnimation(.spring()) {
                    self.viewModel.moveToNextStep()
                }
            }
            .font(DesignTokens.Typography.body)
            .foregroundColor(DesignTokens.Colors.primary)
            .padding(.bottom, 16)
            .accessibilityIdentifier("welcome-skip-button")
        }
        .onAppear {
            // Auto-advance through welcome screens
            self.startAutoAdvance()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("welcome-screens")
    }

    private func startAutoAdvance() {
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { timer in
            withAnimation(.spring()) {
                if self.currentWelcomeStep < self.welcomeScreens.count - 1 {
                    self.currentWelcomeStep += 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

struct WelcomeScreenContent: View {
    let screen: WelcomeScreen

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: self.screen.icon)
                .font(.system(size: 80))
                .foregroundStyle(DesignTokens.Colors.primaryGradient)
                .accessibilityHidden(true)

            // Content
            VStack(spacing: 16) {
                Text(self.screen.title)
                    .font(DesignTokens.Typography.largeTitle)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(self.screen.subtitle)
                    .font(DesignTokens.Typography.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text(self.screen.description)
                    .font(DesignTokens.Typography.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct WelcomeScreen {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
}
