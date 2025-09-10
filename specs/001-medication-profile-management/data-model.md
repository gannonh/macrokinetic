# Data Model: Medication Profile Management

**Date**: 2025-09-05  
**Feature**: Medication Profile Management

## Core Entities

### 1. Medication (Enum)

**Purpose**: Represents the four supported GLP-1 medication types with medical properties

```swift
enum Medication: String, CaseIterable, Codable {
    case semaglutide
    case tirzepatide 
    case liraglutide
    case dulaglutide
    
    // Medical Properties
    var halfLifeDays: Double { /* 7.0, 5.0, 0.54, 4.7 */ }
    var availableDoses: [Double] { /* medication-specific dose arrays */ }
    var frequency: DoseFrequency { /* .daily for liraglutide, .weekly for others */ }
    var brandNames: [String] { /* brand name arrays */ }
    var penClickRatio: Double? { /* clicks per mg for branded pens */ }
}

enum DoseFrequency: String, Codable {
    case daily
    case weekly
}
```

**Validation Rules**:
- Must be one of the four supported medication types
- Medical properties are immutable (computed properties)
- Brand names map correctly to generic types

### 2. Enhanced MedicationProfile (SwiftData Model)

**Purpose**: User-specific medication configuration with compounding and pen settings

```swift
@Model
final class MedicationProfile {
    // Existing fields (preserved)
    var id: UUID = UUID()
    var genericName: String = ""
    var brandName: String = ""
    var currentDose: Double = 0.0
    var startDate: Date = Date()
    var refillDate: Date? = nil
    var createdAt: Date = Date()
    
    // New fields for enhanced functionality
    var medicationType: Medication? = nil  // Links to enum
    var isCompounded: Bool = false         // Compounded vs branded
    var vialStrength: Double? = nil        // For compounded: mg in vial
    var reconstitutionVolume: Double? = nil // For compounded: ml to add
    var penType: String? = nil             // For branded: specific pen model
    var notes: String = ""                 // User notes
    var updatedAt: Date = Date()           // Track modifications
    
    // Relationships (existing)
    @Relationship(inverse: \User.medicationProfiles) 
    var user: User? = nil
    
    @Relationship(deleteRule: .cascade, inverse: \Dose.medicationProfile) 
    var doses: [Dose] = []
    
    @Relationship(deleteRule: .cascade, inverse: \DoseEscalation.medicationProfile)
    var escalations: [DoseEscalation] = []
}
```

**Validation Rules**:
- `medicationType` must be valid Medication enum value
- `currentDose` must be within `medicationType.availableDoses` range
- For compounded (`isCompounded = true`): `vialStrength` and `reconstitutionVolume` required
- For branded (`isCompounded = false`): `penType` should be provided if available
- `vialStrength` must be ≥ `currentDose` for compounded medications

**State Transitions**:
- Created → Active (when all required fields populated)
- Active → Modified (when dose or settings change) 
- Active → Archived (when user switches medications)

### 3. Enhanced DoseEscalation (SwiftData Model)

**Purpose**: Tracks planned dose increases with validation against medication limits

```swift
@Model 
final class DoseEscalation {
    var id: UUID = UUID()
    var targetDose: Double = 0.0
    var scheduledDate: Date = Date()
    var completed: Bool = false
    var completedDate: Date? = nil
    var notes: String = ""
    var createdAt: Date = Date()
    
    @Relationship(inverse: \MedicationProfile.escalations)
    var medicationProfile: MedicationProfile? = nil
}
```

**Validation Rules**:
- `targetDose` must be within medication's available dose range
- `scheduledDate` must be in the future for new escalations
- Cannot exceed maximum dose for medication type

## Calculation Models

### 4. ReconstitutionResult (Value Type)

**Purpose**: Represents calculated reconstitution instructions

```swift
struct ReconstitutionResult {
    let waterVolume: Double      // ml to add
    let unitsPerDose: Double     // units to inject for target dose
    let concentration: Double    // mg per ml after reconstitution
    let totalUnits: Double      // total units in reconstituted vial
    
    var displayText: String {
        "Add \(waterVolume.formatted()) ml water. Your dose is \(unitsPerDose.formatted()) units"
    }
}
```

### 5. PenClickResult (Value Type)

**Purpose**: Represents pen click calculations for dose adjustments

```swift
struct PenClickResult {
    let clicks: Int             // number of clicks to dial
    let actualDose: Double      // actual dose delivered (may differ slightly)
    let penType: String         // pen model used for calculation
    
    var displayText: String {
        "Dial to \(clicks) clicks for your \(actualDose.formatted()) mg dose"
    }
}
```

## Data Relationships

```
User (1) ←→ (many) MedicationProfile
MedicationProfile (1) ←→ (many) Dose  
MedicationProfile (1) ←→ (many) DoseEscalation
MedicationProfile (1) → (1) Medication (enum reference)
```

## CloudKit Schema Changes

### New Fields for MedicationProfile:
- `medicationType` (String) - stores enum rawValue
- `isCompounded` (Bool)
- `vialStrength` (Double, optional)
- `reconstitutionVolume` (Double, optional)  
- `penType` (String, optional)
- `notes` (String)
- `updatedAt` (Date)

### Migration Strategy:
- Existing MedicationProfile records preserved
- New fields added with default values
- CloudKit schema evolution handles additions gracefully
- No data loss for existing users

## Validation Implementation

### Input Validation:
1. **Medication Selection**: Must be one of 4 supported types
2. **Dose Validation**: Current dose within medication's available range
3. **Compounded Validation**: Vial strength ≥ target dose
4. **Escalation Validation**: Target dose ≤ medication maximum

### Business Rules:
1. User can have multiple medication profiles (historical tracking)
2. Only one profile can be "active" at a time
3. Dose escalations must follow medical progression (gradual increases)
4. Compounded and branded settings are mutually exclusive

## Performance Considerations

### Indexing:
- Index on `medicationType` for filtering
- Index on `user` relationship for user-specific queries
- Index on `createdAt` for chronological ordering

### Memory Usage:
- Lazy loading for related entities (doses, escalations)
- Computed properties for medication constants (not stored)
- Efficient string storage for notes and pen types

**Status**: Data model design complete, ready for contract generation