import AppKit
import OpenChargeCore
import OpenChargeFeatures
import OpenChargeSystem
import SwiftUI

@main
struct OpenChargeApp: App {
    var body: some Scene {
        MenuBarExtra("OpenCharge", systemImage: "bolt.fill") {
            Text("OpenCharge")
            Text("macOS \(OpenChargeCoreModule.minimumSystemVersion) or later")
                .foregroundStyle(.secondary)

            Divider()

            Button("Quit OpenCharge") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}
