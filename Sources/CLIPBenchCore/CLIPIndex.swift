import Foundation
import PhotoAIContracts

public struct CLIPIndexEntry: Codable, Equatable, Sendable {
    public let source: AIImageSource
    public let fingerprint: SourceFingerprint
    public let artifact: SimilarityArtifact

    public init(
        source: AIImageSource,
        fingerprint: SourceFingerprint,
        artifact: SimilarityArtifact
    ) {
        self.source = source
        self.fingerprint = fingerprint
        self.artifact = artifact
    }
}

public struct CLIPPersistedIndex: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let backend: SimilarityBackendDescriptor
    public let entries: [CLIPIndexEntry]
    public let updatedAt: Date

    public init(
        schemaVersion: Int = Self.currentSchemaVersion,
        backend: SimilarityBackendDescriptor,
        entries: [CLIPIndexEntry],
        updatedAt: Date = .now
    ) {
        self.schemaVersion = schemaVersion
        self.backend = backend
        self.entries = entries
        self.updatedAt = updatedAt
    }
}

public actor CLIPIndexStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load(
        compatibleWith backend: SimilarityBackendDescriptor
    ) throws -> CLIPPersistedIndex? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        let index = try PropertyListDecoder().decode(
            CLIPPersistedIndex.self,
            from: data
        )
        guard index.schemaVersion == CLIPPersistedIndex.currentSchemaVersion,
              index.backend == backend
        else {
            return nil
        }
        return index
    }

    public func save(_ index: CLIPPersistedIndex) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(index)
        try data.write(to: fileURL, options: .atomic)
    }
}

extension SimilarityArtifactDescriptor {
    func matches(_ backend: SimilarityBackendDescriptor) -> Bool {
        self.backend == backend.backend
            && modelFingerprint == backend.modelFingerprint
            && representation == backend.representation
            && preprocessingVersion == backend.preprocessingVersion
            && normalizationVersion == backend.normalizationVersion
            && configurationVersion == backend.configurationVersion
            && schemaVersion == Self.currentSchemaVersion
    }
}
