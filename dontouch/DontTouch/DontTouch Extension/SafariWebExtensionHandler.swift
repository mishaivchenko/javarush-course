import SafariServices
import OSLog

/// Native handler for the Safari Web Extension.
/// Conforms to SFSafariExtensionHandling to bridge between the
/// W3C content script and native detection code.
class SafariWebExtensionHandler: NSObject, SFSafariExtensionHandling {
    private let logger = Logger(subsystem: "com.yourname.donttouch.extension", category: "handler")

    // MARK: - SFSafariExtensionHandling

    func beginRequest(with context: NSExtensionContext) {
        logger.debug("Safari extension context began")
    }

    /// Handle messages from content.js sent via safari.self.tab.dispatchMessage().
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
                self.logger.info("Page loaded — Don't Touch watching: \(properties.url?.absoluteString ?? "unknown", privacy: .public)")
                self.respond(to: page, result: ["status": "ready"])

            case "checkImage":
                guard let userInfo = userInfo,
                      let imageData = userInfo["imageData"] as? String,
                      let url = userInfo["url"] as? String else {
                    self.respond(to: page, result: ["blocked": false, "reason": "invalid_payload"])
                    return
                }
                self.handleImageCheck(imageData: imageData, url: url, page: page)

            case "getState":
                self.respond(to: page, result: [
                    "paused": false,
                    "sensitivity": 60,
                    "scanned": 0,
                    "blocked": 0
                ])

            default:
                self.logger.warning("Unknown message: \(messageName, privacy: .public)")
                self.respond(to: page, result: ["status": "unknown_message"])
            }
        }
    }

    /// Validate that the extension should run on the given page.
    /// Returning true means it activates on all pages.
    func validate(
        context: SFSafariExtensionContext,
        validationHandler: @escaping (Bool, NSError?) -> Void
    ) {
        validationHandler(true, nil)
    }

    /// Handle toolbar button click.
    func toolbarItemClicked(in window: SFSafariWindow) {
        logger.debug("Toolbar item clicked")
        window.getActivePage { page in
            page?.dispatchMessageToScript(
                withName: "donttouch-toggle",
                userInfo: nil
            )
        }
    }

    // MARK: - Private

    private func handleImageCheck(imageData: String, url: String, page: SFSafariPage) {
        // Phase 1 stub — always returns not blocked.
        // Phase 2 will implement actual CoreML detection via AnalysisOrchestrator.
        logger.debug("Image check requested for: \(url, privacy: .public)")
        respond(to: page, result: [
            "blocked": false,
            "confidence": 0.0,
            "url": url
        ])
    }

    private func respond(to page: SFSafariPage, result: [String: Any]) {
        page.dispatchMessageToScript(withName: "donttouch-response", userInfo: result)
    }
}
