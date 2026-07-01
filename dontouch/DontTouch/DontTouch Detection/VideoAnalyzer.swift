import AVFoundation
import CoreImage
import OSLog

/// Analyzes video content by periodically sampling frames from an `AVPlayerItem`
/// and running each frame through the NSFW detection pipeline.
///
/// ## Usage
///
/// ```swift
/// let analyzer = VideoAnalyzer()
/// analyzer.startMonitoring(playerItem: player.currentItem!)
///
/// // At each sample interval (default 2s):
/// let avgConfidence = await analyzer.analyzeFrame(at: player.currentTime())
/// if analyzer.shouldBlock {
///     // Apply blur / overlay to the video element
/// }
/// ```
///
/// ## Running Average
///
/// Maintains a running average over the last `runningAverageWindow` (5) frames.
/// The block decision (`shouldBlock`) is based on this average, not a single-frame
/// spike, which reduces flickering from transient detections.
///
/// ## Configuration
///
/// The sample interval is read from `UserDefaults.standard` under the key
/// `"videoSampleRate"`. Set it at runtime:
///
/// ```swift
/// VideoAnalyzer.sampleRate = 3.0  // sample every 3 seconds
/// ```
public class VideoAnalyzer {
    // MARK: - Configuration

    /// How often to sample a video frame (in seconds).
    /// Default: 2.0 seconds. Configurable at runtime via `UserDefaults.standard`.
    static var sampleRate: TimeInterval {
        get {
            let stored = UserDefaults.standard.double(forKey: Self.sampleRateKey)
            return stored > 0 ? stored : 2.0
        }
        set { UserDefaults.standard.set(newValue, forKey: Self.sampleRateKey) }
    }

    /// UserDefaults key persisted for `sampleRate`.
    private static let sampleRateKey = "videoSampleRate"

    /// Number of recent frame confidences to retain for the running average.
    /// A larger window smooths out noise but increases response latency.
    static let runningAverageWindow = 5

    // MARK: - State

    /// AVPlayerItemVideoOutput attached to the monitored player item.
    /// Extracts `CVPixelBuffer` at specific timestamps for classification.
    private var videoOutput: AVPlayerItemVideoOutput?

    /// Sliding window of recent frame confidences.
    private var recentConfidences: [Double] = []

    private let logger = Logger(
        subsystem: "com.yourname.donttouch.detection",
        category: "video"
    )

    // MARK: - Lifecycle

    /// Start monitoring a video player item.
    ///
    /// Attaches an `AVPlayerItemVideoOutput` with 32BGRA pixel format
    /// to the given player item. Call `stopMonitoring()` to detach it.
    ///
    /// - Parameter playerItem: The player item whose video frames should be analyzed.
    public func startMonitoring(playerItem: AVPlayerItem) {
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        playerItem.add(output)
        self.videoOutput = output
        recentConfidences.removeAll()
        logger.debug("Video monitoring started, sample rate: \(Self.sampleRate)s")
    }

    /// Stop monitoring and release the video output.
    ///
    /// Resets the running average. Call this when the player item is
    /// deallocated or when monitoring is no longer needed.
    public func stopMonitoring() {
        videoOutput = nil
        recentConfidences.removeAll()
        logger.debug("Video monitoring stopped")
    }

    // MARK: - Frame Analysis

    /// Analyze a video frame at the given presentation time.
    ///
    /// Extracts a pixel buffer from the `AVPlayerItemVideoOutput` at the specified
    /// time, runs it through `AnalysisEngine.shared.analyzeVideoFrame(_:)`, and
    /// updates the running confidence average.
    ///
    /// - Parameter time: The `CMTime` (typically `AVPlayer.currentTime()`) at which
    ///   to sample the frame.
    /// - Returns: The running average confidence over the last N frames (0.0 – 1.0).
    ///   Returns `0.0` if no video output is attached or the frame could not be copied.
    public func analyzeFrame(at time: CMTime) async -> Double {
        guard let output = videoOutput else {
            logger.warning("analyzeFrame called without active monitoring")
            return 0.0
        }

        guard let pixelBuffer = output.copyPixelBuffer(
            forItemTime: time,
            itemTimeForDisplay: nil
        ) else {
            logger.debug("No pixel buffer available at time: \(time.seconds)")
            return runningAverage // return current average rather than 0
        }

        let confidence = await AnalysisEngine.shared.analyzeVideoFrame(pixelBuffer)

        // Sliding window: append and cap at runningAverageWindow
        recentConfidences.append(confidence)
        if recentConfidences.count > Self.runningAverageWindow {
            recentConfidences.removeFirst()
        }

        let avg = runningAverage
        logger.debug("Frame confidence: \(confidence, privacy: .public), running avg: \(avg, privacy: .public)")
        return avg
    }

    /// The running average confidence over the last `runningAverageWindow` frames.
    ///
    /// Returns `0.0` when no frames have been analyzed yet.
    public var runningAverage: Double {
        guard !recentConfidences.isEmpty else { return 0.0 }
        return recentConfidences.reduce(0, +) / Double(recentConfidences.count)
    }

    /// Whether the running average exceeds the user's configured sensitivity threshold.
    ///
    /// Delegates to `AnalysisEngine.shared.shouldBlock(confidence:)`.
    public var shouldBlock: Bool {
        AnalysisEngine.shared.shouldBlock(confidence: runningAverage)
    }

    // MARK: - Reset

    /// Clear the running confidence average.
    ///
    /// Call this when switching to a new video or after a threshold change
    /// to avoid a stale average from the previous content.
    public func reset() {
        recentConfidences.removeAll()
        logger.debug("Running average reset")
    }
}
