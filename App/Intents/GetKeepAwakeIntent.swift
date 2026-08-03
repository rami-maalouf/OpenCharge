import AppIntents
import Foundation
import OpenChargeFeatures

enum KeepAwakeIntentDependency {
    nonisolated static let actionKey =
        "studio.orbitlabs.opencharge.keep-awake-action"

    static func register(
        _ action: KeepAwakeAction,
        manager: AppDependencyManager = .shared
    ) {
        manager.add(key: actionKey, dependency: action)
    }
}

struct GetKeepAwakeIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Keep Awake Mode"
    static let description = IntentDescription(
        "Reports the Keep Awake mode currently applied by OpenCharge."
    )
    static var supportedModes: IntentModes {
        .background
    }

    @AppDependency(key: KeepAwakeIntentDependency.actionKey)
    private var action: KeepAwakeAction

    init() {}

    init(action: KeepAwakeAction) {
        self.action = action
    }

    func perform() async throws -> some IntentResult &
        ReturnsValue<KeepAwakeIntentMode> & ProvidesDialog
    {
        let state = await action.refresh()
        let mode = KeepAwakeIntentMode(configuration: state.configuration)
        return .result(value: mode, dialog: mode.currentStatusDialog)
    }
}
