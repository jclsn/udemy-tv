// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

// Runs in Udemy's own course player page, for lectures that only play there (DRM).
// It lets the app's controls drive the video, and can blow the player up to fill the screen.

(function () {
    if (window.__udtvPlayer) {
        return;
    }

    const style = document.createElement("style");
    style.textContent = `
        html.udtv-mode, html.udtv-mode body { overflow: hidden !important; }
        html.udtv-mode .udtv-host {
            position: fixed !important; inset: 0 !important;
            width: 100vw !important; height: 100vh !important;
            max-width: none !important; max-height: none !important;
            margin: 0 !important; padding: 0 !important;
            z-index: 2147483647 !important; background: #000 !important;
        }
        html.udtv-mode .udtv-ancestor {
            transform: none !important; filter: none !important; contain: none !important;
            will-change: auto !important; perspective: none !important;
        }
        html.udtv-mode .udtv-host video {
            width: 100% !important; height: 100% !important; object-fit: contain !important;
        }
    `;
    document.documentElement.appendChild(style);

    // From the most to the least of the player: the whole lecture area keeps the slides of a
    // video mashup next to the video
    const hostSelectors = [
        '[class*="app--curriculum-item"]',
        '[data-purpose="curriculum-item-viewer-content"]',
        '[data-purpose="video-player"]',
        '[class*="video-player--container"]',
    ];

    function video() {
        return document.querySelector("video");
    }

    function markHost() {
        const v = video();

        if (!v || v.classList.contains("udtv-marked")) {
            return;
        }

        v.classList.add("udtv-marked");
        let host = null;

        for (const selector of hostSelectors) {
            host = v.closest(selector);

            if (host) {
                break;
            }
        }

        host = host || v.parentElement;
        host.classList.add("udtv-host");

        // A transformed ancestor would trap the fixed position inside it
        for (let e = host.parentElement; e && e !== document.body; e = e.parentElement) {
            e.classList.add("udtv-ancestor");
        }
    }

    window.__udtvPlayer = {
        state: function () {
            markHost();
            const v = video();

            if (!v) {
                return { found: false };
            }

            return {
                found: true,
                position: v.currentTime * 1000,
                duration: isFinite(v.duration) ? v.duration * 1000 : 0,
                paused: v.paused,
                ended: v.ended,
                buffering: !v.paused && v.readyState < 3,
                rate: v.playbackRate,
                error: v.error ? String(v.error.code) : "",
            };
        },
        togglePlay: function () {
            const v = video();

            if (v) {
                v.paused ? v.play() : v.pause();
            }
        },
        seek: function (ms) {
            const v = video();

            if (v) {
                v.currentTime = ms / 1000;
            }
        },
        setRate: function (rate) {
            const v = video();

            if (v) {
                v.playbackRate = rate;
            }
        },
        setTvMode: function (on) {
            document.documentElement.classList.toggle("udtv-mode", on);
        },
    };
    window.__udtvPlayer.setTvMode(true);
})();
