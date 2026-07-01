# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Don't Touch 🚫** — A cross-platform Safari extension (macOS + iOS) that detects and blurs NSFW/adult content using on-device AI. CoreML/Vision framework runs entirely on-device — zero network calls, 100% private.

## Architecture

Three Xcode targets defined declaratively in `DontTouch/Project.yml` (XcodeGen), expanded to four via platform-specific variants:

1. **DontTouch** — macOS host app (SwiftUI). Onboarding screen, Safari extension preferences link, status display.
2. **DontTouch_iOS** — iOS host app (SwiftUI). Same shared sources as macOS, with iOS-specific stubs.
3. **DontTouch Extension (macOS + iOS variants)** — Safari Web Extension (JS/CSS/HTML). Content script (`content.js`) scans images/video frames/text on every page. Native handler (`SafariWebExtensionHandler.swift`) processes messages and runs detection (macOS full implementation; iOS stub due to missing SFSafariExtensionHandling types).
4. **DontTouch Detection** — Swift framework with the detection pipeline. Uses the **Adapter Pattern**: `ContentAnalyzer` protocol → `CoreMLAdapter` (Vision framework) / `StubAnalyzer` (placeholder). Compiled as source in all four targets.

### Cross-target dependencies

- `DontTouch` host app depends on both `DontTouch Extension` (embedded) and `DontTouch Detection` (linked)
- `DontTouch Extension` (native handler) depends on `DontTouch Detection` for on-device analysis — imported as `import DontTouch_Detection`
- `DontTouch Detection` is a standalone framework with no dependencies (pure Swift + system frameworks)
- All Detection framework types accessed cross-module are marked `public`

### Key architectural decisions

- **Adapter Pattern for detection**: `ContentAnalyzer` protocol abstracts the ML backend. `CoreMLAdapter` conforms to it using Apple's Vision framework (`VNClassifyImageRequest` with NSFW-relevant label mapping). Swap implementations without touching the rest of the system.
- **Built-in Vision classifier**: Uses `VNClassifyImageRequest` — no custom CoreML model file required. Apple's on-device classifier ships with a pre-trained Inceptionv3-derived model. NSFW detection works by flagging classification labels (swimwear, lingerie, etc.) with weighted confidence scoring. A future custom `.mlpackage` can be loaded via `NSFWClassifier.loadModel()` for higher accuracy.
- **AnalysisEngine singleton**: `AnalysisEngine.shared` is the central entry point called by `SafariWebExtensionHandler`. It wraps `AnalysisOrchestrator` for image analysis, handles URL-based caching (per-URL, session-scoped), runs text blocklist matching via `blocklist.txt`, provides `analyzeVideoFrame()` for `CVPixelBuffer` and base64 inputs, and offers `shouldBlock(confidence:)` that reads the user's sensitivity threshold from `UserDefaults` (App Group `group.com.yourname.donttouch`, default 0.6).
- **AnalysisOrchestrator actor**: Singleton actor (`AnalysisOrchestrator.shared`) manages the Vision pipeline, caches results per image data hash (SHA-256), and applies the user's sensitivity threshold. Actors serialize access to mutable state without locks.
- **App Groups for settings**: `UserDefaults(suiteName: "group.com.yourname.donttouch")` shared between the host app and Safari extension. Settings manager (`AppSettings.swift`) uses `@Published` for SwiftUI reactivity.
- **Safari Web Extension model**: Content script (`content.js`) injects CSS (`dt-hidden` class with `filter: blur(20px)`) and communicates with the native extension via `browser.runtime.sendMessage`. Native handler processes heavy work (Vision analysis) and responds with block decisions.
- **Privacy by design**: No network calls in the detection pipeline. All ML inference is on-device via the Vision framework that ships with macOS/iOS.

### Detection flow

1. `content.js` runs on every page at `document_end` — injects badge, CSS, sends pageLoaded
2. `contentBlocker.js` runs alongside — scans `<img>` elements (collected as src+selector batch), `<video>` elements (frame-sampled every 2s via canvas), and text nodes (keyword blocklist matching via TreeWalker)
3. Content scripts send messages via `browser.runtime.sendMessage()`
4. `background.js` catches all messages and forwards to native via `safari.self.tab.dispatchMessage(name, payload)`
5. `SafariWebExtensionHandler.messageReceived(withName:from:userInfo:)` decodes each message type:
   - `"analyzeImages"`: fetches each image URL via URLSession, runs `AnalysisEngine.shared.analyzeImage(url:data:)`
   - `"analyzeVideoFrame"`: decodes base64, runs `AnalysisEngine.shared.analyzeVideoFrame(base64:)`
   - `"analyzeText"`: runs `AnalysisEngine.shared.analyzeText()` against blocklist
6. All detection uses on-device Vision framework (`VNClassifyImageRequest`) — zero network calls for ML
7. Native handler sends responses via `page.dispatchMessageToScript(withName: "donttouch-response", userInfo:)`
   - Responses always include `"type": "donttouch-response"` for content script `browser.runtime.onMessage` matching
   - Image/video: `{type, action: "block"|"unblock", selector: "..."}` — contentBlocker.js matches by CSS selector
   - Text: `{type, textBlocked: true, textId: N}` — contentBlocker.js matches by `data-dt-text-id` attribute
   - Legacy: `{type, blocked: true/false, url: "..."}` — content.js matches by `data-dt-url` attribute
8. `contentBlocker.js` applies/removes `dt-hidden` CSS class on the element

### CSS injection

- `.dt-hidden { filter: blur(20px) !important; pointer-events: none; user-select: none; }`
- `.dt-badge` — floating "🚫 DT" badge in top-right corner
- `.dt-video-overlay` — overlay for blocked video elements

## Commands

### Xcode project generation and build

```bash
# Generate .xcodeproj from Project.yml (after editing Project.yml)
cd DontTouch && xcodegen generate

# Build the macOS app (generates DontTouch.app)
cd DontTouch && xcodebuild -project DontTouch.xcodeproj -scheme DontTouch -destination "platform=macOS" build 2>&1

# Build for iOS (check compilation only)
cd DontTouch && xcodebuild -project DontTouch.xcodeproj -scheme DontTouch -destination "platform=iOS Simulator,name=iPhone 15" build 2>&1
```

### Development workflow

- Edit `Project.yml` for structural changes (new files, targets, capabilities, dependencies), then regenerate with `xcodegen generate`
- Add Swift source files to the appropriate target directory under `DontTouch/`
- Safari Web Extension resource files (JS/CSS/HTML) live in `DontTouch/DontTouch Extension/Resources/`
- The detection framework lives in `DontTouch/DontTouch Detection/`
- Run the app from Xcode: select `DontTouch` scheme, `My Mac` destination

### Playbooks

Multi-phase implementation covered in `.maestro/playbooks/`:
- **Phase 1** (`DONT-TOUCH-01.md`): Project scaffold, Safari extension, CSS injection, badge
- **Phase 2** (`DONT-TOUCH-02.md`): Adapter Pattern, CoreMLAdapter, image/text analysis, settings popover
- **Phase 3** (`DONT-TOUCH-03.md`): Video frame analysis, live slider, cross-platform polish, iOS build

## Project Structure

```
dontouch/
├── .maestro/playbooks/        — Multi-phase implementation plans
│   ├── DONT-TOUCH-01.md       — Foundation & Safari scaffold
│   ├── DONT-TOUCH-02.md       — Detection pipeline with Adapter Pattern
│   └── DONT-TOUCH-03.md       — Video analysis, iOS support, error handling
├── DontTouch/                  — XcodeGen project root
│   ├── Project.yml             — Declarative project definition (4 targets)
│   ├── .gitignore
│   ├── VERIFICATION.md         — Build status, architecture, feature checklist
│   ├── DontTouch/              — Shared host app source (macOS + iOS)
│   │   ├── DontTouchApp.swift  — SwiftUI @main (macOS, #if os(macOS))
│   │   ├── ContentView.swift   — Onboarding UI, settings (macOS-only APIs guarded)
│   │   ├── AppSettings.swift   — Shared settings with @Published
│   │   ├── Info.plist
│   │   └── iOS/                — iOS host app stubs
│   │       ├── iOSApp.swift    — SwiftUI @main (iOS, #if os(iOS))
│   │       ├── SceneDelegate.swift
│   │       └── Info.plist
│   ├── DontTouch Extension/    — Safari Web Extension (shared sources)
│   │   ├── SafariWebExtensionHandler.swift  — macOS full impl, iOS stub
│   │   ├── Info.plist           — macOS extension Info.plist
│   │   ├── iOS-Info.plist       — iOS extension Info.plist
│   │   └── Resources/
│   │       ├── manifest.json   — W3C extension manifest
│   │       ├── content.js      — Page scanner (images, video, text) — badge, CSS, messaging
│   │       ├── contentBlocker.js — Scanning module: images, video frames, text nodes, MutationObserver
│   │       ├── background.js   — Event relay
│   │       ├── popup.html/css/js — Toolbar popover settings UI
│   │       └── icons/
│   └── DontTouch Detection/    — Detection framework (compiled as source in all targets)
│       ├── ContentAnalyzer.swift      — Adapter protocol
│       ├── CoreMLAdapter.swift        — Vision-based analyzer
│       ├── NSFWClassifier.swift       — Classification helper
│       ├── AnalysisOrchestrator.swift  — Pipeline coordinator (actor)
│       ├── AnalysisEngine.swift       — Central entry point (singleton)
│       ├── VideoAnalyzer.swift        — AVPlayerItem frame sampler with running average
│       ├── VideoFrameExtractor.swift   — Base64 → CVPixelBuffer
│       ├── blocklist.txt              — NSFW keyword blocklist (~215 terms)
│       └── Info.plist
└── CLAUDE.md
```

## Build Targets (XcodeGen Project.yml)

| Target | Type | Platform | Bundle ID |
|---|---|---|---|
| `DontTouch` | Application | macOS | `com.yourname.donttouch` |
| `DontTouch_iOS` | Application | iOS | `com.yourname.donttouch` |
| `DontTouch_Extension_Mac` | Safari Web Extension | macOS | `com.yourname.donttouch.extension` |
| `DontTouch_Extension_iOS` | Safari Web Extension | iOS | `com.yourname.donttouch.extension` |

- macOS app (`DontTouch`) embeds `DontTouch_Extension_Mac`
- iOS app (`DontTouch_iOS`) embeds `DontTouch_Extension_iOS`
- App Groups (`group.com.yourname.donttouch`) shared across all targets
