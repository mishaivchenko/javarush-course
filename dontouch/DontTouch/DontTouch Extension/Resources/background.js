/**
 * Don't Touch — Background Script
 *
 * Relays messages between the content script and the native Safari extension.
 * Safari Web Extensions use this bridge for native messaging.
 */

(function () {
    'use strict';

    const LOG_PREFIX = '[Don\'t Touch BG]';

    // Forward messages from content script to native app
    browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
        if (!message || !message.type) {
            sendResponse({ error: 'invalid_message' });
            return;
        }

        console.debug(LOG_PREFIX, 'Forwarding:', message.type);

        // Safari native messaging bridge
        if (typeof safari !== 'undefined' && safari.self) {
            safari.self.tab.dispatchMessage(message.type, {
                ...message,
                tabId: sender?.tab?.id,
                frameId: sender?.frameId
            });
        }

        sendResponse({ received: true });
    });

    // Handle installation
    browser.runtime.onInstalled.addListener((details) => {
        console.log(LOG_PREFIX, 'Extension installed:', details.reason);
    });

    console.log(LOG_PREFIX, 'Background script loaded');
})();
