import AppIntents
import Foundation
import OpenChargeCore
import OpenChargeFeatures

enum KeepAwakeIntentMode: String, AppEnum {
    case off
    case systemAndDisplaySleep
    case systemSleep

    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Keep Awake Mode"
    )
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .off: "Off",
        .systemSleep: "Prevent System Sleep",
        .systemAndDisplaySleep: "Prevent System and Display Sleep"
    ]

    init(configuration: KeepAwakeConfiguration) {
        self = switch configuration {
        case .disabled:
            .off
        case .idleSystem:
            .systemSleep
        case .idleSystemAndDisplay:
            .systemAndDisplaySleep
        }
    }

    var configuration: KeepAwakeConfiguration {
        switch self {
        case .off:
            .disabled
        case .systemSleep:
            .idleSystem
        case .systemAndDisplaySleep:
            .idleSystemAndDisplay
        }
    }

    var currentStatusDialog: IntentDialog {
        switch self {
        case .off:
            "Keep Awake is off."
        case .systemSleep:
            "OpenCharge is preventing system sleep."
        case .systemAndDisplaySleep:
            "OpenCharge is preventing system and display sleep."
        }
    }

    var updateFailureDialog: IntentDialog {
        switch self {
        case .off:
            "OpenCharge could not update Keep Awake. It remains off."
        case .systemSleep:
            "OpenCharge could not update Keep Awake. It is still preventing system sleep."
        case .systemAndDisplaySleep:
            "OpenCharge could not update Keep Awake. It is still preventing system and display sleep."
        }
    }
}

struct SetKeepAwakeIntent: AppIntent {
    static let title: LocalizedStringResource = "Set Keep Awake Mode"
    static let description = IntentDescription(
        "Controls whether OpenCharge prevents system or display sleep."
    )
    static var supportedModes: IntentModes {
        .background
    }

    @Parameter(
        title: "Mode",
        description: "The sleep behavior OpenCharge should prevent."
    )
    var mode: KeepAwakeIntentMode

    @AppDependency(key: KeepAwakeIntentDependency.actionKey)
    private var action: KeepAwakeAction

    static var parameterSummary: some ParameterSummary {
        Summary("Set Keep Awake to \(\.$mode)")
    }

    init() {}

    init(
        mode: KeepAwakeIntentMode,
        action: KeepAwakeAction
    ) {
        self.mode = mode
        self.action = action
    }

    func perform() async throws -> some IntentResult &
        ReturnsValue<KeepAwakeIntentMode> & ProvidesDialog
    {
        switch await action.set(mode.configuration) {
        case let .success(state):
            let observedMode = KeepAwakeIntentMode(
                configuration: state.configuration
            )
            return .result(
                value: observedMode,
                dialog: observedMode.currentStatusDialog
            )
        case .cancelled, .failure, .partialSuccess:
            let state = await action.currentState()
            let observedMode = KeepAwakeIntentMode(
                configuration: state.configuration
            )
            return .result(
                value: observedMode,
                dialog: observedMode.updateFailureDialog
            )
        }
    }
}
