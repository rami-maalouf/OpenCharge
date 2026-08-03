import XCTest

final class AccessibilitySmokeTests: XCTestCase {
    @MainActor
    func testShellExposesStableIdentifiersAndVoiceOverNames() {
        let app = XCUIApplication()
        app.launch()

        let statusItem = app.menuBars.statusItems["menuBar.openCharge"]
        XCTAssertTrue(statusItem.waitForExistence(timeout: 5))
        XCTAssertEqual(statusItem.identifier, "menuBar.openCharge")

        app.activate()
        app.typeKey(",", modifierFlags: .command)

        let settingsWindow = app.windows.firstMatch
        XCTAssertTrue(settingsWindow.waitForExistence(timeout: 5))

        let sections = [
            ("general", "General"),
            ("menu", "Menu"),
            ("foundation", "Foundation"),
            ("finder", "Finder"),
            ("permissions", "Permissions"),
            ("about", "About")
        ]
        for (route, title) in sections {
            let sidebarItem = settingsWindow.descendants(matching: .any)[
                "settings.sidebar.\(route)"
            ]
            XCTAssertTrue(sidebarItem.exists)
            XCTAssertEqual(sidebarItem.label, title)
        }

        let loginItem = settingsWindow.descendants(matching: .any)[
            "settings.general.launchAtLogin"
        ]
        XCTAssertEqual(loginItem.label, "Launch OpenCharge at login")

        let appearance = settingsWindow.descendants(matching: .any)[
            "settings.general.appearance"
        ]
        XCTAssertEqual(appearance.label, "Appearance")

        let aboutSidebarItem = settingsWindow.descendants(matching: .any)[
            "settings.sidebar.about"
        ]
        aboutSidebarItem.click()
        XCTAssertTrue(
            settingsWindow.descendants(matching: .any)["settings.section.about"]
                .waitForExistence(timeout: 2)
        )
        let links = [
            ("settings.about.license", "MIT License"),
            ("settings.about.privacy", "Privacy"),
            ("settings.about.repository", "OpenCharge Repository"),
            ("settings.about.website", "Orbit Labs")
        ]
        for (identifier, label) in links {
            let link = settingsWindow.descendants(matching: .any)[identifier]
            XCTAssertTrue(link.waitForExistence(timeout: 2))
            XCTAssertEqual(link.label, label)
        }

        app.terminate()
    }
}
