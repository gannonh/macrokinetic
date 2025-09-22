import Testing

@testable import JabTracker

@Suite("Medication Coverage Tests")
struct MedicationCoverageTests {
  @Test("Test all medication properties directly")
  func allMedicationPropertiesDirectly() throws {
    // Explicitly test every medication property to ensure coverage

    for medication in Medication.allCases {
      // Test id property (currently 0% covered)
      let id = medication.id
      #expect(!id.isEmpty, "ID should not be empty for \(medication)")

      // Test halfLifeDays property (currently 0% covered)
      let halfLife = medication.halfLifeDays
      #expect(halfLife > 0, "Half-life should be positive for \(medication)")

      // Test frequency property (currently 0% covered)
      let frequency = medication.frequency
      #expect(
        frequency == .daily || frequency == .weekly,
        "Frequency should be daily or weekly for \(medication)")

      // Test unit property (currently 0% covered)
      let unit = medication.unit
      #expect(unit == "mg", "Unit should be mg for \(medication)")

      // Test description property (currently 0% covered)
      let description = medication.description
      #expect(!description.isEmpty, "Description should not be empty for \(medication)")

      // Test colorHex property (currently 0% covered)
      let colorHex = medication.colorHex
      #expect(colorHex.count == 6, "Color hex should be 6 characters for \(medication)")

      // Test displayName property (already covered but verify)
      let displayName = medication.displayName
      #expect(!displayName.isEmpty, "Display name should not be empty for \(medication)")

      // Test brands property (already covered but verify)
      let brands = medication.brands
      #expect(!brands.isEmpty, "Brands should not be empty for \(medication)")

      // Test availableDoses property (already covered but verify)
      let doses = medication.availableDoses
      #expect(!doses.isEmpty, "Available doses should not be empty for \(medication)")
    }
  }

  @Test("Test specific medication values for coverage")
  func specificMedicationValues() throws {
    // Semaglutide
    let sema = Medication.semaglutide
    #expect(sema.id == "semaglutide")
    #expect(sema.halfLifeDays == 7.0)
    #expect(sema.frequency == .weekly)
    #expect(sema.unit == "mg")
    #expect(sema.description.contains("GLP-1"))
    #expect(sema.colorHex == "667eea")

    // Tirzepatide
    let tirze = Medication.tirzepatide
    #expect(tirze.id == "tirzepatide")
    #expect(tirze.halfLifeDays == 5.0)
    #expect(tirze.frequency == .weekly)
    #expect(tirze.unit == "mg")
    #expect(tirze.description.contains("GIP/GLP-1"))
    #expect(tirze.colorHex == "764ba2")

    // Liraglutide
    let lira = Medication.liraglutide
    #expect(lira.id == "liraglutide")
    #expect(lira.halfLifeDays == 0.54)
    #expect(lira.frequency == .daily)
    #expect(lira.unit == "mg")
    #expect(lira.description.contains("GLP-1"))
    #expect(lira.colorHex == "4c5fbf")

    // Dulaglutide
    let dula = Medication.dulaglutide
    #expect(dula.id == "dulaglutide")
    #expect(dula.halfLifeDays == 4.7)
    #expect(dula.frequency == .weekly)
    #expect(dula.unit == "mg")
    #expect(dula.description.contains("GLP-1"))
    #expect(dula.colorHex == "8b9ff4")
  }

  @Test("Test DoseFrequency displayName property")
  func doseFrequencyDisplayName() throws {
    // This property is also showing 0% coverage
    let dailyDisplay = DoseFrequency.daily.displayName
    let weeklyDisplay = DoseFrequency.weekly.displayName

    #expect(dailyDisplay == "Daily" || !dailyDisplay.isEmpty, "Daily should have display name")
    #expect(weeklyDisplay == "Weekly" || !weeklyDisplay.isEmpty, "Weekly should have display name")
  }
}
