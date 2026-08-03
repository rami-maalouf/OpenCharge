import XCTest

final class GeneralAndAboutTests: XCTestCase {
    @MainActor
    func testGeneralAndAboutExposeExpectedControlsAndLinks() {
        let app = XCUIApplication()
        app.launch()
        openSettings(in: app)

        let settingsWindow = app.windows.firstMatch
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 5))

        app.typeKey("1", modifierFlags: .command)
        XCTAssertTrue(
            settingsWindow.descendants(matching: .any)["settings.general.launchAtLogin"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(
            settingsWindow.descendants(matching: .any)["settings.general.appearance"].exists
        )

        app.typeKey("6", modifierFlags: .command)
        XCTAssertTrue(settingsWindow.staticTexts["OpenCharge"].waitForExistence(timeout: 2))
        XCTAssertTrue(settingsWindow.links["MIT License"].exists)
        XCTAssertTrue(settingsWindow.links["Privacy"].exists)
        XCTAssertTrue(settingsWindow.links["OpenCharge Repository"].exists)
        XCTAssertTrue(settingsWindow.links["Orbit Labs"].exists)

        app.terminate()
    }

    @MainActor
    private func openSettings(in app: XCUIApplication) {
        let statusItem = app.menuBars.statusItems["OpenCharge"]
        XCTAssertTrue(statusItem.waitForExistence(timeout: 5))
        statusItem.click()

        let settingsItem = app.menuItems["Settings..."]
        XCTAssertTrue(settingsItem.waitForExistence(timeout: 2))
        settingsItem.click()
    }
}
