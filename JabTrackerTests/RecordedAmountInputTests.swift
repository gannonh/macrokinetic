import Foundation
import Testing

@testable import JabTracker

@Suite("Recorded amount text")
struct RecordedAmountInputTests {
    private let english = Locale(identifier: "en_US")

    @Test("Complete decimal input preserves literal amounts without a medication range")
    func completeAmounts() {
        #expect(RecordedAmountInput.parse("1.375", locale: english) == 1.375)
        #expect(RecordedAmountInput.parse("2.125", locale: english) == 2.125)
        #expect(RecordedAmountInput.parse("0.375", locale: english) == 0.375)
        #expect(RecordedAmountInput.parse(".625", locale: english) == 0.625)
        #expect(RecordedAmountInput.parse("1250", locale: english) == 1250)
        #expect(RecordedAmountInput.parse("1e3", locale: english) == 1000)
    }

    @Test("Empty, partial, malformed, negative, and nonfinite text is rejected completely")
    func invalidAmounts() {
        for text in [
            "", " ", "1.375 ", "1.375\n", ".", "1.", "1.375mg", "2.1251abc",
            "1..375", "1,375", "1 375", "-1.375", "-0", "+1.375", "0", "0.000",
            "nan", "NaN", "inf", "Infinity", "1e", "1e+", "1e309", "1e-999",
        ] {
            #expect(RecordedAmountInput.parse(text, locale: english) == nil)
        }
    }

    @Test("Zero is accepted only for a skipped record and never makes invalid text valid")
    func skippedZero() {
        #expect(RecordedAmountInput.parse("0", locale: english) == nil)
        #expect(RecordedAmountInput.parse("0", allowZero: true, locale: english) == 0)
        #expect(RecordedAmountInput.parse("0.000", allowZero: true, locale: english) == 0)
        #expect(RecordedAmountInput.parse("0.375", allowZero: true, locale: english) == 0.375)
        for text in ["", "nan", "inf", "-1", "-0", "1e309", "1e-999"] {
            #expect(RecordedAmountInput.parse(text, allowZero: true, locale: english) == nil)
        }
    }

    @Test("The locale decimal separator is preserved without accepting grouping separators")
    func localizedAmounts() {
        let french = Locale(identifier: "fr_FR")
        #expect(RecordedAmountInput.parse("1,375", locale: french) == 1.375)
        #expect(RecordedAmountInput.parse(",625", locale: french) == 0.625)
        #expect(RecordedAmountInput.parse("1.375", locale: french) == nil)
        #expect(RecordedAmountInput.parse("1 375", locale: french) == nil)
        #expect(RecordedAmountInput.text(for: 2.125, locale: french) == "2,125")
    }

    @Test("Editing text round trips existing finite amounts without decimal rounding")
    func existingAmounts() {
        #expect(RecordedAmountInput.text(for: 1.375, locale: english) == "1.375")
        #expect(RecordedAmountInput.text(for: 0.375, locale: english) == "0.375")
        #expect(RecordedAmountInput.text(for: 2, locale: english) == "2")
        #expect(RecordedAmountInput.text(for: .infinity, locale: english) == "")
        #expect(RecordedAmountInput.text(for: .nan, locale: english) == "")
        for amount in [1.375, 2.125, 0.375, 1.0000000000000002, 0.0000001, Double.greatestFiniteMagnitude] {
            #expect(RecordedAmountInput.parse(
                RecordedAmountInput.text(for: amount, locale: english), locale: english
            ) == amount)
        }
    }

    @Test("Readback keeps at least two decimal places without rounding recorded precision")
    func displayPrecision() {
        #expect(RecordedAmountInput.displayText(for: 0.25, locale: english) == "0.25")
        #expect(RecordedAmountInput.displayText(for: 0.5, locale: english) == "0.50")
        #expect(RecordedAmountInput.displayText(for: 1, locale: english) == "1.00")
        #expect(RecordedAmountInput.displayText(for: 1.375, locale: english) == "1.375")
        #expect(RecordedAmountInput.displayText(for: 0.375, locale: english) == "0.375")
        #expect(RecordedAmountInput.displayText(for: 0.625, locale: english) == "0.625")
        #expect(RecordedAmountInput.displayText(for: 0, locale: english) == "0.00")
        let french = Locale(identifier: "fr_FR")
        #expect(RecordedAmountInput.displayText(for: 0.5, locale: french) == "0,50")
        #expect(RecordedAmountInput.displayText(for: 1.375, locale: french) == "1,375")
        for amount in [0.25, 0.5, 1, 1.375, 0.375, 0.625, Double.greatestFiniteMagnitude] {
            #expect(RecordedAmountInput.parse(
                RecordedAmountInput.displayText(for: amount, locale: english), locale: english
            ) == amount)
        }
    }

    @Test("Quick Dose validates the current draft rather than a previous positive amount")
    @MainActor
    func quickDoseRejectsPreviousValueFallback() {
        let profile = MedicationProfile(genericName: "semaglutide", brandName: "Generic", currentDose: 1.375)
        let viewModel = QuickDoseViewModel()
        viewModel.selectedMedicationProfile = profile
        viewModel.selectedInjectionSite = "Thigh"
        #expect(viewModel.amountToSave == 1.375)
        #expect(viewModel.canSaveDose == true)

        for text in ["", "1.375mg", "nan", "inf", "0", "-1.375"] {
            viewModel.doseAmountText = text
            #expect(viewModel.amountToSave == nil)
            #expect(viewModel.canSaveDose == false)
            #expect(profile.currentDose == 1.375)
        }

        viewModel.doseAmountText = RecordedAmountInput.text(for: 2.125)
        #expect(viewModel.amountToSave == 2.125)
        #expect(viewModel.canSaveDose == true)
        #expect(viewModel.doseAmount == 1.375)
        #expect(profile.currentDose == 1.375)
    }

    @Test("Stored-dose readback keeps the recorded fraction")
    @MainActor
    func doseReadback() {
        #expect(Dose(amount: 1.375).formattedAmount == "1.375 mg")
        #expect(Dose(amount: 0.375).formattedAmount == "0.375 mg")
        #expect(Dose(amount: 0.625).formattedAmount == "0.625 mg")
        #expect(Dose(amount: 0.5).formattedAmount == "0.50 mg")
    }
}
