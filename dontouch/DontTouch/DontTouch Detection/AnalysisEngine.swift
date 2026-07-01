import Foundation
import CoreImage
import Vision
import OSLog

/// Central analysis engine — the main entry point for NSFW content detection.
///
/// AnalysisEngine wraps `AnalysisOrchestrator` for Vision-based image classification,
/// adds text blocklist matching, video frame analysis, URL-based caching,
/// and threshold comparison against the user's sensitivity setting.
///
/// **Thread safety:**
/// - `analyzeImage()` and `analyzeVideoFrame()` use Swift concurrency (`async`)
/// - `analyzeText()` is synchronous (pure string matching)
/// - URL cache access is serialized via a dedicated dispatch queue
/// - `shouldBlock()` reads from `UserDefaults` via `AppSettings` (main/safe)
///
/// **Usage:**
/// ```swift
/// let confidence = await AnalysisEngine.shared.analyzeImage(imageData)
/// if AnalysisEngine.shared.shouldBlock(confidence: confidence) { ... }
/// ```
public class AnalysisEngine {
    // MARK: - Singleton

    public static let shared = AnalysisEngine()

    // MARK: - Dependencies

    private let orchestrator = AnalysisOrchestrator.shared
    private let classifier = NSFWClassifier()
    private let logger = Logger(subsystem: "com.yourname.donttouch.detection", category: "engine")

    // MARK: - Text Blocklist

    /// Minimum number of matching tokens required to report a non-zero score.
    /// Prevents false positives from single-word matches in everyday text.
    private static let blocklistMinMatchCount = 2

    private let blocklist: Set<String>

    // MARK: - URL-based Caching

    /// Per-URL confidence cache so the same image isn't re-analyzed on repeated scans.
    private var urlCache: [String: Double] = [:]
    private let cacheQueue = DispatchQueue(
        label: "com.yourname.donttouch.engine-cache",
        qos: .utility
    )

    // MARK: - Initialization

    private init() {
        self.blocklist = Self.loadBlocklist()
        logger.debug("AnalysisEngine initialized with \(self.blocklist.count) blocklist entries")
    }

    // MARK: - Image Analysis

    /// Analyze raw image data and return a confidence score (0.0 – 1.0).
    ///
    /// Delegates to `AnalysisOrchestrator` which uses `CoreMLAdapter` / `NSFWClassifier`
    /// backed by the Vision framework's built-in `VNClassifyImageRequest`.
    /// Results are cached by image data hash inside the orchestrator.
    public func analyzeImage(_ data: Data) async -> Double {
        do {
            let result = try await orchestrator.analyzeImage(data, url: "")
            return result.confidence
        } catch {
            logger.error("Image analysis failed: \(error.localizedDescription, privacy: .public)")
            return 0.0
        }
    }

    /// Analyze image data with URL-based caching.
    ///
    /// Checks the URL cache first. On a miss, runs full analysis and caches the
    /// confidence score keyed by URL for the remainder of the session.
    /// - Parameters:
    ///   - url: The image source URL (used for cache key).
    ///   - data: Raw image data (JPEG / PNG).
    /// - Returns: A confidence score between 0.0 (safe) and 1.0 (likely NSFW).
    public func analyzeImage(url: String, data: Data) async -> Double {
        if let cached = getCachedConfidence(for: url) {
            logger.debug("URL cache hit: \(url, privacy: .public)")
            return cached
        }

        let confidence = await analyzeImage(data)
        setCachedConfidence(confidence, for: url)
        logger.debug("URL cache miss — analyzed: \(url, privacy: .public) confidence: \(confidence)")
        return confidence
    }

    // MARK: - Text Analysis

    /// Analyze text against the NSFW keyword blocklist.
    ///
    /// Tokenizes the input (splits on whitespace and punctuation, lowercases),
    /// counts matching blocklist tokens, and returns:
    /// - `0.0` if fewer than `blocklistMinMatchCount` tokens matched
    /// - `matchedTokens / totalTokens` otherwise
    ///
    /// - Parameter text: The text to analyze.
    /// - Returns: A confidence score between 0.0 (safe) and 1.0 (likely NSFW).
    public func analyzeText(_ text: String) -> Double {
        let tokens = tokenize(text)
        guard tokens.count >= Self.blocklistMinMatchCount else { return 0.0 }

        let matchedCount = tokens.filter { blocklist.contains($0) }.count
        guard matchedCount >= Self.blocklistMinMatchCount else { return 0.0 }

        return Double(matchedCount) / Double(tokens.count)
    }

    // MARK: - Threshold Comparison

    /// Determine whether content should be blocked at the given confidence level.
    ///
    /// Reads the user's sensitivity threshold from `UserDefaults` (App Group suite
    /// `group.com.yourname.donttouch`), falling back to `UserDefaults.standard` if
    /// the App Group container is unavailable. Default threshold is **0.6**.
    ///
    /// - Parameter confidence: Detection confidence score (0.0 – 1.0).
    /// - Returns: `true` if confidence meets or exceeds the threshold.
    public func shouldBlock(confidence: Double) -> Bool {
        let defaults = UserDefaults(suiteName: "group.com.yourname.donttouch")
            ?? UserDefaults.standard
        let threshold = defaults.object(forKey: "sensitivityThreshold") as? Double ?? 0.6
        return confidence >= threshold
    }

    // MARK: - Video Frame Analysis

    /// Analyze a video frame from a `CVPixelBuffer`.
    ///
    /// Converts the pixel buffer to a `CIImage` and runs it through the Vision
    /// classifier. Used by `VideoAnalyzer` when sampling frames from `<video>` elements.
    ///
    /// - Parameter pixelBuffer: A video frame pixel buffer.
    /// - Returns: A confidence score between 0.0 (safe) and 1.0 (likely NSFW).
    public func analyzeVideoFrame(_ pixelBuffer: CVPixelBuffer) async -> Double {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        do {
            return try await classifier.classify(ciImage)
        } catch {
            logger.error("Video frame analysis failed: \(error.localizedDescription, privacy: .public)")
            return 0.0
        }
    }

    /// Analyze a video frame from base64-encoded image data.
    ///
    /// Decodes the base64 string, creates a `CIImage`, and runs classification.
    ///
    /// - Parameter base64: Base64-encoded JPEG/PNG image data.
    /// - Returns: A confidence score between 0.0 (safe) and 1.0 (likely NSFW).
    public func analyzeVideoFrame(base64: String) async -> Double {
        guard let data = Data(base64Encoded: base64),
              let ciImage = CIImage(data: data) else {
            logger.warning("Could not decode base64 video frame")
            return 0.0
        }
        do {
            return try await classifier.classify(ciImage)
        } catch {
            logger.error("Video frame (base64) analysis failed: \(error.localizedDescription, privacy: .public)")
            return 0.0
        }
    }

    // MARK: - Cache Management

    /// Clear the URL-based confidence cache.
    public func clearUrlCache() {
        cacheQueue.sync {
            urlCache.removeAll()
        }
        logger.debug("URL cache cleared")
    }

    /// Number of cached URL entries.
    var urlCacheSize: Int {
        cacheQueue.sync { urlCache.count }
    }

    // MARK: - Private Helpers

    private func getCachedConfidence(for url: String) -> Double? {
        cacheQueue.sync { urlCache[url] }
    }

    private func setCachedConfidence(_ confidence: Double, for url: String) {
        cacheQueue.sync { urlCache[url] = confidence }
    }

    /// Split text into lowercase tokens, removing whitespace and punctuation.
    private func tokenize(_ text: String) -> [String] {
        let separators = CharacterSet.whitespacesAndNewlines
            .union(.punctuationCharacters)
        return text
            .lowercased()
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }
    }

    /// Load the NSFW keyword blocklist from the framework's resource bundle.
    /// Lines starting with `#` are treated as comments and ignored.
    /// Each non-empty line is a single keyword (lowercased).
    private static func loadBlocklist() -> Set<String> {
        let bundle = Bundle(for: AnalysisEngine.self)
        guard let url = bundle.url(forResource: "blocklist", withExtension: "txt"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            Logger(subsystem: "com.yourname.donttouch.detection", category: "engine")
                .warning("blocklist.txt not found in framework bundle — text analysis disabled")
            return []
        }

        let entries = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }

        return Set(entries)
    }
}
