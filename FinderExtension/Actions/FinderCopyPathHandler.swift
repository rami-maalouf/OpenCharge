import FinderSync
import OpenChargeFeatures
import OpenChargeSystem

final class FinderCopyPathHandler: NSObject {
    typealias SelectionProvider = () -> [URL]

    @MainActor private static let pasteboard = PasteboardClient()

    private let action: CopyPathAction
    private let selectionProvider: SelectionProvider

    init(
        selectionProvider: @escaping SelectionProvider,
        writeText: @escaping CopyPathAction.TextWriter = { text in
            try await FinderCopyPathHandler.writeToPasteboard(text)
        }
    ) {
        self.selectionProvider = selectionProvider
        action = CopyPathAction(writeText: writeText)
        super.init()
    }

    @objc
    func copyPath(_ sender: Any?) {
        let urls = selectionProvider()
        guard !urls.isEmpty else {
            return
        }

        let action = action
        Task {
            _ = await action.copy(urls)
        }
    }

    private static func writeToPasteboard(_ text: String) async throws {
        try await pasteboard.writePlainText(text)
    }
}
