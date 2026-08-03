import CoreGraphics
import Foundation
import OpenChargeCore

public struct ScreenRecordingPermissionProvider: PermissionProviding {
    public static let recoveryURL = URL(
        string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture"
    )!

    public let kind = PermissionKind.screenRecording

    private let preflight: @Sendable () -> Bool
    private let request: @Sendable () -> Bool

    public init() {
        preflight = {
            CGPreflightScreenCaptureAccess()
        }
        request = {
            CGRequestScreenCaptureAccess()
        }
    }

    init(
        preflight: @escaping @Sendable () -> Bool,
        request: @escaping @Sendable () -> Bool
    ) {
        self.preflight = preflight
        self.request = request
    }

    public func currentState() async -> PermissionState {
        preflight() ? .granted : .denied
    }

    public func requestAccess() async -> PermissionState {
        request() ? .granted : .denied
    }
}
