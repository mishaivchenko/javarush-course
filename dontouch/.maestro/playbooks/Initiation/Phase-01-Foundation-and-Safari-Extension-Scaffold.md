# Phase 01: Foundation & Safari Extension Scaffold

Build the full project skeleton: Xcode project with Safari extension target, content script that injects CSS into web pages, toolbar popover UI, and a working build. By the end you'll have a "Don't Touch" badge appearing on any page and a popover ready for detection settings.

## Tasks

- [ ] Create Xcode project structure using XcodeGen:
  - First, check if XcodeGen is installed (`which xcodegen`). If not, install via `brew install xcodegen`.
  - Create the directory structure under `/Users/mishaivchenko/dev/javarush_course/dontouch/`:
    ```
    DontTouch/
    ├── Project.yml
    ├── DontTouch/
    │   ├── AppDelegate.swift
    │   ├── SceneDelegate.swift
    │   ├── ContentView.swift
    │   ├── Info.plist
    │   └── Assets.xcassets/
    │       ├── Contents.json
    │       ├── AppIcon.appiconset/
    │       └── Contents.json
    ├── DontTouch\ Extension/
    │   ├── SafariWebExtensionHandler.swift
    │   ├── Info.plist
    │   └── Resources/
    │       ├── manifest.json
    │       ├── background.js
    │       ├── content.js
    │       ├── popup.html
    │       ├── popup.css
    │       └── popup.js
    └── DontTouch\ Detection/
        ├── ContentAnalyzer.swift
        └── Info.plist
    ```
  - Write `DontTouch/Project.yml` with XcodeGen config: macOS app target (DontTouch, SwiftUI, macOS 14.0), Safari Extension target (DontTouch Extension, productType: app-extension, iOS + macOS), and a Dynamic Library framework target (DontTouch Detection). Set bundle identifiers: `com.yourname.DontTouch`, `com.yourname.DontTouch.Extension`, `com.yourname.DontTouch.Detection`. Link the extension and framework targets to the app target.

- [ ] Write the main macOS app files:
  - `DontTouch/DontTouch/AppDelegate.swift`: Standard NSApplicationDelegate that launches the app. On first launch, show the settings/onboarding window; on subsequent launches, hide to menu bar with a status item.
  - `DontTouch/DontTouch/ContentView.swift`: SwiftUI view with:
    - App title "Don't Touch 🚫" at top (large font, bold)
    - Status text: "Extension is [Enabled/Disabled]" using `@AppStorage("extensionEnabled")`
    - Button "Open Safari Extension Preferences" that calls `SFSafariApplication.showPreferencesForExtension(withIdentifier: "com.yourname.DontTouch.Extension")`
    - Help text: "Enable the extension in Safari → Settings → Extensions"
    - A quit button "Quit" that calls `NSApplication.shared.terminate(nil)`
  - `DontTouch/DontTouch/Info.plist`: Standard macOS app plist with bundle identifier `com.yourname.DontTouch`, `NSExtensionPointIdentifier` for Safari, and `LSApplicationCategoryType` set to `public.app-category.utilities`.

- [ ] Write the Safari extension handler and resources:
  - `DontTouch/DontTouch Extension/SafariWebExtensionHandler.swift`: Subclass `NSExtensionRequestHandler` conforming to `SFSafariExtensionHandling`. Implement:
    - `beginRequest(with context: NSExtensionContext)` — validates and logs activation
    - `messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String: Any]?)` — handles messages: `"pageLoaded"` → responds `{status: "ready"}`, `"analyzeImage"` → (stub for Phase 02), `"getSettings"` → reads from UserDefaults and returns `{threshold: 0.6, blockImages: true, blockVideos: true}`
    - `validateContext(with parameters: Any?, validationHandler:)` — returns `true` for all pages
    - `popoverViewController()` — returns a `NSViewController` that loads `popup.html` from the Resources bundle
    - Store user defaults in an App Group suite with identifier `group.com.yourname.donttouch` using `UserDefaults(suiteName:)`
  - `DontTouch/DontTouch Extension/Info.plist`: Extension plist with `NSExtension` dictionary, `SFSafariExtensionBundleIdentifier` set to `com.yourname.DontTouch.Extension`, `SFSafariWebsiteAccess` = `All`, bundle identifier `com.yourname.DontTouch.Extension`.

- [ ] Write the Safari web extension resources (JS/CSS/HTML):
  - `DontTouch/DontTouch Extension/Resources/manifest.json`:
    ```json
    {
      "manifest_version": 2,
      "name": "Don't Touch",
      "version": "1.0",
      "description": "AI-powered 18+ content blocker — private, on-device, no data leaves your machine",
      "permissions": ["<all_urls>", "storage"],
      "background": {
        "scripts": ["background.js"],
        "persistent": false
      },
      "content_scripts": [{
        "matches": ["<all_urls>"],
        "js": ["content.js"],
        "run_at": "document_end"
      }],
      "browser_action": {
        "default_popup": "popup.html",
        "default_icon": {
          "16": "icon-16.png",
          "48": "icon-48.png",
          "128": "icon-128.png"
        }
      },
      "icons": {
        "16": "icon-16.png",
        "48": "icon-48.png",
        "128": "icon-128.png"
      }
    }
    ```
  - `DontTouch/DontTouch Extension/Resources/background.js`: Listens for browser action clicks, relays messages between content scripts and native app using `browser.runtime.sendNativeMessage`. On install, sets default settings in `browser.storage.local`.
  - `DontTouch/DontTouch Extension/Resources/content.js`:
    - On load, inject a CSS stylesheet with: `.dt-hidden { filter: blur(20px) !important; pointer-events: none; user-select: none; }`, `.dt-badge { position: fixed; top: 8px; right: 8px; z-index: 2147483647; background: rgba(13,7,9,0.85); color: #c4b8a8; font: 12px -apple-system; padding: 4px 8px; border-radius: 4px; display: flex; align-items: center; gap: 4px; animation: dt-pulse 2s ease-in-out infinite; pointer-events: none; }`, `@keyframes dt-pulse { 0%,100% { opacity: 0.7; } 50% { opacity: 1; } }`
    - Create and append the badge element: `<div class="dt-badge">🚫 DT</div>`
    - Log `"[Don't Touch] Active on this page"` to console
    - Listen for messages from native extension via `browser.runtime.onMessage`: handle `"block"` (adds `.dt-hidden` class to the element matched by the given CSS selector) and `"unblock"` (removes the class)
    - Page scan (stub, will be filled in Phase 02): on DOMContentLoaded, scan all `<img>` and `<video>` elements and send them to native via `browser.runtime.sendMessage({type: "pageScanned", count: imgCount + videoCount})`
  - `DontTouch/DontTouch Extension/Resources/popup.html`: A clean 300×250 popup with:
    - Title "Don't Touch 🚫"
    - Sensitivity slider (0.0–1.0, default 0.6, labeled "Sensitivity")
    - Toggle "Block Images" (default ON)
    - Toggle "Block Videos" (default ON)
    - Status text: "Analyzed: 0 | Blocked: 0"
    - Footer: "🔒 On-device, 100% private"
    - Links to `popup.css` and `popup.js`
  - `DontTouch/DontTouch Extension/Resources/popup.css`: Dark theme matching the app: background `#0d0907`, text `#c4b8a8`, accent `#6b1414`, slider styling, toggle switches styled as CSS-only checkboxes, smooth transitions.
  - `DontTouch/DontTouch Extension/Resources/popup.js`: On load, reads settings from `browser.storage.local` and populates controls. On change, saves settings back to `browser.storage.local` and sends message to content script to update behavior. Uses `browser.tabs.query({active: true, currentWindow: true})` to communicate with the active tab's content script for live stats updates.

- [ ] Write the Detection framework scaffold:
  - `DontTouch/DontTouch Detection/ContentAnalyzer.swift`: Define the **Adapter Pattern** protocol:
    ```swift
    import Foundation
    import CoreVideo

    /// Protocol defining the content analysis interface.
    /// Implementations can be swapped (CoreML, custom model, future cloud fallback)
    /// without changing the rest of the system.
    public protocol ContentAnalyzer {
        /// Analyze an image and return a confidence score (0.0 = safe, 1.0 = certainly 18+)
        func analyze(imageData: Data) async -> Double
        
        /// Analyze a video frame and return a confidence score
        func analyze(videoFrame: CVPixelBuffer) async -> Double
    }
    ```
    Add a placeholder `StubAnalyzer` that conforms to `ContentAnalyzer`:
    ```swift
    /// Stub analyzer — always returns 0.0 (safe).
    /// Replace with CoreMLAdapter in Phase 02.
    public struct StubAnalyzer: ContentAnalyzer {
        public func analyze(imageData: Data) async -> Double { 0.0 }
        public func analyze(videoFrame: CVPixelBuffer) async -> Double { 0.0 }
        public init() {}
    }
    ```
  - `DontTouch/DontTouch Detection/Info.plist`: Framework plist with bundle identifier `com.yourname.DontTouch.Detection`.

- [ ] Generate the Xcode project and verify the build:
  - Run `cd /Users/mishaivchenko/dev/javarush_course/dontouch/DontTouch && xcodegen generate` to generate the `.xcodeproj`
  - If XcodeGen is not available, instead create a minimal Xcode project by running `swift package init --type executable --name DontTouch` then manually restructure, OR write a `Makefile` that creates the project using the `xcodebuild` tooling
  - After project generation, build the main app: `xcodebuild -project DontTouch.xcodeproj -scheme DontTouch -destination "platform=macOS" build`
  - If the build fails, fix build settings issues (missing Info.plist paths, missing framework search paths, bundle identifier mismatches) and retry. Common fixes: verify all Info.plist files are in the correct targets' Copy Bundle Resources phase, ensure the Safari Extension target has the correct `PRODUCT_BUNDLE_IDENTIFIER`, verify the framework target is linked to the main app target.
  - Once the build succeeds, verify the resulting `.app` bundle exists at `DerivedData` or the build products directory. Log success: "✅ Phase 01 build complete — DontTouch.app created successfully at [path]"
