---
type: spec
title: Safari Extension Popover Settings — Block Toggles & App Groups Persistence
created: 2026-07-01
tags:
  - safari-extension
  - settings
  - app-groups
  - persistence
related:
  - '[[DONT-TOUCH-02.md]]'
---

# Safari Extension Popover Settings

## Goal

Enhance the existing Safari Web Extension toolbar popover with individual content-type toggles (Block Images, Block Videos, Block Text) and wire settings persistence through App Groups so both the host app and Safari extension share configuration.

## Scope

- Add 3 toggle switches to `popup.html`
- Wire popup to `browser.storage.local` (content script access) and native handler (App Groups UserDefaults)
- Add `saveSettings`/`loadSettings` message handling in `background.js` and `SafariWebExtensionHandler.swift`
- Update `contentBlocker.js` to respect toggle states and gate scanning
- Add App Groups entitlements to `Project.yml`
- Update `popup.css` with toggle switch styles

## Architecture

```
Popup (popup.js)
  ├──→ browser.storage.local.set(settings)    ← content scripts read this
  └──→ browser.runtime.sendMessage({type: "saveSettings", ...})
        → background.js
          → safari.self.tab.dispatchMessage("saveSettings", ...)
            → SafariWebExtensionHandler
              → UserDefaults(App Group, "group.com.yourname.donttouch")
```

### Reading path

```
contentBlocker.js
  └──→ browser.storage.local.get(["blockImages", "blockVideos", "blockText"])
        → gate scanImages(), setupVideoScanning(), scanText()

Native handler (AnalysisEngine.shouldBlock)
  └──→ UserDefaults(App Group, "group.com.yourname.donttouch")
```

## Settings Schema

### browser.storage.local (Web Extension API)

```json
{
  "sensitivity": 60,
  "blockImages": true,
  "blockVideos": true,
  "blockText": true,
  "isPaused": false
}
```

### UserDefaults (App Group, key prefix "browser-")

| Key | Type | Default | Description |
|---|---|---|---|
| `sensitivityThreshold` | Double | 0.6 | Confidence threshold (native-side) |
| `blockImages` | Bool | true | Gate image scanning |
| `blockVideos` | Bool | true | Gate video scanning |
| `blockText` | Bool | true | Gate text scanning |

Note: `sensitivityThreshold` is already read by `AnalysisEngine.shouldBlock()`. The new keys (`blockImages`, `blockVideos`, `blockText`) are written by native-side handling of `saveSettings`.

## Files Changed

1. **popup.html** — Add 3 toggle rows, update status label
2. **popup.css** — Toggle switch styles, layout adjustments for toggles
3. **popup.js** — Read/write browser.storage.local, relay settings to native, wire toggle events
4. **background.js** — Handle `saveSettings`/`loadSettings` messages, forward to native
5. **SafariWebExtensionHandler.swift** — Handle `saveSettings`/`loadSettings` native messages, persist to UserDefaults (App Group)
6. **contentBlocker.js** — Read toggles from storage on init, gate scanning in scan loop + MutationObserver
7. **Project.yml** — Add App Groups entitlements config + entitements file references

## Success Criteria

- Popup has 3 working toggles that persist across popup open/close
- Disabling "Block Images" stops image scanning (no analyzeImages messages sent)
- Disabling "Block Videos" stops video frame sampling
- Disabling "Block Text" stops text scanning
- Settings survive extension reload
- No console errors from content scripts or popup
