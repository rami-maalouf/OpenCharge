import XCTest

final class FinderSettingsTests: XCTestCase {
    @MainActor
    func testDisabledExtensionShowsActivationAndServicesGuidance() {
        let app = launchApp(finderState: "denied")
        let window = openFinderSettings(in: app)

        let copyPathToggle = element(
            "settings.finder.copyPath.toggle",
            in: window
        )
        XCTAssertTrue(copyPathToggle.waitForExistence(timeout: 5))
        XCTAssertEqual(
            (copyPathToggle.value as? NSNumber)?.intValue,
            0
        )

        let status = element(
            "settings.finder.extension.status",
            in: window
        )
        XCTAssertTrue(status.waitForExistence(timeout: 2))
        XCTAssertEqual(status.value as? String, "Disabled")
        XCTAssertTrue(
            element("settings.finder.extension.manage", in: window)
                .exists
        )
        XCTAssertTrue(
            element("settings.finder.services.fallback", in: window)
                .exists
        )
        XCTAssertTrue(
            element("settings.finder.services.setup", in: window)
                .exists
        )

        copyPathToggle.click()
        let enabled = NSPredicate(format: "value == 1")
        expectation(for: enabled, evaluatedWith: copyPathToggle)
        waitForExpectations(timeout: 2)

        app.terminate()
    }

    @MainActor
    func testEnabledExtensionReportsActiveState() {
        let app = launchApp(finderState: "granted")
        let window = openFinderSettings(in: app)
        let status = element(
            "settings.finder.extension.status",
            in: window
        )

        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertEqual(status.value as? String, "Enabled")
        XCTAssertTrue(
            element("settings.finder.services.fallback", in: window)
                .exists
        )

        app.terminate()
    }

    @MainActor
    private func launchApp(finderState: String) -> XCUIApplication {
        let app = XCUIApplication.openCharge()
        app.launchArguments += [
            "--ui-in-memory-settings",
            "--ui-preview-keep-awake",
            "--ui-permission-finderSync", finderState
        ]
        app.launch()
        return app
    }

    @MainActor
    private func openFinderSettings(
        in app: XCUIApplication
    ) -> XCUIElement {
        app.activate()
        app.typeKey(",", modifierFlags: .command)
        app.typeKey("4", modifierFlags: .command)
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        return window
    }

    @MainActor
    private func element(
        _ identifier: String,
        in window: XCUIElement
    ) -> XCUIElement {
        window.descendants(matching: .any)[identifier]
    }
}
