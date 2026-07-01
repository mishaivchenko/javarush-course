/**
 * Don't Touch — Background Script
 *
 * Relays messages between the content script and the native Safari extension.
 * Safari Web Extensions use this bridge for native messaging.
 *
 * Also serves as a relay for settings persistence (popup → native → App Groups).
 */

(function () {
    'use strict';

    const LOG_PREFIX = '[Don\'t Touch BG]';

    // Track blocked count per tab for the popup to query
    let tabBlockedCounts = {};

    // Forward messages from content script to native app
    browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
        if (!message || !message.type) {
            sendResponse({ error: 'invalid_message' });
            return false;
        }

        console.debug(LOG_PREFIX, 'Forwarding:', message.type);

        // Handle blocked-count tracking (from content script to popup)
        if (message.type === 'reportBlocked') {
            const tabId = sender?.tab?.id;
            if (tabId != null) {
                tabBlockedCounts[tabId] = message.count;
            }
            sendResponse({ received: true });
            return false;
        }

        // Safari native messaging bridge — forward all other messages to the native extension
        if (typeof safari !== 'undefined' && safari.self) {
            safari.self.tab.dispatchMessage(message.type, {
                ...message,
                tabId: sender?.tab?.id,
                frameId: sender?.frameId
            });
        } else {
            console.warn(LOG_PREFIX, 'safari.self not available — native bridge inactive');
        }

        sendResponse({ received: true });
        return false;
    });

    // Handle installation
    browser.runtime.onInstalled.addListener((details) => {
        console.log(LOG_PREFIX, 'Extension installed:', details.reason);
    });

    console.log(LOG_PREFIX, 'Background script loaded');
})();
