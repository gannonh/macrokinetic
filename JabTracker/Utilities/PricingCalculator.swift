import Foundation

/// Utility for calculating subscription pricing display information and savings
struct PricingCalculator {
    
    /// Represents annual subscription savings information
    struct AnnualSavings {
        let dollarAmount: Double
        let percentage: Double
    }
    
    /// Calculate annual savings compared to monthly subscription
    /// - Parameters:
    ///   - monthlyPrice: Monthly subscription price
    ///   - annualPrice: Annual subscription price
    /// - Returns: Savings information with dollar amount and percentage
    static func calculateAnnualSavings(monthlyPrice: Double, annualPrice: Double) -> AnnualSavings {
        guard monthlyPrice > 0 else {
            return AnnualSavings(dollarAmount: 0.0, percentage: 0.0)
        }
        
        let annualEquivalentOfMonthly = monthlyPrice * 12
        let dollarSavings = annualEquivalentOfMonthly - annualPrice
        let percentageSavings = (dollarSavings / annualEquivalentOfMonthly) * 100
        
        return AnnualSavings(
            dollarAmount: dollarSavings,
            percentage: percentageSavings
        )
    }
    
    /// Format monthly price for display
    /// - Parameter price: Monthly price value
    /// - Returns: Formatted string like "$4.99/month"
    static func formatMonthlyPrice(_ price: Double) -> String {
        String(format: "$%.2f/month", price)
    }
    
    /// Format annual price for display
    /// - Parameter price: Annual price value
    /// - Returns: Formatted string like "$39.99/year"
    static func formatAnnualPrice(_ price: Double) -> String {
        String(format: "$%.2f/year", price)
    }
    
    /// Calculate monthly equivalent of annual pricing
    /// - Parameter annualPrice: Annual subscription price
    /// - Returns: Monthly equivalent price
    static func calculateMonthlyEquivalent(annualPrice: Double) -> Double {
        annualPrice / 12.0
    }
    
    /// Format savings display string for UI
    /// - Parameter savings: Annual savings information
    /// - Returns: User-friendly savings display string
    static func formatSavingsDisplay(savings: AnnualSavings) -> String {
        if savings.percentage <= 0 {
            return "No savings"
        }
        
        let percentageString = String(format: "%.0f%%", savings.percentage)
        let dollarString = String(format: "$%.2f", savings.dollarAmount)
        
        return "Save \(percentageString) (\(dollarString))"
    }
}
