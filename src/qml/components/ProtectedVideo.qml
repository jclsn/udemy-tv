// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtWebEngine

import io.github.udemytv

// A copy-protected video, decrypted by the browser engine's Widevine module (see
// protectedplayer.js). It only shows the picture; NativePlayer draws the controls.
Item {
    id: root

    required property string source
    required property string licenseToken

    // Where to start, in seconds
    property real startPosition: 0
    property real playbackRate: 1

    readonly property bool loaded: videoState.loaded ?? false
    readonly property real position: videoState.position ?? 0
    readonly property real duration: videoState.duration ?? 0
    readonly property bool playing: loaded && !(videoState.paused ?? true)
    readonly property bool busy: !loaded || (videoState.buffering ?? false)
    readonly property string errorString: videoState.error ?? ""

    signal finished()

    property var videoState: ({})

    function play(): void {
        call("play()");
    }

    function pause(): void {
        call("pause()");
    }

    function seek(milliseconds: real): void {
        call(`seek(${milliseconds})`);
        // Show the new position at once rather than at the next poll
        videoState = Object.assign({}, videoState, { position: milliseconds });
    }

    function call(script: string): void {
        view.runJavaScript(`window.__udtvVideo && window.__udtvVideo.${script}`);
    }

    onPlaybackRateChanged: call(`setRate(${playbackRate})`)

    WebEngineView {
        id: view

        anchors.fill: parent
        // The remote stays with the app's controls
        enabled: false
        profile: UdemyClient.profile
        backgroundColor: "black"
        url: UdemyClient.bridgeUrl

        settings.playbackRequiresUserGesture: false
        settings.showScrollBars: false

        onLoadingChanged: request => {
            if (request.status !== WebEngineView.LoadSucceededStatus) {
                if (request.status === WebEngineView.LoadFailedStatus) {
                    root.videoState = { error: request.errorString };
                }

                return;
            }

            view.runJavaScript(UdemyClient.protectedPlayerScript);
            const licenseUrl = UdemyClient.absoluteUrl(
                "/api-2.0/media-license-server/validate-auth-token?drm_type=widevine&auth_token="
                + encodeURIComponent(root.licenseToken));
            const args = [root.source, licenseUrl.toString(), root.startPosition]
                .map(value => JSON.stringify(value))
                .join(",");
            root.call(`load(${args})`);
            root.call(`setRate(${root.playbackRate})`);
        }

        onJavaScriptConsoleMessage: (level, message, lineNumber, sourceId) => {
            if (level !== WebEngineView.InfoMessageLevel) {
                console.info("Protected video:", message);
            }
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: true
        onTriggered: view.runJavaScript("window.__udtvVideo ? window.__udtvVideo.state() : null",
                                        result => {
            if (!result) {
                return;
            }

            const ended = result.ended && !(root.videoState.ended ?? false);
            root.videoState = result;

            if (ended) {
                root.finished();
            }
        })
    }
}
