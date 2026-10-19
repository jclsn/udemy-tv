// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtWebEngine
import QtWebChannel

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// The hidden page that makes API requests for UdemyClient (see bridge.js).
// When Cloudflare wants a person to confirm, it takes over the screen until they do.
Item {
    id: root

    readonly property bool needsAttention: challengeTimer.expired

    readonly property string challengeTitle: "Just a moment..."

    function load(): void {
        challengeTimer.stop();
        challengeTimer.expired = false;
        UdemyClient.bridgeDetached();
        view.url = "about:blank";
        view.url = UdemyClient.bridgeUrl;
    }

    // Takes a 1px corner until it is needed; Chromium throttles pages it thinks are hidden
    width: needsAttention ? parent.width : 1
    height: needsAttention ? parent.height : 1
    z: needsAttention ? 1000 : -1
    opacity: needsAttention ? 1 : 0.01

    Component.onCompleted: {
        if (!UdemyClient.demoMode) {
            load();
        }
    }

    WebEngineView {
        id: view

        anchors.fill: parent
        anchors.topMargin: root.needsAttention ? notice.height : 0
        profile: UdemyClient.profile
        webChannel: channel
        focus: root.needsAttention

        onLoadingChanged: request => {
            if (request.status === WebEngineView.LoadStartedStatus) {
                UdemyClient.bridgeDetached();

                return;
            }

            if (request.status === WebEngineView.LoadStoppedStatus) {
                return;
            }

            // HTTP errors still load the page (403 while signed out); only a dead network can't
            if (request.status === WebEngineView.LoadFailedStatus
                    && request.errorDomain !== WebEngineView.HttpErrorDomain) {
                console.warn("Bridge page failed to load:", request.errorString);
                retryTimer.restart();

                return;
            }

            if (view.title === root.challengeTitle) {
                // Cloudflare usually passes on its own and then reloads the page
                if (!challengeTimer.running && !challengeTimer.expired) {
                    challengeTimer.start();
                }

                return;
            }

            challengeTimer.stop();
            challengeTimer.expired = false;
            view.runJavaScript(UdemyClient.bridgeScript);
        }
    }

    WebChannel {
        id: channel
        registeredObjects: [endpoint]
    }

    WebBridge {
        id: endpoint
        WebChannel.id: "udtvBridge"
    }

    Timer {
        id: challengeTimer
        property bool expired: false
        interval: 12000
        onTriggered: expired = true
    }

    Timer {
        id: retryTimer
        interval: 5000
        onTriggered: root.load()
    }

    Connections {
        target: UdemyClient

        function onFetchRequested(id: int, method: string, url: string, body: string,
                                  headers: var, anonymous: bool): void {
            const args = [id, method, url, body, headers, anonymous]
                .map(value => JSON.stringify(value))
                .join(",");
            const script = `window.__udtv && window.__udtv.fetch
                ? window.__udtv.fetch(${args}) : false`;
            view.runJavaScript(script, result => {
                if (result === false) {
                    // The page went away between the request and now; it is sent again once it is
                    // back
                    UdemyClient.bridgeDetached();
                }
            });
        }

        function onBridgeReloadRequested(): void {
            root.load();
        }
    }

    Rectangle {
        id: notice

        visible: root.needsAttention
        width: parent.width
        height: noticeLayout.implicitHeight + Kirigami.Units.gridUnit * 2
        color: Style.band

        RowLayout {
            id: noticeLayout
            anchors.fill: parent
            anchors.margins: Kirigami.Units.gridUnit
            spacing: Kirigami.Units.gridUnit

            Kirigami.Icon {
                source: "security-medium"
                implicitWidth: Kirigami.Units.iconSizes.medium
                implicitHeight: implicitWidth
            }

            BigscreenUI.Label {
                Layout.fillWidth: true
                color: "white"
                wrapMode: Text.Wrap
                text: i18n("Udemy wants to make sure you are a person. Use the arrow keys to reach "
                    + "the check box below and press OK.")
            }
        }
    }
}
