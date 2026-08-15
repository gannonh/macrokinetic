---
created: 2025-12-19T21:32:45Z
updated: 2026-01-13T00:00:00Z
---

# Food Data Layer

## Overview

The food data layer provides fast, reliable food search using a comprehensive local database containing both USDA whole foods and Open Food Facts branded products. This local-first architecture eliminates rate limiting issues and enables fully offline search for 1.7M+ foods.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         FoodSearchView                          │
│                    (User Interface Layer)                       │
├─────────────────────────────────────────────────────────────────┤
│  • Search bar with 500ms debounce                               │
│  • Minimum 2 characters before search                           │
│  • Source indicators (leaf=local, barcode=packaged)             │
│  • Recent searches section                                      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                         FoodService                             │
│                    (Orchestration Layer)                        │
├─────────────────────────────────────────────────────────────────┤
│  • Searches local database (1.7M+ foods)                        │
│  • Merges and deduplicates results                              │
│  • Manages SwiftData cache                                      │
│  • Tracks recent food access                                    │
└───────────┬─────────────────────────────────┬───────────────────┘
            │                                 │
            ▼                                 ▼
┌───────────────────────────────────────────────────────────────────┐
│                       LocalFoodDatabase                           │
│                       (Local Data Layer)                          │
├───────────────────────────────────────────────────────────────────┤
│  • SQLite + FTS5 full-text search                                 │
│  • 1,731,053 foods (8K USDA + 1.7M Open Food Facts)               │
│  • ~10-50ms queries                                               │
│  • Fully offline capable                                          │
│  • Database size: ~322 MB                                         │
└───────────────────────────────────────────────────────────────────┘
                                │
                                ▼ (fallback for barcode lookup)
┌───────────────────────────────────────────────────────────────────┐
│                     OpenFoodFactsService                          │
│                     (Network Fallback)                            │
├───────────────────────────────────────────────────────────────────┤
│  • REST API client for barcode lookup                             │
│  • Used when local search finds no matches                        │
│  • 30s timeout to handle slow responses                           │
└───────────────────────────────────────────────────────────────────┘
```

## Database Maintenance

### Update Script

The local food database can be updated using the automated script:

```bash
./scripts/update-food-database.sh
```

### Script Options

| Option               | Description                                        |
| -------------------- | -------------------------------------------------- |
| (none)               | Full rebuild: downloads USDA + OFF, processes both |
| `--skip-download`    | Skip all downloads, rebuild from existing data     |
| `--skip-off-download`| Download USDA only, use existing OFF data          |
| `--usda-only`        | Only process USDA data, skip OFF entirely          |
| `--us-only`          | Only import US products from Open Food Facts       |
| `--verify`           | Only verify the current database                   |
| `--help`             | Show usage information                             |

### Full Update Workflow

For TestFlight releases, use the GitHub Actions workflow documented in
[`docs/operations/testflight-releases.md`](../../operations/testflight-releases.md).
The local commands below are development-only database maintenance commands;
they are not the release or signing path, and the generated SQLite file is
ignored rather than committed.

```bash
# 1. Run the update script (downloads USDA + OFF automatically)
./scripts/update-food-database.sh

# 2. Run full test suite
./scripts/check-all.sh --skip-ui

# 3. Test in simulator
# Build and run app, search for various foods

# 4. Run the app locally and inspect representative searches
```

### Incremental Updates

```bash
# Re-download only USDA, keep existing OFF data
./scripts/update-food-database.sh --skip-off-download

# Rebuild from existing downloaded files (no network)
./scripts/update-food-database.sh --skip-download
```

### What the Script Does

```
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: Download USDA Data                                      │
├─────────────────────────────────────────────────────────────────┤
│   • Downloads Foundation Foods ZIP (~0.5MB)                     │
│   • Downloads SR Legacy ZIP (~13MB)                             │
│   • Saves to scripts/usda_data/                                 │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: Extract Archives                                        │
├─────────────────────────────────────────────────────────────────┤
│   • Extracts Foundation Foods JSON                              │
│   • Extracts SR Legacy JSON                                     │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 3: Verify Data Files                                       │
├─────────────────────────────────────────────────────────────────┤
│   • Confirms JSON files exist                                   │
│   • Reports file locations                                      │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 4: Process USDA Data                                       │
├─────────────────────────────────────────────────────────────────┤
│   • Runs process_usda_data.py                                   │
│   • Parses both JSON files                                      │
│   • Extracts nutrients (protein, carbs, fat, fiber, calories)   │
│   • Calculates missing calories from macros                     │
│   • Creates SQLite database with FTS5 index                     │
│   • Outputs to JabTracker/Resources/usda_foods.sqlite           │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 5: Download & Process Open Food Facts Data                 │
├─────────────────────────────────────────────────────────────────┤
│   • Downloads OFF CSV (~2GB) from static.openfoodfacts.org      │
│   • Skips download if --skip-download or --skip-off-download    │
│   • Runs process-off-data.py                                    │
│   • Streams 4M+ products from CSV                               │
│   • Filters for products with valid nutrition data              │
│   • Adds ~1.7M branded foods to database                        │
│   • Rebuilds FTS5 index                                         │
│   • Skipped entirely if --usda-only                             │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 6: Verify Output                                           │
├─────────────────────────────────────────────────────────────────┤
│   • Counts foods by source (USDA, OFF)                          │
│   • Reports database file size (~322 MB with OFF)               │
│   • Runs sample queries for both USDA and OFF foods             │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 7: Run Tests                                               │
├─────────────────────────────────────────────────────────────────┤
│   • Runs LocalFoodDatabaseTests                                 │
│   • Verifies search functionality                               │
│   • Reports pass/fail status                                    │
└─────────────────────────────────────────────────────────────────┘
```

### Verify Only Mode

Quick check of the current database without rebuilding:

```bash
./scripts/update-food-database.sh --verify
```

Output:
```
============================================
Verifying Food Database
============================================
→ Checking database integrity...
ok
→ Counting foods by source...
  USDA foods:           8080
  Open Food Facts:      1722973
  Total foods:          1731053
→ Checking FTS5 index...
  FTS5 entries:         1731053
→ Sample search test...
  'chicken' results:
    Chicken, broilers or fryers, drumstick, meat only (foundation)
    Chicken, ground, with additives, raw (sr_legacy)
  'oreo' results:
    Oreo Cookies (openFoodFacts)
    Double Stuf Oreo (openFoodFacts)
→ Database file size...
  Size: 322M
✓ Database verification passed (1731053 foods)
```

### Data Source Update Frequency

| Dataset          | Update Frequency     | URL                                                                  |
| ---------------- | -------------------- | -------------------------------------------------------------------- |
| Foundation Foods | Quarterly (~4x/year) | [fdc.nal.usda.gov](https://fdc.nal.usda.gov/download-datasets.html)  |
| SR Legacy        | Static (2018)        | [fdc.nal.usda.gov](https://fdc.nal.usda.gov/download-datasets.html)  |
| Open Food Facts  | Weekly               | [world.openfoodfacts.org/data](https://world.openfoodfacts.org/data) |

### Open Food Facts Data

The OFF CSV data (~2GB) is automatically downloaded when running the update script without flags. The download URL is:

```
https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz
```

The CSV contains 4M+ products. Processing filters for products with valid nutrition data, resulting in ~1.7M foods added to the database.

To skip re-downloading OFF data (use existing file):
```bash
./scripts/update-food-database.sh --skip-off-download
```

### When to Update

| Trigger                   | Action                                   |
| ------------------------- | ---------------------------------------- |
| Quarterly USDA release    | Run full update                          |
| Before major app release  | Run full update                          |
| User reports missing food | Check if food exists in latest USDA data |
| Database corruption       | Run `--skip-download` to rebuild         |

### Updating Download URLs

When USDA releases new data, update the URLs in `scripts/update-food-database.sh`:

```bash
# Find the latest URLs at https://fdc.nal.usda.gov/download-datasets.html
# Then update these lines in the script:

FOUNDATION_URL="https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_foundation_food_json_YYYY-MM-DD.zip"
SR_LEGACY_URL="https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_json_2018-04.zip"
```

### Troubleshooting

| Issue                     | Solution                                   |
| ------------------------- | ------------------------------------------ |
| Download fails            | Check USDA website for updated URLs        |
| "JSON not found"          | Verify ZIP extraction completed            |
| Fewer foods than expected | Check USDA data format hasn't changed      |
| Tests fail                | Review test output, may need schema update |
| Database too large        | Check for duplicate entries in processing  |

### Directory Structure

```
scripts/
├── update-food-database.sh   # Main update script
├── process_usda_data.py      # USDA JSON processor
├── process-off-data.py       # Open Food Facts CSV processor
├── usda_data/                # USDA data (gitignored)
│   ├── foundation_foods.zip
│   ├── sr_legacy.zip
│   ├── foundation/
│   │   └── foundationDownload.json
│   └── sr_legacy/
│       └── FoodData_Central_sr_legacy_food_json_2018-04.json
└── off_data/                 # Open Food Facts data (gitignored)
    └── en.openfoodfacts.org.products.csv.gz

JabTracker/
└── Resources/
    └── usda_foods.sqlite     # Local generated output; promoted snapshots live in GitHub Releases
```

### Database Schema

```sql
CREATE TABLE foods (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fdc_id INTEGER NOT NULL,
    barcode TEXT DEFAULT '',          -- Product barcode (EAN-13, UPC-A, etc.)
    name TEXT NOT NULL,
    brand TEXT DEFAULT '',
    category TEXT DEFAULT '',
    source TEXT DEFAULT '',           -- 'foundation', 'sr_legacy', 'openFoodFacts'
    calories_per_100g REAL DEFAULT 0,
    protein_per_100g REAL DEFAULT 0,
    carbs_per_100g REAL DEFAULT 0,
    fat_per_100g REAL DEFAULT 0,
    fiber_per_100g REAL DEFAULT 0,
    serving_size REAL DEFAULT 100,
    serving_unit TEXT DEFAULT 'g',
    serving_options TEXT DEFAULT '[]'
);

-- FTS5 full-text search index
CREATE VIRTUAL TABLE foods_fts USING fts5(
    name,
    category,
    content=foods,
    content_rowid=rowid
);

-- Indexes for common queries
CREATE INDEX idx_foods_fdc_id ON foods(fdc_id);
CREATE INDEX idx_foods_barcode ON foods(barcode);  -- Fast barcode lookups
CREATE INDEX idx_foods_name ON foods(name);
CREATE INDEX idx_foods_category ON foods(category);
CREATE INDEX idx_foods_calories ON foods(calories_per_100g);
```

## Reproducible Snapshot Pipeline

Release tooling treats the food database as a verified, immutable artifact rather than a Git or Git LFS file.

- USDA Foundation and SR Legacy inputs are pinned repository configuration; changing a revision or URL is an intentional code review.
- Open Food Facts full CSV ingestion and delta ingestion share `scripts/food_database/normalization.py`.
- OFF identity is the normalized non-empty barcode. Duplicate display names are valid; duplicate OFF barcodes are not.
- Delta filenames are half-open integer intervals. A gap, overlap, malformed payload, missing cursor, or cursor newer than the index selects a full rebuild.
- A full rebuild requires an authoritative full-export cursor; download time and the live index watermark are never used as a substitute.
- Promoted snapshots are non-draft GitHub Releases tagged `food-db-<created_epoch>-<sha12>` with `usda_foods.sqlite.gz` and `food-db-manifest.json` assets.
- Candidate artifacts are run-scoped as `food-db-candidate-<GITHUB_RUN_ID>` and contain the exact SQLite file, its compressed copy, and manifest; they are published only after SQLite integrity, schema, FTS parity, source counts, identity, search, and checksum validation pass.
- Because public OFF deltas do not provide durable tombstones, the release pipeline must force a full rebuild when the promoted snapshot is at least 30 days old.

Fixture-only verification for the pipeline is available without production downloads:

```bash
python3 -m unittest discover -s scripts/tests -p 'test_*.py'
python3 -m py_compile scripts/build-food-database.py scripts/food_database/*.py
```

The production build entry point requires explicit source paths and cursor metadata:

```bash
python3 scripts/build-food-database.py \
  --foundation-json scripts/usda_data/foundation/foundationDownload.json \
  --sr-legacy-json scripts/usda_data/sr_legacy/FoodData_Central_sr_legacy_food_json_2018-04.json \
  --off-csv-gzip scripts/off_data/en.openfoodfacts.org.products.csv.gz \
  --off-cursor <authoritative-full-export-cursor>
```

The generated SQLite file remains local and ignored. The CI release workflow packages it with the manifest and promotes the exact validated candidate as a GitHub Release asset.

## Data Sources

### Local Food Database

| Attribute       | Value                                    |
| --------------- | ---------------------------------------- |
| File            | `JabTracker/Resources/usda_foods.sqlite` |
| Size            | ~322 MB                                  |
| Total Foods     | 1,731,053                                |
| USDA Foods      | 8,080 (Foundation 287 + SR Legacy 7,793) |
| Open Food Facts | 1,722,973 branded products               |
| Search          | FTS5 full-text search                    |
| Latency         | ~10-50ms                                 |
| Offline         | Yes                                      |

**USDA Foods** (source: `foundation`, `sr_legacy`): Raw ingredients, whole foods
- Chicken breast, salmon, ground beef
- Apples, bananas, broccoli, spinach
- Rice, oats, quinoa, pasta
- Eggs, milk, cheese, yogurt

**Open Food Facts** (source: `openFoodFacts`): Branded/packaged foods
- Coca-Cola, Pepsi, La Croix
- Oreos, Doritos, Kind Bars
- Cheerios, Chobani, Nutella
- Quest Protein, Clif Bars

### Open Food Facts API (Fallback Only)

| Attribute  | Value                            |
| ---------- | -------------------------------- |
| Endpoint   | `world.openfoodfacts.org`        |
| Rate Limit | 100 requests/minute per IP       |
| Timeout    | 30 seconds                       |
| Use Case   | New products not yet in local DB |

The API is only used as a fallback when a barcode is scanned that isn't in the local database. With 1.7M+ products with barcodes stored locally, most barcode scans will complete instantly offline.

## Algorithms

### Categorized Search Architecture

The search results are organized into expandable sections, each queried separately to prevent large datasets (1.7M Open Food Facts) from dominating results over smaller high-quality datasets (8K USDA foods).

```
┌─────────────────────────────────────────────────────────────────┐
│                    CATEGORIZED SEARCH FLOW                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   User types "banana"                                            │
│           │                                                      │
│           ▼                                                      │
│   ┌───────────────────────────────────────────────────────┐     │
│   │        FoodService.searchCategorized()                 │     │
│   │   (Runs 3 parallel queries, each with own limit)       │     │
│   └───────────────────────────────────────────────────────┘     │
│           │                                                      │
│     ┌─────┼─────────────────┬──────────────────┐                │
│     ▼     ▼                 ▼                  ▼                │
│  ┌──────┐ ┌───────────┐ ┌──────────┐ ┌────────────────┐        │
│  │History│ │  Custom   │ │  Common  │ │    Branded     │        │
│  │       │ │  (stub)   │ │  (USDA)  │ │     (OFF)      │        │
│  │ ≤15   │ │   ≤15     │ │   ≤15    │ │     ≤15        │        │
│  └──────┘ └───────────┘ └──────────┘ └────────────────┘        │
│                                                                  │
│   UI shows 5 per section, "See X More" expands to 15            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Result Categories**:

| Category | Source                       | Description                          |
| -------- | ---------------------------- | ------------------------------------ |
| History  | FoodEntry records            | Foods the user has previously logged |
| Custom   | User-created                 | User-created foods (stub for now)    |
| Common   | USDA (foundation, sr_legacy) | Whole foods, raw ingredients         |
| Branded  | Open Food Facts              | Packaged/branded products            |

**Why Per-Source Queries?**

Without source filtering, a single FTS5 query for "banana" returns mostly Open Food Facts results (1.7M products) while USDA bananas (8K foods) get buried. Per-source queries ensure balanced results:

```swift
// OLD: Single query dominated by OFF volume
results = database.search(query: "banana", limit: 30)
// Returns: 28 OFF products, 2 USDA foods

// NEW: Separate queries per source
commonResults = database.search(query: "banana", limit: 15, sources: ["foundation", "sr_legacy"])
// Returns: 15 USDA foods (guaranteed)

brandedResults = database.search(query: "banana", limit: 15, sources: ["openFoodFacts"])
// Returns: 15 OFF products
```

### Expandable Section UI

Each section uses a collapse/expand pattern (like Cronometer, MyFitnessPal):

```
┌─────────────────────────────────────────────────────────────────┐
│  Common                                      See 10 More ▶      │
├─────────────────────────────────────────────────────────────────┤
│  🍌 Bananas, ripe and slightly ripe, raw          89 cal        │
│  🍌 Bananas, raw                                  89 cal        │
│  🍌 Banana, dehydrated, or banana powder         346 cal        │
│  🍌 Bananas, overripe, raw                        95 cal        │
│  🍌 Plantains, yellow, raw                       122 cal        │
└─────────────────────────────────────────────────────────────────┘
                    │
                    │ User taps "See 10 More"
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Common                                           See Less ◀    │
├─────────────────────────────────────────────────────────────────┤
│  🍌 Bananas, ripe and slightly ripe, raw          89 cal        │
│  🍌 Bananas, raw                                  89 cal        │
│  ... (shows up to 15 items)                                     │
└─────────────────────────────────────────────────────────────────┘
```

**Rules**:
- Collapsed: Shows first 5 items
- Expanded: Shows up to 15 items
- "See X More" where X = min(remaining items, 10)
- If section has ≤5 items, no expand button shown

### Search Algorithm

```
FUNCTION searchCategorized(query: String) -> CategorizedSearchResults

    // Validation
    IF query.trimmed.isEmpty THEN
        RETURN empty results

    // 1. Search food history (foods user has logged)
    historyResults = searchFoodHistory(
        query: query,
        limit: 15
    )

    // 2. Custom foods (stub - empty until feature built)
    customResults = []

    // 3. Search USDA common foods
    commonResults = LocalFoodDatabase.search(
        query: query,
        limit: 15,
        sources: ["foundation", "sr_legacy"]
    )

    // 4. Search Open Food Facts branded foods
    brandedResults = LocalFoodDatabase.search(
        query: query,
        limit: 15,
        sources: ["openFoodFacts"]
    )

    RETURN CategorizedSearchResults(
        historyResults,
        customResults,
        commonResults,
        brandedResults
    )
```

### Legacy Search Algorithm (for backwards compatibility)

```
FUNCTION search(query: String) -> [Food]

    // Validation
    IF query.trimmed.length < 2 THEN
        RETURN empty

    // 1. Search local database (always runs first)
    localResults = LocalFoodDatabase.search(
        query: query,
        limit: 15,
        algorithm: FTS5_BM25  // Relevance ranking
    )

    // 2. Search Open Food Facts API (concurrent)
    TRY
        apiResults = OpenFoodFactsService.search(
            query: query,
            pageSize: 10
        )
    CATCH
        apiResults = empty  // Graceful degradation

    // 3. Merge results (local first, then API)
    merged = localResults.map(toFood)

    FOR each food IN apiResults
        IF NOT merged.containsSimilarName(food.name) THEN
            merged.append(food)

    // 4. Cache API results to SwiftData
    FOR each food IN apiResults
        saveToCache(food)

    RETURN merged
```

### FTS5 Full-Text Search

The local database uses SQLite FTS5 (Full-Text Search 5) with a custom multi-factor ranking algorithm. See **[Search Ranking Algorithm](./search-ranking-algorithm.md)** for complete details.

```sql
-- Search query with multi-factor ranking
SELECT f.fdc_id, f.name, f.brand, ...
FROM foods_fts fts
JOIN foods f ON fts.rowid = f.id
WHERE foods_fts MATCH 'chicken*'
ORDER BY
    CASE WHEN LOWER(f.name) LIKE 'chicken%' THEN 0 ELSE 1 END,  -- Prefix match
    CASE WHEN LOWER(f.name) GLOB 'chicken[s,]*' THEN 0 ELSE 1 END,  -- Whole word
    LENGTH(f.name),  -- Shorter names preferred
    bm25(foods_fts, 10.0, 1.0)  -- BM25 relevance
LIMIT 25
```

**Ranking Factors (Priority Order)**:
1. **Prefix match**: Names starting with search term rank first
2. **Whole word match**: "Apple" ranks before "APPLEBEE'S"
3. **Name length**: Shorter names preferred ("Bananas, raw" > "Bananas, dehydrated...")
4. **BM25 relevance**: Standard TF-IDF scoring with name weighted 10x

### Debounce Algorithm

```
FUNCTION performDebouncedSearch(query: String)

    // Cancel any pending search
    searchTask?.cancel()

    // Validate minimum length
    IF query.trimmed.length < 2 THEN
        clearResults()
        RETURN

    // Start new debounced search
    searchTask = Task {
        // Wait 500ms before executing
        AWAIT sleep(500ms)

        IF Task.isCancelled THEN RETURN

        results = AWAIT foodService.search(query)
        updateUI(results)
    }
```

**Why 500ms debounce?**
- Prevents API spam while typing
- Allows user to complete thought before search
- Balances responsiveness with efficiency

### Calorie Calculation (Fallback)

Some USDA Foundation Foods lack calorie data. We calculate from macros:

```
FUNCTION calculateCalories(food: Food) -> Double
    IF food.calories > 0 THEN
        RETURN food.calories

    // Atwater factors
    proteinCalories = food.protein * 4
    carbCalories = food.carbs * 4
    fatCalories = food.fat * 9

    RETURN proteinCalories + carbCalories + fatCalories
```

### Serving Size Calculation

All nutritional values are stored per 100g and scaled:

```
FUNCTION calculateForServing(baseValue: Double, servingGrams: Double) -> Double
    RETURN baseValue * servingGrams / 100.0

// Example: 165 cal per 100g chicken, user selects 150g
// Result: 165 * 150 / 100 = 247.5 cal
```

## Rate Limits

### USDA API (NOT USED)

| Limit Type | Value      | Scope                       |
| ---------- | ---------- | --------------------------- |
| DEMO_KEY   | 30/hour    | **Shared across ALL users** |
| Registered | 1,000/hour | Per API key                 |

**Problem**: DEMO_KEY is shared globally, causing rate limiting even with few users.

**Solution**: We ship a local database instead of calling USDA API.

### Open Food Facts API

| Limit Type | Value      | Scope          |
| ---------- | ---------- | -------------- |
| Search     | 100/minute | Per IP address |
| Barcode    | 100/minute | Per IP address |

**Mitigation strategies**:
1. Local database searched first (reduces API calls)
2. 500ms debounce prevents rapid-fire requests
3. Results cached to SwiftData
4. Graceful degradation if API fails

### Cache TTL

| Cache Type      | TTL      | Storage   |
| --------------- | -------- | --------- |
| API Results     | 24 hours | SwiftData |
| Recent Searches | 50 items | SwiftData |

## Caching

### SwiftData Cache Schema

```swift
@Model
final class Food {
    var fdcId: Int = 0             // USDA FDC ID
    var barcode: String = ""       // Product barcode (for API foods)
    var name: String = ""
    var brand: String = ""
    var caloriesPer100g: Double = 0
    var proteinPer100g: Double = 0
    var carbsPer100g: Double = 0
    var fatPer100g: Double = 0
    var fiberPer100g: Double = 0
    var source: String = ""        // "local", "openFoodFacts", "userCreated"
    var lastAccessedAt: Date?      // For recent foods tracking
}
```

### Cache Operations

```
FUNCTION getCachedFood(fdcId: Int) -> Food?
    food = SwiftData.fetch(where: fdcId == fdcId)

    IF food == nil THEN RETURN nil

    // Check if stale (>24 hours old)
    IF food.cachedAt < now - 24.hours THEN
        RETURN nil

    // Update access time for LRU
    food.lastAccessedAt = now
    RETURN food

FUNCTION clearStaleCache()
    staleDate = now - 24.hours
    SwiftData.delete(where: cachedAt < staleDate)
```

### Recent Searches

Tracks last 50 foods the user has viewed/added:

```
FUNCTION recordFoodAccess(food: Food)
    food.lastAccessedAt = now
    SwiftData.save(food)

FUNCTION loadRecentSearches() -> [Food]
    RETURN SwiftData.fetch(
        sortedBy: lastAccessedAt.descending,
        limit: 50
    )
```

## User Experience

### Search Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USER OPENS FOOD SEARCH                                       │
├─────────────────────────────────────────────────────────────────┤
│    • Quick Add Sheet → Search button                            │
│    • Shows recent searches OR empty state                       │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. USER TYPES SEARCH QUERY                                      │
├─────────────────────────────────────────────────────────────────┤
│    • Minimum 2 characters required                              │
│    • 500ms debounce before search executes                      │
│    • Loading indicator during search                            │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. RESULTS DISPLAYED                                            │
├─────────────────────────────────────────────────────────────────┤
│    • Local results appear first (instant)                       │
│    • API results merge in (~500ms later)                        │
│    • Source indicator: 🍃 local | ▭ packaged                    │
│    • Shows: name, brand, calories, P/C/F macros                 │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. USER TAPS FOOD ITEM                                          │
├─────────────────────────────────────────────────────────────────┤
│    • Navigates to FoodDetailView                                │
│    • Shows full nutrition facts                                 │
│    • Serving size adjustment (stepper + presets)                │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. USER ADDS FOOD                                               │
├─────────────────────────────────────────────────────────────────┤
│    • Taps "Add X cal" button                                    │
│    • Food recorded to recent searches                           │
│    • Both detail + search views dismiss                         │
│    • Returns to main app                                        │
└─────────────────────────────────────────────────────────────────┘
```

### Source Indicators

| Icon          | Color  | Meaning             | Example Foods        |
| ------------- | ------ | ------------------- | -------------------- |
| `leaf.fill`   | Green  | Local USDA database | Chicken, apple, rice |
| `barcode`     | Orange | Open Food Facts API | Coca-Cola, Oreos     |
| `person.fill` | Blue   | User-created food   | Custom recipes       |

### Serving Size Controls

1. **Stepper**: Increment/decrement by 10g (under 100g) or 25g (100g+)
2. **Presets**: 50g, 100g, 150g, 200g buttons
3. **Food-specific**: Options like "1 cup (240g)" from database

### Error States

| State      | UI                                | Recovery                               |
| ---------- | --------------------------------- | -------------------------------------- |
| No results | "No Results" view with suggestion | Try different search term              |
| API error  | Alert with message                | OK dismisses, local results still show |
| Offline    | Local results only                | No indicator (graceful)                |

## File Reference

| File                             | Purpose                                           |
| -------------------------------- | ------------------------------------------------- |
| `FoodService.swift`              | Orchestrates search, categorized queries, caching |
| `LocalFoodDatabase.swift`        | SQLite/FTS5 queries with source filtering         |
| `OpenFoodFactsService.swift`     | REST API client for packaged foods                |
| `FoodSearchSheetViewModel.swift` | Manages search state, expand/collapse             |
| `FoodSearchSheet+Sections.swift` | Expandable section UI components                  |
| `FoodDetailView.swift`           | Nutrition facts and serving adjustment            |
| `Food.swift`                     | SwiftData model for food items                    |
| `FoodEntry.swift`                | SwiftData model for logged food entries           |
| `FoodSource.swift`               | Enum for food source types                        |
| `usda_foods.sqlite`              | Bundled local database                            |
| [`search-ranking-algorithm.md`](./search-ranking-algorithm.md) | Detailed ranking algorithm documentation |

## Performance Metrics

| Operation    | Target | Actual     |
| ------------ | ------ | ---------- |
| Local search | <50ms  | ~10ms      |
| API search   | <2s    | 500-1000ms |
| UI debounce  | 500ms  | 500ms      |
| Cache lookup | <10ms  | ~5ms       |

## Testing

| Test Suite                    | Tests | Coverage |
| ----------------------------- | ----- | -------- |
| LocalFoodDatabaseTests        | 27    | 90%      |
| FoodServiceTests              | 24    | 85%      |
| FoodSearchSheetViewModelTests | 22    | 85%      |
| NutritionFlowUITests          | 11    | E2E      |

### Key Test Scenarios

**LocalFoodDatabase Source Filtering**:
- Search with `sources: ["foundation", "sr_legacy"]` returns only USDA entries
- Search with `sources: ["openFoodFacts"]` returns only OFF entries
- Search with `sources: nil` returns all sources

**FoodService Categorized Search**:
- `searchCategorized()` returns all 4 categories
- `searchFoodHistory()` returns foods user has logged
- History search deduplicates by food name

**ViewModel Expand/Collapse**:
- Expansion states initialize to false
- Toggle methods flip state correctly
- `visibleXxxResults` returns 5 when collapsed, up to 15 when expanded
- `remainingXxxCount()` returns correct remaining count

**E2E Section Verification**:
- Search shows "Common" and "Branded" sections
- "See X More" expands section
- "See Less" collapses section back
