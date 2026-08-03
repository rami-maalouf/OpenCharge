import AppKit
import Foundation
@testable import OpenCharge
import OpenChargeCore
import OpenChargeFeatures
import XCTest

@MainActor
final class CopyPathServiceTests: XCTestCase {
    func testServiceCopiesMultipleFileURLsInInputOrder() async throws {
        let fixture = try makeFixtureDirectory()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let first = try makeFile(named: "first file.txt", in: fixture)
        let second = try makeFile(named: "café 日本語.txt", in: fixture)
        let input = makePasteboard()
        defer { input.releaseGlobally() }
        XCTAssertTrue(input.writeObjects([second as NSURL, first as NSURL]))
        let output = PasteboardWriterProbe()
        let service = CopyPathService(pasteboard: output)

        let result = await service.copy(from: input)

        XCTAssertEqual(
            result,
            .success(CopyPathOutput(paths: [second.path, first.path]))
        )
        XCTAssertEqual(
            output.plainText,
            [second.path, first.path].joined(separator: "\n")
        )
    }

    func testServiceRejectsPasteboardWithoutFileURLs() async {
        let input = makePasteboard()
        defer { input.releaseGlobally() }
        XCTAssertTrue(input.setString("not a file", forType: .string))
        let output = PasteboardWriterProbe()
        let service = CopyPathService(pasteboard: output)

        let result = await service.copy(from: input)

        XCTAssertEqual(
            result,
            .failure(
                .invalidInput(reasonKey: "feature.copyPath.emptySelection")
            )
        )
        XCTAssertNil(output.plainText)
    }

    func testServiceAcceptsLegacyFinderFilenameLists() async throws {
        let fixture = try makeFixtureDirectory()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let file = try makeFile(named: "legacy file.txt", in: fixture)
        let input = makePasteboard()
        defer { input.releaseGlobally() }
        XCTAssertTrue(
            input.setPropertyList(
                [file.path],
                forType: NSPasteboard.PasteboardType(
                    "NSFilenamesPboardType"
                )
            )
        )
        let output = PasteboardWriterProbe()
        let service = CopyPathService(pasteboard: output)

        let result = await service.copy(from: input)

        XCTAssertEqual(
            result,
            .success(CopyPathOutput(paths: [file.path]))
        )
        XCTAssertEqual(output.plainText, file.path)
    }

    func testInfoPlistDeclaresExactServiceContract() throws {
        let services = try XCTUnwrap(
            Bundle.main.object(forInfoDictionaryKey: "NSServices")
                as? [[String: Any]]
        )
        let copyPath = try XCTUnwrap(
            services.first { $0["NSMessage"] as? String == "copyPath" }
        )

        XCTAssertEqual(copyPath["NSPortName"] as? String, "OpenCharge")
        XCTAssertEqual(
            copyPath["NSSendTypes"] as? [String],
            ["public.file-url", "NSFilenamesPboardType"]
        )
        XCTAssertEqual(
            copyPath["NSSendFileTypes"] as? [String],
            ["public.item"]
        )
        XCTAssertEqual(copyPath["NSReturnTypes"] as? [String], [])
    }

    private func makePasteboard() -> NSPasteboard {
        let pasteboard = NSPasteboard(
            name: NSPasteboard.Name(
                "studio.orbitlabs.opencharge.service-tests.\(UUID())"
            )
        )
        pasteboard.clearContents()
        return pasteboard
    }

    private func makeFixtureDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "OpenCharge-CopyPathService-\(UUID())")
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

@MainActor
private final class PasteboardWriterProbe: PasteboardWriting {
    private(set) var plainText: String?

    func write(_ values: [PasteboardValue]) throws {
        let value = try XCTUnwrap(values.first)
        XCTAssertEqual(
            value.typeIdentifier,
            PasteboardValue.plainTextTypeIdentifier
        )
        plainText = String(decoding: value.data, as: UTF8.self)
    }
}
