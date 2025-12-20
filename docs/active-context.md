Lets continue work on @.claude/context/project-prd.md#L161-173 

I have New UI mocks we need to begin adopting as we continue building out the feature:

1. Add buttton: Brings up a quarter sheet modal with the default options: 
    - Top Shortcuts: Search, Barcode, Photo (AI), Shots
    - Other shortcuts:
      - Weight
      - Quick Add
      - Metrics
      - You Foods
      - Recipes
      - Edit Days
    - Include a non-functional "Customize" icon in the sheet header for future customization options.
    - For now only Search and Shots work, the rest are non-functional until we build those features
    - Mock: mocks/add/IMG_1949.PNG

2. Search sheet:
   - Top of sheet
     - list of adding moethods with the current, search, highlighted as current
     - Time picker button on the left side to set time for the food entry
     - Remaining Calories / Protein for the day
   - Before any typing search results shows most recently used foods: mocks/add/Screenshot 2025-12-20 at 7.30.19 AM.png
   - Search begins with first character: mocks/add/Screenshot 2025-12-20 at 7.33.04 AM.png
     - Search results are grouped by category: History, Custom (Foods added or edited by the user), Common (USDA), Branded (OFF): mocks/add/IMG_1951.PNG
     - clciking an itenm briungs up the nutritional detail sheet: mocks/add/Screenshot 2025-12-20 at 7.44.28 AM.png
     - Add button adds the food to your plate in the top header: mocks/add/Screenshot 2025-12-20 at 7.45.19 AM.png
     - Log Foods or Arrow button in header adds foods to your day: mocks/add/Screenshot 2025-12-20 at 7.47.47 AM.png

Note: not all of the elements in the mocks are correct, but they will give you a general sense of the UX patterns we are after. For example we are using SF Symbols for the icons, not custom icons. The button styles are also not final. Focus on adopting iOS (26) SwiftUI compoenents when possible.