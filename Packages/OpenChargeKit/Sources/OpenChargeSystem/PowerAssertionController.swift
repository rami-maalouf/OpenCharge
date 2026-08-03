import Foundation
@preconcurrency import IOKit.pwr_mgt
import OpenChargeCore

enum PowerAssertionKind: Hashable {
    case display
    case idleSystem

    var assertionType: CFString {
        switch self {
        case .display:
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString
        case .idleSystem:
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString
        }
    }
}

enum PowerAssertionControllerError: Error {
    case creationFailed(kind: PowerAssertionKind, code: IOReturn)
    case releaseFailed(id: IOPMAssertionID, code: IOReturn)
}

public actor PowerAssertionController: KeepAwakeControlling {
    private static let creationOrder: [PowerAssertionKind] = [
        .idleSystem,
        .display
    ]
    private static let releaseOrder: [PowerAssertionKind] = [
        .display,
        .idleSystem
    ]

    private let createAssertion: @Sendable (PowerAssertionKind) throws -> IOPMAssertionID
    private let releaseAssertion: @Sendable (IOPMAssertionID) throws -> Void
    private var assertions: [PowerAssertionKind: PowerAssertionLease] = [:]

    public init() {
        createAssertion = Self.createLiveAssertion
        releaseAssertion = Self.releaseLiveAssertion
    }

    init(
        createAssertion: @escaping @Sendable (PowerAssertionKind) throws -> IOPMAssertionID,
        releaseAssertion: @escaping @Sendable (IOPMAssertionID) throws -> Void
    ) {
        self.createAssertion = createAssertion
        self.releaseAssertion = releaseAssertion
    }

    public func currentConfiguration() -> KeepAwakeConfiguration {
        let hasIdleSystemAssertion = assertions[.idleSystem] != nil
        let hasDisplayAssertion = assertions[.display] != nil

        if hasIdleSystemAssertion, hasDisplayAssertion {
            return .idleSystemAndDisplay
        }
        if hasIdleSystemAssertion {
            return .idleSystem
        }
        return .disabled
    }

    @discardableResult
    public func apply(
        _ configuration: KeepAwakeConfiguration
    ) throws -> KeepAwakeConfiguration {
        let desiredKinds = Self.requiredKinds(for: configuration)
        let currentKinds = Set(assertions.keys)
        guard desiredKinds != currentKinds else {
            return currentConfiguration()
        }

        var createdKinds: [PowerAssertionKind] = []
        do {
            for kind in Self.creationOrder
                where desiredKinds.contains(kind) && assertions[kind] == nil
            {
                let id = try createAssertion(kind)
                assertions[kind] = PowerAssertionLease(
                    id: id,
                    releaseAssertion: releaseAssertion
                )
                createdKinds.append(kind)
            }
        } catch {
            rollbackCreatedAssertions(createdKinds)
            throw error
        }

        for kind in Self.releaseOrder
            where !desiredKinds.contains(kind)
        {
            guard let lease = assertions[kind] else {
                continue
            }
            try lease.release()
            assertions[kind] = nil
        }

        return currentConfiguration()
    }

    private func rollbackCreatedAssertions(
        _ createdKinds: [PowerAssertionKind]
    ) {
        for kind in createdKinds.reversed() {
            guard let lease = assertions[kind] else {
                continue
            }
            do {
                try lease.release()
                assertions[kind] = nil
            } catch {
                // the lease remains owned and will be retried during a later transition or teardown.
            }
        }
    }

    private static func requiredKinds(
        for configuration: KeepAwakeConfiguration
    ) -> Set<PowerAssertionKind> {
        switch configuration {
        case .disabled:
            []
        case .idleSystem:
            [.idleSystem]
        case .idleSystemAndDisplay:
            [.idleSystem, .display]
        }
    }

    private static func createLiveAssertion(
        kind: PowerAssertionKind
    ) throws -> IOPMAssertionID {
        var id = IOPMAssertionID(kIOPMNullAssertionID)
        let code = IOPMAssertionCreateWithName(
            kind.assertionType,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "OpenCharge Keep Awake" as CFString,
            &id
        )
        guard code == kIOReturnSuccess else {
            throw PowerAssertionControllerError.creationFailed(
                kind: kind,
                code: code
            )
        }
        return id
    }

    private static func releaseLiveAssertion(
        id: IOPMAssertionID
    ) throws {
        let code = IOPMAssertionRelease(id)
        guard code == kIOReturnSuccess else {
            throw PowerAssertionControllerError.releaseFailed(id: id, code: code)
        }
    }
}

private final class PowerAssertionLease: @unchecked Sendable {
    private let id: IOPMAssertionID
    private let lock = NSLock()
    private let releaseAssertion: @Sendable (IOPMAssertionID) throws -> Void
    private var isOwned = true

    init(
        id: IOPMAssertionID,
        releaseAssertion: @escaping @Sendable (IOPMAssertionID) throws -> Void
    ) {
        self.id = id
        self.releaseAssertion = releaseAssertion
    }

    deinit {
        try? release()
    }

    func release() throws {
        try lock.withLock {
            guard isOwned else {
                return
            }
            try releaseAssertion(id)
            isOwned = false
        }
    }
}
