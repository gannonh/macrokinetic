import SwiftUI

enum PermissionType {
    case notifications
    case healthKit
}

/// Legacy permissions request view (v0.5.x and earlier). Retained for reference only.
struct PermissionsRequestView: View {
    @ObservedObject var viewModel: LegacyOnboardingViewModel
    let type: PermissionType

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: self.iconName)
                    .font(.system(size: 80))
                    .foregroundStyle(DesignTokens.Colors.primaryGradient)
                    .accessibilityHidden(true)

                Text(self.title)
                    .font(DesignTokens.Typography.largeTitle)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(self.subtitle)
                    .font(DesignTokens.Typography.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)

            // Benefits list
            VStack(spacing: 16) {
                ForEach(self.benefits, id: \.self) { benefit in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignTokens.Colors.success)
                            .accessibilityHidden(true)

                        Text(benefit)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Action buttons
            VStack(spacing: 16) {
                PrimaryButton(title: self.primaryButtonTitle) {
                    Task {
                        await self.requestPermission()
                    }
                }
                .disabled(self.viewModel.isLoading)
                .accessibilityIdentifier("\(self.accessibilityPrefix)-enable-button")

                SecondaryButton(title: self.secondaryButtonTitle) {
                    // Skip permission and continue
                    withAnimation(.spring()) {
                        self.viewModel.moveToNextStep()
                    }
                }
                .accessibilityIdentifier("\(self.accessibilityPrefix)-skip-button")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(DesignTokens.Colors.background)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(self.accessibilityPrefix)-view")
    }

    // MARK: - Computed Properties

    private var iconName: String {
        switch self.type {
        case .notifications: return "bell.fill"
        case .healthKit: return "heart.fill"
        }
    }

    private var title: String {
        switch self.type {
        case .notifications: return "Enable Notifications"
        case .healthKit: return "Connect Health Data"
        }
    }

    private var subtitle: String {
        switch self.type {
        case .notifications: return "Never miss a dose"
        case .healthKit: return "Track your progress"
        }
    }

    private var benefits: [String] {
        switch self.type {
        case .notifications:
            return [
                "Get reminded when it's time for your next dose",
                "Receive refill alerts before you run out",
                "Celebrate milestones and achievements",
            ]
        case .healthKit:
            return [
                "Automatically sync your weight measurements",
                "See correlations with your health metrics",
                "Get more personalized insights",
            ]
        }
    }

    private var primaryButtonTitle: String {
        switch self.type {
        case .notifications: return "Enable Notifications"
        case .healthKit: return "Connect Health Data"
        }
    }

    private var secondaryButtonTitle: String {
        switch self.type {
        case .notifications: return "Not Now"
        case .healthKit: return "Skip for Now"
        }
    }

    private var accessibilityPrefix: String {
        switch self.type {
        case .notifications: return "notifications"
        case .healthKit: return "healthkit"
        }
    }

    // MARK: - Actions

    private func requestPermission() async {
        switch self.type {
        case .notifications:
            await self.viewModel.requestNotificationPermissions()
        case .healthKit:
            await self.viewModel.requestHealthKitPermissions()
        }

        // Auto-advance after permission request
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) {
                self.viewModel.moveToNextStep()
            }
        }
    }
}
