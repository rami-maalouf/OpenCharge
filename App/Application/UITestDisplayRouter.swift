import AppKit
import CoreGraphics

@MainActor
final class UITestDisplayRouter: NSObject {
    static let shared = UITestDisplayRouter()

    private var isInstalled = false

    static func installIfRequested(
        arguments: [String] = ProcessInfo.processInfo.arguments
    ) {
        guard arguments.contains("--ui-built-in-display") else {
            return
        }
        shared.install()
    }

    private func install() {
        guard !isInstalled else {
            return
        }
        isInstalled = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
    }

    @objc
    private func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let screen = NSScreen.screens.first(where: Self.isBuiltInScreen)
        else {
            return
        }

        var frame = window.frame
        frame.origin.x = screen.visibleFrame.midX - (frame.width / 2)
        frame.origin.y = screen.visibleFrame.midY - (frame.height / 2)
        window.setFrame(frame, display: true)
    }

    private static func isBuiltInScreen(_ screen: NSScreen) -> Bool {
        guard let screenNumber = screen.deviceDescription[
            NSDeviceDescriptionKey("NSScreenNumber")
        ] as? NSNumber
        else {
            return false
        }
        return CGDisplayIsBuiltin(CGDirectDisplayID(screenNumber.uint32Value)) != 0
    }
}
