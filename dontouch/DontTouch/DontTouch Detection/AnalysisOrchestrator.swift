import Foundation
import CryptoKit

/// Singleton actor that manages the detection pipeline.
/// Serializes access to shared mutable state (caches, thresholds) without locks.
///
/// Flow:
/// 1. receive image data + URL
/// 2. check cache (SHA-256 hash)
/// 3. run analyzer
/// 4. cache result
/// 5. compare against threshold → return block decision
public actor AnalysisOrchestrator {
    public static let shared = AnalysisOrchestrator()

    private let analyzer: ContentAnalyzer
    private var cache: [String: CacheEntry] = [:]

    /// Default sensitivity threshold (0.0–1.0). Higher = more aggressive blocking.
    nonisolated let defaultThreshold: Double = 0.6

    private struct CacheEntry {
        let confidence: Double
        let timestamp: Date
    }

    private init() {
        self.analyzer = DefaultAnalyzer.make()
    }

    /// Analyze an image and return whether it should be blocked.
    public func analyzeImage(_ imageData: Data, url: String, threshold: Double? = nil) async throws -> AnalysisResult {
        let effectiveThreshold = threshold ?? defaultThreshold
        let hash = sha256(of: imageData)

        // Check cache
        if let cached = cache[hash] {
            return AnalysisResult(
                blocked: cached.confidence >= effectiveThreshold,
                confidence: cached.confidence,
                cached: true
            )
        }

        // Run detection
        let confidence = try await analyzer.analyzeImage(imageData)

        // Cache result
        cache[hash] = CacheEntry(confidence: confidence, timestamp: Date())

        return AnalysisResult(
            blocked: confidence >= effectiveThreshold,
            confidence: confidence,
            cached: false
        )
    }

    /// Clear the analysis cache.
    func clearCache() {
        cache.removeAll()
    }

    /// Number of cached results.
    var cacheSize: Int {
        cache.count
    }

    // MARK: - Private

    private func sha256(of data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

public public struct AnalysisResult {
    public let blocked: Bool
    public let confidence: Double
    public let cached: Bool

    public init(blocked: Bool, confidence: Double, cached: Bool) {
        self.blocked = blocked
        self.confidence = confidence
        self.cached = cached
    }
}
