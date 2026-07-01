# Don't Touch — Phase 2: On-Device AI Detection & Content Blur

This phase adds on-device CoreML models for detecting NSFW content in images, video frames, and text. Analyzed content gets the `dt-hidden` CSS class (blurred, non-interactive) applied automatically.

## Prerequisites

- Phase 1 complete (working Safari extension with badge and CSS injection)
- Xcode 15+ on macOS 14+

---

- [x] Add a CoreML NSFW image classification model to the project:
  1. Search for an open-source NSFW detection CoreML model (e.g., Nudity). Convert it or download a ready `.mlpackage` / `.mlmodel` file. If none is readily available, create a wrapper using Apple's Vision framework with a built-in classification request that flags content categories.
  2. Drag the model file into Xcode's `DontTouchBlocker` group → "Copy items if needed" → add to `DontTouchBlocker` target.
  3. In Build Settings for `DontTouchBlocker`, verify the model is listed under "CoreML Model Compiler" input. Build to trigger model compilation.
  4. If the model fails to compile, create a fallback Vision-based classifier using `VNClassifyImageRequest` with a custom confidence threshold (0.7+ for NSFW labels). Test that it produces results.

**Note (Phase 2 implementation):** No downloadable CoreML model was bundled. Instead, `NSFWClassifier.swift` uses Apple's built-in `VNClassifyImageRequest` (on-device Inceptionv3-derived classifier) with NSFW-relevant label mapping. The label blocklist covers clothing types (lingerie, brassiere, swimwear, etc.) with weighted confidence scoring and fuzzy label matching. `CoreMLAdapter.swift` drives the detection and `DefaultAnalyzer.make()` now returns `CoreMLAdapter()` instead of `StubAnalyzer()`. The `VNCoreMLRequest` path in `NSFWClassifier` is retained for future custom model loading via `loadModel(at:)`.

- [x] Implement the on-device analysis engine (`AnalysisEngine.swift`):
  1. Create `AnalysisEngine.swift` in `DontTouchBlocker/`:
     - A singleton class with a `shared` instance.
     - `func analyzeImage(_ data: Data) -> Double` — returns confidence score (0.0–1.0) using the CoreML model. If no model loaded, uses Vision fallback.
     - `func analyzeText(_ text: String) -> Double` — checks against a blocklist of NSFW keywords and returns a match score. The blocklist should be stored as a `.txt` resource file with ~100-200 common terms (family-safe).
     - `func shouldBlock(confidence: Double) -> Bool` — returns `true` if confidence exceeds the user's threshold (default 0.6, stored in UserDefaults).
  2. Use `VNImageRequestHandler` and `VNCoreMLRequest` for image analysis. Run on a background queue (`DispatchQueue.global(qos: .userInitiated)`).
  3. Cache analysis results per URL per session to avoid re-analyzing the same image.

- [x] Add video frame analysis support:
  1. In `AnalysisEngine.swift`, add `func analyzeVideoFrame(_ pixelBuffer: CVPixelBuffer) -> Double` that uses the same CoreML model via `VNImageRequestHandler` on the pixel buffer.
  2. Create `VideoAnalyzer.swift` in `DontTouchBlocker/`:
     - Uses `AVPlayerItemVideoOutput` to periodically sample video frames.
     - Default sample rate: every 2 seconds. Configurable via UserDefaults.
     - For each sampled frame, calls `AnalysisEngine.shared.analyzeVideoFrame()`.
     - Maintains a running average over the last 5 frames. If the average exceeds threshold → mark the video element as blocked.
  
  **Note:** `analyzeVideoFrame(pixelBuffer:)` and a base64 variant were already present in `AnalysisEngine.swift`. `VideoAnalyzer.swift` was created in `DontTouch/DontTouch Detection/`. Also fixed a pre-existing compilation error in `NSFWClassifier.swift` (removed deprecated `imageCropAndScaleOption` on `VNClassifyImageRequest` and redundant `as?` cast on `results`), and fixed a cross-target dependency in `AnalysisEngine.swift` (replaced `AppSettings.shared.sensitivityThreshold` with direct `UserDefaults` access so the Detection framework is self-contained).

- [x] Build the content scanner that runs in the page context (`contentBlocker.js`):
  1. In `DontTouchBlocker/Resources/`, create `contentBlocker.js`:
     - On `DOMContentLoaded`, scan all `<img>` elements: collect their `src` URLs, batch them, and send to native extension via `safari.extension.dispatchMessage("analyzeImages", {urls: [...]})`.
     - Scan all `<video>` elements: for each, observe on `play` event, sample frames via a `<canvas>` draw at 2-second intervals, send canvas `toDataURL()` (base64) to native via `safari.extension.dispatchMessage("analyzeVideoFrame", {data: base64})`. If blocked, pause video and add `dt-hidden` class.
     - Scan all text nodes (using `TreeWalker` with `NodeFilter.SHOW_TEXT`): chunk text into paragraphs, strip HTML, send batches to native via `safari.extension.dispatchMessage("analyzeText", {text: "..."})`.
  2. On receiving a response from native with `{action: "block", selector: "..."}` → add the `dt-hidden` class to the matched element. On `{action: "unblock", ...}` → remove it.
  3. Throttle scanning: after the initial scan, re-scan dynamically added content every 3 seconds using a `MutationObserver` watching `childList` on the document body.

- [ ] Wire up native-side message handling in `SafariExtensionHandler.swift`:
  1. In the `messageReceived` method, add cases:
     - `"analyzeImages"`: iterate URLs, for each fetch image data via URLSession (yes, same-origin fetch), pass to `AnalysisEngine.shared.analyzeImage()`. Respond with `{action: "block" | "ok", selector: "img[src='url']"}` per image.
     - `"analyzeVideoFrame"`: decode base64 to `Data` → create `CGImageSource` → pass to `AnalysisEngine.shared.analyzeImage()`. Respond with block decision.
     - `"analyzeText"`: pass text to `AnalysisEngine.shared.analyzeText()`. If flagged, respond with `{action: "block", selector: "text-node-id"}`.
  2. All analysis runs on background queues. Use `dispatchGroup` to batch responses and send them at once.
  3. The extension's `SFSafariPage.dispatchMessageToScript()` is used to send responses back to the page script.

- [ ] Create a settings popover for the extension toolbar button:
  1. In `DontTouchBlocker`, create `SafariExtensionViewController`:
     - A small popover (width: 300, height: 250) with:
       - **Sensitivity slider** (0.0–1.0, default 0.6) stored in `UserDefaults` under key `blockThreshold`.
       - **Toggle: Block Images** (default ON)
       - **Toggle: Block Videos** (default ON)
       - **Toggle: Block Text** (default ON)
       - A small status label showing "Blocked X items on this page" (updated via message from the content script).
  2. Override `popoverViewController()` in `SafariExtensionHandler` to return this view controller.
  3. Connect the toggles and slider to `UserDefaults.shared` (App Group container so both main app and extension share settings). Add an App Group capability in both targets with identifier `group.com.yourname.donttouch`.

- [ ] Add text blocklist file:
  1. Create `blocklist.txt` in `DontTouchBlocker/Resources/` with one word per line. Include common adult content keywords (this is a blocker, so accuracy matters). Aim for ~100 entries covering explicit language and adult content indicators.
  2. In `AnalysisEngine.swift`, load this file on init into a `Set<String>` for fast lookup. The `analyzeText()` method tokenizes input text (split on whitespace/punctuation, lowercase) and checks each token against the set.
  3. Return confidence = (matched tokens / total tokens) × 1.0. If fewer than 2 tokens match, return 0.0 to avoid false positives on single-word matches.

- [ ] Final integration test:
  1. Build and run on macOS. Enable the extension.
  2. Test with a page containing NSFW images, a page with explicit text, and a video page. Verify flagged content gets blurred.
  3. Test the sensitivity slider — content should be blocked/unblocked as threshold changes.
  4. Verify the 🚫 badge still shows from Phase 1.
  5. Open Safari's Web Inspector → Console — check for any error messages from the content script.
  6. Build for iOS (change scheme destination to "Any iOS Device" or a simulator) and verify no compilation errors. Note: iOS Safari extensions require building with an Apple Developer Program account (not free tier).
