import SwiftUI

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hex.count == 6 {
            let scanner = Scanner(string: hex)
            var hexNumber: UInt64 = 0

            if scanner.scanHexInt64(&hexNumber) {
                let red = Double((hexNumber & 0xff0000) >> 16) / 255
                let green = Double((hexNumber & 0x00ff00) >> 8) / 255
                let blue = Double(hexNumber & 0x0000ff) / 255

                self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
                return
            }
        }

        return nil
    }
}

extension Color {
    static let primaryBlue = Color(hex: "667eea") ?? .blue
    static let primaryPurple = Color(hex: "764ba2") ?? .purple
}
