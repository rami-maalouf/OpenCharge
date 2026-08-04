import CoreGraphics
import XCTest

final class KeepAwakeTests: XCTestCase {
    @MainActor
    func testSettingsAndMenuShareKeepAwakeState() throws {
        let app = XCUIApplication.openCharge()
        app.launchArguments.append("--ui-in-memory-settings")
        app.launchArguments.append("--ui-preview-keep-awake")
        app.launch()

        openSettings(in: app)
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 2))
        app.typeKey("3", modifierFlags: .command)
        let disabledMode = app.windows.firstMatch.buttons[
            "settings.foundation.keepAwake.mode.disabled"
        ]
        XCTAssertTrue(disabledMode.waitForExistence(timeout: 2))
        XCTAssertTrue(waitForValue("Selected", in: disabledMode))

        let enabledMode = app.windows.firstMatch.buttons[
            "settings.foundation.keepAwake.mode.idleSystem"
        ]
        XCTAssertTrue(enabledMode.waitForExistence(timeout: 2))
        app.activate()
        enabledMode.coordinate(
            withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)
        ).click()
        XCTAssertTrue(waitForValue("Selected", in: enabledMode))

        let status = app.windows.firstMatch.descendants(matching: .any)[
            "settings.foundation.keepAwake.status"
        ]
        XCTAssertTrue(status.waitForExistence(timeout: 2))
        XCTAssertTrue(waitForValue("Preventing system sleep", in: status))

        let displayMode = app.windows.firstMatch.buttons[
            "settings.foundation.keepAwake.mode.idleSystemAndDisplay"
        ]
        XCTAssertTrue(displayMode.waitForExistence(timeout: 2))
        app.activate()
        displayMode.coordinate(
            withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5)
        ).click()
        XCTAssertTrue(waitForValue("Selected", in: displayMode))

        app.activate()
        let settingsWindow = app.windows.firstMatch
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 2))
        let attachment = XCTAttachment(screenshot: settingsWindow.screenshot())
        attachment.name = "Keep Awake display mode"
        attachment.lifetime = .keepAlways
        add(attachment)

        app.typeKey("w", modifierFlags: .command)
        let builtInDisplayBounds = try XCTUnwrap(
            MenuBarTestSupport.builtInDisplayBounds()
        )
        MenuBarTestSupport.revealMenuBar(on: builtInDisplayBounds)
        let menuBarItem = MenuBarTestSupport.menuBarItem(
            in: app,
            displayBounds: builtInDisplayBounds
        )
        XCTAssertTrue(menuBarItem.waitForExistence(timeout: 2))
        menuBarItem.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
        ).click()
        XCTAssertTrue(
            app.menuItems["Keep Awake: System and Display Sleep"]
                .waitForExistence(timeout: 2)
        )

        app.terminate()
    }

    @MainActor
    private func openSettings(in app: XCUIApplication) {
        app.activate()
        app.typeKey(",", modifierFlags: .command)
    }

    @MainActor
    private func waitForValue(
        _ expectedValue: String,
        in element: XCUIElement
    ) -> Bool {
        let predicate = NSPredicate { object, _ in
            (object as? XCUIElement)?.value as? String == expectedValue
        }
        let expectation = XCTNSPredicateExpectation(
            predicate: predicate,
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: 2) == .completed
    }
}
