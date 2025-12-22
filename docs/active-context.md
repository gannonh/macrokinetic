Food Log UX Redesign

  1. Food Entry Card Design

  Each food entry should be a distinct card with this layout:
  - Left: Food emoji/icon
  - Center:
    - Food name (title)
    - Below: {P}P {F}F {C}C • {serving} ({weight}g) in secondary text
  - Right: Calories with flame icon (e.g., "678🔥")

  Reference: See screenshot design pattern with rounded card backgrounds.

  2. Swipe Actions

  Implement swipe actions consistent with MedicationProfile pattern:
  - Swipe Left: Delete (destructive, red)
  - Swipe Right: Edit, Duplicate

  3. Meal Section Headers

  Each meal category header (Breakfast, Lunch, Dinner, Snacks) should display:
  - Section name
  - Aggregated macros: {totalP}P {totalF}F {totalC}C
  - Total calories for that meal

  4. Edit Food Entry Sheet

  When editing an entry, allow changing:
  - Date: Any date (past or future), not just today
  - Meal section: Breakfast/Lunch/Dinner/Snacks
  - All serving options: Same as the "Log Food" interface (quantity, unit, target macro mode)

  5. Shared CRUD Component

  Create a reusable FoodEntryForm component used by both:
  - FoodDetailSheet (new entry)
  - EditFoodEntrySheet (editing existing)

  This avoids duplicate code and ensures consistent UX for logging and editing.