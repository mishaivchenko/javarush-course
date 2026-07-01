# Don't Touch — Phase 3: Video Detection, Live Slider, Polish & Error Handling

Add real video frame analysis, live sensitivity slider, cross-platform App Groups, error handling, and build verification.

## Prerequisites

- Phase 1 and 2 complete (working extension with image/text detection, popover settings, App Groups)

---

- [x] Implement content-side video frame extraction in contentBlocker.js:
  - `setupVideoScanning()` — scans `<video>` elements not yet marked with `data-dt-video-setup`, attaches play-event listener (fires once)
  - `onVideoPlay()` — pauses blocked videos immediately, calls `scheduleFrameSample()` otherwise
  - `scheduleFrameSample()` — creates offscreen canvas (max 512×512), draws current frame, sends base64 JPEG (quality 0.7) via `browser.runtime.sendMessage({type: "analyzeVideoFrame", data: base64, selector: "..."})`
  - Resamples every 2 seconds while video plays
  - Covers blocked video: adds `dt-hidden` class, pauses video, inserts `.dt-video-overlay` overlay div
  - **Missing:** running per-video state (`window.__dtVideoStates`) and 2-of-3 consecutive frames logic — currently blocks on first flagged frame

- [x] Create VideoFrameExtractor utility in `DontTouch/DontTouch Detection/VideoFrameExtractor.swift`:
  - Public class with three overloads: `pixelBuffer(from base64String:)`, `pixelBuffer(from data:)`, `pixelBuffer(from ciImage:)`
  - Uses `CIImage` + `CIContext` + `CVPixelBufferCreate` for conversion
  - Handles error cases: `FrameError.invalidData`, `FrameError.conversionFailed`

- [x] Wire up native `handleAnalyzeVideoFrame()` in `SafariWebExtensionHandler.swift`:
  - Decodes base64 from payload, calls `engine.analyzeVideoFrame(base64:)`
  - Sends `{type: "donttouch-response", action: "block", selector: "..."}` if confidence exceeds threshold
  - **Missing:** 10-second timeout per analysis, guard against nil/missing keys in userInfo

- [x] Add live sensitivity slider and settings persistence in popup.html / popup.js:
  - Sensitivity slider (0-100%) with live percentage display
  - Three toggles: Block Images, Block Videos, Block Text
  - Pause/Resume toggle button
  - Settings saved to `browser.storage.local` AND relayed to native handler via `saveSettings` message
  - `handleSaveSettings()` writes to `UserDefaults(suiteName: "group.com.yourname.donttouch")`
  - Blocked count queried from background.js
  - **Missing:** "Apply to current page" button, `clearCache` handler, `reanalyze` message

- [x] Add App Settings manager in `DontTouch/DontTouch/AppSettings.swift`:
  - `AppSettings.shared` singleton backed by `UserDefaults(suiteName: "group.com.yourname.donttouch")`
  - `@Published` properties: `sensitivityThreshold` (default 0.6), `extensionEnabled` (default false)
  - `registerDefaults()` class method for extension-side initialization

- [x] Configure App Groups entitlements in both targets:
  - `DontTouch.entitlements` and `DontTouch_Extension.entitlements` both include `group.com.yourname.donttouch`
  - Linked in `Project.yml` via `CODE_SIGN_ENTITLEMENTS`

- [x] Add video frame analysis path in `AnalysisEngine.swift`:
  - `analyzeVideoFrame(_ pixelBuffer: CVPixelBuffer) async -> Double` — converts pixel buffer to CIImage, classifies via `NSFWClassifier.classify()`
  - `analyzeVideoFrame(base64: String) async -> Double` — decodes base64 → CIImage → classify
  - Both return `0.0` on error (safe default)

- [x] Add error handling in `CoreMLAdapter.swift`:
  - Vision calls wrapped in `do/catch`, returns `0.0` on failure
  - Handles `invalidImageData` case gracefully

- [x] Add running per-video state with 2-of-3 consecutive frame logic in `contentBlocker.js`:
  - `DontTouch/DontTouch Extension/Resources/contentBlocker.js`
  - Track each video with `window.__dtVideoStates[videoId] = { blocked: false, frameCount: 0, positiveFrames: 0 }`
  - Block only after 2 out of 3 consecutive frames are flagged (prevents flickering)
  - Unblock when running average drops below threshold
  - See Phase-03 Initiation doc for full spec

- [x] Add "Apply to current page" button, `clearCache` and `reanalyze` handlers:
  - `DontTouch/DontTouch Extension/Resources/popup.js`:
    - Add "Apply to current page" button that sends `{type: "reanalyze"}` to content script
  - `DontTouch/DontTouch Extension/SafariWebExtensionHandler.swift`:
    - Add `"clearCache"` handler: calls `AnalysisOrchestrator.shared.clearCache()`, responds `{cleared: true}`
    - Add `"reanalyze"` handler: clear cache + ask content script to re-scan all images
  - `DontTouch/DontTouch Extension/Resources/contentBlocker.js`:
    - Add `reanalyze` message handler: remove `data-dt-scanned`/`data-dt-video-setup` from all elements, clear `dt-hidden` class, re-run `scanImages()`, `setupVideoScanning()`, `scanText()`

- [x] Add edge-case handling in content scripts:
  - `contentBlocker.js`:
    - Skip `data:` URIs and `blob:` URIs (can't load to canvas due to CORS)
    - Wrap all canvas operations in try/catch (tainted canvas fallback)
    - Handle video elements removed from DOM while being analyzed
    - If `browser.runtime.sendMessage` fails, retry once after 1 second
  - `content.js`:
    - Skip `data:` and `blob:` URIs in legacy `checkImage` path

- [x] Add 10-second analysis timeout in `SafariWebExtensionHandler.swift`:
  - Wrap each `Task` in a timeout: if Vision analysis takes > 10s, respond with `{blocked: false, timeout: true}`
  - Guard against nil/empty/missing keys in `userInfo` for all message handlers
  - Log warning on timeout

- [x] Add iOS platform to Safari Extension target in `Project.yml`:
  - `DontTouch/Project.yml`: add `platforms: [macOS, iOS]` to `DontTouch Extension` target
  - Create `DontTouch/DontTouch/iOS/` stub directory with placeholder `SceneDelegate.swift`
  - Verify entitlements are compatible with iOS (App Groups same identifier)
  - Run `xcodegen generate` and attempt iOS build

- [x] Build, fix, and verify full project:
  - Run `cd DontTouch && xcodebuild -project DontTouch.xcodeproj -scheme DontTouch -destination "platform=macOS" build 2>&1`
  - Fix any compilation errors:
    - `CVPixelBuffer` / `CGImageSource` import issues (CoreVideo, CoreGraphics, ImageIO)
    - Module name for `DontTouch_Detection` import (XcodeGen target name may differ)
    - Missing method implementations or protocol conformance errors
  - Create `DontTouch/VERIFICATION.md` with build status, architecture summary, and feature checklist

## Human-only verification steps (not auto-run tasks)

- Open `DontTouch.xcodeproj` in Xcode, build and run with "My Mac" destination
- Verify extension activates in Safari → Settings → Extensions
- Test on a page with images, video, and text — verify blur works
- Test sensitivity slider changes take effect live
- Test pause/resume toggle in popover
- Verify 🚫 DT badge appears on all pages
- Test on iOS (requires Apple Developer Program account)
