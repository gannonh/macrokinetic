# Combined GLP-1 + Nutrition Tracking App

## Strategic Decision

**Build on JabTracker** - Add MacroSnap's nutrition features to the existing production-ready foundation.

### Justification
- JabTracker: 95% complete (32K lines, 144 unit + 60 E2E tests)
- MacroSnap: 20% complete (requires rebuilding)
- JabTracker's PharmacokineticsEngine is a unique competitive moat (NO competitor has true PK modeling)
- Same tech stack (SwiftUI, SwiftData, CloudKit, XcodeGen) - easy to port features

### Competitive Advantage
| Feature                       | Shotsy         | MeAgain        | This App               |
| ----------------------------- | -------------- | -------------- | ---------------------- |
| Pharmacokinetics modeling     | Basic estimate | Basic estimate | True exponential decay |
| Medication level chart        | Paywalled      | Paywalled      | Free                   |
| Nutrition tracking            | No             | Basic          | Full with correlation  |
| Medication-nutrition insights | No             | No             | Yes (unique)           |
| Protein preservation alerts   | No             | No             | Yes (unique)           |
| Reconstitution calculator     | No             | No             | Yes                    |
| Split-dose support            | No             | No             | Yes                    |

---

## Must-Have Features (Per User Requirements)

1. **Basic Nutrition Tracking** - Food search, barcode scanning, macro logging
2. **Medication-Nutrition Correlation** - Food noise tracking, appetite patterns
3. **Protein Preservation Alerts** - Critical for GLP-1 muscle loss prevention
4. **HealthKit Integration** - Weight, activity sync

---

## Implementation Phases

### Phase 1: Core Nutrition Infrastructure (Weeks 1-3)

**Goal:** Port MacroSnap's food database and logging to JabTracker

#### 1.1 Data Models
Add to existing SwiftData schema:

```swift
// Food.swift - Food database item
@Model final class Food {
    var id: UUID = UUID()
    var fdcId: Int = 0                    // USDA Food Data Central ID
    var name: String = ""
    var brand: String?
    var source: FoodSource = .local       // .local or .openFoodFacts
    var caloriesPer100g: Double = 0
    var proteinPer100g: Double = 0
    var carbsPer100g: Double = 0
    var fatPer100g: Double = 0
    var fiberPer100g: Double = 0
    var servingSize: Double = 100
    var servingUnit: String = "g"
    var barcode: String?
    var searchedAt: Date = Date()
    var lastAccessedAt: Date = Date()
}

// FoodEntry.swift - Logged meal item (denormalized)
@Model final class FoodEntry {
    var id: UUID = UUID()
    var user: User?                       // Relationship
    var foodId: UUID = UUID()
    var foodName: String = ""             // Denormalized for history
    var foodBrand: String?
    var mealSection: MealSection = .breakfast
    var servingGrams: Double = 100
    var caloriesPer100g: Double = 0       // Snapshot at log time
    var proteinPer100g: Double = 0
    var carbsPer100g: Double = 0
    var fatPer100g: Double = 0
    var fiberPer100g: Double = 0
    var loggedAt: Date = Date()

    // Computed properties for actual serving
    var calories: Double { (caloriesPer100g / 100) * servingGrams }
    var protein: Double { (proteinPer100g / 100) * servingGrams }
    var carbs: Double { (carbsPer100g / 100) * servingGrams }
    var fat: Double { (fatPer100g / 100) * servingGrams }
}

// MealSection.swift
enum MealSection: String, Codable, CaseIterable {
    case breakfast, lunch, dinner, snacks

    var displayName: String { ... }
    var icon: String { ... }
    var defaultTimeRange: ClosedRange<Int> { ... }
}
```

#### 1.2 Port Food Database Infrastructure
Files to create (port from MacroSnap):
- `JabTracker/Services/LocalFoodDatabase.swift` - SQLite FTS5 search
- `JabTracker/Services/OpenFoodFactsService.swift` - API client
- `JabTracker/Services/FoodService.swift` - Orchestrator
- `JabTracker/Services/MealLogService.swift` - CRUD for FoodEntry
- Bundle `usda_foods.sqlite` (8,109 foods, 2.8MB)

#### 1.3 Extend User Model
```swift
// Add to User.swift
var dailyCalorieGoal: Double = 2000.0
var dailyProteinGoal: Double = 150.0
var dailyCarbGoal: Double = 200.0
var dailyFatGoal: Double = 65.0

@Relationship(deleteRule: .cascade, inverse: \FoodEntry.user)
var foodEntries: [FoodEntry]?
```

#### 1.4 Basic Meal Logging UI
- `FoodSearchView.swift` - Search with results list
- `FoodDetailView.swift` - Nutrition facts, serving adjustment
- `MealLogView.swift` - Today's meals by section
- `AddFoodSheet.swift` - Quick add modal

#### 1.5 Update Tab Navigation
```swift
// Current: Dashboard, +, History, Analytics, Settings
// Updated: Dashboard, +, Today (meals), Analytics, Settings
// History becomes combined dose + meal calendar
```

**Critical Files to Modify:**
- `/JabTracker/DataController.swift` - Add new models to schema
- `/JabTracker/App/AppServices.swift` - Register new services
- `/JabTracker/Models/User.swift` - Add nutrition goals
- `/JabTracker/ContentView.swift` - Update tab structure

**Testing:**
- Unit tests for FoodService, LocalFoodDatabase, MealLogService
- E2E: Search food → log meal → view daily totals

---

### Phase 2: HealthKit Integration (Weeks 4-5)

**Goal:** Sync weight, body composition, activity from Apple Health

#### 2.1 Create HealthKitService
```swift
// HealthKitService.swift
@Observable final class HealthKitService {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws -> Bool
    func syncWeight() async throws -> Double?
    func syncBodyFat() async throws -> Double?
    func syncSteps(for date: Date) async throws -> Int
    func syncActiveCalories(for date: Date) async throws -> Double

    // Optional: Write nutrition data to Health
    func writeNutrition(calories: Double, protein: Double, ...) async throws
}
```

#### 2.2 Weight Tracking Integration
- Display weight trend on dashboard
- Correlate weight with medication adherence + nutrition
- Weight chart in Analytics

#### 2.3 Activity Context
- Show daily steps/calories burned
- Calculate net calories (consumed - burned)
- Activity-adjusted nutrition goals (future)

**Critical Files:**
- Create `/JabTracker/Services/HealthKitService.swift`
- Update `/JabTracker/Info.plist` - HealthKit usage descriptions
- Update `/JabTracker.entitlements` - HealthKit capability

---

### Phase 3: Medication-Nutrition Correlation Engine (Weeks 6-8)

**Goal:** Unique insights connecting drug concentration to eating patterns

#### 3.1 Correlation Data Model
```swift
// AppetiteEntry.swift - Daily appetite tracking
@Model final class AppetiteEntry {
    var id: UUID = UUID()
    var user: User?
    var date: Date = Date()
    var hungerLevel: Int = 5              // 1-10
    var cravingsIntensity: Int = 5        // 1-10
    var foodNoiseLevel: Int = 5           // 1-10 (GLP-1 specific)
    var notes: String?
}
```

#### 3.2 NutritionCorrelationEngine
```swift
// NutritionCorrelationEngine.swift
@Observable final class NutritionCorrelationEngine {
    private let pkEngine: PharmacokineticsEngine
    private let mealLogService: MealLogService

    // Calculate appetite suppression relative to concentration
    func calculateFoodNoiseReduction(
        concentration: Double,
        appetiteEntry: AppetiteEntry,
        baselineAppetite: Double
    ) -> Double

    // Identify optimal eating windows
    func calculateOptimalEatingWindow(
        for medication: MedicationProfile
    ) -> (peakSuppression: DateInterval, normalAppetite: DateInterval)

    // Generate correlation insights
    func generateInsights(
        user: User,
        dateRange: ClosedRange<Date>
    ) -> [NutritionInsight]
}

// Insight types
enum NutritionInsightType {
    case proteinDeficit           // "Protein 40% below target"
    case optimalEatingWindow      // "Best appetite: 2-4 days post-dose"
    case peakSuppression          // "Food noise lowest on dose day"
    case calorieCorrelation       // "Calories drop 30% after dose"
    case consistentTiming         // "Meals at consistent times = better results"
}
```

#### 3.3 Appetite Tracking UI
- Daily appetite check-in (hunger, cravings, food noise)
- Quick rating from 1-10 with visual slider
- Optional notes field
- Prompt after logging dose

#### 3.4 Correlation Visualizations
- Concentration vs. Appetite chart (overlay)
- Food Noise Reduction Timeline
- Eating Patterns by Medication Cycle

**Critical Files:**
- Create `/JabTracker/Services/NutritionCorrelationEngine.swift`
- Create `/JabTracker/Models/AppetiteEntry.swift`
- Create `/JabTracker/Views/Analytics/CorrelationChartsView.swift`

---

### Phase 4: Protein Preservation Alerts (Weeks 9-10)

**Goal:** Proactive alerts for GLP-1 users at risk of muscle loss

#### 4.1 Protein Monitoring Service
```swift
// ProteinMonitoringService.swift
@Observable final class ProteinMonitoringService {
    // Minimum protein = 1.6g per kg bodyweight for GLP-1 users
    func calculateProteinTarget(user: User) -> Double {
        let weightKg = user.weight / 2.205  // Convert if stored in lbs
        return weightKg * 1.6               // g/kg minimum
    }

    func validateDailyProtein(
        user: User,
        date: Date
    ) -> ProteinValidationResult {
        let consumed = mealLogService.totalProtein(for: date)
        let target = calculateProteinTarget(user: user)
        let deficit = target - consumed

        return ProteinValidationResult(
            consumed: consumed,
            target: target,
            deficit: deficit,
            isAdequate: deficit <= 0,
            severity: calculateSeverity(deficit, target),
            recommendations: generateRecommendations(deficit)
        )
    }
}

enum ProteinDeficitSeverity {
    case none       // >= 100% target
    case mild       // 80-99% target
    case moderate   // 50-79% target
    case severe     // < 50% target
}
```

#### 4.2 Push Notifications
- Evening alert if protein below 80% of target
- Actionable: "Log a protein-rich snack"
- Weekly summary of protein adherence

#### 4.3 Protein-Focused UI
- Protein progress ring on dashboard (prominent)
- Color-coded: Green (good), Yellow (low), Red (critical)
- High-protein food suggestions
- Protein trend chart in Analytics

**Critical Files:**
- Create `/JabTracker/Services/ProteinMonitoringService.swift`
- Update `/JabTracker/Services/NotificationService.swift` - Protein alerts
- Create `/JabTracker/Views/Dashboard/ProteinProgressCard.swift`

---

### Phase 5: Unified Dashboard & Analytics (Weeks 11-12)

**Goal:** Combined view of medication + nutrition health

#### 5.1 Redesigned Dashboard
```
┌─────────────────────────────────────┐
│ Current Concentration Card          │
│ [████████░░] 73% | Next: 2d 4h     │
├─────────────────────────────────────┤
│ Today's Nutrition                   │
│ Calories: 1,450 / 2,000            │
│ Protein:  [██████░░░░] 85g / 150g  │ ← Prominent!
│ Carbs:    [████░░░░░░] 120g        │
│ Fat:      [███░░░░░░░] 45g         │
├─────────────────────────────────────┤
│ Appetite Today                      │
│ Food Noise: ●●●○○○○○○○ (3/10)      │
│ vs Peak Suppression Expected        │
├─────────────────────────────────────┤
│ Weight Trend                        │
│ [HealthKit chart] -8.5 lbs         │
└─────────────────────────────────────┘
```

#### 5.2 Combined Calendar View
- Dose markers (existing)
- Meal indicators (breakfast/lunch/dinner icons)
- Protein status (green/yellow/red dot)
- Weight data points

#### 5.3 Unified Analytics Tab
- Concentration Timeline (existing)
- Nutrition Trends (calories, protein over time)
- **Correlation Charts** (unique):
  - Concentration vs. Daily Calories
  - Food Noise by Day Post-Dose
  - Protein Intake vs. Weight Change
  - Adherence + Nutrition + Weight correlation

**Critical Files:**
- Update `/JabTracker/Views/Dashboard/DashboardView.swift`
- Update `/JabTracker/Views/History/CalendarView.swift`
- Update `/JabTracker/ViewModels/AnalyticsViewModel.swift`
- Create `/JabTracker/Views/Analytics/UnifiedInsightsView.swift`

---

### Phase 6: Barcode Scanning & Polish (Weeks 13-14)

**Goal:** Complete food entry experience

#### 6.1 Barcode Scanner
- AVFoundation camera integration
- Open Food Facts API lookup
- Quick-add flow after scan
- Handle "not found" gracefully

#### 6.2 Export & Reporting
```swift
// ExportService.swift
@Observable final class ExportService {
    func generateCombinedReport(
        user: User,
        dateRange: ClosedRange<Date>
    ) -> PDFDocument {
        // Sections:
        // 1. Medication Summary (adherence, concentration)
        // 2. Nutrition Summary (avg macros, protein adequacy)
        // 3. Correlation Insights
        // 4. Weight Progress
        // 5. Recommendations
    }

    func exportToCSV(dateRange: ClosedRange<Date>) -> URL
}
```

#### 6.3 Polish & Edge Cases
- Empty states for all new views
- Error handling for API failures
- Offline mode (local database works offline)
- Accessibility audit
- Performance optimization

---

## File Structure After Implementation

```
JabTracker/
├── Models/
│   ├── Food.swift                    # NEW
│   ├── FoodEntry.swift               # NEW
│   ├── MealSection.swift             # NEW
│   ├── AppetiteEntry.swift           # NEW
│   └── ... (existing)
├── Services/
│   ├── LocalFoodDatabase.swift       # NEW - SQLite FTS5
│   ├── OpenFoodFactsService.swift    # NEW - API client
│   ├── FoodService.swift             # NEW - Orchestrator
│   ├── MealLogService.swift          # NEW - CRUD
│   ├── HealthKitService.swift        # NEW
│   ├── NutritionCorrelationEngine.swift  # NEW
│   ├── ProteinMonitoringService.swift    # NEW
│   ├── ExportService.swift           # NEW
│   └── ... (existing)
├── Views/
│   ├── Nutrition/                    # NEW directory
│   │   ├── FoodSearchView.swift
│   │   ├── FoodDetailView.swift
│   │   ├── MealLogView.swift
│   │   ├── AddFoodSheet.swift
│   │   └── BarcodeScannerView.swift
│   ├── Dashboard/
│   │   ├── DashboardView.swift       # MODIFY
│   │   ├── NutritionSummaryCard.swift    # NEW
│   │   └── ProteinProgressCard.swift     # NEW
│   └── Analytics/
│       ├── CorrelationChartsView.swift   # NEW
│       └── UnifiedInsightsView.swift     # NEW
└── Resources/
    └── usda_foods.sqlite             # NEW - Bundled database
```

---

## Success Criteria

### Phase 1 Complete When:
- [ ] Food search returns results from USDA database
- [ ] Can log a meal with serving size
- [ ] Daily macro totals display correctly
- [ ] Unit tests pass for new services

### Phase 2 Complete When:
- [ ] HealthKit authorization works
- [ ] Weight syncs from Apple Health
- [ ] Weight displayed on dashboard

### Phase 3 Complete When:
- [ ] Can log daily appetite/food noise rating
- [ ] Correlation engine calculates insights
- [ ] Correlation charts render with real data

### Phase 4 Complete When:
- [ ] Protein target calculates based on user weight
- [ ] Deficit alerts fire when protein low
- [ ] Protein progress ring on dashboard

### Phase 5 Complete When:
- [ ] Unified dashboard shows all health data
- [ ] Combined calendar shows doses + meals
- [ ] Analytics has correlation charts

### Phase 6 Complete When:
- [ ] Barcode scanning works for packaged foods
- [ ] PDF export generates combined report
- [ ] All polish items complete

---

## Risk Mitigation

| Risk                        | Mitigation                                                    |
| --------------------------- | ------------------------------------------------------------- |
| SwiftData migration issues  | Test extensively with beta users before public release        |
| CloudKit sync conflicts     | Follow existing CloudKit patterns (parent-only relationships) |
| Food database size (2.8MB)  | Bundle in app, compress if needed                             |
| Open Food Facts rate limits | Implement 24hr cache, graceful degradation                    |
| HealthKit permission denied | App works fully without HealthKit                             |

---

## Next Steps

1. **Create GitHub Epic** for this work with task breakdown
2. **Start Phase 1** - Port food database and basic logging
3. **Iterate** - Quality over speed, validate each phase works before moving on
