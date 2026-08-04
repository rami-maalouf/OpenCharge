import AppKit
import OpenChargeCore
import OpenChargeFeatures

actor AppLifecycleController {
    private let keepAwakeAction: KeepAwakeAction
    private var cleanupTask: Task<Void, Never>?

    init(keepAwakeAction: KeepAwakeAction) {
        self.keepAwakeAction = keepAwakeAction
    }

    func prepareForTermination() async {
        if let cleanupTask {
            await cleanupTask.value
            return
        }

        let action = keepAwakeAction
        let task = Task {
            for _ in 0 ..< 2 {
                if case .success = await action.set(.disabled) {
                    return
                }
            }
        }
        cleanupTask = task
        await task.value
    }
}

@MainActor
final class OpenChargeApplicationDelegate: NSObject, NSApplicationDelegate {
    private var hasCompletedTerminationCleanup = false
    private var isTerminationPending = false
    private var launchHandler: (() -> Void)?
    private var lifecycleController: AppLifecycleController?
    private var servicesProvider: ServicesProvider?

    func configure(
        lifecycleController: AppLifecycleController,
        servicesProvider: ServicesProvider,
        launchHandler: @escaping () -> Void = {}
    ) {
        self.lifecycleController = lifecycleController
        self.servicesProvider = servicesProvider
        self.launchHandler = launchHandler
    }

    func applicationDidFinishLaunching(_: Notification) {
        NSApplication.shared.servicesProvider = servicesProvider
        launchHandler?()
        launchHandler = nil
    }

    func applicationShouldTerminate(
        _ sender: NSApplication
    ) -> NSApplication.TerminateReply {
        if hasCompletedTerminationCleanup {
            return .terminateNow
        }
        guard let lifecycleController else {
            return .terminateNow
        }
        guard !isTerminationPending else {
            return .terminateLater
        }

        isTerminationPending = true
        Task { @MainActor [weak self, weak sender] in
            await lifecycleController.prepareForTermination()
            guard let self else {
                sender?.reply(toApplicationShouldTerminate: true)
                return
            }
            hasCompletedTerminationCleanup = true
            isTerminationPending = false
            sender?.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
