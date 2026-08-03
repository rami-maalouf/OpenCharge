@preconcurrency import ApplicationServices
import Foundation
import OpenChargeCore

public struct AccessibilityPermissionProvider: PermissionProviding {
    public static let recoveryURL = URL(
        string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
    )!

    public let kind = PermissionKind.accessibility
    public let recovery = FeatureRecovery(
        kind: .openSystemSettings,
        titleKey: "permission.accessibility.openSettings"
    )

    private let checkTrust: @Sendable () -> Bool
    private let requestTrust: @Sendable () -> Bool

    public init() {
        checkTrust = {
            AXIsProcessTrusted()
        }
        requestTrust = {
            let options = [
                kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
            ] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
    }

    init(
        checkTrust: @escaping @Sendable () -> Bool,
        requestTrust: @escaping @Sendable () -> Bool
    ) {
        self.checkTrust = checkTrust
        self.requestTrust = requestTrust
    }

    public func currentState() async -> PermissionState {
        checkTrust() ? .granted : .denied
    }

    public func requestAccess() async -> PermissionState {
        requestTrust() ? .granted : .denied
    }
}
