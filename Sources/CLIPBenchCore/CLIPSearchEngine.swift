import CoreAICLIPBackend
import Foundation
import PhotoAIContracts
import PhotoAIWorkflows

public struct CLIPIndexSummary: Codable, Equatable, Sendable {
    public let discovered: Int
    public let reused: Int
    public let indexed: Int
    public let failures: [String]

    public init(
        discovered: Int,
        reused: Int,
        indexed: Int,
        failures: [String]
    ) {
        self.discovered = discovered
        self.reused = reused
        self.indexed = indexed
        self.failures = failures
    }
}

public struct CLIPSearchResult: Codable, Equatable, Sendable {
    public let rank: Int
    public let score: Float
    public let fileName: String
    public let path: String

    public init(rank: Int, score: Float, fileName: String, path: String) {
        self.rank = rank
        self.score = score
        self.fileName = fileName
        self.path = path
    }
}

public struct CLIPIndexingProgress: Sendable {
    public let completed: Int
    public let total: Int
    public let currentFileName: String?
}

public final class CLIPSearchEngine: Sendable {
    public let provider: CoreAICLIPProvider
    public let indexStore: CLIPIndexStore
    public let decoder: ImageIOImageDecoder
    public let concurrencyLimit: Int

    public init(
        provider: CoreAICLIPProvider,
        indexStore: CLIPIndexStore,
        decoder: ImageIOImageDecoder = ImageIOImageDecoder(),
        concurrencyLimit: Int = 2
    ) {
        self.provider = provider
        self.indexStore = indexStore
        self.decoder = decoder
        self.concurrencyLimit = max(1, concurrencyLimit)
    }

    public func synchronize(
        directory: URL,
        progress: (@Sendable (CLIPIndexingProgress) async -> Void)? = nil
    ) async throws -> CLIPIndexSummary {
        let sources = try ImageFileDiscovery.sources(in: directory)
        let oldIndex = try await indexStore.load(
            compatibleWith: provider.backendDescriptor
        )
        let oldEntries = Dictionary(
            uniqueKeysWithValues: (oldIndex?.entries ?? []).map {
                ($0.fingerprint.standardizedPath, $0)
            }
        )
        var entries = [CLIPIndexEntry]()
        var pending = [AIImageSource]()
        for source in sources {
            let fingerprint = SourceFingerprint(source: source)
            if let existing = oldEntries[fingerprint.standardizedPath],
               existing.fingerprint == fingerprint,
               existing.artifact.descriptor.matches(
                   provider.backendDescriptor
               ) {
                entries.append(CLIPIndexEntry(
                    source: source,
                    fingerprint: fingerprint,
                    artifact: existing.artifact
                ))
            } else {
                pending.append(source)
            }
        }

        if !pending.isEmpty {
            let pendingSources = pending
            let indexer = SimilarityArtifactIndexer(
                primaryProvider: provider,
                decoder: decoder,
                concurrencyLimit: concurrencyLimit
            )
            let result = try await indexer.index(pendingSources) { update in
                let currentName = pendingSources.first {
                    $0.id == update.currentSourceID
                }?.displayName
                await progress?(CLIPIndexingProgress(
                    completed: update.completed,
                    total: update.total,
                    currentFileName: currentName
                ))
            }
            for source in pendingSources {
                guard let artifact = result.artifacts[source.id] else {
                    continue
                }
                entries.append(CLIPIndexEntry(
                    source: source,
                    fingerprint: SourceFingerprint(source: source),
                    artifact: artifact
                ))
            }
            entries.sort {
                $0.source.url.path.localizedStandardCompare(
                    $1.source.url.path
                ) == .orderedAscending
            }
            try await indexStore.save(CLIPPersistedIndex(
                backend: provider.backendDescriptor,
                entries: entries
            ))
            return CLIPIndexSummary(
                discovered: sources.count,
                reused: sources.count - pendingSources.count,
                indexed: result.artifacts.count,
                failures: result.failures.map {
                    "\($0.source.displayName): \($0.message)"
                }
            )
        }

        // Re-save so removed files disappear from the durable index.
        try await indexStore.save(CLIPPersistedIndex(
            backend: provider.backendDescriptor,
            entries: entries
        ))
        return CLIPIndexSummary(
            discovered: sources.count,
            reused: entries.count,
            indexed: 0,
            failures: []
        )
    }

    public func search(
        text: String,
        limit: Int
    ) async throws -> [CLIPSearchResult] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw CLIPBenchError.emptyQuery
        }
        guard let index = try await indexStore.load(
            compatibleWith: provider.backendDescriptor
        ) else {
            throw CLIPBenchError.missingCompatibleIndex
        }
        let textEmbedding = try await provider.embedding(for: text)
        let scored = try index.entries.map { entry in
            (
                entry,
                try provider.similarity(
                    image: entry.artifact,
                    text: textEmbedding
                )
            )
        }
        .sorted {
            if $0.1 == $1.1 {
                return $0.0.source.url.path < $1.0.source.url.path
            }
            return $0.1 > $1.1
        }
        return scored.prefix(max(0, limit)).enumerated().map {
            offset,
            item in
            CLIPSearchResult(
                rank: offset + 1,
                score: item.1,
                fileName: item.0.source.displayName,
                path: item.0.source.url.path
            )
        }
    }
}
