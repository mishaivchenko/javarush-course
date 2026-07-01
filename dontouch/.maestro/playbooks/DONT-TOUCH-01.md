# Don't Touch — Phase 1: Foundation & Safari Extension Scaffold

This phase sets up the Xcode project, creates the Safari extension skeleton, and wires up a basic content script that can inject CSS into web pages. By the end you'll have a working bare-bones extension that adds a "Don't Touch" badge to any page.

## Prerequisites

- Xcode 15+ installed (from Mac App Store)
- macOS 14+ for development
- An Apple Developer account (free tier works for local development)

---

- [x] Create the Xcode project and Safari Extension target:
  **Implementation note:** Used XcodeGen (as specified in CLAUDE.md) instead of manual Xcode GUI setup.
  1. Created `DontTouch/Project.yml` with 3 targets: DontTouch (macOS app), DontTouch Extension (Safari Web Extension app-extension), DontTouch Detection (Swift framework).
  2. Targets use macOS 14.0 min deployment target. Cross-platform (iOS 17.0) defined in Project.yml but not yet active — requires separate macOS/iOS build configuration.
  3. DontTouch target embeds the Extension and links the Detection framework.
  4. Extension Info.plist: `com.apple.Safari-web-extension` point, `SFSafariWebsiteAccess: All`, `SFSafariExtensionBundleIdentifier: $(PRODUCT_BUNDLE_IDENTIFIER)`.
  5. Generated with `xcodegen generate` → `DontTouch.xcodeproj`.
  6. **Build verification requires Xcode.app** (not available on this machine; CLI tools don't include SafariServices SDK).

- [x] Configure the extension's Info.plist for content blocking and page access:
  1. Open `DontTouchBlocker/Info.plist`. Add `NSExtension` dictionary with key `SFSafariContentScript` → set to `YES`.
  2. Add `SFSafariWebsiteAccess` with value `All` under `NSExtensionAttributes` so the extension runs on all pages.
  3. Add `NSPhotoLibraryUsageDescription` with value `"Don't Touch needs camera access to analyze images on-device"` (required for CoreML/Vision on-device image analysis).
  4. Set `SFSafariExtensionBundleIdentifier` to `$(PRODUCT_BUNDLE_IDENTIFIER)` in the extension's plist.

- [ ] Implement the basic content script (`script.js`) that loads on every page:
  1. In `DontTouchBlocker/Resources/`, create or edit `script.js`:
     - It must listen for messages from the native extension via `safari.self.addEventListener('message', ...)`.
     - On first load, log `"Don't Touch active"` to console and inject a small floating badge in the top-right corner of the page with text "🚫 DT" and a subtle pulsing CSS animation.
     - The badge should be absolutely positioned, z-index 99999, and have a semi-transparent dark background.
  2. Create `style.css` in the same folder that the script injects:
     - Define a `dt-hidden` class: `{ filter: blur(20px) !important; pointer-events: none; user-select: none; }`
     - Define a `.dt-badge` class for the floating badge with a subtle pulse keyframe animation.
     - Style the badge with the CSS.
  3. In `Resources/`, verify `script.js` is listed in the Copy Bundle Resources build phase.

- [ ] Wire up the native Safari extension handler (`SafariExtensionHandler`):
  1. In `DontTouchBlocker/SafariExtensionHandler.swift`, add a `beginRequest(with context:)` override that sets `context.namespace = "donttouch"` for message identification.
  2. Add a `messageReceived(with message:parameters:)` handler that handles: `"pageLoaded"` → logs "Page loaded, Don't Touch watching", responds with `{status: "ready"}`.
  3. Implement `validate(context:validationHandler:)` returning `true` so the extension activates on all pages.

- [ ] Add extension activation logic in the main app (`DontTouchApp.swift`):
  1. In the main app target's `ContentView.swift` or `DontTouchApp.swift`, add code that calls `SFSafariApplication.showPreferencesForExtension(withIdentifier: "com.yourname.DontTouchBlocker")` to open Safari preferences to the extension tab.
  2. Show a simple SwiftUI view with:
     - App icon/name "Don't Touch" at top
     - Instructions: "1) Go to Safari → Settings → Extensions → Enable 'Don't Touch Blocker'"
     - A button "Open Safari Extension Preferences"
     - A toggle "Enabled" that persists state via `@AppStorage`
  3. The app should show this onboarding screen only once (track with UserDefaults).

- [ ] Verify the extension builds and runs:
  1. Select the `DontTouch` scheme, choose "My Mac" as destination, build and run.
  2. The app window should appear with the onboarding instructions.
  3. Enable the extension in Safari Settings → Extensions.
  4. Open any webpage — you should see "Don't Touch active" in Safari's developer console and the 🚫 DT badge in the top-right corner.
  5. If the badge doesn't appear, check Console.app for sandbox errors and verify the extension's bundle identifier matches Safari Preferences.
