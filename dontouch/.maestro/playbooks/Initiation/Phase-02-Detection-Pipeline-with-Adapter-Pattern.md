# Phase 02: Detection Pipeline with Adapter Pattern

Implement the real detection engine using the SOLID Adapter Pattern. Replace the `StubAnalyzer` with a `CoreMLAdapter` that uses Apple's Vision framework for on-device 18+ image classification. Wire the detection pipeline into the Safari extension so images are scanned and flagged content is blurred.

## Tasks

- [ ] Create AnalysisOrchestrator service — the coordinator that manages the detection pipeline:
  - Create `DontTouch/DontTouch Detection/AnalysisOrchestrator.swift`:
    ```swift
    import Foundation

    /// Coordinates the content analysis pipeline.
    /// Owns the current ContentAnalyzer (swappable via Adapter Pattern),
    /// manages analysis caching, and applies the user's sensitivity threshold.
    public actor AnalysisOrchestrator {
        public static let shared = AnalysisOrchestrator()
        
        private var analyzer: ContentAnalyzer
        private var cache: [String: Double] = [:]  // URL hash → confidence
        
        private init() {
            self.analyzer = StubAnalyzer()
        }
        
        /// Swap the underlying analyzer at runtime (Adapter Pattern).
        /// Pass any ContentAnalyzer implementation — CoreMLAdapter, StubAnalyzer, future model.
        public func setAnalyzer(_ newAnalyzer: ContentAnalyzer) {
            self.analyzer = newAnalyzer
            self.cache.removeAll()
        }
        
        /// Analyze image data. Returns confidence 0.0–1.0.
        public func analyzeImage(_ data: Data, sourceHash: String = "") async -> Double {
            if !sourceHash.isEmpty, let cached = cache[sourceHash] { return cached }
            let result = await analyzer.analyze(imageData: data)
            if !sourceHash.isEmpty { cache[sourceHash] = result }
            return result
        }
        
        /// Analyze a video frame. Returns confidence 0.0–1.0.
        public func analyzeVideoFrame(_ pixelBuffer: CVPixelBuffer) async -> Double {
            return await analyzer.analyze(videoFrame: pixelBuffer)
        }
        
        /// Whether a given confidence score exceeds the user's threshold.
        public func shouldBlock(confidence: Double, threshold: Double = 0.6) -> Bool {
            return confidence >= threshold
        }
        
        /// Clear the analysis cache (useful when model or threshold changes).
        public func clearCache() { cache.removeAll() }
    }
    ```
  - Verify the file compiles in the Detection framework target (`xcodebuild` check after building the whole project).

- [ ] Implement CoreMLAdapter — the real ContentAnalyzer using Apple's Vision framework:
  - Create `DontTouch/DontTouch Detection/CoreMLAdapter.swift`:
    - Conform to `ContentAnalyzer` protocol
    - `init()` loads a Vision classification request using `VNClassifyImageRequest` (Apple's built-in classifier that ships with the OS — no external model download needed)
    - `analyze(imageData: Data) async -> Double`:
      - Create a `VNImageRequestHandler` with the image data
      - Perform the `VNClassifyImageRequest` 
      - Filter results for classifications whose `identifier` contains 18+ related keywords: `"explicit"`, `"nudity"`, `"adult"`, `"sexual"`, `"nsfw"`, `"pornographic"`, `"obscene"`, `"erotica"`, `"indecent"`, `"suggestive"` (lowercased)
      - Return the highest confidence among matching classifications (range 0.0–1.0)
      - If no matching classifications, return 0.0
      - Wrap Vision calls in `Task.detached(priority: .userInitiated)` and use `withCheckedContinuation` to bridge the callback-based Vision API to async/await
    - `analyze(videoFrame: CVPixelBuffer) async -> Double`:
      - Same logic but create handler with `VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])`
    - Add thorough doc comments explaining that this uses on-device Vision framework — no network calls, fully private, works offline
  - Also create `DontTouch/DontTouch Detection/NSFWClassifier.swift`:
    - A helper struct that wraps the Vision classification logic in a reusable way
    - `static func classify(imageData: Data) async -> [(label: String, confidence: Double)]`
    - `static func classify(pixelBuffer: CVPixelBuffer) async -> [(label: String, confidence: Double)]`
    - Returns all classification results with confidence scores, sorted by confidence descending
    - CoreMLAdapter uses this internally
    - This separation keeps adapter and classification logic independently testable

- [ ] Update the Safari extension handler to route images through the detection pipeline:
  - Edit `DontTouch/DontTouch Extension/SafariWebExtensionHandler.swift`:
    - Import `DontTouch_Detection` framework
    - In `beginRequest(with:)`, initialize the pipeline: call `AnalysisOrchestrator.shared.setAnalyzer(CoreMLAdapter())` to swap from StubAnalyzer to real detection
    - In `messageReceived`, add handler for `"analyzeImage"`:
      - Extract `imageData` (base64-decoded from the message's `data` field) and `imageId` from `userInfo`
      - Spawn a `Task` that calls `await AnalysisOrchestrator.shared.analyzeImage(data)`
      - Read the user's threshold from `UserDefaults(suiteName: "group.com.yourname.donttouch")?.double(forKey: "blockThreshold") ?? 0.6`
      - Call `shouldBlock(confidence:threshold:)` to get the decision
      - Respond to the page script: `page.dispatchMessageToScript("blockResult", userInfo: ["imageId": imageId, "blocked": shouldBlock, "confidence": confidence])`
    - Handle `"analyzeVideoFrame"` similarly (stub for Phase 03 — log and respond with `{blocked: false}` for now)
    - Handle `"pageScanned"` message from content script: update a local counter, respond with settings JSON

- [ ] Update content.js to scan images and send for analysis:
  - Edit `DontTouch/DontTouch Extension/Resources/content.js`:
    - On `DOMContentLoaded`, call `scanExistingContent()` and set up a `MutationObserver` to watch for new images added dynamically
    - `scanExistingContent()` function:
      - Get all `<img>` elements: `document.querySelectorAll('img:not([data-dt-scanned])')`
      - Mark each with `data-dt-scanned="true"`
      - For each image that has a `src` attribute (not data URI, not svg+xml), create an `Image` object, load it cross-origin, draw to a `<canvas>` (max 512×512 for performance), get the base64 JPEG data
      - Send to native: `browser.runtime.sendMessage({type: "analyzeImage", imageId: uniqueId, data: base64Data, sourceUrl: img.src})`
    - Listen for `"blockResult"` message from native:
      - If `message.blocked === true`, find the element by `data-dt-image-id` attribute matching `message.imageId`, add class `dt-hidden`
      - If `message.blocked === false`, add class `dt-verified` (no action, just marks as checked)
    - Throttle: process max 5 images per batch with a 200ms delay between batches to avoid overloading the Vision pipeline
    - On every block result, update the popup by sending `{type: "statsUpdate", analyzed: count, blocked: blockedCount}`
    - MutationObserver watches `childList` on `<body>` and processes new images found (but only if they haven't been scanned yet)
    - Skip images smaller than 50×50 pixels (too small to meaningfully classify)

- [ ] Update the popup to show live analysis stats:
  - Edit `DontTouch/DontTouch Extension/Resources/popup.js`:
    - Listen for `browser.runtime.onMessage` with type `"statsUpdate"` and update the status text "Analyzed: X | Blocked: Y"
    - Add periodic refresh: every 2 seconds, query the active tab's content script for current stats via `browser.tabs.sendMessage`
    - When the sensitivity slider changes, send a message to the content script: `{type: "settingsUpdate", threshold: newValue, blockImages: bool, blockVideos: bool}`
    - Save settings to `browser.storage.local` on every change
  - Edit `DontTouch/DontTouch Extension/Resources/popup.html`:
    - Add a "Clear Cache" button that sends `{type: "clearCache"}` to the native extension
    - Add model status indicator: a green dot with text "CoreML + Vision — running on-device"
  - Edit `DontTouch/DontTouch Extension/Resources/popup.css`:
    - Style the status indicator: small colored dot with `border-radius: 50%`, inline with text
    - Style the Clear Cache button: small, understated, with a subtle hover effect

- [ ] Build, fix, and verify Phase 02:
  - Run `cd /Users/mishaivchenko/dev/javarush_course/dontouch/DontTouch && xcodebuild -project DontTouch.xcodeproj -scheme DontTouch -destination "platform=macOS" build 2>&1`
  - If compilation errors occur:
    - Missing framework imports: ensure `DontTouch_Detection` is properly imported with `@_exported import` or `import DontTouch_Detection` in the extension handler
    - Vision framework: add `import Vision` in CoreMLAdapter and NSFWClassifier files
    - async/await issues: ensure deployment targets support Swift concurrency (macOS 14.0+)
    - Framework linking: verify the Detection framework target is a dependency of the Extension target in Project.yml
  - Log success: "✅ Phase 02 build complete — detection pipeline wired and compiling"
