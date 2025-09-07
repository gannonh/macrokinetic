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
  
        let app = XCUIApplication()
        let onboardingContinueBuButton = app/*@START_MENU_TOKEN@*/.buttons["onboarding-continue-button"]/*[[".otherElements",".buttons[\"Continue\"]",".buttons[\"onboarding-continue-button\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        onboardingContinueBuButton.tap()
        app/*@START_MENU_TOKEN@*/.buttons["medication-semaglutide"]/*[[".buttons",".containing(.staticText, identifier: \"7.0 days\").firstMatch",".containing(.staticText, identifier: \"Ozempic, Wegovy, Rybelsus (oral), Generic\").firstMatch",".containing(.staticText, identifier: \"Semaglutide\").firstMatch",".otherElements",".buttons[\"Semaglutide - Ozempic, Wegovy, Rybelsus (oral), Generic\"]",".buttons[\"medication-semaglutide\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/.tap()
        onboardingContinueBuButton.tap()
        onboardingContinueBuButton.tap()
        onboardingContinueBuButton.tap()
        onboardingContinueBuButton.tap()
        app/*@START_MENU_TOKEN@*/.buttons["onboarding-complete-button"]/*[[".otherElements",".buttons[\"Get Started\"]",".buttons[\"onboarding-complete-button\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Settings"]/*[[".tabBars.buttons[\"Settings\"]",".buttons[\"Settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Medication Profiles"]/*[[".buttons",".containing(.image, identifier: \"Forward\").firstMatch",".containing(.staticText, identifier: \"Manage your medications and calculations\").firstMatch",".containing(.staticText, identifier: \"Medication Profiles\").firstMatch",".otherElements",".buttons[\"Medication Profiles, Manage your medications and calculations\"]",".buttons[\"Medication Profiles\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["Add Medication Profile"]/*[[".navigationBars",".buttons[\"Add\"]",".buttons[\"Add Medication Profile\"]"],[[[-1,2],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["0.25 mg"]/*[[".buttons[\"dose-picker\"].staticTexts.firstMatch",".buttons.staticTexts[\"0.25 mg\"]",".staticTexts[\"0.25 mg\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
            
    }
}
