import Foundation
import CoreImage

/// Utility for converting base64-encoded image data to CVPixelBuffer
/// for Vision framework processing.
public class VideoFrameExtractor {
    public enum FrameError: Error {
        case invalidData
        case conversionFailed
    }

    /// Convert base64 image data to a CVPixelBuffer.
    public func pixelBuffer(from base64String: String) throws -> CVPixelBuffer {
        guard let data = Data(base64Encoded: base64String) else {
            throw FrameError.invalidData
        }
        return try pixelBuffer(from: data)
    }

    /// Convert raw image Data to a CVPixelBuffer.
    public func pixelBuffer(from data: Data) throws -> CVPixelBuffer {
        guard let ciImage = CIImage(data: data) else {
            throw FrameError.invalidData
        }
        return try pixelBuffer(from: ciImage)
    }

    /// Convert a CIImage to a CVPixelBuffer.
    public func pixelBuffer(from ciImage: CIImage) throws -> CVPixelBuffer {
        let context = CIContext()
        let width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)

        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw FrameError.conversionFailed
        }

        context.render(ciImage, to: buffer)
        return buffer
    }
}
