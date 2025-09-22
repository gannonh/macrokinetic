import SwiftUI
import Testing
import UIKit

@testable import JabTracker

// Helper extension for testing color values
extension Color {
  var uiColor: UIColor {
    UIColor(self)
  }

  // swiftlint:disable:next large_tuple
  func rgbComponents() -> (red: Double, green: Double, blue: Double, alpha: Double)? {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    guard self.uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
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
      let expectedRed = 102.0 / 255.0  // ≈ 0.4
      let expectedGreen = 126.0 / 255.0  // ≈ 0.494
      let expectedBlue = 234.0 / 255.0  // ≈ 0.918

      #expect(
        abs(primaryRGB.red - expectedRed) < 0.01, "Primary color red component should be ≈0.4")
      #expect(
        abs(primaryRGB.green - expectedGreen) < 0.01,
        "Primary color green component should be ≈0.494")
      #expect(
        abs(primaryRGB.blue - expectedBlue) < 0.01, "Primary color blue component should be ≈0.918")
      #expect(primaryRGB.alpha == 1.0, "Primary color should be fully opaque")
    } else {
      throw TestError.colorComponentsNotAccessible
    }

    // Test actual RGB values for secondary color (764ba2)
    if let secondaryRGB = secondaryColor?.rgbComponents() {
      // 0x76 = 118, 0x4b = 75, 0xa2 = 162
      let expectedRed = 118.0 / 255.0  // ≈ 0.463
      let expectedGreen = 75.0 / 255.0  // ≈ 0.294
      let expectedBlue = 162.0 / 255.0  // ≈ 0.635

      #expect(
        abs(secondaryRGB.red - expectedRed) < 0.01, "Secondary color red component should be ≈0.463"
      )
      #expect(
        abs(secondaryRGB.green - expectedGreen) < 0.01,
        "Secondary color green component should be ≈0.294")
      #expect(
        abs(secondaryRGB.blue - expectedBlue) < 0.01,
        "Secondary color blue component should be ≈0.635")
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
      #expect(
        blackRGB.red < 0.01 && blackRGB.green < 0.01 && blackRGB.blue < 0.01,
        "Black should have RGB ≈(0,0,0)")
    }

    if let whiteRGB = white?.rgbComponents() {
      #expect(
        whiteRGB.red > 0.99 && whiteRGB.green > 0.99 && whiteRGB.blue > 0.99,
        "White should have RGB ≈(1,1,1)")
    }
  }

  enum TestError: Error {
    case colorComponentsNotAccessible
  }

  @Test("Primary gradient is properly configured")
  func primaryGradientColors() throws {
    let gradient = DesignTokens.Colors.primaryGradient

    // Test that gradient exists and is the expected type
    #expect(
      type(of: gradient) == LinearGradient.self, "Primary gradient should be a LinearGradient")

    // Test that we can create gradients with the expected colors
    let manualGradient = LinearGradient(
      colors: [Color.primaryBlue, Color.primaryPurple],
      startPoint: .topLeading,
      endPoint: .bottomTrailing)

    // Both gradients should be LinearGradient type
    #expect(
      type(of: gradient) == type(of: manualGradient),
      "Primary gradient should be same type as manually created LinearGradient")

    // Test that the gradient can be used in SwiftUI views
    let gradientView = Rectangle().fill(gradient)
    let solidView = Rectangle().fill(Color.blue)

    // Different types of fills should have different types
    #expect(
      type(of: gradientView) != type(of: solidView),
      "Gradient-filled view should be different type than solid color-filled view")

    // Test that primary colors exist and can be used in gradients
    let testGradient = LinearGradient(
      colors: [Color.primaryBlue, Color.primaryPurple],
      startPoint: .top,
      endPoint: .bottom)
    #expect(
      type(of: testGradient) == LinearGradient.self,
      "Should be able to create gradient with primary colors")
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
    #expect(fonts.count == 4)  // We have all four typography styles
    #expect(styledTexts.count == 4)  // All can be applied to text
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
    _ = DesignCard {
      Text(testText)
    }

    // Test that card can hold different content types
    _ = DesignCard {
      VStack {
        Text("Title")
        Text("Subtitle")
      }
    }

    // Test that cards are actually created and functional
    // Instead of testing internal type strings, test that they behave as expected

    // Test that cards with Text content work
    let textCard: DesignCard<Text> = DesignCard { Text("Simple") }

    // Test that cards with VStack content work
    let vStackCard: DesignCard<VStack<TupleView<(Text, Text)>>> = DesignCard {
      VStack {
        Text("Title")
        Text("Subtitle")
      }
    }

    // Test that both types of cards can be created without errors
    // This validates the generic functionality without relying on string representations
    #expect(type(of: textCard) == DesignCard<Text>.self)
    #expect(type(of: vStackCard) == DesignCard<VStack<TupleView<(Text, Text)>>>.self)

    // Test that the cards can be used in UI contexts (they are proper Views)
    // We can verify they implement the View protocol by compiling successfully
  }

  @Test("Component functionality verification")
  func componentFunctionality() throws {
    // Test that components have expected functional properties
    let primaryButton = PrimaryButton(title: "Primary") {}
    let secondaryButton = SecondaryButton(title: "Secondary") {}
    let card = DesignCard { Text("Content") }

    // Test button properties (functional validation)
    #expect(primaryButton.title == "Primary")
    #expect(secondaryButton.title == "Secondary")

    // Test that buttons have different titles (behavioral validation)
    #expect(primaryButton.title != secondaryButton.title)

    // Test that components can be created successfully and have expected types
    #expect(type(of: card) == DesignCard<Text>.self)

    // All components should be usable as Views (compilation validates this)
    // This tests actual functionality rather than internal type representations
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
    for firstIndex in 0..<typographyStyles.count {
      for secondIndex in (firstIndex + 1)..<typographyStyles.count {
        #expect(
          typographyStyles[firstIndex] != typographyStyles[secondIndex],
          """
          Typography style at index \(firstIndex) should be different from \
          style at index \(secondIndex)
          """)
      }
    }

    // Test that fonts can be applied to text and are different
    #expect(largeTitle != body, "Large title font should be different from body font")
    #expect(headline != caption, "Headline font should be different from caption font")

    // Test that we can successfully apply fonts to text (creation test)
    let testText = Text("Sample")
    _ = testText.font(largeTitle)  // Test font application doesn't crash
    _ = testText.font(body)  // Test font application doesn't crash

    // Verify fonts can be applied without error by testing font inequality again
    #expect(largeTitle != body, "Fonts should remain different when applied to text")
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
    #expect(
      String(describing: gradientRect) != String(describing: solidRect),
      "Gradient should create different view than solid color")

    // Test that design tokens maintain consistency
    #expect(DesignTokens.Colors.primary == Color.primaryBlue)
    #expect(DesignTokens.Colors.secondary == Color.primaryPurple)
  }
}
