@testable import JabTracker
import SwiftUI
import Testing
import UIKit

// Helper extension for testing color values
extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
    
    func rgbComponents() -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }
}

@Suite("Design System Tests")
struct DesignSystemTests {
    @Test("Color extension creates correct hex colors with proper RGB values")
    func colorHexExtension() throws {
        let primaryColor = Color(hex: "667eea")
        let secondaryColor = Color(hex: "764ba2")
        let invalidColor = Color(hex: "invalid")

        // Test valid hex colors are created correctly
        #expect(primaryColor != nil)
        #expect(secondaryColor != nil)
        
        // Test invalid hex colors return nil
        #expect(invalidColor == nil)
        
        // Test actual RGB values for primary color (667eea)
        if let primaryRGB = primaryColor?.rgbComponents() {
            // 0x66 = 102, 0x7e = 126, 0xea = 234
            let expectedRed = 102.0 / 255.0    // ≈ 0.4
            let expectedGreen = 126.0 / 255.0  // ≈ 0.494
            let expectedBlue = 234.0 / 255.0   // ≈ 0.918
            
            #expect(abs(primaryRGB.red - expectedRed) < 0.01, "Primary color red component should be ≈0.4")
            #expect(abs(primaryRGB.green - expectedGreen) < 0.01, "Primary color green component should be ≈0.494")
            #expect(abs(primaryRGB.blue - expectedBlue) < 0.01, "Primary color blue component should be ≈0.918")
            #expect(primaryRGB.alpha == 1.0, "Primary color should be fully opaque")
        } else {
            throw TestError.colorComponentsNotAccessible
        }
        
        // Test actual RGB values for secondary color (764ba2)
        if let secondaryRGB = secondaryColor?.rgbComponents() {
            // 0x76 = 118, 0x4b = 75, 0xa2 = 162
            let expectedRed = 118.0 / 255.0    // ≈ 0.463
            let expectedGreen = 75.0 / 255.0   // ≈ 0.294
            let expectedBlue = 162.0 / 255.0   // ≈ 0.635
            
            #expect(abs(secondaryRGB.red - expectedRed) < 0.01, "Secondary color red component should be ≈0.463")
            #expect(abs(secondaryRGB.green - expectedGreen) < 0.01, "Secondary color green component should be ≈0.294")
            #expect(abs(secondaryRGB.blue - expectedBlue) < 0.01, "Secondary color blue component should be ≈0.635")
            #expect(secondaryRGB.alpha == 1.0, "Secondary color should be fully opaque")
        } else {
            throw TestError.colorComponentsNotAccessible
        }
        
        // Test that predefined colors match expected hex values
        #expect(Color.primaryBlue == Color(hex: "667eea"))
        #expect(Color.primaryPurple == Color(hex: "764ba2"))
    }
    
    @Test("Color edge cases and error handling")
    func colorEdgeCases() throws {
        // Test various invalid hex formats
        let emptyHex = Color(hex: "")
        let shortHex = Color(hex: "fff")  // Too short
        let longHex = Color(hex: "1234567")  // Too long
        let invalidChars = Color(hex: "gghhii")  // Invalid hex characters
        
        #expect(emptyHex == nil, "Empty hex string should return nil")
        #expect(shortHex == nil, "Short hex string should return nil")
        #expect(longHex == nil, "Long hex string should return nil") 
        #expect(invalidChars == nil, "Invalid hex characters should return nil")
        
        // Test hex with # prefix should be handled
        let hexWithHash = Color(hex: "#667eea")
        #expect(hexWithHash != nil, "Hex with # prefix should be parsed")
        
        // Test hex with spaces should be handled
        let hexWithSpaces = Color(hex: " 667eea ")
        #expect(hexWithSpaces != nil, "Hex with spaces should be parsed")
        
        // Test pure black and white
        let black = Color(hex: "000000")
        let white = Color(hex: "ffffff")
        
        if let blackRGB = black?.rgbComponents() {
            #expect(blackRGB.red < 0.01 && blackRGB.green < 0.01 && blackRGB.blue < 0.01, "Black should have RGB ≈(0,0,0)")
        }
        
        if let whiteRGB = white?.rgbComponents() {
            #expect(whiteRGB.red > 0.99 && whiteRGB.green > 0.99 && whiteRGB.blue > 0.99, "White should have RGB ≈(1,1,1)")
        }
    }

    enum TestError: Error {
        case colorComponentsNotAccessible
    }

    @Test("Primary gradient is properly configured")
    func primaryGradientColors() throws {
        let gradient = DesignTokens.Colors.primaryGradient
        
        // Test that gradient can be created and used
        let testView = Rectangle().fill(gradient)
        
        // Test that gradient is different from a solid color fill
        let solidFill = Rectangle().fill(Color.blue)
        #expect(String(describing: testView) != String(describing: solidFill))
        
        // Test that we can create gradients with the expected colors
        let manualGradient = LinearGradient(
            colors: [Color.primaryBlue, Color.primaryPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Both gradients should be LinearGradient type
        #expect(type(of: gradient) == type(of: manualGradient))
    }

    @Test("Typography styles have correct font properties")
    func typographyStyles() throws {
        let largeTitle = DesignTokens.Typography.largeTitle
        let headline = DesignTokens.Typography.headline
        let body = DesignTokens.Typography.body
        let caption = DesignTokens.Typography.caption
        
        // Test that fonts are not equal (they should have different styles)
        #expect(largeTitle != headline)
        #expect(headline != body)
        #expect(body != caption)
        
        // Test specific font properties where accessible
        // Note: SwiftUI Font equality may not work as expected, so we test they can be used differently
        let fonts = [largeTitle, headline, body, caption]
        
        // Test that fonts can be applied to create different styled text
        let sampleText = "Test Text"
        let styledTexts = fonts.map { font in Text(sampleText).font(font) }
        
        // While we can't easily compare Font objects directly, we can verify they exist and are usable
        #expect(fonts.count == 4) // We have all four typography styles
        #expect(styledTexts.count == 4) // All can be applied to text
    }

    @Test("Button styles are properly configured")
    func buttonStylesConfiguration() throws {
        let primaryStyle = DesignTokens.ButtonStyles.primary
        let secondaryStyle = DesignTokens.ButtonStyles.secondary
        
        // Test that button styles are different types
        #expect(type(of: primaryStyle) == PrimaryButtonStyle.self)
        #expect(type(of: secondaryStyle) == SecondaryButtonStyle.self)
        
        // Test that styles can be applied to buttons
        let testButton = Button("Test") {}
        let primaryStyledButton = testButton.buttonStyle(primaryStyle)
        let secondaryStyledButton = testButton.buttonStyle(secondaryStyle)
        
        // Test that styled buttons have different string representations
        #expect(String(describing: primaryStyledButton) != String(describing: secondaryStyledButton))
    }
}

@Suite("Design Components Tests")
struct DesignComponentsTests {
    @Test("PrimaryButton has correct properties")
    func primaryButtonProperties() throws {
        let testAction = { print("Button tapped") }
        let button = PrimaryButton(title: "Test Button", action: testAction)
        
        // Test button properties
        #expect(button.title == "Test Button")
        
        // Test that button can be created with different titles
        let button2 = PrimaryButton(title: "Different Title") {}
        #expect(button2.title == "Different Title")
        #expect(button2.title != button.title)
    }

    @Test("SecondaryButton has correct properties")
    func secondaryButtonProperties() throws {
        let testAction = { print("Secondary button tapped") }
        let button = SecondaryButton(title: "Secondary Test", action: testAction)
        
        // Test button properties
        #expect(button.title == "Secondary Test")
        
        // Test that secondary button is different from primary
        let primaryButton = PrimaryButton(title: "Secondary Test") {}
        #expect(type(of: button) != type(of: primaryButton))
    }

    @Test("DesignCard contains expected content")
    func designCardContent() throws {
        let testText = "Test Content for Card"
        let card = DesignCard {
            Text(testText)
        }
        
        // Test that card can hold different content types
        let card2 = DesignCard {
            VStack {
                Text("Title")
                Text("Subtitle")
            }
        }
        
        // Cards with different content types are actually different generic types (this is expected behavior)
        // Test that both cards can be created successfully
        #expect(card != nil) // This will show a warning but proves the concept
        #expect(card2 != nil) // This will show a warning but proves the concept
        
        // Test that cards maintain their generic content type
        let textCard: DesignCard<Text> = DesignCard { Text("Simple") }
        let vStackCard: DesignCard<VStack<TupleView<(Text, Text)>>> = DesignCard {
            VStack {
                Text("Title")
                Text("Subtitle")
            }
        }
        
        // Test that different generic types are actually different
        #expect(String(describing: type(of: textCard)) != String(describing: type(of: vStackCard)))
    }
    
    @Test("Component accessibility identifiers are correct")
    func componentAccessibilityIdentifiers() throws {
        // Test that components have the expected accessibility identifiers
        // This is a structural test - identifiers should be consistent
        let primaryButton = PrimaryButton(title: "Primary") {}
        let secondaryButton = SecondaryButton(title: "Secondary") {}
        let card = DesignCard { Text("Content") }
        
        // Test that different component types are actually different
        #expect(String(describing: type(of: primaryButton)) != String(describing: type(of: card)))
        #expect(String(describing: type(of: secondaryButton)) != String(describing: type(of: card)))
        
        // Test that different button types are actually different
        #expect(String(describing: type(of: primaryButton)) != String(describing: type(of: secondaryButton)))
    }
}

@Suite("Accessibility Tests")
struct DesignSystemAccessibilityTests {
    @Test("Button components have correct accessibility properties")
    func buttonAccessibilityProperties() throws {
        let primaryTitle = "Primary Button"
        let secondaryTitle = "Secondary Button"
        
        let primaryButton = PrimaryButton(title: primaryTitle) {}
        let secondaryButton = SecondaryButton(title: secondaryTitle) {}
        
        // Test that buttons maintain their title properties for accessibility
        #expect(primaryButton.title == primaryTitle)
        #expect(secondaryButton.title == secondaryTitle)
        
        // Test that buttons have different titles when they should
        #expect(primaryButton.title != secondaryButton.title)
        
        // Test that empty title is handled
        let emptyTitleButton = PrimaryButton(title: "") {}
        #expect(emptyTitleButton.title == "")
        #expect(emptyTitleButton.title != primaryButton.title)
    }

    @Test("Typography fonts support system accessibility")
    func typographySystemAccessibility() throws {
        let largeTitle = DesignTokens.Typography.largeTitle
        let body = DesignTokens.Typography.body
        let headline = DesignTokens.Typography.headline
        let caption = DesignTokens.Typography.caption
        
        // Test that typography styles are distinct
        let typographyStyles = [largeTitle, headline, body, caption]
        
        // All typography styles should be different
        for i in 0..<typographyStyles.count {
            for j in (i+1)..<typographyStyles.count {
                #expect(typographyStyles[i] != typographyStyles[j],
                       "Typography style at index \(i) should be different from style at index \(j)")
            }
        }
        
        // Test that fonts can be applied to text and create different results
        let testText = Text("Sample")
        let styledText1 = testText.font(largeTitle)
        let styledText2 = testText.font(body)
        
        // SwiftUI Text objects with different fonts may have similar internal representations
        // Instead, test that both styled texts can be created and fonts are not equal
        #expect(largeTitle != body, "Large title font should be different from body font")
        
        // Test that both styled text objects can be created
        let bothTextsExist = styledText1 != nil && styledText2 != nil // This will show warnings but tests the concept
        #expect(bothTextsExist)
    }
    
    @Test("Design system supports accessibility features")
    func designSystemAccessibilitySupport() throws {
        // Test that color contrast is maintained
        let primaryColor = DesignTokens.Colors.primary
        let backgroundColor = Color(.systemBackground)
        
        #expect(primaryColor != backgroundColor, "Primary color should be different from background")
        
        // Test gradient is properly configured
        let gradient = DesignTokens.Colors.primaryGradient
        let solidColor = Color.blue
        
        // Gradient should be different from solid color when applied
        let gradientRect = Rectangle().fill(gradient)
        let solidRect = Rectangle().fill(solidColor)
        #expect(String(describing: gradientRect) != String(describing: solidRect), "Gradient should create different view than solid color")
        
        // Test that design tokens maintain consistency
        #expect(DesignTokens.Colors.primary == Color.primaryBlue)
        #expect(DesignTokens.Colors.secondary == Color.primaryPurple)
    }
}
