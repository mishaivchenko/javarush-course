import SafariServices
import OSLog

/// Native handler for the Safari Web Extension.
/// Conforms to SFSafariExtensionHandling to bridge between the
/// W3C content script and native detection code.
///
/// ## Messaging Architecture
///
/// **Inbound** (content script → native):
/// 1. `contentBlocker.js` / `content.js` → `browser.runtime.sendMessage()`
/// 2. `background.js` → `safari.self.tab.dispatchMessage(name, payload)`
/// 3. `messageReceived(withName:from:userInfo:)` handles the message
///
/// **Outbound** (native → content script):
/// 1. `page.dispatchMessageToScript(withName: "donttouch-response", userInfo:)`
/// 2. Content scripts receive via `browser.runtime.onMessage`
/// 3. Response always includes `"type": "donttouch-response"` for content script matching
class SafariWebExtensionHandler: NSObject, SFSafariExtensionHandling {
    private let logger = Logger(subsystem: "com.yourname.donttouch.extension", category: "handler")
    private let engine = AnalysisEngine.shared

    /// Shared URLSession for fetching image data from page URLs.
    /// Timeouts are tight to avoid holding up the scan.
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    // MARK: - SFSafariExtensionHandling

    func beginRequest(with context: NSExtensionContext) {
        logger.debug("Safari extension context began")
    }

    /// Handle messages from content scripts forwarded by background.js.
    func messageReceived(
        withName messageName: String,
        from page: SFSafariPage,
        userInfo: [String: Any]?
    ) {
        logger.debug("Message received: \(messageName, privacy: .public)")

        page.getPropertiesWithCompletionHandler { properties in
            guard let properties = properties else {
                self.logger.warning("No page properties available")
                return
            }

            switch messageName {
            case "pageLoaded":
                self.logger.info("Page loaded: \(properties.url?.absoluteString ?? "unknown", privacy: .public)")
                self.respond(to: page, result: [
                    "type": "donttouch-response",
                    "status": "ready"
                ])

            case "checkImage":
                guard let userInfo = userInfo,
                      let imageData = userInfo["imageData"] as? String,
                      let url = userInfo["url"] as? String else {
                    self.respond(to: page, result: [
                        "type": "donttouch-response",
                        "blocked": false,
                        "reason": "invalid_payload"
                    ])
                    return
                }
                self.handleImageCheck(imageData: imageData, url: url, page: page)

            case "analyzeImages":
                self.handleAnalyzeImages(userInfo: userInfo, page: page)

            case "analyzeVideoFrame":
                self.handleAnalyzeVideoFrame(userInfo: userInfo, page: page)

            case "analyzeText":
                self.handleAnalyzeText(userInfo: userInfo, page: page)

            case "saveSettings":
                self.handleSaveSettings(userInfo: userInfo, page: page)

            case "getState":
                let defaults = UserDefaults(suiteName: "group.com.yourname.donttouch") ?? .standard
                let threshold = defaults.object(forKey: "sensitivityThreshold") as? Double ?? 0.6
                let blockImages = defaults.object(forKey: "blockImages") as? Bool ?? true
                let blockVideos = defaults.object(forKey: "blockVideos") as? Bool ?? true
                let blockText = defaults.object(forKey: "blockText") as? Bool ?? true
                self.respond(to: page, result: [
                    "type": "donttouch-response",
                    "paused": false,
                    "sensitivity": Int(threshold * 100),
                    "scanned": 0,
                    "blocked": 0,
                    "blockImages": blockImages,
                    "blockVideos": blockVideos,
                    "blockText": blockText
                ])

            default:
                self.logger.warning("Unknown message: \(messageName, privacy: .public)")
                self.respond(to: page, result: [
                    "type": "donttouch-response",
                    "status": "unknown_message"
                ])
            }
        }
    }

    /// Handle toolbar button click.
    func toolbarItemClicked(in window: SFSafariWindow) {
        logger.debug("Toolbar item clicked")
        window.getActiveTab { tab in
            tab?.getActivePage { page in
                page?.dispatchMessageToScript(withName: "donttouch-toggle", userInfo: nil)
            }
        }
    }

    // MARK: - Message Handlers

    /// Handle batch image analysis from contentBlocker.js.
    ///
    /// Iterates over the `images` array from the payload, fetches each
    /// image via URLSession, runs on-device Vision-based detection, and
    /// sends a block/unblock response per image that crosses the user's
    /// sensitivity threshold.
    ///
    /// Payload format:
    /// ```json
    /// { "type": "analyzeImages", "images": [{ "src": "...", "selector": "..." }] }
    /// ```
    private func handleAnalyzeImages(userInfo: [String: Any]?, page: SFSafariPage) {
        guard let images = userInfo?["images"] as? [[String: String]], !images.isEmpty else {
            logger.debug("analyzeImages: no images in payload")
            return
        }

        logger.info("Analyzing \(images.count) image(s)")

        Task {
            // Use a task group to fetch and analyze images concurrently
            let results = await withTaskGroup(
                of: [String: Any]?.self,
                returning: [[String: Any]].self
            ) { group in
                for imageInfo in images {
                    guard let src = imageInfo["src"],
                          let selector = imageInfo["selector"],
                          let url = URL(string: src) else { continue }

                    group.addTask {
                        return await self.analyzeSingleImage(url: url, selector: selector)
                    }
                }

                var collected: [[String: Any]] = []
                for await result in group {
                    if let result = result {
                        collected.append(result)
                    }
                }
                return collected
            }

            // Send responses back to the content script
            for result in results {
                self.respond(to: page, result: result)
            }

            if results.isEmpty {
                self.logger.debug("analyzeImages: no images were blocked")
            } else {
                self.logger.info("analyzeImages: \(results.count) image(s) blocked")
            }
        }
    }

    /// Fetch a single image from its URL, run on-device detection,
    /// and return a block response if the confidence exceeds the threshold.
    private func analyzeSingleImage(url: URL, selector: String) async -> [String: Any]? {
        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                logger.warning("Bad HTTP response for: \(url.absoluteString, privacy: .public)")
                return nil
            }

            guard !data.isEmpty else { return nil }

            let confidence = await engine.analyzeImage(url: url.absoluteString, data: data)

            if engine.shouldBlock(confidence: confidence) {
                return [
                    "type": "donttouch-response",
                    "action": "block",
                    "selector": selector
                ]
            }
        } catch {
            logger.warning("Image fetch/analysis failed for \(url.absoluteString, privacy: .public): \(error.localizedDescription)")
        }
        return nil
    }

    /// Handle video frame analysis from contentBlocker.js.
    ///
    /// Decodes the base64-encoded frame data and runs on-device detection.
    /// Always responds with the frame result (`isFlagged: true/false`) and
    /// the `videoId` so the content script can update its sliding window
    /// and only block after 2-of-3 consecutive flagged frames.
    ///
    /// Payload format:
    /// ```json
    /// { "type": "analyzeVideoFrame", "data": "<base64>", "selector": "...", "videoId": 1 }
    /// ```
    ///
    /// Response format:
    /// ```json
    /// { "type": "donttouch-response", "action": "frameResult", "videoId": 1,
    ///   "isFlagged": true, "selector": "..." }
    /// ```
    private func handleAnalyzeVideoFrame(userInfo: [String: Any]?, page: SFSafariPage) {
        guard let userInfo = userInfo,
              let base64 = userInfo["data"] as? String,
              let selector = userInfo["selector"] as? String,
              let videoId = userInfo["videoId"] as? Int else {
            logger.debug("analyzeVideoFrame: invalid payload")
            return
        }

        logger.debug("Analyzing video frame (id:\(videoId)) for: \(selector, privacy: .public)")

        Task {
            let confidence = await engine.analyzeVideoFrame(base64: base64)
            let isFlagged = engine.shouldBlock(confidence: confidence)

            self.respond(to: page, result: [
                "type": "donttouch-response",
                "action": "frameResult",
                "videoId": videoId,
                "isFlagged": isFlagged,
                "selector": selector
            ])

            if isFlagged {
                self.logger.debug("Video frame flagged (id:\(videoId))")
            }
        }
    }

    /// Handle text analysis from contentBlocker.js.
    ///
    /// Runs keyword blocklist matching via `AnalysisEngine.analyzeText()`.
    /// If the match confidence exceeds the sensitivity threshold, sends a
    /// text-block response with the text chunk ID so the content script
    /// can blur the parent element.
    ///
    /// Payload format:
    /// ```json
    /// { "type": "analyzeText", "text": "...", "textId": 1, "selector": "..." }
    /// ```
    private func handleAnalyzeText(userInfo: [String: Any]?, page: SFSafariPage) {
        guard let userInfo = userInfo,
              let text = userInfo["text"] as? String,
              let textId = userInfo["textId"] as? Int else {
            logger.debug("analyzeText: invalid payload")
            return
        }

        let confidence = engine.analyzeText(text)

        if engine.shouldBlock(confidence: confidence) {
            respond(to: page, result: [
                "type": "donttouch-response",
                "textBlocked": true,
                "textId": textId
            ])
            logger.debug("Text blocked (id: \(textId), confidence: \(confidence))")
        }
    }

    /// Handle settings persistence from the toolbar popup.
    ///
    /// Saves settings to UserDefaults (App Group) so both the host app
    /// (`AppSettings.swift`) and native detection code (`AnalysisEngine.shouldBlock()`)
    /// can read them.
    ///
    /// Payload format:
    /// ```json
    /// { "type": "saveSettings", "settings": { "sensitivity": 60, "blockImages": true, ... } }
    /// ```
    private func handleSaveSettings(userInfo: [String: Any]?, page: SFSafariPage) {
        guard let userInfo = userInfo,
              let settings = userInfo["settings"] as? [String: Any] else {
            logger.debug("saveSettings: invalid payload")
            return
        }

        let defaults = UserDefaults(suiteName: "group.com.yourname.donttouch") ?? .standard

        if let sensitivity = settings["sensitivity"] as? Int {
            let threshold = Double(sensitivity) / 100.0
            defaults.set(threshold, forKey: "sensitivityThreshold")
            logger.info("Sensitivity set to \(threshold)")
        }

        if let blockImages = settings["blockImages"] as? Bool {
            defaults.set(blockImages, forKey: "blockImages")
        }
        if let blockVideos = settings["blockVideos"] as? Bool {
            defaults.set(blockVideos, forKey: "blockVideos")
        }
        if let blockText = settings["blockText"] as? Bool {
            defaults.set(blockText, forKey: "blockText")
        }

        logger.debug("Settings saved to App Groups")
    }

    // MARK: - Legacy Handler (Phase 1)

    /// Handle individual image check from content.js (legacy `checkImage` message).
    ///
    /// Upgraded from Phase 1 stub to use real on-device detection.
    /// Decodes the base64 canvas data and runs the full Vision pipeline.
    /// Responds with `blocked`, `confidence`, and `url` for content.js's
    /// legacy response handler (`data-dt-url` attribute matching).
    private func handleImageCheck(imageData: String, url: String, page: SFSafariPage) {
        logger.debug("Image check requested for: \(url, privacy: .public)")

        guard let data = Data(base64Encoded: imageData) else {
            respond(to: page, result: [
                "type": "donttouch-response",
                "blocked": false,
                "confidence": 0.0,
                "url": url
            ])
            return
        }

        Task {
            let confidence = await engine.analyzeImage(url: url, data: data)
            let blocked = engine.shouldBlock(confidence: confidence)

            self.respond(to: page, result: [
                "type": "donttouch-response",
                "blocked": blocked,
                "confidence": confidence,
                "url": url
            ])
        }
    }

    // MARK: - Response Helpers

    /// Send a response to the content script via dispatchMessageToScript.
    ///
    /// - Parameters:
    ///   - page: The target Safari page.
    ///   - result: Dictionary sent as userInfo. Must include `"type": "donttouch-response"`
    ///     for content script `browser.runtime.onMessage` matching.
    private func respond(to page: SFSafariPage, result: [String: Any]) {
        page.dispatchMessageToScript(withName: "donttouch-response", userInfo: result)
    }
}
