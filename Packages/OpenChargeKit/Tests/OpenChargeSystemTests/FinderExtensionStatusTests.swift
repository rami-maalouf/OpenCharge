import Foundation
import OpenChargeCore
@testable import OpenChargeSystem
import Testing

@Suite("Finder extension status")
struct FinderExtensionStatusTests {
    @Test
    func reportsInstalledAndEnabledWithoutClaimingMenuVisibility() async {
        let probe = FinderExtensionProbe(
            installationResult: .success(true),
            enablementResult: .success(true)
        )
        let provider = makeProvider(probe: probe)

        let status = await provider.currentStatus()

        #expect(status.installation == .installed)
        #expect(status.activation == .enabled)
        #expect(status.menuVisibility == .unknown)
        #expect(probe.installationCallCount == 1)
        #expect(probe.enablementCallCount == 1)
        #expect(probe.managementCallCount == 0)
    }

    @Test
    func reportsInstalledButDisabled() async {
        let probe = FinderExtensionProbe(
            installationResult: .success(true),
            enablementResult: .success(false)
        )
        let provider = makeProvider(probe: probe)

        let status = await provider.currentStatus()
        let permissionState = await provider.currentState()

        #expect(status.installation == .installed)
        #expect(status.activation == .disabled)
        #expect(permissionState == .denied)
    }

    @Test
    func notInstalledSkipsEnablementQuery() async {
        let probe = FinderExtensionProbe(
            installationResult: .success(false),
            enablementResult: .failure(.queryFailed)
        )
        let provider = makeProvider(probe: probe)

        let status = await provider.currentStatus()

        #expect(status.installation == .notInstalled)
        #expect(
            status.activation
                == .unavailable(reasonKey: "permission.finderSync.notInstalled")
        )
        #expect(probe.installationCallCount == 1)
        #expect(probe.enablementCallCount == 0)
    }

    @Test
    func isolatesInstallationAndEnablementFailures() async {
        let installationProbe = FinderExtensionProbe(
            installationResult: .failure(.queryFailed),
            enablementResult: .success(true)
        )
        let installationStatus = await makeProvider(
            probe: installationProbe
        ).currentStatus()

        #expect(
            installationStatus.installation
                == .unavailable(reasonKey: "permission.finderSync.installationCheckFailed")
        )
        #expect(
            installationStatus.activation
                == .unavailable(reasonKey: "permission.finderSync.installationCheckFailed")
        )
        #expect(installationProbe.enablementCallCount == 0)

        let enablementProbe = FinderExtensionProbe(
            installationResult: .success(true),
            enablementResult: .failure(.queryFailed)
        )
        let enablementStatus = await makeProvider(
            probe: enablementProbe
        ).currentStatus()

        #expect(enablementStatus.installation == .installed)
        #expect(
            enablementStatus.activation
                == .unavailable(reasonKey: "permission.finderSync.enablementCheckFailed")
        )
    }

    @Test
    @MainActor
    func managementInterfaceOpensOnlyOnExplicitAction() {
        let probe = FinderExtensionProbe(
            installationResult: .success(true),
            enablementResult: .success(false)
        )
        let provider = makeProvider(probe: probe)

        #expect(probe.managementCallCount == 0)
        provider.openManagementInterface()
        #expect(probe.managementCallCount == 1)
    }

    private func makeProvider(
        probe: FinderExtensionProbe
    ) -> FinderExtensionStatusProvider {
        FinderExtensionStatusProvider(
            isInstalled: probe.isInstalled,
            isEnabled: probe.isEnabled,
            showManagement: probe.showManagement
        )
    }
}

private enum FinderExtensionProbeError: Error {
    case queryFailed
}

private final class FinderExtensionProbe: @unchecked Sendable {
    private let lock = NSLock()
    private let installationResult: Result<Bool, FinderExtensionProbeError>
    private let enablementResult: Result<Bool, FinderExtensionProbeError>
    private var storedInstallationCallCount = 0
    private var storedEnablementCallCount = 0
    private var storedManagementCallCount = 0

    init(
        installationResult: Result<Bool, FinderExtensionProbeError>,
        enablementResult: Result<Bool, FinderExtensionProbeError>
    ) {
        self.installationResult = installationResult
        self.enablementResult = enablementResult
    }

    var installationCallCount: Int {
        lock.withLock { storedInstallationCallCount }
    }

    var enablementCallCount: Int {
        lock.withLock { storedEnablementCallCount }
    }

    var managementCallCount: Int {
        lock.withLock { storedManagementCallCount }
    }

    func isInstalled() throws -> Bool {
        lock.withLock {
            storedInstallationCallCount += 1
        }
        return try installationResult.get()
    }

    func isEnabled() throws -> Bool {
        lock.withLock {
            storedEnablementCallCount += 1
        }
        return try enablementResult.get()
    }

    @MainActor
    func showManagement() {
        lock.withLock {
            storedManagementCallCount += 1
        }
    }
}
