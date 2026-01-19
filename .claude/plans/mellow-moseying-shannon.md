# Plan: Fix Expenditure Detail View Issues

## Summary
Two issues in the Expenditure detail view:
1. ✅ Strategy status mismatch between header and history list (already fixed)
2. Graph spike from bad historical TDEE data (add automatic outlier cleanup)

---

## Issue 1: Strategy Status Mismatch ✅ FIXED

**Problem**: Header shows "Updating" but history list shows "Holding" for all entries

**Root Cause**: `generateHistoricalEntries()` in `ExpenditureDetailViewModel.swift:335-347` hardcoded `.holding` status instead of using actual snapshot data

**Status**: Already fixed earlier in this session - the function now uses actual `dailyData` from snapshots

---

## Issue 2: Graph Spike from Bad Historical Data

**Problem**: Expenditure graph shows ~2,600+ kcal spike throwing off Y-axis scale

**Root Cause**: A `TDEESnapshot` was saved with an incorrect value when a previous bug existed. The current TDEE algorithms are working correctly - this is just stale bad data.

**Solution**: Add automatic outlier detection and cleanup on app startup

### Implementation

#### Step 1: Add outlier cleanup method
**File**: `JabTracker/Services/TDEEService.swift`

```swift
/// Remove TDEE snapshots that are statistical outliers (>20% from median)
/// - Returns: Count of deleted snapshots
func cleanupOutlierSnapshots() throws -> Int
```

Logic:
1. Fetch all TDEESnapshots sorted by date
2. If fewer than 5 snapshots, skip (not enough data to determine outliers)
3. Calculate median TDEE value
4. Delete snapshots where `abs(value - median) / median > 0.20`
5. Log deletions for debugging
6. Return count of deleted

#### Step 2: Call cleanup on app startup
**File**: `JabTracker/AuthenticationManager.swift`

Call `cleanupOutlierSnapshots()` after user authentication completes

---

## Files to Modify

| File | Change |
|------|--------|
| `JabTracker/Services/TDEEService.swift` | Add `cleanupOutlierSnapshots()` method |
| `JabTracker/AuthenticationManager.swift` | Call cleanup after authentication |

---

## Verification

1. Build and run the app
2. Open Expenditure detail view
3. Confirm spike is gone from the graph
4. Confirm historical entries show correct status values
5. Check console logs for cleanup message
