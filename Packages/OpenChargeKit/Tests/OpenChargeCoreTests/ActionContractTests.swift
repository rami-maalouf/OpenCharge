import Foundation
@testable import OpenChargeCore
import Testing

@Suite("Action contracts")
struct ActionContractTests {
    @Test
    func requestCarriesTypedInputAndStableIdentity() throws {
        let featureID = try #require(FeatureID(rawValue: "foundation.keep-awake"))
        let requestID = try #require(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        let request = ActionRequest(
            id: requestID,
            featureID: featureID,
            input: DurationInput(seconds: 900)
        )

        #expect(request.id == requestID)
        #expect(request.featureID == featureID)
        #expect(request.input.seconds == 900)
    }

    @Test
    func progressRejectsInvalidCountsAndCalculatesFraction() throws {
        #expect(ActionProgress(completedUnitCount: -1, totalUnitCount: 1) == nil)
        #expect(ActionProgress(completedUnitCount: 2, totalUnitCount: 1) == nil)

        let progress = try #require(
            ActionProgress(
                completedUnitCount: 1,
                totalUnitCount: 4,
                messageKey: "action.progress.copying"
            )
        )

        #expect(progress.fractionCompleted == 0.25)
        #expect(progress.messageKey == "action.progress.copying")
    }

    @Test
    func resultRepresentsSuccessPartialSuccessCancellationAndFailure() {
        let success = ActionResult<String>.success("done")
        let partial = ActionResult<String>.partialSuccess(
            successes: ["first"],
            failures: [.systemFailure(reasonKey: "action.second.failed")]
        )
        let cancelled = ActionResult<String>.cancelled
        let failure = ActionResult<String>.failure(.invalidInput(reasonKey: "action.input.empty"))

        #expect(success.isSuccess)
        #expect(partial.isPartialSuccess)
        #expect(cancelled.isCancelled)
        #expect(failure.error == .invalidInput(reasonKey: "action.input.empty"))
    }

    @Test
    func errorsCoverRecoverableFailureKinds() {
        let recovery = FeatureRecovery(
            kind: .openSystemSettings,
            titleKey: "recovery.openAccessibilitySettings"
        )
        let errors: [ActionError] = [
            .invalidInput(reasonKey: "action.input.invalid"),
            .unavailable(reasonKey: "action.unavailable", recovery: nil),
            .missingPermission(kind: .accessibility, state: .denied, recovery: recovery),
            .conflict(reasonKey: "action.destination.exists"),
            .partialSuccess(
                succeededCount: 1,
                failedCount: 1,
                reasonKey: "action.partiallySucceeded"
            ),
            .cancelled,
            .systemFailure(reasonKey: "action.system.failed")
        ]

        #expect(errors.count == 7)
        #expect(errors[2].recovery == recovery)
    }

    @Test
    func errorRoundTripsThroughJSON() throws {
        let error = ActionError.missingPermission(
            kind: .screenRecording,
            state: .restricted,
            recovery: FeatureRecovery(
                kind: .openSystemSettings,
                titleKey: "recovery.openScreenRecordingSettings"
            )
        )

        let encoded = try JSONEncoder().encode(error)
        let decoded = try JSONDecoder().decode(ActionError.self, from: encoded)

        #expect(decoded == error)
    }
}

private struct DurationInput: Hashable, Codable {
    let seconds: Int
}
