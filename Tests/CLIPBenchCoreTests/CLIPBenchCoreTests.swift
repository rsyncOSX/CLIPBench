@testable import CLIPBenchCore
import Foundation
import PhotoAIContracts
import Testing

@Suite("CLIPBench core")
struct CLIPBenchCoreTests {
    @Test("Retrieval metrics use ranked relevant files")
    func retrievalMetrics() {
        let metrics = CLIPRetrievalMetrics.evaluate(
            rankedFileNames: [
                "other.jpg",
                "dog-1.jpg",
                "other-2.jpg",
                "dog-2.jpg",
            ],
            relevantFileNames: ["dog-1.jpg", "dog-2.jpg"]
        )

        #expect(abs(metrics.precisionAt5 - 0.4) < 0.0001)
        #expect(abs(metrics.precisionAt10 - 0.2) < 0.0001)
        #expect(abs(metrics.recallAt5 - 1) < 0.0001)
        #expect(abs(metrics.reciprocalRank - 0.5) < 0.0001)
    }

    @Test("Index store rejects another model without deleting its data")
    func indexCompatibility() async throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let fileURL = root.appendingPathComponent("test.clipindex")
        let store = CLIPIndexStore(fileURL: fileURL)
        let first = backend(model: "first")
        try await store.save(CLIPPersistedIndex(
            backend: first,
            entries: []
        ))

        #expect(try await store.load(compatibleWith: first) != nil)
        #expect(
            try await store.load(
                compatibleWith: backend(model: "second")
            ) == nil
        )
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test("Discovery includes photo formats and skips unrelated files")
    func imageDiscovery() throws {
        let root = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        try Data().write(to: root.appendingPathComponent("one.JPG"))
        try Data().write(to: root.appendingPathComponent("two.heic"))
        try Data().write(to: root.appendingPathComponent("notes.txt"))

        let sources = try ImageFileDiscovery.sources(in: root)

        #expect(sources.map(\.displayName) == ["one.JPG", "two.heic"])
    }

    @Test(
        "Default index paths are model-specific",
        arguments: ["model:a", "model/b", "model c"]
    )
    func modelSpecificIndexPath(model: String) {
        let directory = URL(fileURLWithPath: "/tmp/photos")
        let result = CLIPBenchPaths.defaultIndexURL(
            directory: directory,
            modelFingerprint: model
        )

        #expect(result.deletingLastPathComponent().lastPathComponent == ".clipbench")
        #expect(result.pathExtension == "clipindex")
        #expect(!result.lastPathComponent.contains("/"))
    }

    @Test("Long shared model names cannot collide")
    func modelIndexHashing() {
        let directory = URL(fileURLWithPath: "/tmp/photos")
        let sharedPrefix = String(repeating: "same-model-prefix-", count: 20)
        let first = CLIPBenchPaths.defaultIndexURL(
            directory: directory,
            modelFingerprint: sharedPrefix + "first"
        )
        let second = CLIPBenchPaths.defaultIndexURL(
            directory: directory,
            modelFingerprint: sharedPrefix + "second"
        )

        #expect(first != second)
    }

    private func backend(model: String) -> SimilarityBackendDescriptor {
        SimilarityBackendDescriptor(
            backend: "clip",
            modelFingerprint: model,
            representation: "normalized-float-vector-json-v1",
            preprocessingVersion: "test",
            normalizationVersion: "l2-v1",
            configurationVersion: "test"
        )
    }

    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CLIPBenchTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }
}
