import Foundation
import OpenChargeCore
@testable import OpenChargeFeatures
import Testing

@Suite("Copy Path action")
struct CopyPathActionTests {
    @Test
    func emptySelectionDoesNotWrite() async {
        let writer = CopyPathWriterProbe()
        let action = CopyPathAction { value in
            try await writer.write(value)
        }

        let result = await action.copy([])

        #expect(
            result
                == .failure(
                    .invalidInput(reasonKey: "feature.copyPath.emptySelection")
                )
        )
        #expect(await writer.values.isEmpty)
    }

    @Test
    func writesAbsolutePathsOnceInInputOrder() async throws {
        let fixture = try makeFixtureDirectory()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let first = try makeFile(named: "first file.txt", in: fixture)
        let second = try makeFile(named: "café 日本語.txt", in: fixture)
        let writer = CopyPathWriterProbe()
        let action = CopyPathAction { value in
            try await writer.write(value)
        }

        let result = await action.copy([second, first, second])
        let paths = [second.path, first.path, second.path]

        #expect(result == .success(CopyPathOutput(paths: paths)))
        #expect(await writer.values == [paths.joined(separator: "\n")])
        #expect(paths.allSatisfy { $0.hasPrefix("/") })
    }

    @Test
    func mixedInvalidInputWritesValidPathsAndReportsPartialSuccess() async throws {
        let fixture = try makeFixtureDirectory()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let valid = try makeFile(named: "valid.txt", in: fixture)
        let missing = fixture.appending(path: "missing.txt")
        let remote = try #require(URL(string: "https://example.com/file.txt"))
        let writer = CopyPathWriterProbe()
        let action = CopyPathAction { value in
            try await writer.write(value)
        }

        let result = await action.copy([missing, valid, remote])

        #expect(
            result
                == .partialSuccess(
                    successes: [CopyPathOutput(paths: [valid.path])],
                    failures: [
                        .invalidInput(
                            reasonKey: "feature.copyPath.missingItem"
                        ),
                        .invalidInput(
                            reasonKey: "feature.copyPath.notFileURL"
                        )
                    ]
                )
        )
        #expect(await writer.values == [valid.path])
    }

    @Test
    func entirelyInvalidSelectionDoesNotWrite() async throws {
        let fixture = try makeFixtureDirectory()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let writer = CopyPathWriterProbe()
        let action = CopyPathAction { value in
            try await writer.write(value)
        }

        let result = await action.copy([
            fixture.appending(path: "missing.txt")
        ])

        #expect(
            result
                == .failure(
                    .invalidInput(
                        reasonKey: "feature.copyPath.noValidSelection"
                    )
                )
        )
        #expect(await writer.values.isEmpty)
    }

    @Test
    func writeFailureReturnsContentFreeSystemError() async throws {
        let fixture = try makeFixtureDirectory()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let file = try makeFile(named: "private-name.txt", in: fixture)
        let writer = CopyPathWriterProbe(shouldFail: true)
        let action = CopyPathAction { value in
            try await writer.write(value)
        }

        let result = await action.copy([file])

        #expect(
            result
                == .failure(
                    .systemFailure(reasonKey: "feature.copyPath.writeFailed")
                )
        )
        #expect(await writer.values == [file.path])
        #expect(!String(describing: result).contains(file.lastPathComponent))
    }

    private func makeFixtureDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "OpenCharge-CopyPath-\(UUID())")
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

private enum CopyPathWriterProbeError: Error {
    case expected
}

private actor CopyPathWriterProbe {
    private let shouldFail: Bool
    private(set) var values: [String] = []

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func write(_ value: String) throws {
        values.append(value)
        if shouldFail {
            throw CopyPathWriterProbeError.expected
        }
    }
}
