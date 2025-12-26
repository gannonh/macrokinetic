# Phase 10-04: Feature Settings (Body Metrics & Units)

**Captured:** 2025-12-25
**Status:** Pending (after 10-02, 10-03)

## Overview

Add "Feature Settings" section to MoreView with:
1. Body Metrics Visibility - toggles to show/hide metrics in Dashboard and editors
2. Units of Measure - configure display units

## Body Metrics Visibility Screen

**Title:** "Body Metrics Visibility"

**Description text:**
> Toggling a body metric will control its visibility in your Dashboard and editors without deleting any existing data. When hidden, you won't see this metric going forward, but your historical data will remain unaffected. You can always come back and toggle the metric back on.

### Sections & Metrics

**Weight & Body Fat**
- Scale Weight (Default label, not toggle)
- Visual Body Fat (Default label, not toggle)

**Progress Photos**
- Front Photo (Toggle)
- Side Photo (Toggle)
- Back Photo (Toggle)

**Upper Body**
- Neck (Toggle)
- Shoulders (Toggle)
- Bust (Toggle)
- Chest (Toggle)
- Waist (Toggle - ON by default)
- Hips (Toggle)

**Arms**
- Left Bicep (Toggle)
- Right Bicep (Toggle)
- Left Forearm (Toggle)
- Right Forearm (Toggle)
- Left Wrist (Toggle)
- Right Wrist (Toggle)

**Legs**
- Left Thigh (Toggle)
- Right Thigh (Toggle)
- Left Calf (Toggle)
- Right Calf (Toggle)
- Left Ankle (Toggle)
- Right Ankle (Toggle)

**Ratios** (calculated values)
- Waist to Height (Toggle)
- Waist to Hip (Toggle)

### Default States
- Waist: ON (matches current implementation)
- Front Photo: ON
- All others: OFF

## Units of Measure Screen

Configure display units for:
- Weight (kg/lbs)
- Body measurements (cm/in)
- Height (cm/ft-in)

## Implementation Notes

### Model Changes
- Create `MetricsPreferences` or add to `User` model:
  - `enabledMetrics: [String]` or individual Bool properties
  - `enabledPhotoTypes: [String]`
  - Store as JSON or individual fields

### New Views
- `BodyMetricsVisibilityView.swift` - Settings screen matching screenshots
- `UnitsOfMeasureView.swift` - Unit preferences
- Navigation from MoreView → Feature Settings section

### Update Existing
- `QuickMetricsSheet` - Only show enabled metrics
- `MetricsEntry` model - May need to expand for all body parts
- Dashboard - Only display enabled metrics

## Screenshots Reference
See conversation from 2025-12-25 with 4 screenshots showing:
1. Top of screen: Weight & Body Fat, Progress Photos, Upper Body (Neck, Shoulders)
2. Upper Body continued: Bust, Chest, Waist (ON), Hips; Arms section starts
3. Arms: All 6 measurements; Legs section starts
4. Legs: All 6 measurements; Ratios section

## Priority
Medium - enhances user customization but core metrics tracking works without it
