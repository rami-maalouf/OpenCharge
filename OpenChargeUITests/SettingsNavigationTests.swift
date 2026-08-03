import XCTest

final class SettingsNavigationTests: XCTestCase {
    @MainActor
    func testOpensSettingsAndNavigatesEverySectionByKeyboard() {
        let app = XCUIApplication.openCharge()
        app.launchArguments += ["--ui-in-memory-settings", "--ui-preview-keep-awake"]
        app.launch()
        app.activate()
        app.typeKey(",", modifierFlags: .command)

        let settingsWindow = app.windows.firstMatch
        if !settingsWindow.waitForExistence(timeout: 2) {
            app.activate()
            app.typeKey(",", modifierFlags: .command)
        }
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 5))

        let routes = ["general", "menu", "foundation", "finder", "permissions", "about"]
        for (index, route) in routes.enumerated() {
            let key = String(index + 1)
            let section = settingsWindow.descendants(matching: .any)[
                "settings.section.\(route)"
            ]
            app.typeKey(key, modifierFlags: .command)
            if !section.waitForExistence(timeout: 1) {
                app.activate()
                app.typeKey(key, modifierFlags: .command)
            }
            XCTAssertTrue(
                section.waitForExistence(timeout: 2),
                "Expected settings route \(route)"
            )
        }

        app.terminate()
    }
}
