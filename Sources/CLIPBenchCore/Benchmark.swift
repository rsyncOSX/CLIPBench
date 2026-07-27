import Foundation

public struct CLIPBenchmarkManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let collection: String
    public let queries: [CLIPBenchmarkQuery]

    public init(
        schemaVersion: Int = 1,
        collection: String,
        queries: [CLIPBenchmarkQuery]
    ) {
        self.schemaVersion = schemaVersion
        self.collection = collection
        self.queries = queries
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case collection
        case queries
    }
}

public struct CLIPBenchmarkQuery: Codable, Equatable, Sendable {
    public let text: String
    public let relevant: [String]

    public init(text: String, relevant: [String]) {
        self.text = text
        self.relevant = relevant
    }
}

public struct CLIPRetrievalMetrics: Codable, Equatable, Sendable {
    public let precisionAt5: Double
    public let precisionAt10: Double
    public let recallAt5: Double
    public let recallAt10: Double
    public let reciprocalRank: Double

    public init(
        precisionAt5: Double,
        precisionAt10: Double,
        recallAt5: Double,
        recallAt10: Double,
        reciprocalRank: Double
    ) {
        self.precisionAt5 = precisionAt5
        self.precisionAt10 = precisionAt10
        self.recallAt5 = recallAt5
        self.recallAt10 = recallAt10
        self.reciprocalRank = reciprocalRank
    }

    public static func evaluate(
        rankedFileNames: [String],
        relevantFileNames: Set<String>
    ) -> Self {
        func matches(at limit: Int) -> Int {
            rankedFileNames.prefix(limit).reduce(0) {
                $0 + (relevantFileNames.contains($1) ? 1 : 0)
            }
        }
        func precision(at limit: Int) -> Double {
            Double(matches(at: limit)) / Double(limit)
        }
        func recall(at limit: Int) -> Double {
            guard !relevantFileNames.isEmpty else { return 0 }
            return Double(matches(at: limit))
                / Double(relevantFileNames.count)
        }
        let firstRelevantRank = rankedFileNames.firstIndex {
            relevantFileNames.contains($0)
        }.map { $0 + 1 }
        return Self(
            precisionAt5: precision(at: 5),
            precisionAt10: precision(at: 10),
            recallAt5: recall(at: 5),
            recallAt10: recall(at: 10),
            reciprocalRank: firstRelevantRank.map {
                1 / Double($0)
            } ?? 0
        )
    }

    public static func mean(_ metrics: [Self]) -> Self {
        guard !metrics.isEmpty else {
            return Self(
                precisionAt5: 0,
                precisionAt10: 0,
                recallAt5: 0,
                recallAt10: 0,
                reciprocalRank: 0
            )
        }
        let count = Double(metrics.count)
        return Self(
            precisionAt5: metrics.reduce(0) { $0 + $1.precisionAt5 } / count,
            precisionAt10: metrics.reduce(0) { $0 + $1.precisionAt10 } / count,
            recallAt5: metrics.reduce(0) { $0 + $1.recallAt5 } / count,
            recallAt10: metrics.reduce(0) { $0 + $1.recallAt10 } / count,
            reciprocalRank: metrics.reduce(0) {
                $0 + $1.reciprocalRank
            } / count
        )
    }
}

public struct CLIPBenchmarkQueryResult: Codable, Equatable, Sendable {
    public let query: CLIPBenchmarkQuery
    public let metrics: CLIPRetrievalMetrics
    public let results: [CLIPSearchResult]
}

public struct CLIPBenchmarkReport: Codable, Equatable, Sendable {
    public let generatedAt: Date
    public let collection: String
    public let modelFingerprint: String
    public let meanMetrics: CLIPRetrievalMetrics
    public let queries: [CLIPBenchmarkQueryResult]
}

public enum CLIPBenchmarkRunner {
    public static func run(
        manifest: CLIPBenchmarkManifest,
        engine: CLIPSearchEngine
    ) async throws -> CLIPBenchmarkReport {
        var queryResults = [CLIPBenchmarkQueryResult]()
        for query in manifest.queries {
            let results = try await engine.search(text: query.text, limit: 100)
            let metrics = CLIPRetrievalMetrics.evaluate(
                rankedFileNames: results.map(\.fileName),
                relevantFileNames: Set(query.relevant)
            )
            queryResults.append(CLIPBenchmarkQueryResult(
                query: query,
                metrics: metrics,
                results: results
            ))
        }
        return CLIPBenchmarkReport(
            generatedAt: .now,
            collection: manifest.collection,
            modelFingerprint: engine.provider
                .backendDescriptor.modelFingerprint,
            meanMetrics: .mean(queryResults.map(\.metrics)),
            queries: queryResults
        )
    }
}
