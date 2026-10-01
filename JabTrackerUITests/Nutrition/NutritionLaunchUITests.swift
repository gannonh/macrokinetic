import XCTest

final class NutritionLaunchUITests: XCTestCase {
    private var app: XCUIApplication!
    private var today = Date()
    private var selectedDate = Date()
    private var captureIndex = 0

    override func setUpWithError() throws {
        continueAfterFailure = false
        today = Calendar.current.startOfDay(for: Date())
        selectedDate = today
        app = launch(resetData: true)
        expect(app.tabBars.firstMatch.waitForExistence(timeout: 10), "The nutrition-only user opens the app")
        expectNoMedicationProfiles()
        selectDay(offset: 0)
        expectEntries([])
        expectLogTotals(calories: "0/2000", protein: "0/150", fat: "0/65", carbs: "0/200")
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testNutritionOnlyTotalsAndRelaunch() throws {
        addSalmon(grams: "200", meal: "Breakfast")
        expectEntries(["🐟, Salmon, Atlantic, raw, 40P, 26F, 0C, •, 200g, 416"])
        expectMeal("breakfast", labels: ["Breakfast", "40P", "26F", "0C", "416"])
        expectDayCount(1)
        expectLogTotals(calories: "416/2000", protein: "40/150", fat: "26/65", carbs: "0/200")
        expectDashboard(calories: "416", protein: "40", fat: "26", carbs: "0")
        capture("nutrition-only-dashboard-before-relaunch")

        relaunchWithoutReset()
        expectNoMedicationProfiles()
        selectDay(offset: 0)
        expectEntries(["🐟, Salmon, Atlantic, raw, 40P, 26F, 0C, •, 200g, 416"])
        expectMeal("breakfast", labels: ["Breakfast", "40P", "26F", "0C", "416"])
        expectDayCount(1)
        expectLogTotals(calories: "416/2000", protein: "40/150", fat: "26/65", carbs: "0/200")
        expectDashboard(calories: "416", protein: "40", fat: "26", carbs: "0")
        capture("nutrition-only-dashboard-after-relaunch")
    }

    func testEditAndDeleteRetainOtherDay() throws {
        selectDay(offset: -1)
        addSalmon(grams: "100", meal: "Breakfast")
        expectHundredGramDay()
        selectDay(offset: 0)
        addSalmon(grams: "200", meal: "Breakfast")
        expectEntries(["🐟, Salmon, Atlantic, raw, 40P, 26F, 0C, •, 200g, 416"])

        openEdit(originalGrams: "200")
        setQuantity("100", in: app.otherElements["edit-food-entry-sheet"])
        tap(app.buttons["save-entry-button"], "Save the edited serving")
        expect(app.otherElements["edit-food-entry-sheet"].waitForNonExistence(timeout: 5), "Edit closes after saving")
        expectHundredGramDay()
        expectDashboard(calories: "208", protein: "20", fat: "13", carbs: "0")

        selectDay(offset: 0)
        openEdit(originalGrams: "100")
        setQuantity("200", in: app.otherElements["edit-food-entry-sheet"])
        tap(app.otherElements["edit-food-entry-sheet"].buttons["Cancel"], "Cancel the changed serving")
        expect(app.otherElements["edit-food-entry-sheet"].waitForNonExistence(timeout: 5), "Canceled edit closes")
        expectHundredGramDay()

        openDeleteConfirmation()
        tap(app.alerts["Delete Entry?"].buttons["Cancel"], "Cancel deletion")
        expect(app.alerts["Delete Entry?"].waitForNonExistence(timeout: 5), "Canceled deletion closes")
        expectHundredGramDay()
        openDeleteConfirmation()
        tap(app.alerts["Delete Entry?"].buttons["Delete"], "Confirm deletion of today's entry")
        expect(app.alerts["Delete Entry?"].waitForNonExistence(timeout: 5), "Confirmed deletion closes")
        expectEmptyDay()
        expectDashboard(calories: "0", protein: "0", fat: "0", carbs: "0")
        selectDay(offset: -1)
        expectHundredGramDay()
        capture("nutrition-delete-retained-yesterday")

        relaunchWithoutReset()
        selectDay(offset: 0)
        expectEmptyDay()
        selectDay(offset: -1)
        expectHundredGramDay()
        capture("nutrition-delete-retained-yesterday-after-relaunch")
    }

    func testClearDayRetainsOtherDay() throws {
        selectDay(offset: -1)
        addSalmon(grams: "100", meal: "Breakfast")
        expectHundredGramDay()
        selectDay(offset: 0)
        addSalmon(grams: "100", meal: "Breakfast")
        addSalmon(grams: "200", meal: "Lunch")
        expectTwoEntryDay()
        expectDashboard(calories: "624", protein: "60", fat: "39", carbs: "0")

        selectDay(offset: 0)
        openClearDayConfirmation()
        tap(app.alerts["Clear All Foods?"].buttons["Cancel"], "Cancel clearing today's two entries")
        expect(app.alerts["Clear All Foods?"].waitForNonExistence(timeout: 5), "Canceled clear-day closes")
        expectTwoEntryDay()
        openClearDayConfirmation()
        tap(app.alerts["Clear All Foods?"].buttons["Clear Day"], "Clear today's two entries")
        expect(app.alerts["Clear All Foods?"].waitForNonExistence(timeout: 5), "Confirmed clear-day closes")
        expectEmptyDay()
        expectDashboard(calories: "0", protein: "0", fat: "0", carbs: "0")
        selectDay(offset: -1)
        expectHundredGramDay()
        capture("nutrition-clear-day-retained-yesterday")

        relaunchWithoutReset()
        selectDay(offset: 0)
        expectEmptyDay()
        selectDay(offset: -1)
        expectHundredGramDay()
        expectNoMedicationProfiles()
        capture("nutrition-clear-day-no-medication-after-relaunch")
    }

    /// Scenario 10 evidence run: the same journey against the production food database. The host script
    /// queries the bundled database and passes two named foods through TEST_RUNNER_PROD_FOOD{1,2}_* variables
    /// (NAME, QUERY, GRAMS, KCAL, P, C, F per 100 g). Without them the test is skipped with an explicit message.
    func testProductionDatabaseJourneyWithDatabaseValues() throws {
        let env = ProcessInfo.processInfo.environment
        guard env["PROD_FOOD1_NAME"] != nil else {
            throw XCTSkip("Production-database run: set TEST_RUNNER_PROD_FOOD1_* and PROD_FOOD2_* (see docs/nutrition-launch-verification.md)")
        }
        let foods = try [1, 2].map { try ProductionFood(index: $0, environment: env) }
        let first = foods[0], second = foods[1]
        let totals = ProductionFood.totals(foods)

        addProductionFood(first, meal: "Breakfast")
        expectProductionRows([first])
        expectLogTotals(first.totals)
        addProductionFood(second, meal: "Lunch")
        expectProductionRows([first, second])
        expectDayCount(2)
        expectLogTotals(totals)
        expectDashboard(totals)
        capture("production-before-relaunch")

        relaunchWithoutReset()
        expectNoMedicationProfiles()
        selectDay(offset: 0)
        expectProductionRows([first, second])
        expectDayCount(2)
        expectLogTotals(totals)
        expectDashboard(totals)
        capture("production-after-relaunch")
    }

    private struct ProductionFood {
        let name: String
        let query: String
        let grams: Int
        let kcal: Double, protein: Double, carbs: Double, fat: Double

        init(index: Int, environment env: [String: String]) throws {
            func value(_ key: String) throws -> String {
                try XCTUnwrap(env["PROD_FOOD\(index)_\(key)"], "PROD_FOOD\(index)_\(key) is required")
            }
            name = try value("NAME")
            query = try value("QUERY")
            grams = try XCTUnwrap(Int(value("GRAMS")))
            kcal = try XCTUnwrap(Double(value("KCAL")))
            protein = try XCTUnwrap(Double(value("P")))
            carbs = try XCTUnwrap(Double(value("C")))
            fat = try XCTUnwrap(Double(value("F")))
        }

        var identifier: String { "food-result-" + name.lowercased().replacingOccurrences(of: " ", with: "-") }
        var totals: ProductionTotals { ProductionTotals(kcal: scaled(kcal), protein: scaled(protein), carbs: scaled(carbs), fat: scaled(fat)) }
        private func scaled(_ per100: Double) -> Double { per100 * Double(grams) / 100 }

        static func totals(_ foods: [ProductionFood]) -> ProductionTotals {
            foods.map(\.totals).reduce(ProductionTotals(kcal: 0, protein: 0, carbs: 0, fat: 0)) {
                ProductionTotals(kcal: $0.kcal + $1.kcal, protein: $0.protein + $1.protein, carbs: $0.carbs + $1.carbs, fat: $0.fat + $1.fat)
            }
        }
    }

    private func addProductionFood(_ food: ProductionFood, meal: String) {
        let totals = food.totals
        expect(totals.isUnambiguous, "\(food.name) at \(food.grams) g has values whose display rounding is unambiguous")
        tap(app.otherElements["food-log-view"].buttons["add-food-button"], "Search on the selected log date")
        let search = app.otherElements["food-search-sheet"]
        expect(search.waitForExistence(timeout: 5), "The food search opens")
        let field = search.textFields["food-search-field"]
        tap(field, "Search for \(food.name)")
        field.typeText(food.query)
        let swipeTip = app.buttons["Continue"]
        if swipeTip.waitForExistence(timeout: 2) {
            swipeTip.tap()  // iOS keyboard "slide to type" tip on a fresh simulator
        }
        let result = search.buttons[food.identifier].firstMatch
        expect(result.waitForExistence(timeout: 15), "The production database returns \(food.name)")
        for _ in 0..<4 where !result.isHittable {
            search.swipeUp()
        }
        tap(result, "Select \(food.name)")
        let detail = app.otherElements["food-detail-sheet"]
        expect(detail.waitForExistence(timeout: 5), "The selected food's details open")
        expect(detail.staticTexts[food.name].exists, "The detail names \(food.name)")
        // Production foods list many household units; the gram pill can sit past the right edge.
        let gramPill = detail.buttons["serving-pill-g"]
        for _ in 0..<8 where !gramPill.isHittable {
            detail.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'serving-pill-'")).firstMatch.swipeLeft()
        }
        tap(gramPill, "Choose grams")
        setQuantity(String(food.grams), in: detail)
        let shown = totals.shown
        expectDetail(calories: shown.kcal, protein: shown.protein, fat: shown.fat, carbs: shown.carbs)
        let picker = detail.buttons.matching(NSPredicate(
            format: "label == 'Meal' OR label BEGINSWITH 'Meal,' OR label IN %@",
            ["Breakfast", "Lunch", "Dinner", "Snacks"]
        )).firstMatch
        tap(picker, "Choose the meal")
        tap(app.buttons[meal].firstMatch, "Select \(meal)")
        tap(detail.buttons["add-food-button"], "Log \(food.name)")
        expect(detail.waitForNonExistence(timeout: 5), "Food details close after logging")
        expect(search.waitForNonExistence(timeout: 5), "Food search closes after logging")
    }

    private func expectProductionRows(_ foods: [ProductionFood]) {
        let rows = app.otherElements["food-log-view"].buttons.matching(identifier: "food-entry-row")
        waitUntil("Food Log has exactly the \(foods.count) production rows with literal values") {
            let labels = rows.allElementsBoundByIndex.map(\.label)
            guard labels.count == foods.count else { return false }
            return foods.allSatisfy { food in
                let shown = food.totals.shown
                return labels.contains { label in
                    [food.name, "\(shown.protein)P", "\(shown.fat)F", "\(shown.carbs)C", "\(food.grams)g", shown.kcal]
                        .allSatisfy(label.contains)
                }
            }
        }
    }

    private func expectLogTotals(_ totals: ProductionTotals) {
        let shown = totals.shown
        expectLogTotals(calories: "\(shown.kcal)/2000", protein: "\(shown.protein)/150", fat: "\(shown.fat)/65", carbs: "\(shown.carbs)/200")
    }

    private func expectDashboard(_ totals: ProductionTotals) {
        let shown = totals.shown
        expectDashboard(calories: shown.kcal, protein: shown.protein, fat: shown.fat, carbs: shown.carbs)
    }

    private func launch(resetData: Bool) -> XCUIApplication {
        TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: resetData,
            additionalArguments: ["--disable-cloudkit", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"],
            additionalEnvironment: ["TEST_DATA_SEED": "false"]
        )
    }

    private func relaunchWithoutReset() {
        app.terminate()
        app = launch(resetData: false)
        selectedDate = today
        expect(!app.launchArguments.contains("--reset-app-data"), "Relaunch has no reset argument")
        expect(!app.launchArguments.contains(where: { $0.hasPrefix("--seed-") }), "Relaunch has no seed argument")
        expect(app.launchEnvironment["TEST_DATA_SEED"] == "false", "Relaunch disables requested seeding")
        expect(app.tabBars.firstMatch.waitForExistence(timeout: 10), "Relaunch opens the persisted user")
    }

    private func navigate(_ tab: String) {
        tap(app.tabBars.firstMatch.buttons[tab], "Open \(tab)")
    }

    private func expectNoMedicationProfiles() {
        navigate("More")
        tap(app.buttons["glp1-programs-row"], "Open GLP-1 Programs")
        tap(app.segmentedControls["glp1-programs-view"].buttons["Medications"], "View medication profiles")
        expect(app.staticTexts["No medication profiles yet"].waitForExistence(timeout: 5), "The user has no medication profiles")
    }

    private func selectDay(offset: Int) {
        expect(Calendar.current.isDateInToday(today), "The scenario must not cross local midnight")
        navigate("Food Log")
        let date = Calendar.current.date(byAdding: .day, value: offset, to: today)!
        let day = dayCell(date)
        if !day.exists {
            let direction = date < selectedDate ? "Previous week" : "Next week"
            tap(app.buttons[direction], "Navigate to the selected date's week")
        }
        tap(day, "Select the \(offset == 0 ? "current" : "previous") day")
        waitUntil("The calendar selects the requested date") { day.isSelected }
        selectedDate = date
    }

    /// Runtime day cells expose "Weekday, Month D, YYYY[, today], <entry summary>" labels under the
    /// `week-calendar-strip` identifier; the `food-day-N` identifiers are overridden by their container.
    private func dayCell(_ date: Date) -> XCUIElement {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier == 'week-calendar-strip' AND label BEGINSWITH %@", formatter.string(from: date)
        )).firstMatch
    }

    private func addSalmon(grams: String, meal: String) {
        tap(app.otherElements["food-log-view"].buttons["add-food-button"], "Search on the selected log date")
        let search = app.otherElements["food-search-sheet"]
        expect(search.waitForExistence(timeout: 5), "The food search opens")
        let field = search.textFields["food-search-field"]
        tap(field, "Search for the known salmon")
        field.typeText("salmon")
        let result = search.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'food-result-'"))
            .containing(.staticText, identifier: "Salmon, Atlantic, raw").firstMatch
        tap(result, "Select Salmon, Atlantic, raw")
        let detail = app.otherElements["food-detail-sheet"]
        expect(detail.waitForExistence(timeout: 5), "The selected salmon details open")
        expectDetail(calories: "208", protein: "20", fat: "13", carbs: "0")
        tap(detail.buttons["serving-pill-g"], "Choose grams")
        setQuantity(grams, in: detail)
        if grams == "200" {
            expectDetail(calories: "416", protein: "40", fat: "26", carbs: "0")
        } else {
            expect(grams == "100", "The scenario uses a literal 100g or 200g serving")
            expectDetail(calories: "208", protein: "20", fat: "13", carbs: "0")
        }
        let picker = detail.buttons.matching(NSPredicate(
            format: "label == 'Meal' OR label BEGINSWITH 'Meal,' OR label IN %@",
            ["Breakfast", "Lunch", "Dinner", "Snacks"]
        )).firstMatch
        tap(picker, "Choose the meal")
        tap(app.buttons[meal].firstMatch, "Select \(meal)")
        tap(detail.buttons["add-food-button"], "Log the exact salmon serving")
        expect(detail.waitForNonExistence(timeout: 5), "Food details close after logging")
        expect(search.waitForNonExistence(timeout: 5), "Food search closes after logging")
    }

    private func setQuantity(_ value: String, in sheet: XCUIElement) {
        let input = sheet.textFields["quantity-input"]
        tap(input, "Edit the serving quantity")
        guard let previous = input.value as? String else {
            expect(false, "Quantity has a readable value")
            return
        }
        input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: previous.count) + value)
        expect(input.value as? String == value, "Quantity is exactly \(value) grams")
    }

    private func expectDetail(calories: String, protein: String, fat: String, carbs: String) {
        let detail = app.otherElements["food-detail-sheet"]
        for (identifier, label) in [
            ("food-detail-calories", calories), ("food-detail-macro-protein", protein),
            ("food-detail-macro-fat", fat), ("food-detail-macro-carbs", carbs),
        ] {
            let group = detail.descendants(matching: .any)[identifier].firstMatch
            expect(group.staticTexts[label].exists, "\(identifier) displays exactly \(label)")
        }
    }

    private func expectEntries(_ labels: [String]) {
        let rows = app.otherElements["food-log-view"].buttons.matching(identifier: "food-entry-row")
        waitUntil("Food Log has exactly these rows: \(labels)") {
            rows.allElementsBoundByIndex.map(\.label).sorted() == labels.sorted()
        }
    }

    private func expectMeal(_ meal: String, labels: [String]) {
        let headers = app.descendants(matching: .any).matching(identifier: "meal-section-header-\(meal)")
        waitUntil("The selected meal contains exactly \(labels)") {
            let visibleLabels = headers.allElementsBoundByIndex.flatMap {
                [$0.label] + $0.staticTexts.allElementsBoundByIndex.map(\.label)
            }
            return labels.allSatisfy { visibleLabels.contains($0) }
        }
    }

    private func expectDayCount(_ count: Int) {
        let suffix = count == 0 ? "no entries" : "\(count) food \(count == 1 ? "entry" : "entries")"
        let cell = dayCell(selectedDate)
        waitUntil("The selected date has exactly \(count) entries") {
            cell.label.hasSuffix(suffix)
        }
    }

    private func expectLogTotals(calories: String, protein: String, fat: String, carbs: String) {
        for (identifier, label) in [
            ("macro-consumed-cal", calories), ("macro-consumed-protein", protein),
            ("macro-consumed-fat", fat), ("macro-consumed-carbs", carbs),
        ] {
            let total = app.staticTexts.matching(
                NSPredicate(format: "identifier == %@ AND label == %@", identifier, label)
            ).firstMatch
            expect(total.waitForExistence(timeout: 10), "Food Log \(identifier) is exactly \(label)")
        }
    }

    private func expectDashboard(calories: String, protein: String, fat: String, carbs: String) {
        navigate("Dashboard")
        let scroll = app.scrollViews["dashboard-scroll-view"]
        expect(scroll.waitForExistence(timeout: 5), "The dashboard scroll view opens")
        let card = app.descendants(matching: .any)["nutrition-rings-card"].firstMatch
        for _ in 0..<6 where !card.exists || !card.isHittable {
            scroll.swipeUp()
        }
        expect(card.exists && card.isHittable, "The nutrition totals card is reachable")
        for (identifier, label) in [
            ("progress-ring-calories", calories), ("progress-ring-protein", protein),
            ("progress-ring-fat", fat), ("progress-ring-carbs", carbs),
        ] {
            let ring = card.descendants(matching: .any).matching(
                NSPredicate(format: "identifier == %@ AND label == %@", identifier, label)
            ).firstMatch
            expect(ring.waitForExistence(timeout: 10), "Dashboard \(identifier) is exactly \(label)")
        }
    }

    private func expectHundredGramDay() {
        expectEntries(["🐟, Salmon, Atlantic, raw, 20P, 13F, 0C, •, 100g, 208"])
        expectMeal("breakfast", labels: ["Breakfast", "20P", "13F", "0C", "208"])
        expectDayCount(1)
        expectLogTotals(calories: "208/2000", protein: "20/150", fat: "13/65", carbs: "0/200")
    }

    private func expectTwoEntryDay() {
        expectEntries([
            "🐟, Salmon, Atlantic, raw, 20P, 13F, 0C, •, 100g, 208",
            "🐟, Salmon, Atlantic, raw, 40P, 26F, 0C, •, 200g, 416",
        ])
        expectMeal("breakfast", labels: ["Breakfast", "20P", "13F", "0C", "208"])
        expectMeal("lunch", labels: ["Lunch", "40P", "26F", "0C", "416"])
        expectDayCount(2)
        expectLogTotals(calories: "624/2000", protein: "60/150", fat: "39/65", carbs: "0/200")
    }

    private func expectEmptyDay() {
        expectEntries([])
        expectDayCount(0)
        expectLogTotals(calories: "0/2000", protein: "0/150", fat: "0/65", carbs: "0/200")
    }

    private func openEdit(originalGrams: String) {
        tap(app.buttons.matching(identifier: "food-entry-row").firstMatch, "Edit today's only food entry")
        let sheet = app.otherElements["edit-food-entry-sheet"]
        expect(sheet.waitForExistence(timeout: 5), "The edit sheet opens")
        let gramsPill = sheet.buttons["serving-pill-g"]
        let grams = gramsPill.exists ? gramsPill : sheet.buttons["unit-button-g"]
        tap(grams, "Edit the original serving in grams")
        expect(
            sheet.textFields["quantity-input"].value as? String == originalGrams,
            "Edit retains exactly \(originalGrams) grams"
        )
    }

    private func openDeleteConfirmation() {
        let row = app.buttons.matching(identifier: "food-entry-row").firstMatch
        expect(row.waitForExistence(timeout: 5), "The exact entry exists before deletion")
        row.swipeLeft()
        tap(app.buttons["delete-entry-button"], "Request deletion")
        let alert = app.alerts["Delete Entry?"]
        expect(alert.waitForExistence(timeout: 5), "Deletion requires confirmation")
        expect(alert.staticTexts["This will remove Salmon, Atlantic, raw from your log."].exists, "Deletion names the exact food")
    }

    private func openClearDayConfirmation() {
        let summary = app.staticTexts.matching(identifier: "macro-consumed-cal").firstMatch
        expect(summary.waitForExistence(timeout: 5), "The selected day's summary is visible")
        summary.press(forDuration: 1)
        tap(app.buttons["Clear Day (2 items)"], "Request clearing exactly two entries")
        let alert = app.alerts["Clear All Foods?"]
        expect(alert.waitForExistence(timeout: 5), "Clearing the day requires confirmation")
        expect(alert.staticTexts["This will remove 2 items from your log."].exists, "Clear-day confirmation names exactly two entries")
    }

    private func tap(_ element: XCUIElement, _ message: String) {
        expect(element.waitForExistence(timeout: 5), message)
        expect(element.isHittable, "\(message): the control is hittable")
        element.tap()
    }

    private func waitUntil(_ message: String, condition: @escaping () -> Bool) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in condition() }, object: app)
        // 15 s: single accessibility queries took more than 4 s each while the shared host was heavily loaded.
        expect(XCTWaiter.wait(for: [expectation], timeout: 15) == .completed, message)
    }

    private func expect(
        _ condition: @autoclosure () -> Bool, _ message: String,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let passed = condition()
        if !passed {
            capture("nutrition-before-failure", context: message)
        }
        XCTAssertTrue(passed, message, file: file, line: line)
    }

    private func capture(_ name: String, context: String? = nil) {
        captureIndex += 1
        let label = "\(name)-\(captureIndex)"
        TestUtilities.debugScreenshot(app, name: label, context: context)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = label
        attachment.lifetime = .keepAlways
        add(attachment)
        print(app.debugDescription)
    }
}

/// Displayed integers for a production-food run. The caller guarantees no value has a fractional part of .5 or
/// more, so truncating and rounding surfaces agree.
private struct ProductionTotals {
    var kcal: Double, protein: Double, carbs: Double, fat: Double

    struct Shown {
        let kcal: String, protein: String, carbs: String, fat: String
    }

    var shown: Shown {
        Shown(kcal: String(Int(kcal)), protein: String(Int(protein)), carbs: String(Int(carbs)), fat: String(Int(fat)))
    }

    var isUnambiguous: Bool { [kcal, protein, carbs, fat].allSatisfy { $0 - $0.rounded(.down) < 0.5 } }
}
