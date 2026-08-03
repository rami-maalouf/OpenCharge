import XCTest

final class AppLaunchTests: XCTestCase {
    @MainActor
    func testLaunches() {
        let app = XCUIApplication()

        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        app.terminate()
    }
}
