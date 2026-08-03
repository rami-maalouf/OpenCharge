import XCTest

final class SettingsNavigationTests: XCTestCase {
    @MainActor
    func testOpensSettingsAndNavigatesEverySectionByKeyboard() {
        let app = XCUIApplication()
        app.launch()

        let statusItem = app.menuBars.statusItems["OpenCharge"]
        XCTAssertTrue(statusItem.waitForExistence(timeout: 5))
        statusItem.click()

        let settingsItem = app.menuItems["Settings..."]
        XCTAssertTrue(settingsItem.waitForExistence(timeout: 2))
        settingsItem.click()

        let settingsWindow = app.windows.firstMatch
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 5))

        let routes = ["general", "menu", "foundation", "finder", "permissions", "about"]
        for (index, route) in routes.enumerated() {
            app.typeKey(String(index + 1), modifierFlags: .command)
            XCTAssertTrue(
                settingsWindow.staticTexts["settings.section.\(route)"].waitForExistence(timeout: 2),
                "Expected settings route \(route)"
            )
        }

        app.terminate()
    }
}
