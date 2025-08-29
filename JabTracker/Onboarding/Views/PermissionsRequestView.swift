import SwiftUI

enum PermissionType {
    case notifications
    case healthKit
}

struct PermissionsRequestView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let type: PermissionType
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.system(size: 80))
                    .foregroundStyle(DesignTokens.Colors.primaryGradient)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(DesignTokens.Typography.largeTitle)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text(subtitle)
                    .font(DesignTokens.Typography.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            
            // Benefits list
            VStack(spacing: 16) {
                ForEach(benefits, id: \.self) { benefit in
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
                PrimaryButton(title: primaryButtonTitle) {
                    Task {
                        await requestPermission()
                    }
                }
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("\(accessibilityPrefix)-enable-button")
                
                SecondaryButton(title: secondaryButtonTitle) {
                    // Skip permission and continue
                    withAnimation(.spring()) {
                        viewModel.moveToNextStep()
                    }
                }
                .accessibilityIdentifier("\(accessibilityPrefix)-skip-button")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(DesignTokens.Colors.background)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("\(accessibilityPrefix)-view")
    }
    
    // MARK: - Computed Properties
    
    private var iconName: String {
        switch type {
        case .notifications: return "bell.fill"
        case .healthKit: return "heart.fill"
        }
    }
    
    private var title: String {
        switch type {
        case .notifications: return "Enable Notifications"
        case .healthKit: return "Connect Health Data"
        }
    }
    
    private var subtitle: String {
        switch type {
        case .notifications: return "Never miss a dose"
        case .healthKit: return "Track your progress"
        }
    }
    
    private var benefits: [String] {
        switch type {
        case .notifications:
            return [
                "Get reminded when it's time for your next dose",
                "Receive refill alerts before you run out",
                "Celebrate milestones and achievements"
            ]
        case .healthKit:
            return [
                "Automatically sync your weight measurements",
                "See correlations with your health metrics",
                "Get more personalized insights"
            ]
        }
    }
    
    private var primaryButtonTitle: String {
        switch type {
        case .notifications: return "Enable Notifications"
        case .healthKit: return "Connect Health Data"
        }
    }
    
    private var secondaryButtonTitle: String {
        switch type {
        case .notifications: return "Not Now"
        case .healthKit: return "Skip for Now"
        }
    }
    
    private var accessibilityPrefix: String {
        switch type {
        case .notifications: return "notifications"
        case .healthKit: return "healthkit"
        }
    }
    
    // MARK: - Actions
    
    private func requestPermission() async {
        switch type {
        case .notifications:
            await viewModel.requestNotificationPermissions()
        case .healthKit:
            await viewModel.requestHealthKitPermissions()
        }
        
        // Auto-advance after permission request
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring()) {
                viewModel.moveToNextStep()
            }
        }
    }
}