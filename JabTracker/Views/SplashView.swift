import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App Logo with Animation
            VStack(spacing: 16) {
                Image(systemName: "syringe.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(DesignTokens.Colors.primaryGradient)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("JabTracker")
                    .font(DesignTokens.Typography.largeTitle)
                    .bold()
                    .opacity(isAnimating ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
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
            isAnimating = true
        }
    }
}

#Preview {
    SplashView()
}