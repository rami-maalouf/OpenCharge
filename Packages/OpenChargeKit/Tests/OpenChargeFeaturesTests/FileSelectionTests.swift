import Foundation
import OpenChargeCore
@testable import OpenChargeFeatures
import Testing

@Suite("File selection")
struct FileSelectionTests {
    @Test
    func emptyInputProducesEmptySelection() {
        let selection = FileSelectionNormalizer().normalize([])

        #expect(selection.isEmpty)
        #expect(selection.urls.isEmpty)
        #expect(!selection.hasIssues)
    }

    @Test
    func preservesInputOrderDuplicatesSpacesAndUnicode() throws {
        let fixture = try makeFixtureDirectory()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let first = try makeFile(named: "first file.txt", in: fixture)
        let second = try makeFile(named: "café 日本語.txt", in: fixture)
        let folder = fixture.appending(path: "selected folder", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: false
        )

        let selection = FileSelectionNormalizer().normalize([
            second,
            folder,
            first,
            second
        ])

        #expect(
            selection.urls
                == [second, folder, first, second].map(\.standardizedFileURL)
        )
        #expect(selection.items.map(\.inputIndex) == [0, 1, 2, 3])
        #expect(selection.items.map(\.kind) == [.file, .directory, .file, .file])
        #expect(selection.issues.isEmpty)
    }

    @Test
    func classifiesPackagesAliasesAndSymbolicLinksWithoutResolvingThem() throws {
        let fixture = try makeFixtureDirectory()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let target = try makeFile(named: "target.txt", in: fixture)
        let package = fixture.appending(path: "Example.app", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(
            at: package,
            withIntermediateDirectories: false
        )
        let alias = fixture.appending(path: "Target alias")
        let bookmark = try target.bookmarkData(
            options: .suitableForBookmarkFile,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        try URL.writeBookmarkData(bookmark, to: alias)
        let symbolicLink = fixture.appending(path: "Target link")
        try FileManager.default.createSymbolicLink(
            at: symbolicLink,
            withDestinationURL: target
        )

        let selection = FileSelectionNormalizer().normalize([
            package,
            alias,
            symbolicLink
        ])

        #expect(selection.urls == [package, alias, symbolicLink])
        #expect(selection.items.map(\.kind) == [.package, .alias, .symbolicLink])
        #expect(selection.items[1].url != target)
        #expect(selection.items[2].url != target)
        #expect(selection.issues.isEmpty)
    }

    @Test
    func reportsInvalidAndMissingInputsWithoutDroppingValidSiblings() throws {
        let fixture = try makeFixtureDirectory()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let valid = try makeFile(named: "valid.txt", in: fixture)
        let remote = try #require(URL(string: "https://example.com/file.txt"))
        let relative = try #require(URL(string: "file:relative.txt"))
        let missing = fixture.appending(path: "missing.txt")

        let selection = FileSelectionNormalizer().normalize([
            remote,
            valid,
            relative,
            missing
        ])

        #expect(selection.urls == [valid.standardizedFileURL])
        #expect(selection.items.map(\.inputIndex) == [1])
        #expect(selection.issues.map(\.inputIndex) == [0, 2, 3])
        #expect(
            selection.issues.map(\.reason)
                == [.notFileURL, .relativeFileURL, .missingItem]
        )
        #expect(selection.issues[2].url == missing.standardizedFileURL)
    }

    private func makeFixtureDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "OpenCharge-FileSelection-\(UUID())")
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: false
        )
        return url
    }

    private func makeFile(named name: String, in directory: URL) throws -> URL {
        let url = directory.appending(path: name)
        try Data("fixture".utf8).write(to: url, options: .atomic)
        return url
    }
}
