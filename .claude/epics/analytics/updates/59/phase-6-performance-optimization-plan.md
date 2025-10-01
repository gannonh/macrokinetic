# Chart Performance Optimization: Persistent Caching + Filter-Only Architecture

**Issue**: #59 - Analytics Orchestration & Polish
**Phase**: 6 - State & Performance Optimization
**Date**: 2025-10-01
**Status**: Implementation Plan

---

## Problem Statement

Charts regenerate all 31,676 concentration points on EVERY time period change:
- **30d switch**: 750ms
- **90d switch**: 6-7 seconds
- **1y switch**: 80 seconds
- **Zero caching** - even after app restart
- **Poor UX** - no loading indicators, abrupt switches

### Root Cause Analysis

Current architecture regenerates entire concentration timeline on every time period change:
```swift
// Current (SLOW) approach
func selectTimePeriod(_ period: TimeRange) {
    // ❌ Regenerates ALL points with PK calculations
    chartDataset = generateChartDataset(for: user, timePeriod: period)
}
```

**Performance Data (52 doses, 1 year):**
```
7d:  64ms     (1 dose,  477 points)    ✅ Acceptable
30d: 750ms    (4 doses, 2,346 points)  ✅ Acceptable
90d: 6.2s     (12 doses, 7,335 points) ⚠️  Too slow
1y:  80s      (52 doses, 31,676 points) ❌ Unacceptable
```

**Key Insight**: Dose fetching is fast (5-30ms). Chart generation is the bottleneck.

---

## Solution Architecture (Inspired by MacroFactor)

### The MacroFactor Pattern

Professional apps like MacroFactor achieve instant chart switching through:

1. **Generate full dataset ONCE** - compute all concentration points
2. **Save to disk permanently** - cache survives app restarts
3. **Filter in memory** - time period changes just filter arrays (<10ms)
4. **Incremental updates** - background updates when new dose added

### Key Architectural Change

```swift
// NEW (FAST) approach
func selectTimePeriod(_ period: TimeRange) {
    // ✅ INSTANT - just filter existing array
    chartDataset = fullChartDataset.filtered(to: period)
}
```

**Benefits:**
- ✅ First load: Slow (80s) - BUT ONLY HAPPENS ONCE EVER
- ✅ Subsequent switches: <10ms (array filtering)
- ✅ After app restart: 10ms (load from cache)
- ✅ Smooth animations: SwiftUI can animate because it's instant

---

## Implementation Plan

### Phase 1: Client-Side Filtering (Immediate Win)
**Goal**: Make time period switching instant by filtering pre-computed data
**Time Estimate**: 30 minutes

#### Step 1.1: Add filtering method to ConcentrationChartDataset
**File**: `JabTracker/Models/ChartData.swift`

Add filtering capability:
```swift
extension ConcentrationChartDataset {
    /// Filter dataset to specific time range (instant - no regeneration)
    func filtered(to timeRange: TimeRange) -> ConcentrationChartDataset {
        let cutoffDate = timeRange.startDate(from: Date())

        // Filter concentration points
        let filteredPoints = concentrationPoints.filter { $0.date >= cutoffDate }

        // Filter dose markers
        let filteredMarkers = doseMarkers.filter { $0.date >= cutoffDate }

        // Create new dataset with same config, filtered data
        var newConfig = configuration
        newConfig.timeRange = timeRange

        return ConcentrationChartDataset(
            concentrationPoints: filteredPoints,
            doseMarkers: filteredMarkers,
            configuration: newConfig
        )
    }
}
```

#### Step 1.2: Generate full dataset once in AnalyticsView
**File**: `JabTracker/Views/Analytics/AnalyticsView.swift`

Change generation strategy:
```swift
// Generate FULL dataset once (all time)
private func refreshChartDataset() {
    // ...

    // Generate for ALL time (not just selected period)
    let dataset = chartDatasetService.generateChartDataset(
        for: user,
        profilesWithDoses: profilesWithDoses,
        timePeriod: .all  // ← Generate full dataset
    )

    // Store full dataset
    fullChartDataset = dataset

    // Filter for display
    chartDataset = dataset.filtered(to: selectedTimePeriod)
}

// Time period changes just filter
func selectTimePeriod(_ period: TimeRange) {
    guard let full = fullChartDataset else { return }

    // INSTANT - just filter array
    chartDataset = full.filtered(to: period)
}
```

#### Step 1.3: Update ConcentrationTimelineChart
**File**: `JabTracker/Views/Analytics/ConcentrationTimelineChart.swift`

Remove internal filtering (trust filtered input):
```swift
// Remove processedConcentrationPoints filtering
// Chart now displays exactly what it receives
var body: some View {
    Chart {
        ForEach(dataset.concentrationPoints) { point in
            // Display all points (already filtered)
        }
    }
}
```

**Expected Result**: Time period switching becomes <10ms instead of 0.75-80 seconds

---

### Phase 2: Persistent Disk Caching (Never Wait Again)
**Goal**: Cache chart dataset to disk so it's instant even after app restart
**Time Estimate**: 1-2 hours

#### Step 2.1: Create ChartDatasetCache service
**File**: `JabTracker/Services/ChartDatasetCache.swift` (NEW)

Implement persistent caching:
```swift
import Foundation

/// Persistent cache for chart datasets (survives app restarts)
@Observable
class ChartDatasetCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = docs.appendingPathComponent("ChartCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Load cached dataset (instant - ~10ms)
    func loadCached(userId: UUID, profileId: UUID) -> ConcentrationChartDataset? {
        let fileURL = cacheURL(userId: userId, profileId: profileId)

        guard let data = try? Data(contentsOf: fileURL),
              let cached = try? JSONDecoder().decode(CachedDataset.self, from: data) else {
            return nil
        }

        // Verify cache is still valid
        if cached.isStale(currentLastDose: getCurrentLastDose(profileId)) {
            return nil  // Needs regeneration
        }

        return cached.dataset
    }

    /// Save to disk for future launches (permanent)
    func saveToDisk(_ dataset: ConcentrationChartDataset, userId: UUID, profileId: UUID, lastDose: Date) {
        let fileURL = cacheURL(userId: userId, profileId: profileId)
        let cached = CachedDataset(
            dataset: dataset,
            lastDoseTimestamp: lastDose,
            version: 1
        )

        if let data = try? JSONEncoder().encode(cached) {
            try? data.write(to: fileURL)
        }
    }

    private func cacheURL(userId: UUID, profileId: UUID) -> URL {
        cacheDirectory.appendingPathComponent("\(userId)_\(profileId)_full.json")
    }
}

struct CachedDataset: Codable {
    let dataset: ConcentrationChartDataset
    let lastDoseTimestamp: Date
    let version: Int

    func isStale(currentLastDose: Date?) -> Bool {
        guard let current = currentLastDose else { return true }
        return lastDoseTimestamp != current
    }
}
```

#### Step 2.2: Make ConcentrationChartDataset Codable
**File**: `JabTracker/Models/ChartData.swift`

Add Codable conformance:
```swift
struct ConcentrationChartDataset: Codable, Identifiable {
    // ... existing properties
}

struct ConcentrationPoint: Codable, Identifiable {
    // ... existing properties
}

struct DoseMarker: Codable, Identifiable {
    // ... existing properties
}

// Ensure all nested types are Codable
```

#### Step 2.3: Integrate cache into AnalyticsView
**File**: `JabTracker/Views/Analytics/AnalyticsView.swift`

Load from cache first:
```swift
@State private var chartCache = ChartDatasetCache()

private func refreshChartDataset() {
    guard let user = currentUser,
          let profile = medicationProfiles.first else { return }

    // Try cache FIRST
    if let cached = chartCache.loadCached(userId: user.id, profileId: profile.id) {
        // ✅ INSTANT - show immediately
        fullChartDataset = cached
        chartDataset = cached.filtered(to: selectedTimePeriod)
        logger.info("📊 Loaded from cache (instant)")
        return
    }

    // Cache miss - generate once
    logger.info("⏳ Generating analytics (first time)...")

    Task.detached {
        // Generate full dataset (slow)
        let dataset = await generateFullDataset()

        // Save for next time
        await chartCache.saveToDisk(
            dataset,
            userId: user.id,
            profileId: profile.id,
            lastDose: getLastDoseDate()
        )

        await MainActor.run {
            fullChartDataset = dataset
            chartDataset = dataset.filtered(to: selectedTimePeriod)
            logger.info("✅ Generated and cached")
        }
    }
}
```

**Expected Result**: Analytics instant on every app launch (except very first time)

---

### Phase 3: Background Incremental Updates (Polish)
**Goal**: Update cache in background when dose added, so analytics always instant
**Time Estimate**: 30 minutes

#### Step 3.1: Add incremental update support
**File**: `JabTracker/Services/ChartDatasetCache.swift`

Add background update method:
```swift
extension ChartDatasetCache {
    /// Update cached dataset with new dose (background)
    func updateWithNewDose(_ dose: Dose, userId: UUID, profileId: UUID) async {
        guard let cached = loadCached(userId: userId, profileId: profileId) else {
            return  // No cache to update
        }

        // Add new concentration curve for this dose
        let newPoints = calculateConcentrationCurve(for: dose)
        let updatedDataset = cached.merging(newPoints: newPoints)

        // Save back to disk
        saveToDisk(updatedDataset, userId: userId, profileId: profileId, lastDose: dose.timestamp)
    }
}
```

#### Step 3.2: Trigger updates from dose entry
**File**: `JabTracker/Views/Dashboard/QuickDoseSheet.swift` (or dose entry point)

Background cache update:
```swift
func saveDose() {
    // ... save dose to SwiftData

    // Update cache in background (invisible to user)
    Task.detached(priority: .background) {
        await chartCache.updateWithNewDose(
            dose,
            userId: currentUser.id,
            profileId: profile.id
        )
    }
}
```

**Expected Result**: Even after adding doses, analytics remain instant

---

### Phase 4: Optimize Point Density (Future)
**Goal**: Reduce 1y generation from 80s to 10-20s
**Time Estimate**: 1 hour

#### Step 4.1: Reduce interpolation density
**File**: `JabTracker/Services/ChartDataProcessor+Interpolation.swift`

Current density:
- **86 points per day** (31,676 for 1 year)
- Overkill for visual smoothness

Target density:
- **10-20 points per day** (3,650-7,300 for 1 year)
- Still smooth curves, 4-8x faster

Implementation:
```swift
// Adaptive point density
func generateConcentrationCurve(startDate: Date, endDate: Date) -> [ConcentrationPoint] {
    let totalDays = endDate.timeIntervalSince(startDate) / 86400
    let pointsPerDay = min(20, max(10, 100 / totalDays))  // Adaptive

    // Generate with optimal density
}
```

**Expected Result**: First-time generation: 80s → 10-20s

---

## Files to Create

1. **JabTracker/Services/ChartDatasetCache.swift**
   - Persistent caching service
   - Load/save to Documents/ChartCache/
   - Cache validation and staleness checking

## Files to Modify

1. **JabTracker/Models/ChartData.swift**
   - Add `filtered(to:)` method to ConcentrationChartDataset
   - Add Codable conformance to all chart types
   - Add version/timestamp for cache validation

2. **JabTracker/Views/Analytics/AnalyticsView.swift**
   - Generate full dataset (.all time range)
   - Integrate ChartDatasetCache
   - Filter on time period change (instant)
   - Add loading state for first-time generation

3. **JabTracker/Views/Analytics/ConcentrationTimelineChart.swift**
   - Remove internal time range filtering
   - Trust filtered input from AnalyticsView
   - Display points directly

4. **JabTracker/Views/Dashboard/QuickDoseSheet.swift** (Phase 3)
   - Trigger background cache update on dose save

---

## Expected Performance Improvements

### Current State (Before)
| Action | Time | Status |
|--------|------|--------|
| 30d switch | 750ms | ✅ Acceptable |
| 90d switch | 6-7s | ⚠️ Too slow |
| 1y switch | 80s | ❌ Unacceptable |
| After app restart | Same slow times | ❌ No caching |
| Smooth animations | No | ❌ Too slow |

### After Phase 1 (Client-Side Filtering)
| Action | Time | Status |
|--------|------|--------|
| 30d switch | <10ms | ✅ Instant |
| 90d switch | <10ms | ✅ Instant |
| 1y switch | <10ms | ✅ Instant |
| First load | 80s | ⚠️ One time |
| After app restart | 80s again | ⚠️ No persistence |
| Smooth animations | Yes | ✅ Works |

### After Phase 2 (Persistent Cache)
| Action | Time | Status |
|--------|------|--------|
| 30d switch | <10ms | ✅ Instant |
| 90d switch | <10ms | ✅ Instant |
| 1y switch | <10ms | ✅ Instant |
| First load | 80s | ⚠️ ONCE EVER |
| After app restart | 10ms | ✅ From cache |
| Smooth animations | Yes | ✅ Works |

### After Phase 3 (Background Updates)
| Action | Time | Status |
|--------|------|--------|
| New dose added | Background | ✅ Invisible |
| Analytics after dose | 10ms | ✅ Pre-cached |

### After Phase 4 (Optimized Density)
| Action | Time | Status |
|--------|------|--------|
| First-ever load | 10-20s | ✅ Much better |

---

## Implementation Order

1. **Phase 1** (30 min) - Immediate UX win for time period switching
2. **Phase 2** (1-2 hours) - The big win: instant after restart
3. **Phase 3** (30 min) - Polish: background updates
4. **Phase 4** (1 hour) - Optional: reduce first-time wait

**Total Estimated Time**: 3-4 hours for Phases 1-3 (core functionality)

---

## Testing Strategy

### Phase 1 Testing
- [ ] Verify 7d/30d/90d/1y switches are <10ms
- [ ] Confirm smooth animations work
- [ ] Check memory usage with full dataset
- [ ] Test with 1 year of data (52 doses)

### Phase 2 Testing
- [ ] Verify cache saves to disk after first generation
- [ ] Confirm instant load from cache on app restart
- [ ] Test cache invalidation when new dose added
- [ ] Verify cache survives app updates

### Phase 3 Testing
- [ ] Confirm background updates complete invisibly
- [ ] Verify cache updates after dose entry
- [ ] Test analytics remain instant after dose added

### Phase 4 Testing
- [ ] Measure generation time reduction
- [ ] Verify curve smoothness maintained
- [ ] Check visual quality at lower density

---

## Risk Mitigation

### Potential Issues

1. **Cache Corruption**: Implement version checking and graceful fallback
2. **Disk Space**: Monitor cache size (~1-2MB per profile, negligible)
3. **Stale Cache**: Validate against last dose timestamp
4. **Memory Usage**: Full dataset in RAM (~2-3MB, acceptable)

### Fallback Strategy

If cache fails to load:
```swift
if let cached = chartCache.loadCached(...) {
    // Use cache
} else {
    // Regenerate (same as current behavior)
}
```

---

## Success Metrics

### User Experience Goals
- ✅ Time period switches: <10ms (imperceptible)
- ✅ App launch to analytics: <50ms (instant)
- ✅ Smooth animations: 60fps
- ✅ First-time wait: <20s (with Phase 4 optimization)

### Technical Goals
- ✅ Cache hit rate: >99% (after first generation)
- ✅ Memory usage: <5MB for full dataset
- ✅ Disk usage: <2MB per profile cache
- ✅ Background updates: <1s

---

## Future Enhancements (Post-Phase 4)

1. **Multi-Profile Support**: Cache datasets for all user profiles
2. **GPU Acceleration**: Metal framework for curve generation
3. **Progressive Rendering**: Show partial data while computing
4. **Streaming Computation**: Display first 30 days while computing year
5. **Smart Pre-computation**: Generate caches during app idle time
6. **Export Optimization**: Pre-render PDF charts for instant export

---

## References

- **Inspiration**: MacroFactor app (weight trend charts)
- **Performance Data**: Issue #59 Phase 6 console logs
- **Architecture**: Apple's Swift Charts best practices
- **Caching Pattern**: iOS FileManager + Codable
