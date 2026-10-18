// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

// Plays a copy-protected lecture in a page on the Udemy origin, after Shaka Player.
// The browser engine's Widevine module decrypts the video, with licenses from Udemy's
// license server, as in Udemy's own player. The app draws all controls itself
// (ProtectedVideo.qml); this page shows nothing but the video.

(function () {
    if (window.__udtvVideo) {
        return;
    }

    // Replace the page (robots.txt) with a bare video
    document.documentElement.style.cssText = "margin: 0; height: 100%; background: #000;";
    document.body.innerHTML = "";
    document.body.style.cssText = "margin: 0; height: 100%; overflow: hidden; background: #000;";
    const video = document.createElement("video");
    video.style.cssText = "width: 100%; height: 100%; object-fit: contain; background: #000;";
    video.autoplay = true;
    document.body.appendChild(video);

    shaka.polyfill.installAll();

    const state = {
        loaded: false,
        error: "",
    };
    let player = null;

    function describe(error) {
        if (error && error.code !== undefined) {
            // See https://shaka-player-demo.appspot.com/docs/api/shaka.util.Error.html
            return "Shaka error " + error.code + (error.data && error.data.length
                ? ": " + String(error.data[0]).slice(0, 200) : "");
        }

        return String(error);
    }

    window.__udtvVideo = {
        load: function (manifest, licenseUrl, startSeconds) {
            state.loaded = false;
            state.error = "";

            if (!shaka.Player.isBrowserSupported()) {
                state.error = "This browser engine cannot play protected video";

                return;
            }

            player = new shaka.Player();
            player.addEventListener("error", function (event) {
                state.error = describe(event.detail);
            });
            player.configure({
                drm: {
                    servers: { "com.widevine.alpha": licenseUrl },
                },
                streaming: {
                    bufferingGoal: 30,
                },
            });
            // The license server knows the user from the session cookies
            player.getNetworkingEngine().registerRequestFilter(function (type, request) {
                if (type === shaka.net.NetworkingEngine.RequestType.LICENSE) {
                    request.allowCrossSiteCredentials = true;
                }
            });
            player.attach(video)
                .then(function () {
                    return player.load(manifest, startSeconds > 0 ? startSeconds : null);
                })
                .then(function () {
                    state.loaded = true;

                    return video.play();
                })
                .catch(function (error) {
                    state.error = describe(error);
                });
        },
        state: function () {
            return {
                loaded: state.loaded,
                error: state.error,
                position: video.currentTime * 1000,
                duration: isFinite(video.duration) ? video.duration * 1000 : 0,
                paused: video.paused,
                ended: video.ended,
                buffering: player ? player.isBuffering() : true,
            };
        },
        play: function () {
            video.play();
        },
        pause: function () {
            video.pause();
        },
        seek: function (milliseconds) {
            video.currentTime = milliseconds / 1000;
        },
        setRate: function (rate) {
            video.playbackRate = rate;
        },
    };
})();
