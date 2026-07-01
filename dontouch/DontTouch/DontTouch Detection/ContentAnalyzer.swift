import Foundation

/// Adapter protocol for the detection pipeline.
/// Conforming types analyze image data and return a confidence score (0.0–1.0).
///
/// This enables the Adapter Pattern: swap ML backends (CoreML, stub, future models)
/// without changing the rest of the system.
public protocol ContentAnalyzer {
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
public enum DefaultAnalyzer {
    static func make() -> ContentAnalyzer {
        // Uses Vision framework VNClassifyImageRequest with NSFW-relevant label mapping.
        // No custom CoreML model file needed — Apple's built-in on-device classifier handles it.
        return CoreMLAdapter()
    }
}

/// Stub analyzer that always returns safe.
/// Used during Phase 1 development before CoreML integration.
public struct StubAnalyzer: ContentAnalyzer {
    public func analyzeImage(_ imageData: Data) async throws -> Double {
        // Stub: always returns 0.0 (safe)
        return 0.0
    }

    public func analyzeText(_ text: String) -> Double {
        // Stub: always returns 0.0 (safe)
        return 0.0
    }
}
