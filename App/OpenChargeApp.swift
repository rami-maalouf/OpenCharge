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
        MenuBarExtra {
            MenuContentView(appModel: model)
        } label: {
            Label("OpenCharge", systemImage: "bolt.fill")
                .accessibilityLabel("OpenCharge")
                .accessibilityIdentifier(AccessibilityID.menuBar)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(appModel: model)
        }
    }
}
