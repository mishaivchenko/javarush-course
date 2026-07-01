import Foundation

/// Adapter protocol for the detection pipeline.
/// Conforming types analyze image data and return a confidence score (0.0–1.0).
///
/// This enables the Adapter Pattern: swap ML backends (CoreML, stub, future models)
/// without changing the rest of the system.
protocol ContentAnalyzer {
    /// Analyze a base64-encoded image.
    /// - Parameter imageData: Base64 string of the image (JPEG or PNG).
    /// - Returns: A confidence score between 0.0 (safe) and 1.0 (explicit).
    func analyzeImage(_ imageData: Data) async throws -> Double

    /// Analyze text content against a blocklist or classifier.
    /// - Parameter text: The text to analyze.
    /// - Returns: A confidence score between 0.0 (safe) and 1.0 (explicit).
    func analyzeText(_ text: String) -> Double
}

/// Default analyzer type used by AnalysisOrchestrator.
/// Swap this out during tests or when switching ML backends.
enum DefaultAnalyzer {
    static func make() -> ContentAnalyzer {
        // Phase 1: stub — always returns safe
        // Phase 2: replace with CoreMLAdapter()
        return StubAnalyzer()
    }
}

/// Stub analyzer that always returns safe.
/// Used during Phase 1 development before CoreML integration.
struct StubAnalyzer: ContentAnalyzer {
    func analyzeImage(_ imageData: Data) async throws -> Double {
        // Stub: always returns 0.0 (safe)
        return 0.0
    }

    func analyzeText(_ text: String) -> Double {
        // Stub: always returns 0.0 (safe)
        return 0.0
    }
}
