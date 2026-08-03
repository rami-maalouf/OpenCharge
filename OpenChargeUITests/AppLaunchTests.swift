import XCTest

final class AppLaunchTests: XCTestCase {
    @MainActor
    func testLaunches() {
        let app = XCUIApplication()

        app.launch()

        let isRunning = app.wait(for: .runningBackground, timeout: 5)
            || app.wait(for: .runningForeground, timeout: 1)
        XCTAssertTrue(isRunning)
        app.terminate()
    }
}
