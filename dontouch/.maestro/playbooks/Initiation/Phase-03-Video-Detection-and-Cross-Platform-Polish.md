# Phase 03: Video Detection & Cross-Platform Polish

Add video frame analysis — sample frames from `<video>` elements and classify them through the same Adapter Pattern pipeline. Polish the extension with a sensitivity slider that takes effect live, proper App Group settings sharing between macOS and iOS, and thorough cross-platform verification.

## Status: Partially Complete (built, needs polish tasks)

## Tasks

- [x] Implement the content-side video frame extraction in contentBlocker.js:
  - `scanVideos()`, `setupVideoScanning()`, `onVideoPlay()`, `scheduleFrameSample()` — all present
  - Canvas capture max 512×512, base64 JPEG quality 0.7, every 2 seconds
  - Blocked video: `dt-hidden` + pause + `.dt-video-overlay` overlay
  - **Known gap:** No `window.__dtVideoStates` per-video running state, no 2-of-3 consecutive frames logic

- [x] Create VideoFrameExtractor.swift in detection framework:
  - `pixelBuffer(from base64String:)`, `pixelBuffer(from data:)`, `pixelBuffer(from ciImage:)`
  - Uses `CIImage` + `CIContext` + `CVPixelBufferCreate`
  - Error cases: `FrameError.invalidData`, `FrameError.conversionFailed`

- [x] Update native handler for video frames:
  - `handleAnalyzeVideoFrame()` decodes base64, calls `engine.analyzeVideoFrame(base64:)`
  - Responds with `{action: "block", selector: "..."}`
  - **Known gap:** No 10-second analysis timeout

- [x] Implement live sensitivity slider and settings persistence:
  - Popup: sensitivity slider (0-100%), 3 toggles (images/video/text), pause/resume button, blocked count
  - Settings saved to `browser.storage.local` + relayed to native `saveSettings`
  - `handleSaveSettings()` writes to App Groups UserDefaults
  - **Known gap:** No "Apply to current page" button, no `clearCache`/`reanalyze` handlers

- [x] Add App Group settings and entitlements:
  - `AppSettings.swift` — `@Published sensitivityThreshold` (default 0.6), `extensionEnabled`, App Groups backing
  - Both targets have `group.com.yourname.donttouch` entitlement plists
  - iOS deployment target 17.0 defined in Project.yml
  - **Known gap:** Extension target only builds for macOS — iOS not configured

- [x] Add error handling and edge cases (partial):
  - `CoreMLAdapter.swift`: do/catch on Vision calls, returns 0.0 on failure
  - **Known gap:** No `data:`/`blob:` URI skip, no canvas try/catch, no removed-video guard, no sendMessage retry

- [ ] **Remaining work (6 tasks, see DONT-TOUCH-03.md):**
  - Per-video running state + 2-of-3 frame logic in contentBlocker.js
  - "Apply to current page", clearCache, reanalyze handlers
  - Edge-case handling (data: URIs, canvas errors, removed videos, retry)
  - 10-second analysis timeout in native handler
  - iOS platform for extension target
  - Full build verification + VERIFICATION.md
