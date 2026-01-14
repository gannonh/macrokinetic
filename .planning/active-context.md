# Next Milestone

## Food Libray and Search Improvements

- Update db: ./scripts/update-food-database.sh (latest off data set already downloaded to `scripts/off_data/en.openfoodfacts.org.products.csv.gz`)
- Barcope scanner: stays active after food detail sheet appears, cuasing possible additional scans
- Search - improve performance, precision & recall:
  - Slow and sluggish when typing quickly; why slow when data 100% on device? Begins searching on first letter, synchronously, stopping typing flow.
  - Input box shold be in focus immediately when opening search screen
  - Header: kcals and protein remaining indicators shoud look like indicators on the food log view: /Users/gannonhall/Desktop/Screenshot 2026-01-12 at 1.00.33 PM.png
  - The docs (docs/features/food-data-layer.md) mention that we do API searching as a fallback, but this shouldnt be necessary with the OFF+USDA local DB
- Food Detail:
  - How are we handling units for food items from  USDA and OFF? The entry for Eggs for example doesnt have item as a unit, which would be the most common use. E.g. 2 whole eggs
  - I can't find whole Apples when searching "Apples". I think because we limit resesults to 15 common items and the seaerch ranking needs work. If I search for Apples raw I can find them.
  - clicking anywhere in the amount field should bring up the numpad; currently you need to carefully tap the numbers.

## Pending Todos

- Run `/gsd:check-todos` and add pending todos to milestone scope

---


 /gsd:execute-plan .planning/phases/36-search-ranking-recall/36-01-PLAN.md; Context: We are in the process of working on this. Here is my latest feedback:

 - I think we need to favor whole words so that Apple comes before APPLEBEE'S in search results. `/Users/gannonhall/Desktop/Simulator Screenshot - iPhone 17 Pro - 2026-01-12 at 14.32.39.png`
 - Also, perhaps we favor shorter results over longer results so that in this case Bananas, raw comes before Bananas, dehydrated...: `/Users/gannonhall/Desktop/Simulator Screenshot - iPhone 17 Pro - 2026-01-12 at 14.34.09.png`