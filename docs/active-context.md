# Next Milestone

## Food Libray and Search Improvements

- Update db: ./scripts/update-food-database.sh (latest off data set already downloaded to `scripts/off_data/en.openfoodfacts.org.products.csv.gz`)
- Barcope scanner: stays active after food detail sheet appears, cuasing possible additional scans
- Search - improve performance, precision & recall:
  - Slow and sluggish when typing quickly; why slow when data 100% on device? Begins searching on first letter, synchronously, stopping typing flow.
  - Input box shold be in focus immediately when opening search screen
  - Header: kcals and protien remaining indicators shoud look like indicators on the food log view
  - The docs (docs/features/food-data-layer.md) mention that we do API searching as a fallback, but this shouldnt be necessary with the OFF+USDA local DB
- Food Detail:
  - How are we handling units for food items from  USDA and OFF? The entry for Eggs for example doesnt have item as a unit, which would be the most common use. E.g. 2 whole eggs
  - I can't find whole Apples when searching "Apples". I think because we limit resesults to 15 common items and the seaerch ranking needs work. If I search for Apples raw I can find them.
  - clicking anywhere in the amount field should bring up the numpad; currently you need to carefully tap the numbers.

## Pending Todos

- Run `/gsd:check-todos` and add pending todos to milestone scope