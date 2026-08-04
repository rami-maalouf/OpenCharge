import CoreGraphics
import XCTest

enum MenuBarTestSupport {
    static func builtInDisplayBounds() -> CGRect? {
        var displayCount: UInt32 = 0
        guard CGGetActiveDisplayList(0, nil, &displayCount) == .success else {
            return nil
        }

        var displays = [CGDirectDisplayID](
            repeating: 0,
            count: Int(displayCount)
        )
        guard CGGetActiveDisplayList(
            displayCount,
            &displays,
            &displayCount
        ) == .success,
            let display = displays.first(where: { CGDisplayIsBuiltin($0) != 0 })
        else {
            return nil
        }
        return CGDisplayBounds(display)
    }

    @MainActor
    static func revealMenuBar(on displayBounds: CGRect) {
        let point = CGPoint(x: displayBounds.midX, y: displayBounds.minY + 1)
        CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))
    }

    @MainActor
    static func menuBarItem(
        in app: XCUIApplication,
        displayBounds: CGRect
    ) -> XCUIElement {
        let matches = app.statusItems.matching(identifier: "menuBar.openCharge")
        let expandedBounds = displayBounds.insetBy(dx: -1, dy: -30)
        return matches.allElementsBoundByIndex.first { element in
            expandedBounds.contains(
                CGPoint(x: element.frame.midX, y: element.frame.midY)
            )
        } ?? matches.firstMatch
    }
}
