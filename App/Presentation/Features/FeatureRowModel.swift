import OpenChargeCore

struct FeatureRowModel: Identifiable, Equatable {
    let descriptor: FeatureDescriptor
    let isEnabled: Bool
    let availability: FeatureAvailability
    let health: FeatureHealth

    var id: FeatureID {
        descriptor.id
    }

    var titleKey: String {
        descriptor.titleKey
    }

    var descriptionKey: String {
        descriptor.descriptionKey
    }

    var canChangeEnablement: Bool {
        if case .unsupported = availability {
            return false
        }
        return true
    }

    var recovery: FeatureRecovery? {
        availability.recovery ?? health.recovery
    }

    var availabilityMessageKey: String? {
        switch availability {
        case let .missingPermission(reasonKey, _), let .unsupported(reasonKey):
            reasonKey
        case .available, .disabled:
            nil
        }
    }

    var healthMessageKey: String? {
        switch health {
        case let .degraded(messageKey, _), let .failed(messageKey, _):
            messageKey
        case .healthy:
            nil
        }
    }
}
