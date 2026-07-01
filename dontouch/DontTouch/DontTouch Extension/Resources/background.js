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
                // Persist for popup access — keyed by tab ID
                browser.storage.local.set({
                    ['blockedCount_' + tabId]: message.count,
                    latestBlockedTab: tabId
                }).catch(() => {});
            }
            sendResponse({ received: true });
            return false;
        }

        // Popup query: return blocked count for the current tab
        // Uses the most recently reported tab — content scripts always report
        // for their own tab, so the latest reportBlocked has the right count.
        if (message.type === 'getBlockedCount') {
            // Return the count for the tab that reported most recently,
            // or try storage (persisted by reportBlocked handler above)
            browser.storage.local.get('latestBlockedTab').then(stored => {
                const tabId = stored.latestBlockedTab;
                const count = tabId != null ? (tabBlockedCounts[tabId] || 0) : 0;
                sendResponse({ count });
            }).catch(() => {
                sendResponse({ count: 0 });
            });
            return true; // Keep channel open for async response
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
