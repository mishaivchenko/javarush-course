/**
 * Don't Touch — Content Script
 *
 * Injects a floating badge and prepares the page for image/video/text analysis.
 * Communicates with the native Safari extension via browser.runtime.sendMessage.
 */

(function () {
    'use strict';

    // ── State ───────────────────────────────────────────────────────────────
    const BADGE_ID = 'dt-badge';
    const HIDDEN_CLASS = 'dt-hidden';
    const LOG_PREFIX = '[Don\'t Touch]';

    let isReady = false;

    // ── Badge ────────────────────────────────────────────────────────────────
    function createBadge() {
        if (document.getElementById(BADGE_ID)) return;

        const badge = document.createElement('div');
        badge.id = BADGE_ID;
        badge.className = 'dt-badge';
        badge.textContent = '🚫 DT';
        document.body.appendChild(badge);

        console.log(LOG_PREFIX, 'Badge injected');
    }

    // ── CSS Injection ────────────────────────────────────────────────────────
    function injectStyles() {
        // style.css is injected via manifest.json, but ensure the hidden class exists
        const style = document.createElement('style');
        style.textContent = `
            .dt-hidden {
                filter: blur(20px) !important;
                pointer-events: none !important;
                user-select: none !important;
            }
        `;
        document.head.appendChild(style);
    }

    // ── Messaging ────────────────────────────────────────────────────────────
    function notifyPageLoaded() {
        browser.runtime.sendMessage({ type: 'pageLoaded', url: window.location.href })
            .then(response => {
                if (response && response.status === 'ready') {
                    isReady = true;
                    console.log(LOG_PREFIX, 'Extension ready:', response);
                }
            })
            .catch(err => {
                console.warn(LOG_PREFIX, 'Failed to contact native handler:', err.message);
                // Still function as a badge — native handler may not be available
                isReady = true;
            });
    }

    // Listen for responses from the native extension
    browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
        if (message.type === 'donttouch-response') {
            handleBlockResponse(message);
        }
        sendResponse({ received: true });
    });

    function handleBlockResponse(response) {
        if (response.blocked) {
            const el = document.querySelector(`[data-dt-url="${response.url}"]`);
            if (el) {
                el.classList.add(HIDDEN_CLASS);
                console.log(LOG_PREFIX, 'Blocked:', response.url, 'confidence:', response.confidence);
            }
        }
    }

    // ── Initialization ───────────────────────────────────────────────────────
    function init() {
        // Only run on web pages
        if (document.contentType && !document.contentType.startsWith('text/html')) return;

        console.log(LOG_PREFIX, 'Don\'t Touch active');

        injectStyles();
        createBadge();
        notifyPageLoaded();
    }

    // Run when DOM is ready (already at document_end per manifest)
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
