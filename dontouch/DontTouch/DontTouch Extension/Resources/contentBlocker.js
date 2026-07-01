/**
 * Don't Touch — Content Blocker Scanner
 *
 * Scans images, video frames, and text nodes on every page.
 * Sends content to the native Safari extension for on-device AI analysis
 * and applies/removes the `dt-hidden` CSS class based on responses.
 *
 * Runs as a separate content script alongside content.js (badge, CSS injection).
 * Both scripts share the DOM and use browser.runtime.* for messaging.
 */

(function () {
    'use strict';

    const HIDDEN_CLASS = 'dt-hidden';
    const LOG_PREFIX = '[Don\'t Touch Scanner]';
    const TEXT_ATTR = 'data-dt-text-id';

    // ── State ───────────────────────────────────────────────────────────────
    let blockedCount = 0;
    let scannedCount = 0;
    let textIdCounter = 0;
    let videoIdCounter = 0;
    let blockImagesEnabled = true;
    let blockVideosEnabled = true;
    let blockTextEnabled = true;
    let isPaused = false;

    // ── Per-Video Frame State ──────────────────────────────────────────────
    // Each video gets a stable ID assigned at setup time. The sliding window
    // tracks the last N frame results. Block only after 2 of 3 consecutive
    // frames are flagged, preventing flicker on transient detections.
    const VIDEO_WINDOW_SIZE = 3;
    const VIDEO_BLOCK_THRESHOLD = 2;
    const VIDEO_SAMPLE_INTERVAL_MS = 2000;
    const VIDEO_SAMPLE_INTERVAL_BLOCKED_MS = 5000;

    window.__dtVideoStates = {};

    /**
     * Get or initialize the frame state for a video element.
     * Returns null if the video has no dt-video-id assigned.
     */
    function getVideoState(video) {
        const videoId = video.dataset.dtVideoId;
        return videoId ? (window.__dtVideoStates[videoId] || null) : null;
    }

    /**
     * Initialize tracking state for a video.
     */
    function initVideoState(videoId, selector) {
        window.__dtVideoStates[videoId] = {
            blocked: false,       // Is this video currently visually blocked?
            window: [],           // Sliding window of recent frame results (booleans)
            selector: selector    // CSS selector for this video element
        };
    }

    /**
     * Record a frame result into the per-video sliding window and return
     * the action to take:
     * - 'block' if 2/3 consecutive frames are flagged and not yet blocked
     * - 'unblock' if <2 frames flagged and currently blocked
     * - null if no state change is needed
     *
     * Updates `state.blocked` to track the current visual state, keeping
     * future calls aware of whether the video is currently hidden.
     */
    function updateVideoWindow(videoId, isFlagged) {
        const state = window.__dtVideoStates[videoId];
        if (!state) return null;

        // Add result to the sliding window
        state.window.push(isFlagged);
        if (state.window.length > VIDEO_WINDOW_SIZE) {
            state.window.shift();
        }

        // Count flagged frames in the current window
        const flaggedCount = state.window.filter(Boolean).length;
        const enoughWindowData = state.window.length >= 2; // have enough samples

        if (!state.blocked && enoughWindowData && flaggedCount >= VIDEO_BLOCK_THRESHOLD) {
            state.blocked = true;
            return 'block';
        } else if (state.blocked && flaggedCount < VIDEO_BLOCK_THRESHOLD) {
            state.blocked = false;
            return 'unblock';
        }

        return null;
    }

    // ── Settings ──────────────────────────────────────────────────────────────

    /**
     * Load block-type toggles from browser.storage.local.
     * Called once on init and whenever the popup saves changes
     * (received via onMessage).
     */
    async function loadSettings() {
        try {
            const result = await browser.storage.local.get([
                'sensitivity', 'blockImages', 'blockVideos', 'blockText', 'isPaused'
            ]);
            blockImagesEnabled = result.blockImages !== false;
            blockVideosEnabled = result.blockVideos !== false;
            blockTextEnabled = result.blockText !== false;
            isPaused = result.isPaused ?? false;
            console.log(LOG_PREFIX, `Settings loaded — images:${blockImagesEnabled} videos:${blockVideosEnabled} text:${blockTextEnabled} paused:${isPaused}`);
        } catch (err) {
            console.warn(LOG_PREFIX, 'Failed to load settings:', err.message);
        }
    }

    // ── Image Scanning ──────────────────────────────────────────────────────

    /**
     * Scan all <img> elements not yet analyzed, collect their src URLs,
     * and send them in a batch to the native handler for analysis.
     */
    function scanImages() {
        if (!blockImagesEnabled || isPaused) return;
        const images = document.querySelectorAll('img:not([data-dt-scanned])');
        const batch = [];

        images.forEach(img => {
            const src = img.currentSrc || img.src || img.getAttribute('src');
            if (!src) return;
            // Mark as scanned immediately to avoid re-scanning before response arrives
            img.dataset.dtScanned = 'true';
            batch.push({ src, selector: buildSelector(img) });
        });

        if (batch.length === 0) return;

        scannedCount += batch.length;

        browser.runtime.sendMessage({ type: 'analyzeImages', images: batch })
            .catch(err => console.warn(LOG_PREFIX, 'analyzeImages failed:', err.message));
    }

    // ── Video Scanning ──────────────────────────────────────────────────────

    /**
     * Attach play-event listeners to <video> elements not yet set up.
     * Assigns each video a stable ID and initializes its frame state.
     */
    function setupVideoScanning() {
        if (!blockVideosEnabled || isPaused) return;
        document.querySelectorAll('video:not([data-dt-video-setup])').forEach(video => {
            video.dataset.dtVideoSetup = 'true';

            // Assign unique video ID if not already present
            if (!video.dataset.dtVideoId) {
                const id = ++videoIdCounter;
                video.dataset.dtVideoId = String(id);
                const selector = buildSelector(video);
                initVideoState(id, selector);
            }

            video.addEventListener('play', onVideoPlay, { once: true });
        });
    }

    /**
     * When a video starts playing, begin periodic frame sampling.
     */
    function onVideoPlay(event) {
        const video = event.target;
        if (video.dataset.dtVideoBlocked === 'true') {
            video.pause();
            return;
        }
        scheduleFrameSample(video);
    }

    /**
     * Sample a video frame to a canvas and send the base64-encoded image
     * data to the native handler for analysis.
     *
     * Continues sampling even while visually blocked so the sliding window
     * can detect when it is safe to unblock. Uses an adaptive interval:
     * 2 seconds while active, 5 seconds while blocked.
     */
    function scheduleFrameSample(video) {
        if (video.ended) return;
        if (video.paused && !(video.dataset.dtVideoBlocked === 'true')) return;

        const videoId = video.dataset.dtVideoId;
        if (!videoId) return;

        const canvas = document.createElement('canvas');
        // Cap dimensions to avoid sending enormous images
        const maxDim = 512;
        const scale = Math.min(maxDim / (video.videoWidth || maxDim), maxDim / (video.videoHeight || maxDim), 1);
        canvas.width = Math.round((video.videoWidth || 320) * scale);
        canvas.height = Math.round((video.videoHeight || 240) * scale);

        const ctx = canvas.getContext('2d');
        if (!ctx) {
            scheduleNextSample(video);
            return;
        }
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

        // Strip the data:image/jpeg;base64, prefix — native handler expects raw base64
        const base64 = canvas.toDataURL('image/jpeg', 0.7).split(',')[1];

        browser.runtime.sendMessage({
            type: 'analyzeVideoFrame',
            data: base64,
            selector: buildSelector(video),
            videoId: parseInt(videoId, 10)
        }).catch(err => console.warn(LOG_PREFIX, 'analyzeVideoFrame failed:', err.message));

        // Schedule next sample at the appropriate interval
        scheduleNextSample(video);
    }

    /**
     * Schedule the next frame sample.
     * Uses a shorter interval when active, longer when blocked (so the
     * sliding window can still accumulate clean frames to trigger unblock).
     */
    function scheduleNextSample(video) {
        if (video.ended) return;
        const videoState = getVideoState(video);
        const interval = (videoState && videoState.blocked)
            ? VIDEO_SAMPLE_INTERVAL_BLOCKED_MS
            : VIDEO_SAMPLE_INTERVAL_MS;

        setTimeout(() => {
            if (!video.ended) {
                scheduleFrameSample(video);
            } else {
                video.dataset.dtPlaying = 'false';
            }
        }, interval);
    }

    // ── Text Scanning ───────────────────────────────────────────────────────

    /**
     * Walk all text nodes in the document body, group them into paragraphs,
     * and send each paragraph to the native handler for keyword blocklist matching.
     *
     * Each text chunk is tracked via a `data-dt-text-id` attribute on its closest
     * semantic parent element so the response can target the right node.
     */
    function scanText() {
        if (!blockTextEnabled || isPaused) return;
        const walker = document.createTreeWalker(
            document.body,
            NodeFilter.SHOW_TEXT,
            {
                acceptNode: function (node) {
                    // Skip text inside script, style, noscript, SVG, and hidden elements
                    const parent = node.parentElement;
                    if (!parent) return NodeFilter.FILTER_REJECT;
                    const tag = parent.tagName.toLowerCase();
                    if (['script', 'style', 'noscript', 'svg', 'canvas', 'template'].includes(tag)) {
                        return NodeFilter.FILTER_REJECT;
                    }
                    // Skip text that's already part of a tracked paragraph
                    if (parent.hasAttribute(TEXT_ATTR)) return NodeFilter.FILTER_REJECT;
                    // Skip whitespace-only text
                    if (!node.textContent.trim()) return NodeFilter.FILTER_REJECT;
                    return NodeFilter.FILTER_ACCEPT;
                }
            }
        );

        const paragraphs = []; // { parent, text, id }
        let currentNodes = [];
        let currentText = '';
        let currentParent = null;

        function flushParagraph() {
            if (!currentText.trim() || currentNodes.length === 0) return;
            const id = ++textIdCounter;
            // Mark all parent elements in this paragraph with the same text ID
            const parents = new Set();
            currentNodes.forEach(n => {
                if (n.parentElement) parents.add(n.parentElement);
            });
            parents.forEach(p => p.setAttribute(TEXT_ATTR, String(id)));

            paragraphs.push({
                selector: parents.size === 1 ? buildSelector(currentParent) : 'body',
                text: currentText.trim().substring(0, 2000), // cap per message
                id
            });
            currentNodes = [];
            currentText = '';
            currentParent = null;
        }

        let node;
        while ((node = walker.nextNode())) {
            const text = node.textContent.trim();
            if (!text) continue;

            const parent = node.parentElement;

            // Start a new paragraph on block-element boundaries
            if (currentParent && parent !== currentParent && isBlockElement(parent)) {
                flushParagraph();
            }

            if (!currentParent) currentParent = parent;
            currentNodes.push(node);
            currentText += ' ' + text;

            // Flush long paragraphs
            if (currentText.length > 1000) {
                flushParagraph();
            }
        }
        flushParagraph();

        // Send each paragraph for analysis
        paragraphs.forEach(p => {
            scannedCount++;
            const payload = { type: 'analyzeText', text: p.text, textId: p.id, selector: p.selector };
            browser.runtime.sendMessage(payload)
                .catch(err => console.warn(LOG_PREFIX, 'analyzeText failed:', err.message));
        });

        console.log(LOG_PREFIX, `Sent ${paragraphs.length} text chunks for analysis`);
    }

    /**
     * Chunk a long string into fixed-size pieces.
     */
    function chunkText(text, maxLen) {
        const chunks = [];
        for (let i = 0; i < text.length; i += maxLen) {
            chunks.push(text.substring(i, i + maxLen));
        }
        return chunks;
    }

    /**
     * Check whether an element is a block-level container that should
     * act as a paragraph boundary.
     */
    function isBlockElement(el) {
        const blockTags = [
            'p', 'div', 'section', 'article', 'header', 'footer', 'nav',
            'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li', 'blockquote',
            'pre', 'td', 'th', 'figure', 'figcaption', 'details', 'main',
            'aside', 'form', 'table', 'ol', 'ul', 'hr'
        ];
        return blockTags.includes(el.tagName.toLowerCase()) ||
            getComputedStyle(el).display === 'block' ||
            getComputedStyle(el).display === 'flex' ||
            getComputedStyle(el).display === 'grid';
    }

    // ── Response Handling ───────────────────────────────────────────────────

    /**
     * Report the current blocked count to the background script
     * so the popup can display it.
     */
    function reportBlockedCount() {
        browser.runtime.sendMessage({ type: 'reportBlocked', count: blockedCount })
            .catch(() => {}); // Ignore — background may not respond
    }

    /**
     * Listen for messages:
     * - 'donttouch-response' — block/unblock decisions from the native handler
     * - 'settingsUpdated' — toggle state changes from the popup
     * - 'donttouch-toggle' — pause/resume toggle from the native handler
     */
    browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
        if (message.type === 'donttouch-response') {
            handleBlockResponse(message);
        } else if (message.type === 'settingsUpdated') {
            // Reload settings when the popup saves changes
            loadSettings();
        } else if (message.type === 'donttouch-toggle') {
            isPaused = !isPaused;
            browser.storage.local.set({ isPaused });
            console.log(LOG_PREFIX, 'Extension toggled:', isPaused ? 'paused' : 'active');
        }
        sendResponse({ received: true });
    });

    /**
     * Process a block/unblock response from the native extension.
     *
     * Response types:
     *   - frameResult: video frame analysis result — routes through the
     *     per-video sliding window (2-of-3 consecutive frames to block)
     *   - block/unblock with selector: direct block decision (images, etc.)
     *   - legacy: { blocked: true, url: '...' }
     *   - textBlocked: text blocklist match
     */
    function handleBlockResponse(response) {
        // Re-analyze request from native handler (triggered by "Apply to Current Page")
        if (response.action === 'reanalyze') {
            handleReanalyze();
            return;
        }

        // Video frame result — route through per-video sliding window
        if (response.action === 'frameResult' && response.videoId != null && response.selector) {
            const windowAction = updateVideoWindow(response.videoId, response.isFlagged);
            if (windowAction === 'block') {
                applyBlock(response.selector);
                console.log(LOG_PREFIX, `Video blocked after 2/3 frames (id:${response.videoId})`);
            } else if (windowAction === 'unblock') {
                applyUnblock(response.selector);
                console.log(LOG_PREFIX, `Video unblocked — running avg below threshold (id:${response.videoId})`);
            }
            return;
        }

        // New format: action + selector
        if (response.action === 'block' && response.selector) {
            applyBlock(response.selector);
        } else if (response.action === 'unblock' && response.selector) {
            applyUnblock(response.selector);
        }

        // Legacy format (from content.js phase 1): blocked + url
        if (response.blocked && response.url) {
            const el = document.querySelector(`[data-dt-url="${CSS.escape(response.url)}"]`);
            if (el) {
                el.classList.add(HIDDEN_CLASS);
                blockedCount++;
            }
        }

        // Text block response
        if (response.textBlocked && response.textId != null) {
            handleTextBlock(response.textId);
        }
    }

    /**
     * Apply the `dt-hidden` class to elements matching a CSS selector.
     * For video elements, also pauses playback and adds a visual overlay.
     */
    function applyBlock(selector) {
        const els = document.querySelectorAll(selector);
        els.forEach(el => {
            if (el.classList.contains(HIDDEN_CLASS)) return;
            el.classList.add(HIDDEN_CLASS);
            blockedCount++;

            if (el.tagName === 'VIDEO') {
                el.dataset.dtVideoBlocked = 'true';
                el.pause();
                addVideoOverlay(el);
            }

            console.log(LOG_PREFIX, 'Blocked:', selector);
        });
        if (blockedCount > 0) {
            reportBlockedCount();
        }
    }

    /**
     * Remove the `dt-hidden` class from elements matching a CSS selector.
     */
    function applyUnblock(selector) {
        const els = document.querySelectorAll(selector);
        els.forEach(el => {
            el.classList.remove(HIDDEN_CLASS);
            if (el.tagName === 'VIDEO') {
                el.dataset.dtVideoBlocked = 'false';
                removeVideoOverlay(el);
            }
        });
    }

    /**
     * When text is flagged, apply the hidden class to the parent element
     * identified by the text ID attribute.
     */
    function handleTextBlock(textId) {
        const selector = `[${TEXT_ATTR}="${textId}"]`;
        const els = document.querySelectorAll(selector);
        els.forEach(el => {
            el.classList.add(HIDDEN_CLASS);
            blockedCount++;
        });
    }

    /**
     * Wrap a video in an overlay container when blocked.
     * If the video is already wrapped, just ensures the overlay exists.
     */
    function addVideoOverlay(video) {
        // Find existing wrapper or create one
        let wrapper = video.closest('.dt-video-wrapper');
        if (!wrapper) {
            wrapper = document.createElement('div');
            wrapper.className = 'dt-video-wrapper';
            wrapper.style.position = 'relative';
            wrapper.style.display = 'inline-block';
            wrapper.style.maxWidth = '100%';

            if (video.parentNode) {
                video.parentNode.insertBefore(wrapper, video);
                wrapper.appendChild(video);
            }
        }

        // Check for existing overlay
        if (wrapper.querySelector('.dt-video-overlay')) return;

        const overlay = document.createElement('div');
        overlay.className = 'dt-video-overlay';
        overlay.textContent = '🚫 Blocked by Don\'t Touch';
        wrapper.appendChild(overlay);
    }

    /**
     * Remove the video overlay when unblocked.
     */
    function removeVideoOverlay(video) {
        const wrapper = video.closest('.dt-video-wrapper');
        if (wrapper) {
            const overlay = wrapper.querySelector('.dt-video-overlay');
            if (overlay) overlay.remove();
        }
    }

    // ── Reanalyze Handler ──────────────────────────────────────────────────

    /**
     * Reset all scanned state and re-scan the page from scratch.
     *
     * Triggered by the native handler when the user clicks "Apply to Current Page"
     * in the popup. Clears all detection markers, unhides all elements, resets
     * counters, and re-runs the full scan pipeline (images, videos, text).
     *
     * This ensures the page is re-evaluated with fresh analysis after
     * sensitivity changes or when the user wants to force a re-check.
     */
    function handleReanalyze() {
        console.log(LOG_PREFIX, 'Re-analyzing page — clearing scanned state');

        // ── Reset element markers ──
        // Remove scanned/image markers so scanImages() will re-process them
        document.querySelectorAll('[data-dt-scanned]').forEach(el => {
            el.removeAttribute('data-dt-scanned');
        });
        // Remove video setup markers so setupVideoScanning() will re-attach listeners
        document.querySelectorAll('[data-dt-video-setup]').forEach(el => {
            el.removeAttribute('data-dt-video-setup');
        });
        // Remove text IDs so scanText() will assign fresh ones
        document.querySelectorAll('[data-dt-text-id]').forEach(el => {
            el.removeAttribute('data-dt-text-id');
        });
        // Remove URL markers (legacy path from content.js)
        document.querySelectorAll('[data-dt-url]').forEach(el => {
            el.removeAttribute('data-dt-url');
        });
        // Remove video blocked state so onVideoPlay can fire
        document.querySelectorAll('[data-dt-video-blocked]').forEach(el => {
            el.removeAttribute('data-dt-video-blocked');
        });

        // ── Unhide all elements ──
        document.querySelectorAll('.dt-hidden').forEach(el => {
            el.classList.remove('dt-hidden');
        });

        // ── Remove video overlays ──
        document.querySelectorAll('.dt-video-wrapper').forEach(wrapper => {
            const overlay = wrapper.querySelector('.dt-video-overlay');
            if (overlay) overlay.remove();
        });

        // ── Reset state ──
        blockedCount = 0;
        scannedCount = 0;
        textIdCounter = 0;
        videoIdCounter = 0;
        window.__dtVideoStates = {};

        console.log(LOG_PREFIX, 'State reset — re-scanning page');

        // ── Re-run scan pipeline ──
        scanImages();
        setupVideoScanning();
        scanText();

        console.log(LOG_PREFIX, 'Re-scan complete');
    }

    // ── Selector Builder ────────────────────────────────────────────────────

    /**
     * Build a unique CSS selector for the given element.
     * Prefers ID, falls back to class + nth-child precision.
     */
    function buildSelector(el) {
        if (!el || !el.tagName) return '';

        // ID is the most precise
        if (el.id) {
            // Escape special characters in IDs
            return `#${CSS.escape(el.id)}`;
        }

        // Build a path from the element up to a reasonable ancestor
        const path = [];
        let current = el;
        let maxDepth = 5;

        while (current && current.tagName && current !== document.body && maxDepth > 0) {
            let segment = current.tagName.toLowerCase();

            // Add class if it's distinctive
            if (current.className && typeof current.className === 'string') {
                const classes = current.className.trim().split(/\s+/).filter(Boolean);
                if (classes.length > 0 && classes.length <= 3) {
                    segment += '.' + classes.map(c => CSS.escape(c)).join('.');
                }
            }

            // Add nth-child for precision if no ID was used
            const parent = current.parentElement;
            if (parent && !current.id) {
                const siblings = Array.from(parent.children).filter(
                    s => s.tagName === current.tagName
                );
                if (siblings.length > 1) {
                    const index = siblings.indexOf(current) + 1;
                    segment += `:nth-of-type(${index})`;
                }
            }

            path.unshift(segment);
            current = current.parentElement;
            maxDepth--;
        }

        const selector = path.join(' > ');
        return selector || el.tagName.toLowerCase();
    }

    // ── MutationObserver ────────────────────────────────────────────────────

    /**
     * Watch for dynamically added DOM nodes and re-scan for new
     * images, videos, and text content every 3 seconds.
     */
    function setupMutationObserver() {
        // Debounced scan to avoid excessive re-scanning
        let scanTimeout = null;

        const observer = new MutationObserver(() => {
            if (scanTimeout) return;

            scanTimeout = setTimeout(() => {
                scanTimeout = null;
                scanImages();
                setupVideoScanning();
                // Re-scanning all text on every mutation is expensive;
                // only text nodes in newly added subtrees are meaningful
                // and those are already handled by the initial scan.
                // For dynamic content, a full re-scan is triggered
                // only every 30 seconds if mutations keep happening.
            }, 3000);
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    // ── Initialization ──────────────────────────────────────────────────────

    function init() {
        // Only run on HTML pages
        if (document.contentType && !document.contentType.startsWith('text/html')) return;

        console.log(LOG_PREFIX, 'Scanner active');

        // Load settings first, then start scanning
        loadSettings().then(() => {
            // Initial scans (gated by toggle state inside each function)
            scanImages();
            setupVideoScanning();
            scanText();

            // Watch for dynamic content
            setupMutationObserver();

            console.log(LOG_PREFIX, `Initial scan complete — scanned ${scannedCount} items`);
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
