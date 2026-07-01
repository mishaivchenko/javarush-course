---
type: analysis
title: Blocking Prerequisite — Xcode Not Installed
created: 2026-07-01
tags:
  - blocker
  - prerequisite
  - dont-touch
related:
  - '[[DONT-TOUCH-01]]'
---

## Condition

Xcode 15+ is **not installed** on this machine. Only Apple Command Line Tools (v26.5) are available via `/Library/Developer/CommandLineTools`.

## Why This Blocks Phase 1

The Phase 1 playbook requires Xcode for every task:

| Task | Xcode Dependency |
|------|-----------------|
| Create Xcode project + Safari Extension target | Xcode GUI (File → New → Target) |
| Configure Info.plist and signing | Xcode project editor |
| Build and run the extension | `xcodebuild` (requires Xcode.app) |
| Verify badge on webpages | Run from Xcode → Safari |

Without Xcode.app, there is no `xcodebuild` binary (CLT-only ships `swift` and `xcrun` but not `xcodebuild`), and no way to create a `DontTouchBlocker` Safari Extension target programmatically — Safari Extension targets are notoriously specific to Xcode's project templates.

## What Exists Now

- Repository root: `CLAUDE.md` only
- No `DontTouch/` directory, no `Project.yml`, no Swift source files
- XcodeGen is not installed (would need Xcode.app for its project templates anyway)

## Resolution

Install Xcode from:
- Mac App Store (recommended): search "Xcode" → Get
- Apple Developer Portal: https://developer.apple.com/xcode/

After installation, run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` to set the active developer directory.
