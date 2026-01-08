We should start with UI. Build out as static mockups first, then implemennt wiring once happy with core UI patterns: https://www.figma.com/design/eHyHy3hhH5IrJLriOSfwgN/MacroKinetic---Dashboard?node-id=0-1&t=0i83j8gx0BZCATC2-1

- There are 2 primary widget designs: 
  - Main widget, which is unique, will always appear first, and does not have a detail view: https://www.figma.com/design/eHyHy3hhH5IrJLriOSfwgN/MacroKinetic---Dashboard?node-id=28-5&t=0i83j8gx0BZCATC2-1
  - Standard Widgets, which appear grouped by category and each has a detail view: https://www.figma.com/design/eHyHy3hhH5IrJLriOSfwgN/MacroKinetic---Dashboard?node-id=28-11&t=0i83j8gx0BZCATC2-1

First views to build
- Main widget, comprised of 3 views (swipeable), each with a consumed and Remaining state
  - 3 swipe states:
    - Weekly Nutrition: https://www.figma.com/design/eHyHy3hhH5IrJLriOSfwgN/MacroKinetic---Dashboard?node-id=28-6&t=0i83j8gx0BZCATC2-1
    - energy Balance: https://www.figma.com/design/eHyHy3hhH5IrJLriOSfwgN/MacroKinetic---Dashboard?node-id=28-7&t=0i83j8gx0BZCATC2-1
    - Daily Nutrition: https://www.figma.com/design/eHyHy3hhH5IrJLriOSfwgN/MacroKinetic---Dashboard?node-id=28-8&t=0i83j8gx0BZCATC2-1
- Stabdard Widget: insights and analytics group: https://www.figma.com/design/eHyHy3hhH5IrJLriOSfwgN/MacroKinetic---Dashboard?node-id=28-11&t=a24vSSZt7lWvczBd-1
  - Detail views
    - Weight Trend detail view: https://www.figma.com/design/eHyHy3hhH5IrJLriOSfwgN/MacroKinetic---Dashboard?node-id=3-22&t=a24vSSZt7lWvczBd-1
    - Expenditure detail view: https://www.figma.com/design/eHyHy3hhH5IrJLriOSfwgN/MacroKinetic---Dashboard?node-id=3-27&t=a24vSSZt7lWvczBd-1
    - Energy Balance detail view: https://www.figma.com/design/eHyHy3hhH5IrJLriOSfwgN/MacroKinetic---Dashboard?node-id=3-32&t=a24vSSZt7lWvczBd-1

Lets call this: v0.7.0 Dashboard Widget UX