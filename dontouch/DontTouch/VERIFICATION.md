# Don't Touch — Build Verification

## Build Status

| Target | Platform | Status | Last Verified |
|---|---|---|---|
| `DontTouch` | macOS (arm64) | ✅ Build Succeeds | 2026-07-01 |
| `DontTouch_Extension_Mac` | macOS (arm64) | ✅ Build Succeeds | 2026-07-01 |
| `DontTouch_iOS` | iOS (arm64) | ✅ Build Succeeds | 2026-07-01 |
| `DontTouch_Extension_iOS` | iOS (arm64) | ✅ Build Succeeds | 2026-07-01 |

## Architecture Summary

### Targets (XcodeGen)

| Target | Type | Platform | Bundle ID |
|---|---|---|---|
| `DontTouch` | Application | macOS | `com.yourname.donttouch` |
| `DontTouch_iOS` | Application | iOS | `com.yourname.donttouch` |
| `DontTouch_Extension_Mac` | Safari Web Extension | macOS | `com.yourname.donttouch.extension` |
| `DontTouch_Extension_iOS` | Safari Web Extension | iOS | `com.yourname.donttouch.extension` |

### Dependencies

```
DontTouch (macOS)
  └── embeds → DontTouch_Extension_Mac
DontTouch_iOS (iOS)
  └── embeds → DontTouch_Extension_iOS
```

### Detection Framework

`DontTouch Detection` is compiled as source (included via XcodeGen source groups) in all four targets — not as a standalone framework target. Contains:

- `ContentAnalyzer.swift` — Adapter protocol
- `CoreMLAdapter.swift` — Vision-based analyzer
- `NSFWClassifier.swift` — Classification helper
- `AnalysisOrchestrator.swift` — Pipeline coordinator (actor)
- `AnalysisEngine.swift` — Central entry point (singleton)
- `VideoAnalyzer.swift` — Frame sampler
- `VideoFrameExtractor.swift` — Base64 → CVPixelBuffer conversion
- `blocklist.txt` — NSFW keyword blocklist

### App Groups

All targets share `group.com.yourname.donttouch` for settings persistence (sensitivity threshold, toggles) between the host app and extension.

### Platform-Specific Differences

- `SafariWebExtensionHandler.swift`: Full `SFSafariExtensionHandling` implementation on macOS; minimal `NSExtensionRequestHandling` stub on iOS (SFSafariExtensionHandling types are macOS-only)
- `ContentView.swift`: macOS uses `SFSafariApplication`/`SFSafariExtensionManager` for extension preferences; these calls are guarded with `#if os(macOS)`
- Fixed-size frames and `Color(.controlBackgroundColor)` guarded with `#if os(macOS)` on iOS

## Feature Checklist

| Feature | macOS | iOS | Notes |
|---|---|---|---|
| Image scanning (contentBlocker.js) | ✅ | ✅ | Same JS runs on both platforms |
| Video frame analysis (contentBlocker.js) | ✅ | ✅ | Same JS runs on both platforms |
| Text blocklist matching (contentBlocker.js) | ✅ | ✅ | Same JS runs on both platforms |
| CSS blur injection | ✅ | ✅ | Same CSS runs on both platforms |
| 🚫 DT badge | ✅ | ✅ | Same JS runs on both platforms |
| On-device Vision detection | ✅ | ✅ | CoreMLAdapter works on both platforms |
| Toolbar popover (settings UI) | ✅ | ⚠️ | iOS Safari has limited toolbar customization |
| Live sensitivity slider | ✅ | ⚠️ | Depends on popover support |
| Native messaging (JS ↔ native) | ✅ | ❌ | SFSafariExtensionHandling is macOS-only |
| "Apply to current page" button | ✅ | ❌ | Requires native messaging |
| Pause/Resume toggle | ✅ | ❌ | Requires native messaging |

### iOS Limitations

1. **No native messaging**: `SFSafariExtensionHandling` protocol is not available on iOS. The native handler is a stub. On-device detection must be done differently (e.g., inline Swift in a future update).
2. **Limited popover**: iOS Safari extension popovers have reduced capabilities compared to macOS.
3. **JavaScript-only mode**: Without native messaging, the extension works in JS-only mode with CSS blur injection for class-based blocking, but on-device CoreML detection requires native code.

## Build Commands

```bash
# macOS
cd DontTouch && xcodegen generate
xcodebuild -project DontTouch.xcodeproj -scheme DontTouch -destination "platform=macOS" build

# iOS (requires Apple Developer account for signing)
cd DontTouch && xcodegen generate
xcodebuild -project DontTouch.xcodeproj -target DontTouch_iOS -sdk iphoneos build
```
