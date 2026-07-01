# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Don't Touch 🚫** — A cross-platform Safari extension (macOS + iOS) that detects and blurs NSFW/adult content using on-device AI. CoreML/Vision framework runs entirely on-device — zero network calls, 100% private.

## Architecture

Three Xcode targets defined declaratively in `DontTouch/Project.yml` (XcodeGen):

1. **DontTouch** — macOS host app (SwiftUI). Onboarding screen, Safari extension preferences link, status display.
2. **DontTouch Extension** — Safari Web Extension (JS/CSS/HTML). Content script (`content.js`) scans images/video frames/text on every page. Native handler (`SafariWebExtensionHandler.swift`) processes messages and runs detection.
3. **DontTouch Detection** — Swift framework with the detection pipeline. Uses the **Adapter Pattern**: `ContentAnalyzer` protocol → `CoreMLAdapter` (Vision framework) / `StubAnalyzer` (placeholder).

### Key architectural decisions

- **Adapter Pattern for detection**: `ContentAnalyzer` protocol abstracts the ML backend. `CoreMLAdapter` conforms to it using Apple's Vision framework (`VNClassifyImageRequest` with NSFW-relevant label mapping). Swap implementations without touching the rest of the system.
- **Built-in Vision classifier**: Uses `VNClassifyImageRequest` — no custom CoreML model file required. Apple's on-device classifier ships with a pre-trained Inceptionv3-derived model. NSFW detection works by flagging classification labels (swimwear, lingerie, etc.) with weighted confidence scoring. A future custom `.mlpackage` can be loaded via `NSFWClassifier.loadModel()` for higher accuracy.
- **AnalysisOrchestrator actor**: Singleton actor (`AnalysisOrchestrator.shared`) manages the pipeline, caches results per URL hash (SHA-256), and applies the user's sensitivity threshold. Actors serialize access to mutable state without locks.
- **App Groups for settings**: `UserDefaults(suiteName: "group.com.yourname.donttouch")` shared between the host app and Safari extension. Settings manager (`AppSettings.swift`) uses `@Published` for SwiftUI reactivity.
- **Safari Web Extension model**: Content script (`content.js`) injects CSS (`dt-hidden` class with `filter: blur(20px)`) and communicates with the native extension via `browser.runtime.sendMessage`. Native handler processes heavy work (Vision analysis) and responds with block decisions.
- **Privacy by design**: No network calls in the detection pipeline. All ML inference is on-device via the Vision framework that ships with macOS/iOS.

### Detection flow

1. `content.js` runs on every page at `document_end`
2. Scans `<img>` elements (sampled to canvas, max 512×512), `<video>` elements (frame-sampled every 3s), and text nodes (keyword blocklist matching)
3. Sends data as base64 to native via `browser.runtime.sendMessage`
4. `SafariWebExtensionHandler` decodes → `AnalysisOrchestrator.shared.analyzeImage()` → `CoreMLAdapter` / `VNClassifyImageRequest` → returns confidence 0.0–1.0
5. Compares against user threshold (default 0.6) → responds with `blocked: true/false`
6. `content.js` applies/removes the `dt-hidden` CSS class on the element

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
- **Phase 3** (Initiation): Video frame analysis, live slider, cross-platform polish, App Groups

## Project Structure

```
dontouch/
├── .maestro/playbooks/        — Multi-phase implementation plans
│   ├── DONT-TOUCH-01.md       — Foundation & Safari scaffold
│   ├── DONT-TOUCH-02.md       — Detection pipeline with Adapter Pattern
│   └── Initiation/             — Phase 03 details (video, polish)
├── DontTouch/                  — XcodeGen project root (once scaffolded)
│   ├── Project.yml             — Declarative project definition
│   ├── DontTouch/              — macOS host app
│   │   ├── DontTouchApp.swift  — SwiftUI @main app entry point
│   │   ├── ContentView.swift   — Onboarding UI, settings
│   │   ├── AppSettings.swift   — Shared settings with @Published
│   │   └── Info.plist
│   ├── DontTouch Extension/    — Safari Web Extension
│   │   ├── SafariWebExtensionHandler.swift  — Native message handler
│   │   ├── Info.plist
│   │   └── Resources/
│   │       ├── manifest.json   — W3C extension manifest
│   │       ├── content.js      — Page scanner (images, video, text)
│   │       ├── background.js   — Event relay
│   │       ├── popup.html/css/js — Toolbar popover settings UI
│   │       └── icons/
│   └── DontTouch Detection/    — Detection framework
│       ├── ContentAnalyzer.swift      — Adapter protocol
│       ├── CoreMLAdapter.swift        — Vision-based analyzer
│       ├── NSFWClassifier.swift       — Classification helper
│       ├── AnalysisOrchestrator.swift  — Pipeline coordinator (actor)
│       ├── VideoFrameExtractor.swift   — Base64 → CVPixelBuffer
│       └── Info.plist
└── CLAUDE.md
```
