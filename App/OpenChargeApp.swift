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
        let model = AppModel(dependencies: dependencies)
        _model = State(initialValue: model)
        applicationDelegate.configure(
            lifecycleController: AppLifecycleController(
                keepAwakeAction: dependencies.keepAwakeAction
            ),
            servicesProvider: ServicesProvider(),
            launchHandler: {
                Task {
                    await model.load()
                }
            }
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(appModel: model)
        } label: {
            Label(
                "OpenCharge",
                systemImage: model.menu.preferences.iconChoice.systemImage
            )
            .accessibilityLabel("OpenCharge")
            .accessibilityIdentifier(AccessibilityID.menuBar)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(appModel: model)
        }
    }
}
