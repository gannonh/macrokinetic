# Phase 37 Context: Unit/Serving Strategy

## Vision

Replace the basic gram-only serving input with a **horizontal pill picker** for unit selection — matching the UX pattern from MacroFactor and similar apps. Users should be able to tap "1 large egg" instead of typing "50g".

## How It Works

### The UI Pattern

A horizontal scrollable row of pill buttons appears in FoodDetailView:

```
[ 1 serving • 50g ]  [ g ]  [ oz ]  [ 1 cup (240g) ]
```

- First pill is the **default serving** (if available from data)
- `g` and `oz` are **always present** as universal fallbacks
- Additional pills show any **serving options from USDA data**
- Tapping a pill updates the quantity field and recalculates nutrition

### Data-Driven Options

The pills are populated from what's already in the database:

| Field | Source | Example |
|-------|--------|---------|
| `serving_size` + `serving_unit` | Default serving | "1 serving • 50g" |
| `serving_options` JSON array | USDA portion data | "1 cup (240g)", "1 sifted (85g)" |
| Always present | Universal | "g", "oz" |

### Nutrition Updates Live

When the user changes units:
1. Convert the selected unit to grams
2. Recalculate calories, protein, carbs, fat based on grams
3. Update the display immediately

## What's Essential

- **Horizontal pill picker UI** matching competitor screenshots (MacroFactor style)
- **g and oz always available** as universal options
- **Surface existing USDA serving_options** data (parse the JSON, show as pills)
- **Default to "1 serving"** when serving_size/serving_unit exist
- **Live nutrition recalculation** when unit changes
- **Quantity input** that works with the selected unit (e.g., "2" large eggs)

## What's Out of Scope

- **Comprehensive unit mapping table** — No building a database of "large egg = 50g, medium egg = 44g" for all foods
- **External data fetching** — No API calls to get richer serving data
- **Volume conversions** — No converting "1 cup" to "236ml" unless it's in the data
- **Unit preference persistence** — No remembering "user prefers oz for chicken"

## Reference Materials

Competitor screenshots showing the pattern:
- `mocks/units/IMG_2158.PNG` - MacroFactor egg with "large egg" pill
- `mocks/units/IMG_2159.PNG` - MacroFactor with more unit options  
- `mocks/units/IMG_2160.PNG` - MacroFactor volume units
- `mocks/units/IMG_2161.PNG` - Simpler app with "Medium | Oz | G | Large" pills

## Current State

From database inspection:
- USDA foods have `serving_options` but they're basic ("100g", "28g", "1.0 sifted (85g)")
- Apples only have "100g" — no "1 medium" in current data
- Open Food Facts has empty `serving_options` for most products
- The UI will gracefully degrade to just `g | oz` when no extra options exist

## Success Looks Like

User opens FoodDetailView for "Egg, whole, raw" and sees:

```
[ 1 egg • 50g ]  [ g ]  [ oz ]  [ 28g ]
     ↑ selected by default
```

They tap "2" in quantity, and nutrition updates to show values for 2 eggs (100g).

For a food with no extra options (like many OFF products):

```
[ g ]  [ oz ]
```

Clean, simple, always functional.
