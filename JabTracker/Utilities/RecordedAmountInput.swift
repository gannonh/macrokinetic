import Foundation

enum RecordedAmountInput {
    static func parse(_ text: String, allowZero: Bool = false, locale: Locale = .current) -> Double? {
        let decimalSeparator = locale.decimalSeparator ?? "."
        let separator = NSRegularExpression.escapedPattern(for: decimalSeparator)
        let pattern = "\\A(?:[0-9]+(?:\(separator)[0-9]+)?|\(separator)[0-9]+)(?:[eE][+-]?[0-9]+)?\\z"
        guard text.range(of: pattern, options: .regularExpression) != nil,
            let amount = Double(text.replacingOccurrences(of: decimalSeparator, with: ".")),
            amount.isFinite, amount > 0 || (allowZero && amount == 0)
        else { return nil }
        if amount == 0 {
            let mantissa = text.prefix { $0 != "e" && $0 != "E" }
            guard !mantissa.contains(where: { "123456789".contains($0) }) else { return nil }
        }
        return amount
    }

    static func text(for amount: Double, locale: Locale = .current) -> String {
        guard amount.isFinite else { return "" }
        var text = String(amount)
        if text.hasSuffix(".0") {
            text.removeLast(2)
        }
        return text.replacingOccurrences(of: ".", with: locale.decimalSeparator ?? ".")
    }

    static func displayText(for amount: Double, locale: Locale = .current) -> String {
        var text = self.text(for: amount, locale: locale)
        guard !text.isEmpty, !text.contains("e"), !text.contains("E") else { return text }
        let separator = locale.decimalSeparator ?? "."
        let parts = text.components(separatedBy: separator)
        if parts.count == 1 {
            text += separator + "00"
        } else if parts[1].count == 1 {
            text += "0"
        }
        return text
    }
}
