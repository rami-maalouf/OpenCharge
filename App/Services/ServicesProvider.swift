import AppKit
import OpenChargeCore

@MainActor
final class ServicesProvider: NSObject {
    private let copyPathService: CopyPathService

    init(copyPathService: CopyPathService = CopyPathService()) {
        self.copyPathService = copyPathService
        super.init()
    }

    @objc
    func copyPath(
        _ pasteboard: NSPasteboard,
        userData _: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        let fileURLs = copyPathService.fileURLs(from: pasteboard)
        guard !fileURLs.isEmpty else {
            error.pointee = "Select one or more files or folders."
            return
        }

        error.pointee = nil
        Task { @MainActor in
            let result = await copyPathService.copy(fileURLs)
            if case .failure = result {
                NSSound.beep()
            }
        }
    }
}
