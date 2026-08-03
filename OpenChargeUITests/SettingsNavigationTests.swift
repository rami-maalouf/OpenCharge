import XCTest

final class SettingsNavigationTests: XCTestCase {
    @MainActor
    func testOpensSettingsAndNavigatesEverySectionByKeyboard() {
        let app = XCUIApplication()
        app.launch()
        app.activate()
        app.typeKey(",", modifierFlags: .command)

        let settingsWindow = app.windows.firstMatch
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 5))

        let routes = ["general", "menu", "foundation", "finder", "permissions", "about"]
        for (index, route) in routes.enumerated() {
            app.typeKey(String(index + 1), modifierFlags: .command)
            XCTAssertTrue(
                settingsWindow.descendants(matching: .any)["settings.section.\(route)"]
                    .waitForExistence(timeout: 2),
                "Expected settings route \(route)"
            )
        }

        app.terminate()
    }
}
