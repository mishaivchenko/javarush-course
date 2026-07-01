import Foundation
import Vision
import CoreImage

/// Vision framework-based analyzer using Apple's on-device CoreML stack.
/// Conforms to ContentAnalyzer via the Adapter Pattern.
///
/// Uses VNClassifyImageRequest (built-in Vision classifier) for initial classification
/// with NSFW-relevant label mapping. No custom model file required — the Vision
/// framework ships with a pre-trained on-device classifier.
class CoreMLAdapter: ContentAnalyzer {
    private let ciContext: CIContext
    private let classifier: NSFWClassifier

    init() {
        self.ciContext = CIContext()
        self.classifier = NSFWClassifier()
    }

    // MARK: - ContentAnalyzer

    func analyzeImage(_ imageData: Data) async throws -> Double {
        guard let ciImage = decodeImage(from: imageData) else {
            throw CoreMLAdapterError.invalidImageData
        }

        let confidence = try await classifier.classify(ciImage)
        return confidence
    }

    func analyzeText(_ text: String) -> Double {
        // Phase 2: text classification with NLP model or blocklist matching
        // Use the same Vision approach? No — text analysis uses blocklist (separate task)
        return 0.0
    }

    // MARK: - Vision Pipeline

    private func decodeImage(from data: Data) -> CIImage? {
        return CIImage(data: data)
    }
}

enum CoreMLAdapterError: Error {
    case invalidImageData
    case modelNotFound
    case classificationFailed(Error)
}
