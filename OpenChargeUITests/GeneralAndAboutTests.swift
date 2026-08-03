import XCTest

final class GeneralAndAboutTests: XCTestCase {
    @MainActor
    func testGeneralAndAboutExposeExpectedControlsAndLinks() {
        let app = XCUIApplication.openCharge()
        app.launchArguments += ["--ui-in-memory-settings", "--ui-preview-keep-awake"]
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
        XCTAssertTrue(settingsWindow.descendants(matching: .any)["settings.about.license"].exists)
        XCTAssertTrue(settingsWindow.descendants(matching: .any)["settings.about.privacy"].exists)
        XCTAssertTrue(settingsWindow.descendants(matching: .any)["settings.about.repository"].exists)
        XCTAssertTrue(settingsWindow.descendants(matching: .any)["settings.about.website"].exists)

        app.terminate()
    }

    @MainActor
    private func openSettings(in app: XCUIApplication) {
        app.activate()
        app.typeKey(",", modifierFlags: .command)
    }
}
