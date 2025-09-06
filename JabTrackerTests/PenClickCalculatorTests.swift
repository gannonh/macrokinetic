//
//  PenClickCalculatorTests.swift
//  JabTrackerTests
//

import Foundation
import Testing
@testable import JabTracker

@Suite("PenClickCalculator Tests")
struct PenClickCalculatorTests {
    
    @Test("Calculate clicks for Ozempic 1mg pen")
    func testOzempic1mgPenClicks() throws {
        // Given: Ozempic 1mg pen, 0.5mg dose
        let penType = PenClickCalculator.PenType.ozempic1mg
        let targetDose = 0.5
        
        // When: Calculate clicks
        let result = try PenClickCalculator.calculate(
            penType: penType,
            targetDose: targetDose
        )
        
        // Then: Verify clicks
        #expect(result.clicks == 50) // 0.5mg / 0.01mg per click = 50 clicks
        #expect(result.actualDose == 0.5)
        #expect(result.penType == penType.rawValue)
    }
    
    @Test("Calculate clicks for Ozempic 2mg pen")
    func testOzempic2mgPenClicks() throws {
        // Given: Ozempic 2mg pen, 1mg dose
        let penType = PenClickCalculator.PenType.ozempic2mg
        let targetDose = 1.0
        
        // When: Calculate clicks
        let result = try PenClickCalculator.calculate(
            penType: penType,
            targetDose: targetDose
        )
        
        // Then: Verify clicks
        #expect(result.clicks == 50) // 1mg / 0.02mg per click = 50 clicks
        #expect(result.actualDose == 1.0)
    }
    
    @Test("Calculate clicks for Mounjaro pen")
    func testMounjaroPenClicks() throws {
        // Given: Mounjaro 5mg pen, 2.5mg dose
        let penType = PenClickCalculator.PenType.mounjaro5mg
        let targetDose = 2.5
        
        // When: Calculate clicks
        let result = try PenClickCalculator.calculate(
            penType: penType,
            targetDose: targetDose
        )
        
        // Then: Verify clicks
        #expect(result.clicks == 100) // 2.5mg / 0.025mg per click = 100 clicks
        #expect(result.actualDose == 2.5)
    }
    
    @Test("Calculate clicks for Victoza pen")
    func testVictozaPenClicks() throws {
        // Given: Victoza pen, 1.2mg dose
        let penType = PenClickCalculator.PenType.victoza
        let targetDose = 1.2
        
        // When: Calculate clicks
        let result = try PenClickCalculator.calculate(
            penType: penType,
            targetDose: targetDose
        )
        
        // Then: Verify clicks
        #expect(result.clicks == 120) // 1.2mg / 0.01mg per click = 120 clicks
        #expect(result.actualDose == 1.2)
    }
    
    @Test("Fixed-dose pen returns no clicks")
    func testFixedDosePen() throws {
        // Given: Wegovy 2.4mg fixed-dose pen
        let penType = PenClickCalculator.PenType.wegovy24mg
        let targetDose = 2.4
        
        // When: Calculate clicks
        let result = try PenClickCalculator.calculate(
            penType: penType,
            targetDose: targetDose
        )
        
        // Then: Fixed-dose pen returns 0 clicks
        #expect(result.clicks == 0)
        #expect(result.actualDose == 2.4)
    }
    
    @Test("Invalid dose throws error")
    func testInvalidDose() throws {
        // Given: Invalid dose
        let penType = PenClickCalculator.PenType.ozempic1mg
        let targetDose = 0.0
        
        // When/Then: Should throw error
        #expect(throws: PenClickCalculator.PenClickError.invalidDose) {
            try PenClickCalculator.calculate(
                penType: penType,
                targetDose: targetDose
            )
        }
    }
    
    @Test("Dose exceeds maximum throws error")
    func testDoseExceedsMaximum() throws {
        // Given: Dose exceeds pen maximum
        let penType = PenClickCalculator.PenType.ozempic1mg
        let targetDose = 2.0 // Exceeds 1mg maximum
        
        // When/Then: Should throw error
        #expect(throws: PenClickCalculator.PenClickError.doseExceedsMaximum) {
            try PenClickCalculator.calculate(
                penType: penType,
                targetDose: targetDose
            )
        }
    }
    
    @Test("Get available doses for adjustable pen")
    func testAvailableDosesForAdjustablePen() {
        // Given: Ozempic 1mg pen
        let penType = PenClickCalculator.PenType.ozempic1mg
        
        // When: Get available doses
        let doses = PenClickCalculator.availableDoses(for: penType)
        
        // Then: Verify doses
        #expect(doses.count == 100) // 0.01 to 1.0 in 0.01 increments
        #expect(doses.first == 0.01)
        #expect(doses.last == 1.0)
    }
    
    @Test("Get available doses for fixed-dose pen")
    func testAvailableDosesForFixedDosePen() {
        // Given: Wegovy 2.4mg fixed-dose pen
        let penType = PenClickCalculator.PenType.wegovy24mg
        
        // When: Get available doses
        let doses = PenClickCalculator.availableDoses(for: penType)
        
        // Then: Only one dose available
        #expect(doses.count == 1)
        #expect(doses.first == 2.4)
    }
    
    @Test("Get pens for Semaglutide medication")
    func testPensForSemaglutide() {
        // Given: Semaglutide medication
        let medication = Medication.semaglutide
        
        // When: Get compatible pens
        let pens = PenClickCalculator.pensForMedication(medication)
        
        // Then: Verify Ozempic and Wegovy pens
        #expect(pens.count == 8)
        #expect(pens.contains(.ozempic025_05))
        #expect(pens.contains(.ozempic1mg))
        #expect(pens.contains(.ozempic2mg))
        #expect(pens.contains(.wegovy24mg))
    }
    
    @Test("Get pens for Tirzepatide medication")
    func testPensForTirzepatide() {
        // Given: Tirzepatide medication
        let medication = Medication.tirzepatide
        
        // When: Get compatible pens
        let pens = PenClickCalculator.pensForMedication(medication)
        
        // Then: Verify Mounjaro pens
        #expect(pens.count == 6)
        #expect(pens.contains(.mounjaro25mg))
        #expect(pens.contains(.mounjaro15mg))
    }
    
    @Test("Get pens for Liraglutide medication")
    func testPensForLiraglutide() {
        // Given: Liraglutide medication
        let medication = Medication.liraglutide
        
        // When: Get compatible pens
        let pens = PenClickCalculator.pensForMedication(medication)
        
        // Then: Verify Victoza and Saxenda pens
        #expect(pens.count == 2)
        #expect(pens.contains(.victoza))
        #expect(pens.contains(.saxenda))
    }
    
    @Test("Get pens for Dulaglutide medication")
    func testPensForDulaglutide() {
        // Given: Dulaglutide medication
        let medication = Medication.dulaglutide
        
        // When: Get compatible pens
        let pens = PenClickCalculator.pensForMedication(medication)
        
        // Then: Verify Trulicity pens
        #expect(pens.count == 4)
        #expect(pens.contains(.trulicity075mg))
        #expect(pens.contains(.trulicity45mg))
    }
    
    @Test("Pen type properties")
    func testPenTypeProperties() {
        // Test Ozempic 1mg pen properties
        let ozempic1mg = PenClickCalculator.PenType.ozempic1mg
        #expect(ozempic1mg.dosePerClick == 0.01)
        #expect(ozempic1mg.maximumDose == 1.0)
        #expect(ozempic1mg.isAdjustable == true)
        
        // Test fixed-dose Wegovy pen properties
        let wegovy = PenClickCalculator.PenType.wegovy24mg
        #expect(wegovy.dosePerClick == 0.01)
        #expect(wegovy.maximumDose == 2.4)
        #expect(wegovy.isAdjustable == false)
        
        // Test Mounjaro pen properties
        let mounjaro = PenClickCalculator.PenType.mounjaro5mg
        #expect(mounjaro.dosePerClick == 0.025)
        #expect(mounjaro.maximumDose == 5.0)
        #expect(mounjaro.isAdjustable == true)
    }
    
    @Test("Display text formatting")
    func testDisplayText() throws {
        // Given: A pen click result
        let result = try PenClickCalculator.calculate(
            penType: .ozempic1mg,
            targetDose: 0.5
        )
        
        // When: Get display text
        let displayText = result.displayText
        
        // Then: Verify text contains key information
        #expect(displayText.contains("50"))
        #expect(displayText.contains("clicks"))
        #expect(displayText.contains("0.5"))
        #expect(displayText.contains("mg"))
    }
}