import XCTest

final class CodeGenTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        self.app = XCUIApplication()
        self.app.launchArguments = ["--ui-testing", "--reset-app-data"]
        self.app.launch()

        // Wait for app to be ready
        XCTAssertTrue(self.app.tabBars.firstMatch.waitForExistence(timeout: 5.0))
    }

    @MainActor
    func testCodeGen() throws {
        // record here
        /*
        let app = XCUIApplication()
        app/*@START_MENU_TOKEN@*/.buttons["sign-in-with-apple-button"]/*[[".otherElements",".buttons[\"Sign in with Apple\"]",".buttons[\"sign-in-with-apple-button\"]",".buttons.firstMatch"],[[[-1,2],[-1,1],[-1,3],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["SIWA_CONTINUE_BUTTON"]/*[[".otherElements[\"AUTHORIZE_BUTTON_TITLE\"].buttons.firstMatch",".otherElements",".buttons[\"Continue with Password\"]",".buttons[\"SIWA_CONTINUE_BUTTON\"]"],[[[-1,3],[-1,2],[-1,1,1],[-1,0]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.secureTextFields["Password"]/*[[".otherElements.secureTextFields[\"Password\"]",".secureTextFields.firstMatch",".secureTextFields[\"Password\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.tables["Empty list"]/*[[".otherElements.tables[\"Empty list\"]",".tables",".containing(.other, identifier: nil).firstMatch",".firstMatch",".tables[\"Empty list\"]"],[[[-1,4],[-1,1,1],[-1,0]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/.tap()

        let onboardingContinueBuButton = app/*@START_MENU_TOKEN@*/.buttons["onboarding-continue-button"]/*[[".otherElements",".buttons[\"Continue\"]",".buttons[\"onboarding-continue-button\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        onboardingContinueBuButton.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Ozempic, Wegovy, Rybelsus (oral), Generic"]/*[[".buttons.staticTexts[\"Ozempic, Wegovy, Rybelsus (oral), Generic\"]",".staticTexts[\"Ozempic, Wegovy, Rybelsus (oral), Generic\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        onboardingContinueBuButton.tap()
        onboardingContinueBuButton.tap()
        onboardingContinueBuButton.tap()
        onboardingContinueBuButton.tap()
        app/*@START_MENU_TOKEN@*/.buttons["onboarding-complete-button"]/*[[".otherElements",".buttons[\"Get Started\"]",".buttons[\"onboarding-complete-button\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Analytics"]/*[[".tabBars.buttons[\"Analytics\"]",".buttons[\"Analytics\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Adherence"]/*[[".segmentedControls.buttons[\"Adherence\"]",".buttons[\"Adherence\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        let element = app.otherElements/*@START_MENU_TOKEN@*/.containing(.other, identifier: "adherence-metrics-card").firstMatch/*[[".element(boundBy: 19)",".containing(.image, identifier: \"adherence-trend-chart\").firstMatch",".containing(.other, identifier: \"streak-counters-card\").firstMatch",".containing(.other, identifier: \"adherence-metrics-card\").firstMatch"],[[[-1,3],[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        element.swipeUp()

        let staticTextsQuery = app.staticTexts
        let element2 = staticTextsQuery.matching(identifier: "adherence-progress-indicator").element(boundBy: 0)
        element2.tap()
        staticTextsQuery.matching(identifier: "adherence-trend-chart").element(boundBy: 0).tap()

        let missedDosePatternElementsQuery = staticTextsQuery.matching(identifier: "missed-dose-pattern-view")
        missedDosePatternElementsQuery.element(boundBy: 0).tap()
        missedDosePatternElementsQuery.element(boundBy: 1).tap()
        element.swipeDown()
        element2.tap()
        element.swipeDown()
        element.swipeDown()
        app/*@START_MENU_TOKEN@*/.staticTexts["Dose Streaks"]/*[[".otherElements.staticTexts[\"Dose Streaks\"]",".staticTexts[\"Dose Streaks\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
*/
    }
}
