import XCTest

extension XCUIApplication {
    static func openCharge() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-built-in-display")
        return app
    }
}
