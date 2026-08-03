import FinderSync

final class FinderSyncController: FIFinderSync {
    override init() {
        super.init()
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        NSMenu(title: "OpenCharge")
    }
}
