import AppKit
import OpenChargeCore
import OpenChargeFeatures
import OpenChargeSystem
import SwiftUI

@main
struct OpenChargeApp: App {
    @State private var model: AppModel

    init() {
        self.init(dependencies: .live)
    }

    init(dependencies: AppDependencies) {
        _model = State(initialValue: AppModel(dependencies: dependencies))
    }

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
            .task {
                await model.load()
            }
        }
        .menuBarExtraStyle(.menu)
    }
}
