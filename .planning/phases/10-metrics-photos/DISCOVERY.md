# Phase 10: Metrics & Photos - Discovery

**Date:** 2025-12-25
**Depth:** Level 2 (Standard Research)

## Research Summary

### Photo Capture Patterns (Existing in Codebase)

**PhotosUI already implemented** in `DoseEntryPhotoSection.swift`:
- Uses `PhotosPickerItem` from PhotosUI framework
- No explicit permissions needed (user grants per-photo access)
- Pattern: `.photosPicker(isPresented:selection:matching:)` modifier
- Async loading via `loadTransferable(type: Data.self)`
- Stores as `Data?` in SwiftData model

**Key Implementation:**
```swift
import PhotosUI

@Binding var photoData: Data?
@Binding var selectedPhotoItem: PhotosPickerItem?

.photosPicker(isPresented: $showingPicker, selection: $selectedPhotoItem, matching: .images)
.onChange(of: selectedPhotoItem) { _, newItem in
    Task {
        if let data = try? await newItem?.loadTransferable(type: Data.self) {
            photoData = data
        }
    }
}
```

### HealthKit Body Measurements

**Available Types:**
- `.bodyMass` - Already integrated in Phase 9
- `.bodyFatPercentage` - Already integrated in Phase 9
- `.waistCircumference` - Available for sync
- `.height` - Available (but out of scope)

**NOT Available in HealthKit:**
- Hip circumference
- Chest circumference
- Neck circumference
- Other body measurements

**Decision:** Store all measurements locally. Only sync waistCircumference to HealthKit.

### Existing Patterns to Follow

**Model Pattern (WeightEntry):**
- `@Model` with CloudKit-compatible defaults
- Store in standard unit (cm for length, convert to inches for display)
- Optional notes field
- Source field ("manual" or "healthkit")
- Validation helpers with min/max constants

**Service Pattern (WeightService):**
- `@MainActor final class` with ModelContext
- CRUD operations (log, get, update, delete)
- Extension for HealthKit sync
- Error enum with LocalizedError

**UI Pattern (QuickWeightSheet):**
- Form-based entry with sections
- Unit toggle for metric/imperial
- DatePicker for timestamp
- HealthKit sync toggle (when applicable)
- `canSave` computed property for validation

**Shortcuts Integration:**
- ShortcutsSheet has "Metrics" (disabled) and "Photo" (disabled) shortcuts
- Pattern: dismissAndPresent() for sheet transitions
- Binding to trigger new sheets from ContentView

### Architecture Decision

**Approach:** Pragmatic Balance with Minimal New Components

**Progress Photos:**
1. Create `ProgressPhoto` SwiftData model (imageData + timestamp + type + notes)
2. Create `ProgressPhotoService` for CRUD operations
3. Create `ProgressPhotoSheet` using existing DoseEntryPhotoSection pattern
4. Enable "Photo" shortcut in ShortcutsSheet

**Body Metrics:**
1. Create `BodyMetricsEntry` SwiftData model (waist, hip, chest, neck in cm)
2. Create `BodyMetricsService` with HealthKit extension (waist only)
3. Create `QuickMetricsSheet` following QuickWeightSheet pattern
4. Enable "Metrics" shortcut in ShortcutsSheet

**Rationale:**
- Follows established codebase patterns exactly
- Minimal new abstractions
- HealthKit integration only where Apple supports it
- Ships quickly with room for extension

## Unit Conversion Constants

```swift
// Length conversion
static let cmToInchesConversion: Double = 0.393701
static let inchesToCmConversion: Double = 2.54

// Validation ranges (reasonable human body measurements)
static let minWaistCm: Double = 40.0    // ~16 inches
static let maxWaistCm: Double = 200.0   // ~79 inches
static let minHipCm: Double = 50.0      // ~20 inches
static let maxHipCm: Double = 200.0     // ~79 inches
static let minChestCm: Double = 50.0    // ~20 inches
static let maxChestCm: Double = 200.0   // ~79 inches
static let minNeckCm: Double = 20.0     // ~8 inches
static let maxNeckCm: Double = 70.0     // ~28 inches
```

## Photo Type Enum

```swift
enum ProgressPhotoType: String, CaseIterable, Codable {
    case front = "Front"
    case side = "Side"
    case back = "Back"
}
```

## Permissions Already Configured

- `NSCameraUsageDescription` in Info.plist (for barcode, reusable)
- HealthKit entitlement enabled
- PhotosPicker requires no explicit permissions

## Sources

- Apple PhotosUI Documentation
- Apple HealthKit HKQuantityTypeIdentifier Documentation
- Existing codebase: DoseEntryPhotoSection.swift, WeightEntry.swift, WeightService.swift, QuickWeightSheet.swift
