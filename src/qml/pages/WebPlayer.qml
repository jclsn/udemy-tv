// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtWebEngine

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// A lecture in Udemy's own web player, for what only plays there (DRM-protected videos).
// The app's controls drive the page's video (see webplayer.js); "Show the whole page" hands
// the remote to the page instead, for example to use Udemy's own view switcher.
FocusScope {
    id: root

    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary
    Kirigami.Theme.inherit: false

    required property CourseSession session
    required property int row
    required property url url

    property bool hasNext: false
    property bool hasPrevious: false

    signal nextRequested()
    signal previousRequested()

    // The page has the keys, and shows itself as it is
    property bool interactive: false
    property var videoState: ({ found: false })
    property bool completionSent: false

    function call(script: string): void {
        view.runJavaScript(`window.__udtvPlayer && window.__udtvPlayer.${script}`);
    }

    function setInteractive(on: bool): void {
        interactive = on;
        call(`setTvMode(${!on})`);

        if (on) {
            view.forceActiveFocus();
        } else {
            overlay.forceActiveFocus();
        }
    }

    WebEngineView {
        id: view

        anchors.fill: parent
        focus: root.interactive
        profile: UdemyClient.profile
        url: root.url
        zoomFactor: root.interactive ? Math.max(1, Math.min(1.5, root.width / 1400)) : 1
        backgroundColor: "black"

        settings.playbackRequiresUserGesture: false
        settings.fullScreenSupportEnabled: true
        onFullScreenRequested: request => request.accept()

        onLoadingChanged: request => {
            if (request.status === WebEngineView.LoadSucceededStatus) {
                view.runJavaScript(UdemyClient.webPlayerScript);

                if (root.interactive) {
                    root.call("setTvMode(false)");
                }
            }
        }
    }

    // Udemy's player is a single page app; keep asking for the video until it is there
    Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: {
            const script = "window.__udtvPlayer ? window.__udtvPlayer.state() : null";
            view.runJavaScript(script, result => {
                if (!result) {
                    view.runJavaScript(UdemyClient.webPlayerScript);

                    return;
                }

                root.videoState = result;

                if (result.found && result.ended && !root.completionSent) {
                    root.completionSent = true;
                    root.session.setCompleted(root.row, true);
                    overlay.show();
                }
            });
        }
    }

    // Pages without a video, such as quizzes, are used directly
    Timer {
        interval: 8000
        running: !root.videoState.found
        onTriggered: {
            if (!root.videoState.found) {
                root.setInteractive(true);
            }
        }
    }

    BigscreenUI.PlayerOverlay {
        id: overlay

        anchors.fill: parent
        visible: !root.interactive
        focus: !root.interactive

        overline: root.session.course.title ?? ""
        title: root.session.item(root.row).title ?? ""
        metadata: [i18n("Udemy web player")]
        position: root.videoState.position ?? 0
        duration: root.videoState.duration ?? 0
        playing: root.videoState.found && !root.videoState.paused
        busy: !root.videoState.found || root.videoState.buffering
        hasPrevious: root.hasPrevious
        hasNext: root.hasNext

        onPlayPauseRequested: root.call("togglePlay()")
        onSeekRequested: position => root.call(`seek(${position})`)
        onPreviousRequested: root.previousRequested()
        onNextRequested: root.nextRequested()

        actions: [
            Kirigami.Action {
                text: i18n("Speed")
                icon.name: "speedometer"
                onTriggered: {
                    const options = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2].map(rate => ({
                        text: rate === 1 ? i18n("Normal")
                            : i18n("%1×", rate.toLocaleString(Qt.locale())),
                        value: rate
                    }));
                    drawer.openWith(i18n("Playback speed"), options, root.videoState.rate ?? 1,
                                    value => root.call(`setRate(${value})`));
                }
            },
            Kirigami.Action {
                text: i18n("Show the whole page")
                icon.name: "internet-services"
                onTriggered: root.setInteractive(true)
            }
        ]
    }

    // While the page has the keys, Back returns to the app's controls first
    BigscreenUI.BackHandler.enabled: root.interactive && root.videoState.found
    BigscreenUI.BackHandler.onActivated: root.setInteractive(false)

    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Kirigami.Units.gridUnit
        visible: root.interactive
        width: hint.implicitWidth + Kirigami.Units.gridUnit * 2
        height: hint.implicitHeight + Kirigami.Units.gridUnit
        radius: height / 2
        color: Qt.alpha(Style.dark, 0.9)

        BigscreenUI.Label {
            id: hint
            anchors.centerIn: parent
            color: "white"
            type: BigscreenUI.Label.Small
            text: root.videoState.found
                ? i18n("Arrow keys move around the page. Back returns to the player controls.")
                : i18n("Arrow keys move around the page, OK selects. Back returns to the course.")
        }
    }

    OptionsDrawer {
        id: drawer
        onClosed: overlay.forceActiveFocus()
    }
}
