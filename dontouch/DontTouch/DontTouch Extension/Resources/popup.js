/**
 * Don't Touch — Popup Script
 *
 * Toolbar popover settings UI for the Safari extension.
 * Communicates with the background script to get/set extension state.
 */

(function () {
    'use strict';

    const LOG_PREFIX = '[DT Popup]';

    // DOM refs
    const statusIndicator = document.getElementById('statusIndicator');
    const statusText = document.getElementById('statusText');
    const sensitivitySlider = document.getElementById('sensitivitySlider');
    const sensitivityValue = document.getElementById('sensitivityValue');
    const toggleButton = document.getElementById('toggleExtension');
    const imagesScanned = document.getElementById('imagesScanned');
    const imagesBlocked = document.getElementById('imagesBlocked');

    let isPaused = false;

    // ── State ────────────────────────────────────────────────────────────────

    async function getState() {
        try {
            const response = await browser.runtime.sendMessage({ type: 'getState' });
            if (response) {
                updateUI(response);
            }
        } catch (err) {
            console.warn(LOG_PREFIX, 'Failed to get state:', err.message);
        }
    }

    function updateUI(state) {
        isPaused = state.paused || false;
        sensitivitySlider.value = state.sensitivity ?? 60;
        sensitivityValue.textContent = `${state.sensitivity ?? 60}%`;
        imagesScanned.textContent = state.scanned ?? 0;
        imagesBlocked.textContent = state.blocked ?? 0;

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

    // ── Controls ─────────────────────────────────────────────────────────────

    sensitivitySlider.addEventListener('input', (e) => {
        const value = e.target.value;
        sensitivityValue.textContent = `${value}%`;
        browser.runtime.sendMessage({
            type: 'setSensitivity',
            value: parseInt(value, 10)
        }).catch(() => {});
    });

    toggleButton.addEventListener('click', async () => {
        isPaused = !isPaused;
        try {
            await browser.runtime.sendMessage({
                type: 'togglePause',
                paused: isPaused
            });
            updateUI({ paused: isPaused, sensitivity: sensitivitySlider.value });
        } catch (err) {
            console.warn(LOG_PREFIX, 'Toggle failed:', err.message);
        }
    });

    // ── Init ─────────────────────────────────────────────────────────────────

    document.addEventListener('DOMContentLoaded', () => {
        getState();
    });
})();
