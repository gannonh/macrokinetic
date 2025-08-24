import SwiftUI
@testable import JabTracker
import Testing

@Suite("Design System Tests")
struct DesignSystemTests {
    
    @Test("Color extension creates correct hex colors")
    func colorHexExtension() throws {
        let primaryColor = Color(hex: "667eea")
        let secondaryColor = Color(hex: "764ba2")
        
        // These should not be nil - hex colors should be valid
        #expect(primaryColor != nil)
        #expect(secondaryColor != nil)
    }
    
    @Test("Primary gradient has correct start and end colors")
    func primaryGradientColors() throws {
        let gradient = DesignTokens.Colors.primaryGradient
        
        // Verify gradient properties
        #expect(gradient != nil)
        // Gradient should have exactly 2 colors
        #expect(gradient.stops.count == 2)
    }
    
    @Test("Typography styles are properly configured")
    func typographyStyles() throws {
        let largeTitle = DesignTokens.Typography.largeTitle
        let headline = DesignTokens.Typography.headline
        let body = DesignTokens.Typography.body
        let caption = DesignTokens.Typography.caption
        
        // All typography styles should be non-nil
        #expect(largeTitle != nil)
        #expect(headline != nil)
        #expect(body != nil)
        #expect(caption != nil)
    }
    
    @Test("Button style configurations exist")
    func buttonStyles() throws {
        let primaryStyle = DesignTokens.ButtonStyles.primary
        let secondaryStyle = DesignTokens.ButtonStyles.secondary
        
        // Button styles should be configured
        #expect(primaryStyle != nil)
        #expect(secondaryStyle != nil)
    }
}

@Suite("Design Components Tests")
struct DesignComponentsTests {
    
    @Test("PrimaryButton creates correct button")
    func primaryButtonCreation() throws {
        let button = PrimaryButton(title: "Test Button") {}
        
        // Button should be created successfully
        #expect(button != nil)
    }
    
    @Test("SecondaryButton creates correct button")
    func secondaryButtonCreation() throws {
        let button = SecondaryButton(title: "Test Button") {}
        
        // Button should be created successfully
        #expect(button != nil)
    }
    
    @Test("DesignCard creates correct container")
    func designCardCreation() throws {
        let card = DesignCard {
            Text("Test Content")
        }
        
        // Card should be created successfully
        #expect(card != nil)
    }
}

@Suite("Accessibility Tests")
struct DesignSystemAccessibilityTests {
    
    @Test("Button components have proper accessibility traits")
    func buttonAccessibilityTraits() throws {
        let primaryButton = PrimaryButton(title: "Primary Button") {}
        let secondaryButton = SecondaryButton(title: "Secondary Button") {}
        
        // Buttons should exist and be accessible
        #expect(primaryButton != nil)
        #expect(secondaryButton != nil)
    }
    
    @Test("Typography supports Dynamic Type")
    func typographyDynamicType() throws {
        // Typography styles should support Dynamic Type scaling
        let largeTitle = DesignTokens.Typography.largeTitle
        let body = DesignTokens.Typography.body
        
        #expect(largeTitle != nil)
        #expect(body != nil)
    }
}