import AppKit
import OpenChargeCore
import OpenChargeFeatures
import OpenChargeSystem
import SwiftUI

@main
struct OpenChargeApp: App {
    @NSApplicationDelegateAdaptor(OpenChargeApplicationDelegate.self)
    private var applicationDelegate

    @State private var model: AppModel

    init() {
        self.init(dependencies: .live)
    }

    init(dependencies: AppDependencies) {
        UITestDisplayRouter.installIfRequested()
        KeepAwakeIntentDependency.register(dependencies.keepAwakeAction)
        _model = State(initialValue: AppModel(dependencies: dependencies))
        applicationDelegate.configure(
            lifecycleController: AppLifecycleController(
                keepAwakeAction: dependencies.keepAwakeAction
            )
        )
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
