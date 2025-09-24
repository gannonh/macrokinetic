import Testing

@testable import JabTracker

@Suite("Pricing Calculator")
struct PricingCalculatorTests {
    @Test("Calculate annual savings percentage")
    func calculateAnnualSavingsPercentage() throws {
        // GIVEN: Monthly price $4.99 and annual price $39.99
        let monthlyPrice = 4.99
        let annualPrice = 39.99

        // WHEN: Calculate annual savings
        let savings = PricingCalculator.calculateAnnualSavings(
            monthlyPrice: monthlyPrice,
            annualPrice: annualPrice)

        // THEN: Should show correct savings percentage
        let expectedMonthlyCost = monthlyPrice * 12  // $59.88
        let expectedSavings = expectedMonthlyCost - annualPrice  // $19.89
        let expectedPercentage = (expectedSavings / expectedMonthlyCost) * 100  // ~33%

        #expect(abs(savings.dollarAmount - expectedSavings) < 0.01)
        #expect(abs(savings.percentage - expectedPercentage) < 1.0)  // Allow 1% tolerance
        #expect(savings.percentage > 30)
        #expect(savings.percentage < 40)
    }

    @Test("Format pricing display strings")
    func formatPricingDisplayStrings() throws {
        // GIVEN: Product prices
        let monthlyPrice = 4.99
        let annualPrice = 39.99

        // WHEN: Format display strings
        let monthlyDisplay = PricingCalculator.formatMonthlyPrice(monthlyPrice)
        let annualDisplay = PricingCalculator.formatAnnualPrice(annualPrice)

        // THEN: Should format correctly for UI display
        #expect(monthlyDisplay == "$4.99/month")
        #expect(annualDisplay == "$39.99/year")
    }

    @Test("Calculate monthly equivalent for annual pricing")
    func calculateMonthlyEquivalent() throws {
        // GIVEN: Annual price
        let annualPrice = 39.99

        // WHEN: Calculate monthly equivalent
        let monthlyEquivalent = PricingCalculator.calculateMonthlyEquivalent(annualPrice: annualPrice)

        // THEN: Should be approximately $3.33/month
        let expected = annualPrice / 12
        #expect(abs(monthlyEquivalent - expected) < 0.01)
        #expect(monthlyEquivalent < 3.35)
        #expect(monthlyEquivalent > 3.30)
    }

    @Test("Format savings display string")
    func formatSavingsDisplayString() throws {
        // GIVEN: Pricing information
        let monthlyPrice = 4.99
        let annualPrice = 39.99

        // WHEN: Format savings display
        let savings = PricingCalculator.calculateAnnualSavings(
            monthlyPrice: monthlyPrice,
            annualPrice: annualPrice)
        let savingsDisplay = PricingCalculator.formatSavingsDisplay(savings: savings)

        // THEN: Should show user-friendly savings text
        #expect(savingsDisplay.contains("Save"))
        #expect(savingsDisplay.contains("%"))
        #expect(savingsDisplay.contains("$"))

        // Should contain the percentage (around 33%)
        let percentageString = String(format: "%.0f%%", savings.percentage)
        #expect(savingsDisplay.contains(percentageString))
    }

    @Test("Edge case: Zero prices")
    func edgeCaseZeroPrices() throws {
        // GIVEN: Zero prices (edge case)
        let monthlyPrice = 0.0
        let annualPrice = 0.0

        // WHEN: Calculate savings
        let savings = PricingCalculator.calculateAnnualSavings(
            monthlyPrice: monthlyPrice,
            annualPrice: annualPrice)

        // THEN: Should handle gracefully
        #expect(savings.dollarAmount == 0.0)
        #expect(savings.percentage == 0.0)
    }

    @Test("Edge case: Annual price higher than monthly equivalent")
    func edgeCaseAnnualPriceHigher() throws {
        // GIVEN: Annual price higher than monthly equivalent (unusual case)
        let monthlyPrice = 4.99
        let annualPrice = 100.00  // Much higher than 12 * $4.99

        // WHEN: Calculate savings
        let savings = PricingCalculator.calculateAnnualSavings(
            monthlyPrice: monthlyPrice,
            annualPrice: annualPrice)

        // THEN: Should show negative savings (more expensive)
        #expect(savings.dollarAmount < 0)
        #expect(savings.percentage < 0)
    }
}
