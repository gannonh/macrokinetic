---
created: 2024-01-15T00:00:00Z
updated: 2025-12-26T18:01:49Z
---

### 📋 Dashboard

[Figma Mockup](https://www.figma.com/design/eHyHy3hhH5IrJLriOSfwgN/MacroKinetic---Dashboard?node-id=0-1&t=i5ChORSrO8Wl1tD4-1)

Unified dashboard with nutrition tracking, energy balance, body metrics, and weight analytics.

#### Requirements

- [ ] Weekly/Daily nutrition toggle with bar chart visualization
- [ ] Consumed vs Remaining toggle for all nutrition views
- [ ] Insights & Analytics section (expenditure, weight trend, energy balance, goal progress, deficit)
- [ ] Body Metrics cards (scale weight, waist measurements)
- [ ] Nutrition breakdown (macros chart, calories, protein, fat, carbs, fiber)
- [ ] Steps tracking (last 7 days)
- [ ] Weight Trend detail view with historical graph and projections
- [ ] Energy Balance view with sparkline and targets comparison
- [ ] Customizable dashboard option

#### Customize Dashboard

[Customize Dashboard Figma Mockup](https://www.figma.com/design/MlPp7fcebWu5nznomnjGrt/MK---Dashboard---Customize?node-id=0-1&t=hXDqk1iK4yTlP0ii-1)

Full-screen customization view accessible from dashboard.

##### Sections (reorderable)

1. **Primary Focus** - Horizontal carousel to select primary chart (Weekly Nutrition, Energy Balance)
2. **Insights & Analytics** - Expenditure, Weight Trend, Energy Balance, Goal Progress
3. **Habits** - Weigh-In, Food Logging
4. **Body Metrics** - Scale Weight, Waist, Visual Body Fat, Progress Photos, Full Body, Neck, Shoulders, Bust, Chest
5. **Nutrition** - Macros, Calories, Protein, Fat, Carbs, Fiber, Net (Non-Fiber), Starch, Sugars
6. **General** - Steps, Period

##### Customization Features

- [ ] Reorder sections via up/down arrows
- [ ] Reorder tiles within sections via drag handles
- [ ] Toggle tiles on/off via checkmarks
- [ ] Per-tile display mode dropdown (e.g., Consumed/Remaining)
- [ ] "Add or Remove" modal sheets per section with categorized tile toggles
- [ ] Save/Cancel navigation bar actions

##### Add/Remove Modal Categories

**Body Metrics:**
- Weight & Body Fat: Scale Weight, Visual Body Fat
- Visual & Metric Overview: Progress Photos, Full Body
- Upper Body: Neck, Shoulders, Bust, Chest

**Nutrition:**
- Calories & Macros: Macros, Calories, Protein, Fat, Carbs
- Carb Breakdown: Fiber, Net (Non-Fiber), Starch, Sugars

#### User Stories

##### Overview
- **As a user**, I want weekly and daily nutrition views, so that I can track patterns and daily intake.
- **As a user**, I want to toggle consumed vs remaining, so that I see progress from either perspective.

##### Analytics
- **As a user**, I want insights on expenditure, energy balance, and goal progress, so that I understand my trends.
- **As a user**, I want weight trend analytics with projections, so that I can forecast my progress.

##### Body Metrics
- **As a user**, I want body metrics (weight, waist) displayed, so that I track physical changes.
- **As a user**, I want a detailed weight view with time range filters, so that I analyze long-term trends.

##### Customization
- **As a user**, I want to choose my primary focus chart, so that I see my most important metric first.
- **As a user**, I want to show/hide dashboard tiles, so that I only see relevant data.
- **As a user**, I want to reorder sections and tiles, so that I prioritize what matters to me.
- **As a user**, I want to configure display modes per tile, so that I see consumed or remaining as preferred.

#### Key Design Decisions

1. **Time-based views** - Weekly bar charts for pattern recognition, daily view for intake tracking.
2. **Dual toggle system** - Consumed/Remaining toggle persists across views.
3. **Layered detail** - Summary cards on dashboard, "See All" links to detailed views.
4. **Weight analytics depth** - Dedicated weight trend screen with rate of change, deficit calculation, and 30-day projection.
5. **Energy balance visualization** - Sparkline showing nutrition vs expenditure vs targets over 30 days.

#### Acceptance Criteria

- [ ] Weekly nutrition shows 7-day bar chart with macro breakdown
- [ ] Daily nutrition shows consumed/remaining/target with macro progress
- [ ] Consumed/Remaining toggle affects all nutrition displays
- [ ] Insights section shows expenditure, weight trend, energy balance, goal progress, deficit percentage
- [ ] Body Metrics section shows scale weight and waist with 7-entry history
- [ ] Weight Trend detail view includes graph, time filters (1W/3M/6M/1Y/All), weight change rates, and projections
- [ ] Energy Balance view shows nutrition/expenditure/difference with sparkline
- [ ] Steps card shows last 7 days
- [ ] Bottom tab bar: Dashboard, Food Log, Add (+), Strategy, More

##### Customization
- [ ] Customize Dashboard screen accessible from dashboard
- [ ] Primary Focus carousel switches main chart widget
- [ ] Sections reorderable via up/down arrows
- [ ] Tiles reorderable within sections via drag handles
- [ ] Tile visibility toggleable via checkmarks
- [ ] Per-tile display mode configurable (Consumed/Remaining where applicable)
- [ ] Add/Remove modal sheets show categorized toggles
- [ ] Save persists configuration; Cancel discards changes
- [ ] Dashboard reflects saved customization state

