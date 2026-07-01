/**
 * Don't Touch — Popup Script
 *
 * Toolbar popover settings UI for the Safari extension.
 * Manages sensitivity slider, block-type toggles (images/video/text),
 * and pause/resume state. Persists settings via browser.storage.local
 * for content script access AND relays to the native handler for
 * App Groups UserDefaults storage.
 */

(function () {
    'use strict';

    const LOG_PREFIX = '[DT Popup]';
    const STORAGE_KEYS = ['sensitivity', 'blockImages', 'blockVideos', 'blockText', 'isPaused'];

    // ── DOM refs ───────────────────────────────────────────────────────────────
    const statusIndicator = document.getElementById('statusIndicator');
    const statusText = document.getElementById('statusText');
    const sensitivitySlider = document.getElementById('sensitivitySlider');
    const sensitivityValue = document.getElementById('sensitivityValue');
    const blockImages = document.getElementById('blockImages');
    const blockVideos = document.getElementById('blockVideos');
    const blockText = document.getElementById('blockText');
    const toggleButton = document.getElementById('toggleExtension');
    const itemsBlocked = document.getElementById('itemsBlocked');

    let isPaused = false;

    // ── Storage ────────────────────────────────────────────────────────────────

    /**
     * Read all settings from browser.storage.local.
     * Returns defaults for any missing keys.
     */
    async function loadSettings() {
        try {
            const result = await browser.storage.local.get(STORAGE_KEYS);
            return {
                sensitivity: result.sensitivity ?? 60,
                blockImages: result.blockImages !== false,
                blockVideos: result.blockVideos !== false,
                blockText: result.blockText !== false,
                isPaused: result.isPaused ?? false
            };
        } catch (err) {
            console.warn(LOG_PREFIX, 'Failed to load settings:', err.message);
            return { sensitivity: 60, blockImages: true, blockVideos: true, blockText: true, isPaused: false };
        }
    }

    /**
     * Save all settings to browser.storage.local AND relay to the native
     * Safari extension for App Groups persistence.
     */
    async function saveSettings(settings) {
        try {
            await browser.storage.local.set(settings);
        } catch (err) {
            console.warn(LOG_PREFIX, 'Failed to save to browser.storage:', err.message);
        }

        // Relay to native handler so AnalysisEngine can read from App Groups UserDefaults
        try {
            await browser.runtime.sendMessage({
                type: 'saveSettings',
                settings: {
                    sensitivity: settings.sensitivity,
                    blockImages: settings.blockImages,
                    blockVideos: settings.blockVideos,
                    blockText: settings.blockText
                }
            });
        } catch (err) {
            // Native handler might not be available (e.g. during development)
            console.debug(LOG_PREFIX, 'Settings relay to native skipped:', err.message);
        }
    }

    // ── UI Update ──────────────────────────────────────────────────────────────

    function updateUI(state) {
        isPaused = state.isPaused || false;
        sensitivitySlider.value = state.sensitivity ?? 60;
        sensitivityValue.textContent = `${state.sensitivity ?? 60}%`;
        blockImages.checked = state.blockImages !== false;
        blockVideos.checked = state.blockVideos !== false;
        blockText.checked = state.blockText !== false;

        if (isPaused) {
            statusIndicator.className = 'status-dot paused';
            statusText.textContent = 'Paused on this page';
            toggleButton.textContent = 'Resume on This Page';
            toggleButton.classList.add('paused');
        } else {
            statusIndicator.className = 'status-dot active';
            statusText.textContent = 'Active on this page';
            toggleButton.textContent = 'Pause on This Page';
            toggleButton.classList.remove('paused');
        }
    }

    // ── Control Handlers ───────────────────────────────────────────────────────

    sensitivitySlider.addEventListener('input', (e) => {
        const value = parseInt(e.target.value, 10);
        sensitivityValue.textContent = `${value}%`;
        saveSettings({ sensitivity: value });
    });

    blockImages.addEventListener('change', (e) => {
        saveSettings({ blockImages: e.target.checked });
    });

    blockVideos.addEventListener('change', (e) => {
        saveSettings({ blockVideos: e.target.checked });
    });

    blockText.addEventListener('change', (e) => {
        saveSettings({ blockText: e.target.checked });
    });

    toggleButton.addEventListener('click', async () => {
        isPaused = !isPaused;
        await saveSettings({ isPaused });
        updateUI({
            sensitivity: parseInt(sensitivitySlider.value, 10),
            blockImages: blockImages.checked,
            blockVideos: blockVideos.checked,
            blockText: blockText.checked,
            isPaused
        });
    });

    // ── Blocked Count (from content script) ────────────────────────────────────

    /**
     * Listen for blocked-count updates from the content script.
     */
    browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
        if (message.type === 'donttouch-response' && message.itemsBlocked != null) {
            itemsBlocked.textContent = message.itemsBlocked;
        }
        sendResponse({ received: true });
    });

    // ── Init ───────────────────────────────────────────────────────────────────

    document.addEventListener('DOMContentLoaded', async () => {
        const settings = await loadSettings();
        updateUI(settings);
    });
})();
