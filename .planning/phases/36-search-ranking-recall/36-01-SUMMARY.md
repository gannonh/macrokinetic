# Phase 36-01: Search Ranking & Recall Summary

**Enhanced FTS5 ranking to favor whole word matches and shorter names for better search UX.**

## Accomplishments

- Added **whole word matching** ranking factor: "Apple" now ranks before "APPLEBEE'S"
- Added **shorter name preference**: "Bananas, raw" now ranks before "Bananas, dehydrated, or banana powder"
- Maintained existing ranking factors: prefix matching, BM25 relevance, name column weighting
- Added unit tests for new ranking behaviors

## Files Created/Modified

- `JabTracker/Services/LocalFoodDatabase.swift` - Enhanced ORDER BY with 4-factor ranking:
  1. Prefix match (names starting with search term)
  2. Whole word match (GLOB pattern for word boundaries)
  3. Name length (shorter names first)
  4. BM25 relevance score
- `JabTrackerTests/Services/LocalFoodDatabaseTests.swift` - Added 2 new ranking tests:
  - `testSearchAppleRanksWholeWordFirst` - Verifies Apple > APPLEBEE'S
  - `testSearchBananaRanksShorterNamesFirst` - Verifies shorter names rank higher

## Technical Details

The ORDER BY clause now uses:
```sql
ORDER BY
    CASE WHEN LOWER(f.name) LIKE ? THEN 0 ELSE 1 END,  -- Prefix match
    CASE WHEN LOWER(f.name) GLOB ? THEN 0 ELSE 1 END,  -- Whole word match
    LENGTH(f.name),                                      -- Shorter names first
    bm25(foods_fts, 10.0, 1.0)                          -- BM25 relevance
```

The whole word pattern uses SQLite GLOB with `[s,]*` to match words followed by:
- `s` (plurals like "apples")
- `,` (comma separator in food names)
- End of pattern

## Decisions Made

- Used GLOB instead of LIKE for whole word matching because GLOB supports character classes
- Added LENGTH() as a tiebreaker rather than a primary ranking factor to avoid over-penalizing descriptive but relevant entries

## Issues Encountered

None - straightforward SQL ORDER BY enhancement.

## Next Phase Readiness

Ready for Phase 37: Unit/Serving Strategy
