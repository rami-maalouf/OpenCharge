import CoreGraphics
import XCTest

final class MenuConfigurationTests: XCTestCase {
    @MainActor
    func testFavoritesVisibilityOrderAndIconUpdateTheLiveMenu() throws {
        let app = XCUIApplication.openCharge()
        app.launchArguments += [
            "--ui-in-memory-settings",
            "--ui-preview-keep-awake",
            "--ui-menu-fixtures"
        ]
        app.launch()

        XCTAssertTrue(app.statusItems["menuBar.openCharge"].waitForExistence(timeout: 5))

        app.activate()
        app.typeKey(",", modifierFlags: .command)
        let settingsWindow = app.windows.firstMatch
        if !settingsWindow.waitForExistence(timeout: 2) {
            app.activate()
            app.typeKey(",", modifierFlags: .command)
        }
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 3))
        app.typeKey("2", modifierFlags: .command)

        let captureTextRow = settingsWindow.descendants(matching: .any)[
            "settings.menu.row.foundation.capture-text"
        ]
        let clearClipboardRow = settingsWindow.descendants(matching: .any)[
            "settings.menu.row.foundation.clear-clipboard"
        ]
        let keepAwakeRow = settingsWindow.descendants(matching: .any)[
            "settings.menu.row.foundation.keep-awake"
        ]
        XCTAssertTrue(captureTextRow.waitForExistence(timeout: 3))
        XCTAssertTrue(clearClipboardRow.exists)
        XCTAssertTrue(keepAwakeRow.exists)

        let favoriteButton = settingsWindow.descendants(matching: .any)[
            "settings.menu.favorite.foundation.clear-clipboard"
        ]
        favoriteButton.click()
        XCTAssertTrue(
            waitForValue("Favorite", on: favoriteButton),
            "Expected Clear Clipboard to become a favorite"
        )

        let captureTextVisibility = settingsWindow.descendants(matching: .any)[
            "settings.menu.visibility.foundation.capture-text"
        ]
        captureTextVisibility.click()
        XCTAssertTrue(
            waitForValue("Hidden", on: captureTextVisibility),
            "Expected Capture Text to become hidden"
        )

        let keepAwakeMoveUp = settingsWindow.descendants(matching: .any)[
            "settings.menu.moveUp.foundation.keep-awake"
        ]
        keepAwakeMoveUp.click()
        XCTAssertTrue(
            waitUntil { keepAwakeRow.frame.minY < clearClipboardRow.frame.minY },
            "Expected the keyboard-accessible move control to reorder rows"
        )

        let iconPicker = settingsWindow.descendants(matching: .any)["settings.menu.icon"]
        iconPicker.click()
        app.menuItems["Gauge"].click()

        app.typeKey("w", modifierFlags: .command)
        let builtInDisplayBounds = try XCTUnwrap(
            MenuBarTestSupport.builtInDisplayBounds()
        )
        MenuBarTestSupport.revealMenuBar(on: builtInDisplayBounds)
        let updatedMenuBarItem = MenuBarTestSupport.menuBarItem(
            in: app,
            displayBounds: builtInDisplayBounds
        )
        XCTAssertTrue(updatedMenuBarItem.waitForExistence(timeout: 3))
        updatedMenuBarItem.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)
        ).click()

        let clearClipboardMenuItem = app.menuItems["Clear Clipboard"]
        let keepAwakeMenuItem = app.menuItems.matching(
            NSPredicate(format: "title BEGINSWITH 'Keep Awake:'")
        ).firstMatch
        XCTAssertTrue(clearClipboardMenuItem.waitForExistence(timeout: 3))
        XCTAssertTrue(keepAwakeMenuItem.exists)
        XCTAssertFalse(app.menuItems["Capture Text"].exists)
        let menuTitles = app.menuItems.allElementsBoundByIndex.map(\.title)
        let clearClipboardIndex = try XCTUnwrap(
            menuTitles.firstIndex(of: "Clear Clipboard")
        )
        let keepAwakeIndex = try XCTUnwrap(
            menuTitles.firstIndex(where: { $0.hasPrefix("Keep Awake:") })
        )
        XCTAssertLessThan(clearClipboardIndex, keepAwakeIndex)

        app.terminate()
    }

    @MainActor
    private func waitForValue(_ value: String, on element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "value == %@", value)
        return XCTWaiter.wait(
            for: [XCTNSPredicateExpectation(predicate: predicate, object: element)],
            timeout: 3
        ) == .completed
    }

    @MainActor
    private func waitUntil(_ condition: @escaping () -> Bool) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in condition() },
            object: nil
        )
        return XCTWaiter.wait(for: [expectation], timeout: 3) == .completed
    }
}
