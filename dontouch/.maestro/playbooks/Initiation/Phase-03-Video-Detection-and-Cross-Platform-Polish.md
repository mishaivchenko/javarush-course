# Phase 03: Video Detection & Cross-Platform Polish

Add video frame analysis — sample frames from `<video>` elements and classify them through the same Adapter Pattern pipeline. Polish the extension with a sensitivity slider that takes effect live, proper App Group settings sharing between macOS and iOS, and thorough cross-platform verification.

## Tasks

- [ ] Implement the content-side video frame extraction in content.js:
  - Edit `DontTouch/DontTouch Extension/Resources/content.js`:
    - Add `scanVideos()` function, called during initial page scan and by the MutationObserver
    - For each `<video>` element not yet marked with `data-dt-video-scanned`:
      - Mark it with `data-dt-video-scanned="true"`
      - Attach a `timeupdate` event listener that fires every 3 seconds (use a debounced flag to avoid rapid fire)
      - On each sample interval:
        1. Create an offscreen `<canvas>` element (max 256×256 for performance)
        2. Draw the current video frame: `canvas.getContext('2d').drawImage(video, 0, 0, width, height)`
        3. Get the frame data: `canvas.toDataURL('image/jpeg', 0.7)` — lower quality to reduce transfer size
        4. Send to native: `browser.runtime.sendMessage({type: "analyzeVideoFrame", videoId: videoId, frameData: dataUrl, timestamp: video.currentTime})`
    - Listen for `"videoBlockResult"` message from native:
      - If `message.blocked === true`, add class `dt-hidden` to the video element and show an overlay inside the video's parent: `<div class="dt-video-overlay"><span>🚫 Content blocked — Don't Touch</span></div>`
      - Maintain a running state per video: `window.__dtVideoStates[videoId] = { blocked: false, frameCount: 0, positiveFrames: 0 }`
      - Block a video after 2 out of 3 consecutive frames are flagged positive (prevents flickering from single frame false-positives)
      - When unblocking (if threshold changes), remove the overlay and `dt-hidden` class
    - Add `dt-video-overlay` CSS to the injected stylesheet:
      ```css
      .dt-video-overlay {
        position: absolute; inset: 0; z-index: 9999;
        background: rgba(13,7,9,0.85); color: #c4b8a8;
        display: flex; align-items: center; justify-content: center;
        font: 14px -apple-system, sans-serif;
        backdrop-filter: blur(8px);
      }
      ```

- [ ] Update the native extension handler to process video frames:
  - Edit `DontTouch/DontTouch Extension/SafariWebExtensionHandler.swift`:
    - Replace the Phase 02 stub for `"analyzeVideoFrame"` with real logic:
      - Decode the base64 JPEG frame data from `userInfo["frameData"]`
      - Convert to a `CVPixelBuffer` using `CGImageSource` → `CGImage` → pixel buffer via `CVPixelBufferPool` or a helper that creates a pixel buffer from a `CGImage`
      - Call `await AnalysisOrchestrator.shared.analyzeVideoFrame(pixelBuffer)`
      - Compare against the user's threshold
      - Respond with `page.dispatchMessageToScript("videoBlockResult", userInfo: ["videoId": videoId, "blocked": shouldBlock, "confidence": confidence, "timestamp": timestamp])`
    - Create a helper method `base64ToPixelBuffer(_ base64: String) -> CVPixelBuffer?`:
      - Strip the `data:image/jpeg;base64,` prefix
      - Decode base64 string to `Data`
      - Create `CGImageSource` from data
      - Get the first `CGImage`
      - Create a `CVPixelBuffer` using `vImage` or manual pixel buffer creation
      - Return the pixel buffer for Vision framework analysis
  - Create `DontTouch/DontTouch Detection/VideoFrameExtractor.swift`:
    - A utility struct that converts base64 JPEG data to `CVPixelBuffer`
    - `static func fromBase64(_ base64: String) -> CVPixelBuffer?`
    - `static func fromData(_ data: Data) -> CVPixelBuffer?`
    - Uses CoreGraphics and Accelerate/vImage for efficient conversion with proper error handling

- [ ] Implement live sensitivity slider and settings persistence:
  - Edit `DontTouch/DontTouch Extension/Resources/popup.js`:
    - On slider change, immediately save to `browser.storage.local` and send `{type: "thresholdChanged", threshold: value}` to the content script and native extension
    - On toggle change (Block Images, Block Videos), immediately save and send update message
    - Add "Apply to current page" button that re-scans the current page with new settings
    - Display current threshold as a percentage: "Sensitivity: 60%" that updates live as slider moves
  - Edit `DontTouch/DontTouch Extension/SafariWebExtensionHandler.swift`:
    - Add handler for `"thresholdChanged"` message: update `UserDefaults(suiteName: "group.com.yourname.donttouch")` value for key `"blockThreshold"`
    - Add handler for `"clearCache"` message: call `await AnalysisOrchestrator.shared.clearCache()`, respond with `{cleared: true}`
    - Add handler for `"reanalyze"` message: clear cache and re-trigger analysis for the current page by asking the content script to re-scan all images
  - Edit `DontTouch/DontTouch Extension/Resources/content.js`:
    - Add handler for `"reanalyze"` message from popup: remove `data-dt-scanned` and `data-dt-video-scanned` attributes from all elements, clear `dt-hidden` and `dt-verified` classes, re-run `scanExistingContent()` and `scanVideos()`
    - Add handler for `"thresholdChanged"`: store the new threshold in a local variable for reference (actual threshold check is done on the native side, but content script tracks it for stats display)

- [ ] Add App Group settings sharing and iOS configuration:
  - Edit `DontTouch/Project.yml`:
    - Add `baseBundleIdentifier: com.yourname.DontTouch` at the project level
    - Add `App Groups` capability to both the `DontTouch` app target and the `DontTouch Extension` target with group `group.com.yourname.donttouch`
    - Ensure the iOS deployment target is set to 17.0 in the Safari Extension settings
    - Add iOS as a supported platform for the Safari Extension target in the XcodeGen config: `platforms: [macOS, iOS]`
  - Create `DontTouch/DontTouch/AppSettings.swift`:
    - A shared settings manager that uses `UserDefaults(suiteName: "group.com.yourname.donttouch")` as the backing store
    - `static let shared = AppSettings()`
    - Computed properties: `var blockThreshold: Double { get/set }` (default 0.6), `var blockImages: Bool { get/set }` (default true), `var blockVideos: Bool { get/set }` (default true)
    - Uses `@Published` wrappers so SwiftUI views react to changes
    - Sends a notification via `NotificationCenter.default.post(name: .init("DTSettingsChanged"), object: nil)` on any change so the extension can react
  - Update `DontTouch/DontTouch/ContentView.swift`:
    - Bind to `AppSettings.shared` for the sensitivity slider and toggles
    - Show the current model status: "CoreML + Vision — operating on-device"
    - Show analytics summary: "Images analyzed: X, Videos analyzed: Y, Blocked: Z" (via message passing to the extension)
  - Create `DontTouch/DontTouch/iOS/` directory with iOS-specific files (stub for now):
    - `DontTouch/DontTouch/iOS/SceneDelegate.swift` — iOS scene configuration (placeholder, will enable when building for iOS device)

- [ ] Add error handling and edge cases:
  - Edit `DontTouch/DontTouch Detection/CoreMLAdapter.swift`:
    - Wrap Vision calls in `do/catch`: if `VNImageRequestHandler.perform` throws, log the error and return 0.0 (safe) rather than crashing
    - Handle empty image data or pixel buffer gracefully
    - Handle the case where the device has no Vision model available (pre-macOS 14 / iOS 17): log warning and return 0.0
  - Edit `DontTouch/DontTouch Extension/Resources/content.js`:
    - Skip `data:` URIs and `blob:` URIs (can't be loaded to canvas due to CORS)
    - Add CORS fallback: if canvas `toDataURL()` throws (tainted canvas), skip that image and log a warning
    - Handle video elements that are removed from DOM while being analyzed
    - Wrap all canvas operations in try/catch
    - If `browser.runtime.sendMessage` fails (extension context invalid), log and retry once after 1 second
  - Edit `SafariWebExtensionHandler.swift`:
    - Add a `Task` timeout of 10 seconds per analysis — if vision analysis takes longer, return `{blocked: false, timeout: true}` and log a warning
    - Handle the case where `userInfo` is nil or missing required keys

- [ ] Build, fix, and verify full project:
  - Run `cd /Users/mishaivchenko/dev/javarush_course/dontouch/DontTouch && xcodebuild -project DontTouch.xcodeproj -scheme DontTouch -destination "platform=macOS" build 2>&1`
  - If compilation errors:
    - Fix any `CVPixelBuffer` / `CGImageSource` import issues (CoreVideo, CoreGraphics, ImageIO)
    - Ensure `DontTouch_Detection` framework is imported in the extension handler with the correct module name (may be `DontTouch_Detection` or `DontTouchDetection` depending on XcodeGen target name)
    - Fix any missing method implementations or protocol conformance errors
    - Verify App Groups entitlement is properly configured in the generated project
  - After successful build, log: "✅ Phase 03 build complete — all detection targets compiling successfully"
  - Create a verification summary file at `DontTouch/VERIFICATION.md`:
    ```markdown
    # Don't Touch — Build Verification
    
    ## Build Status
    - **macOS app**: ✅ Builds and runs
    - **Safari Extension**: ✅ Included in bundle
    - **Detection Framework**: ✅ Compiles with Vision + CoreML
    
    ## Architecture
    - **Adapter Pattern**: `ContentAnalyzer` protocol → `CoreMLAdapter` / `StubAnalyzer`
    - **Orchestrator**: `AnalysisOrchestrator` actor manages pipeline, caching, thresholds
    - **Settings**: App Groups (`group.com.yourname.donttouch`) shared between app + extension
    
    ## Feature Status
    - [x] Extension activation and content script injection
    - [x] CSS blur injection (`dt-hidden` class)
    - [x] Image analysis via Vision framework (on-device)
    - [x] Video frame analysis via Vision framework
    - [x] Sensitivity threshold (0.0–1.0, default 0.6)
    - [x] Live stats in popover (analyzed / blocked counts)
    - [x] Settings persistence across sessions
    - [x] App Group sharing (macOS + iOS)
    ```
