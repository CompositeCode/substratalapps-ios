import XCTest

/// Runs against demo data (`-uiTesting`), so it needs no network or account.
@MainActor
final class SmokeTests: XCTestCase {
    func testSignInWithTwoFactorReachesHome() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        let email = app.textFields["Email"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("adron@substratalapps.com")
        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("demo-password")
        app.buttons["Sign in"].tap()

        let code = app.textFields["6-digit code"]
        // The Passwords "Save Password?" sheet (from the username/password content types) covers the form.
        let notNow = app.buttons["Not Now"]
        if notNow.waitForExistence(timeout: 3) { notNow.tap() }
        code.tap()
        code.typeText("123456")
        app.buttons["Verify"].tap()

        // iOS 26's floating tab bar exposes tabs as buttons rather than under `tabBars`.
        XCTAssertTrue(app.buttons["Manage"].firstMatch.waitForExistence(timeout: 10))
    }
}
