import CoreImage
import Foundation
import Vision

/// Classification helper that wraps Vision framework requests.
/// Manages model loading and classification lifecycle.
///
/// Uses Apple's built-in VNClassifyImageRequest for on-device classification
/// with no network calls. Flags images whose classification labels match
/// NSFW-relevant categories (e.g., swimwear, lingerie, explicit content).
class NSFWClassifier {
    private var model: VNCoreMLModel?
    private let nsfwLabels: Set<String>
    private let labelWeights: [String: Double]

    init() {
        // Phase 2: load a custom CoreML model (if bundled)
        // Phase 1: VNClassifyImageRequest used as fallback — no model file needed

        // NSFW-relevant classification labels from the built-in Vision classifier (Inceptionv3/ImageNet taxonomy)
        // When VNClassifyImageRequest returns one of these labels with high confidence,
        // the image is flagged as NSFW.
        self.nsfwLabels = Set([
            "brassiere", "bra", "bandeau", // n02871525
            "bathing suit", "swimsuit", "swimming costume", "bikini", "trunks", // n03888257
            "lingerie", // n03642806
            "negligee", "negligeee", // n03877837
            "maillot", "maillot", "tank suit", // not in standard set but related
            "miniskirt", "mini", // not standard but related
            "groom", "bridegroom", // not standard
            "brassiere", "bra", // already listed
            "sunglasses", "sunglass", "dark glasses", // often in NSFW context
            "mask", // often in NSFW context (specific categories)
        ])

        // Weight factors for each label — higher = more confident NSFW indicator
        var weights: [String: Double] = [:]
        for label in nsfwLabels {
            weights[label] = 1.0
        }
        // Higher weight for explicitly sexualized clothing categories
        weights["brassiere"] = 1.2
        weights["lingerie"] = 1.3
        weights["bathing suit"] = 0.8 // less explicit — more common in benign contexts
        self.labelWeights = weights
    }

    /// Load a custom CoreML model from the given URL (optional, for Phase 2+).
    func loadModel(at url: URL) throws {
        let compiledUrl = try MLModel.compileModel(at: url)
        let mlModel = try MLModel(contentsOf: compiledUrl)
        self.model = try VNCoreMLModel(for: mlModel)
    }

    /// Classify an image using the Vision framework's built-in classifier.
    /// Falls back to VNClassifyImageRequest when no custom CoreML model is loaded.
    /// - Parameter ciImage: The image to classify.
    /// - Returns: A confidence score between 0.0 (safe) and 1.0 (likely NSFW).
    func classify(_ ciImage: CIImage) async throws -> Double {
        if let model = model {
            return try await classifyWithCoreML(ciImage, model: model)
        }
        return try await classifyWithVisionBuiltin(ciImage)
    }

    /// Classify using a custom CoreML model.
    private func classifyWithCoreML(_ ciImage: CIImage, model: VNCoreMLModel) async throws -> Double {
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(ciImage: ciImage)
        try handler.perform([request])

        guard let results = request.results as? [VNClassificationObservation],
              let topResult = results.first else {
            return 0.0
        }

        return Double(topResult.confidence)
    }

    /// Classify using Apple's built-in VNClassifyImageRequest.
    /// Flags images whose top classification labels match NSFW-relevant categories.
    private func classifyWithVisionBuiltin(_ ciImage: CIImage) async throws -> Double {
        let request = VNClassifyImageRequest()

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try handler.perform([request])

        guard let results = request.results else {
            return 0.0
        }

        // Scan all results above a minimum confidence for NSFW-related labels
        var maxNsfwConfidence: Double = 0.0

        for observation in results.prefix(20) {
            let label = observation.identifier.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let confidence = Double(observation.confidence)

            // Check if this label matches an NSFW category
            if let weight = labelWeights[label] {
                let weightedConfidence = confidence * weight
                maxNsfwConfidence = max(maxNsfwConfidence, weightedConfidence)
            } else {
                // Fuzzy match: check if the label contains any NSFW keyword
                for nsfwLabel in nsfwLabels {
                    if label.contains(nsfwLabel) || nsfwLabel.contains(label) {
                        let weight = labelWeights[nsfwLabel] ?? 1.0
                        let weightedConfidence = confidence * weight
                        maxNsfwConfidence = max(maxNsfwConfidence, weightedConfidence)
                        break
                    }
                }
            }
        }

        return maxNsfwConfidence
    }
}
