import XCTest

final class PermissionsTests: XCTestCase {
    @MainActor
    func testRendersDeterministicPermissionDiagnosticsWithoutPrompting() {
        let app = XCUIApplication.openCharge()
        app.launchArguments += [
            "--ui-in-memory-settings",
            "--ui-preview-keep-awake",
            "--ui-permission-screenRecording", "denied",
            "--ui-permission-accessibility", "granted",
            "--ui-permission-automation", "restricted",
            "--ui-permission-finderSync", "unavailable"
        ]

        app.launch()
        app.activate()
        app.typeKey(",", modifierFlags: .command)
        app.typeKey("5", modifierFlags: .command)

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))

        assertPermission(
            .screenRecording,
            status: "denied",
            in: window
        )
        assertPermission(
            .accessibility,
            status: "granted",
            in: window
        )
        assertPermission(
            .automation,
            status: "restricted",
            in: window
        )
        assertPermission(
            .finderSync,
            status: "unavailable",
            in: window
        )

        XCTAssertTrue(
            window.buttons["permissions.action.screenRecording.request"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertFalse(
            window.buttons["permissions.action.accessibility.request"].exists
        )
        XCTAssertTrue(window.staticTexts["Permission issues affect only related features."].exists)

        let screenshot = XCTAttachment(screenshot: window.screenshot())
        screenshot.name = "permission diagnostics mixed states"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.terminate()
    }

    @MainActor
    func testRendersNotDeterminedStateAndExplanationBeforeRequest() {
        let app = XCUIApplication.openCharge()
        app.launchArguments += [
            "--ui-in-memory-settings",
            "--ui-preview-keep-awake",
            "--ui-permission-screenRecording", "notDetermined",
            "--ui-permission-accessibility", "granted",
            "--ui-permission-automation", "granted",
            "--ui-permission-finderSync", "granted"
        ]

        app.launch()
        app.activate()
        app.typeKey(",", modifierFlags: .command)
        app.typeKey("5", modifierFlags: .command)

        let window = app.windows.firstMatch
        XCTAssertTrue(
            window.staticTexts["permissions.explanation.screenRecording"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            window.staticTexts["permissions.status.screenRecording.notDetermined"].exists
        )
        XCTAssertTrue(
            window.buttons["permissions.action.screenRecording.request"].exists
        )

        app.terminate()
    }

    @MainActor
    private func assertPermission(
        _ kind: PermissionKind,
        status: String,
        in window: XCUIElement
    ) {
        XCTAssertTrue(
            window.groups["permissions.row.\(kind.rawValue)"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertTrue(
            window.staticTexts["permissions.explanation.\(kind.rawValue)"].exists
        )
        XCTAssertTrue(
            window.staticTexts["permissions.status.\(kind.rawValue).\(status)"].exists
        )
    }
}

private enum PermissionKind: String {
    case accessibility
    case automation
    case finderSync
    case screenRecording
}
