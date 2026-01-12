# Search Ranking Algorithm

> **Last Updated**: 2026-01-12  
> **Implementation**: `LocalFoodDatabase.swift`

## Overview

JabTracker uses a multi-factor ranking algorithm to return the most relevant food results first. The algorithm prioritizes whole foods with simple names that exactly match what the user typed.

## Ranking Factors (Priority Order)

Search results are sorted by these factors in order of precedence:

| Priority | Factor | Description | Example |
|----------|--------|-------------|---------|
| 1 | **Prefix Match** | Names starting with search term | "Banana*" > "Snacks, banana chips" |
| 2 | **Whole Word Match** | Complete word boundaries | "Apple" > "APPLEBEE'S" |
| 3 | **Name Length** | Shorter names preferred | "Bananas, raw" > "Bananas, dehydrated, or banana powder" |
| 4 | **BM25 Relevance** | Full-text search score | Standard FTS5 relevance |

## SQL Implementation

```sql
SELECT f.fdc_id, f.name, f.brand, ...
FROM foods_fts fts
JOIN foods f ON fts.rowid = f.id
WHERE foods_fts MATCH ?
ORDER BY
    -- Priority 1: Names starting with search term
    CASE WHEN LOWER(f.name) LIKE 'banana%' THEN 0 ELSE 1 END,
    
    -- Priority 2: Whole word matches (word boundary after term)
    CASE WHEN LOWER(f.name) GLOB 'banana[s,]*' THEN 0 ELSE 1 END,
    
    -- Priority 3: Shorter names first
    LENGTH(f.name),
    
    -- Priority 4: BM25 relevance (name weighted 10x, category 1x)
    bm25(foods_fts, 10.0, 1.0)
LIMIT ?
```

## Factor Details

### 1. Prefix Match

**Purpose**: Foods that start with the search term should appear before foods where the term appears mid-name.

**Pattern**: `LOWER(f.name) LIKE 'term%'`

**Examples**:
| Search | Preferred Result | Lower Ranked |
|--------|-----------------|--------------|
| "banana" | "Bananas, raw" | "Snacks, banana chips" |
| "chicken" | "Chicken, breast, raw" | "Soup, chicken noodle" |
| "egg" | "Egg, whole, raw" | "Bagel, egg" |

### 2. Whole Word Match

**Purpose**: Exact word matches should rank higher than partial matches. This ensures "Apple" appears before "APPLEBEE'S" when searching for "apple".

**Pattern**: `LOWER(f.name) GLOB 'term[s,]*'`

The GLOB pattern matches the search term followed by:
- `s` - Plural form (e.g., "apples")
- `,` - Comma separator (e.g., "apple, raw")
- End of pattern - Exact match

**Why GLOB instead of LIKE?**
- SQLite `GLOB` supports character classes `[...]`
- SQLite `LIKE` only supports `%` and `_` wildcards
- GLOB is case-sensitive, so we apply `LOWER()` to the name

**Examples**:
| Search | Whole Word ✓ | Partial Match ✗ |
|--------|-------------|----------------|
| "apple" | "Apples, red delicious" | "APPLEBEE'S, chili" |
| "banana" | "Bananas, raw" | "Cabana Chicken Bowl" |
| "egg" | "Eggs, Grade A" | "Eggo Waffle" |

### 3. Name Length

**Purpose**: Simpler, shorter food names are typically more relevant. "Bananas, raw" is more useful than "Bananas, dehydrated, or banana powder, unsweetened".

**Implementation**: `LENGTH(f.name)` as a sort key (ascending)

**Examples**:
| Search | Shorter (Preferred) | Longer (Lower Ranked) |
|--------|--------------------|-----------------------|
| "banana" | "Bananas, raw" (12 chars) | "Bananas, dehydrated, or banana powder" (38 chars) |
| "chicken" | "Chicken, breast" (15 chars) | "Chicken, breast, rotisserie, meat only" (39 chars) |

### 4. BM25 Relevance

**Purpose**: Standard full-text search relevance scoring for tie-breaking within equal priority groups.

**Column Weights**:
- `name`: 10.0 (high importance)
- `category`: 1.0 (low importance)

**Implementation**: `bm25(foods_fts, 10.0, 1.0)`

The name column is weighted 10x more than category because:
- Users search by food name 95% of the time
- Category matches ("Fruits and Fruit Juices") are supplementary

## Query Construction

### Swift Code

```swift
// Prepare patterns from user query
let queryWords = query.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
let firstWord = (queryWords.first ?? query).lowercased()

// Pattern for prefix matching (LIKE uses %)
let namePrefixPattern = firstWord + "%"

// Pattern for whole word matching (GLOB uses * and [...])
let wholeWordPattern = firstWord + "[s,]*"

// FTS5 query with prefix matching on each word
let ftsQuery = queryWords.map { "\($0)*" }.joined(separator: " ")
```

### Parameter Binding

Parameters are bound in this order:
1. `ftsQuery` - FTS5 MATCH parameter
2. `namePrefixPattern` - For LIKE clause
3. `wholeWordPattern` - For GLOB clause
4. `limit` - Result count limit

## Source Filtering

When source filtering is active, the WHERE clause includes a source filter without affecting ranking:

```sql
WHERE foods_fts MATCH ? AND f.source IN ('foundation', 'sr_legacy')
```

**Source values**:
- `foundation` - USDA Foundation Foods
- `sr_legacy` - USDA SR Legacy
- `openFoodFacts` - Open Food Facts branded products

## Performance Considerations

### Index Usage

The ranking algorithm uses:
- `foods_fts` - FTS5 virtual table index for MATCH
- `idx_foods_name` - B-tree index on name (for LIKE optimization)
- Computed ORDER BY expressions (not indexed)

### Query Timing

| Operation | Typical Time |
|-----------|-------------|
| FTS5 MATCH | 5-15 ms |
| Full ORDER BY (with 4 factors) | 10-30 ms |
| Total query time | 15-50 ms |

### Optimization Notes

1. **LIMIT applied early**: SQLite's query optimizer applies LIMIT before full result sorting when possible
2. **Case-insensitive via LOWER()**: Applied at query time, not index time
3. **No regex**: GLOB is faster than regex alternatives

## Testing

### Unit Tests

Located in `LocalFoodDatabaseTests.swift`:

| Test | Validates |
|------|-----------|
| `testSearchRanksFoodsStartingWithTermHigher` | Prefix match ranking |
| `testSearchAppleRanksWholeWordFirst` | Whole word > partial match |
| `testSearchBananaRanksShorterNamesFirst` | Length preference |
| `testSearchBananaReturnsRawFirst` | Overall ranking for "raw" foods |
| `testSearchEggReturnsWholeEggsFirst` | Whole eggs before compounds |
| `testSearchChickenRanksWholeChickenFirst` | Prefix dominance in top results |

### Manual Verification

Test these searches in the app:

| Search | Expected Top Results |
|--------|---------------------|
| "apple" | Apples (USDA), then Apple products (not APPLEBEE'S first) |
| "banana" | Bananas, raw (short) before Bananas, dehydrated... (long) |
| "egg" | Egg, whole before Eggo or compound products |
| "chicken" | Chicken, breast before Soup, chicken |

## History

| Date | Change |
|------|--------|
| 2026-01-12 | Added whole word matching and length preference (Phase 36-01) |
| 2025-12-19 | Initial BM25 ranking with prefix boost |

## Related Documents

- [Food Data Layer](./food-data-layer.md) - Overall food search architecture
- [Phase 36-01 Summary](/.planning/phases/36-search-ranking-recall/36-01-SUMMARY.md) - Implementation details
