import CoreImage
import Foundation
import Vision

/// Classification helper that wraps Vision framework requests.
/// Manages model loading and classification lifecycle.
class NSFWClassifier {
    private var model: VNCoreMLModel?

    init() {
        // Phase 2: load the CoreML model
        // Phase 1: no-op until a model is added to the bundle
    }

    /// Load a CoreML model from the given URL.
    func loadModel(at url: URL) throws {
        let compiledUrl = try MLModel.compileModel(at: url)
        let mlModel = try MLModel(contentsOf: compiledUrl)
        self.model = try VNCoreMLModel(for: mlModel)
    }

    /// Classify an image and return confidence as a Double.
    func classify(_ ciImage: CIImage) async throws -> Double {
        guard let model = model else {
            // No model loaded — return safe
            return 0.0
        }

        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(ciImage: ciImage)
        try handler.perform([request])

        guard let results = request.results as? [VNClassificationObservation],
              let topResult = results.first else {
            return 0.0
        }

        // Map classification label to confidence
        // Phase 2: map model output labels (e.g., "NSFW", "SFW") to confidence
        return Double(topResult.confidence)
    }
}
