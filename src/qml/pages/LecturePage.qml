// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// One lecture, shown the way it needs: the player, an article, Udemy's web player or a message
BigscreenUI.Page {
    id: root

    required property CourseSession session
    required property int row

    // Udemy's player for this lecture, instead of the app's
    property bool useWebPlayer: false

    readonly property var item: session.item(row)
    readonly property var lecture: loader.lecture
    readonly property string kind: lecture.kind ?? ""
    readonly property int nextRow: session.nextLecture(row)
    readonly property int previousRow: session.previousLecture(row)

    function goTo(newRow: int): void {
        if (newRow < 0) {
            return;
        }

        useWebPlayer = false;
        session.setCurrentRow(newRow);
        row = newRow;
    }

    BigscreenUI.BackHandler.enabled: visible
    BigscreenUI.BackHandler.onActivated: T.StackView.view.pop()

    background: Rectangle {
        color: "black"
    }

    LectureLoader {
        id: loader
        courseId: root.session.courseId
        lectureId: root.item.id ?? 0
    }

    Loader {
        id: content

        anchors.fill: parent
        focus: true

        sourceComponent: {
            if (loader.loading || (root.kind.length === 0 && loader.error.length === 0)) {
                return busyView;
            }

            if (loader.error.length > 0) {
                return errorView;
            }

            if (root.useWebPlayer || root.kind === "drm") {
                return UdemyClient.drmAvailable || root.useWebPlayer ? webPlayerView : drmView;
            }

            if ((root.lecture.protected ?? false) && !UdemyClient.drmAvailable) {
                return drmView;
            }

            switch (root.kind) {
            case "video":
            case "mashup":
            case "presentation":
                return playerView;
            case "article":
                return articleView;
            default:
                return unsupportedView;
            }
        }

        onLoaded: item.forceActiveFocus()
    }

    Component {
        id: busyView
        Item {
            BigscreenUI.BusyIndicator {
                anchors.centerIn: parent
                running: true
            }
        }
    }

    Component {
        id: playerView
        NativePlayer {
            session: root.session
            row: root.row
            lecture: root.lecture
            hasNext: root.nextRow >= 0
            hasPrevious: root.previousRow >= 0
            nextTitle: root.session.item(root.nextRow).title ?? ""
            onNextRequested: root.goTo(root.nextRow)
            onPreviousRequested: root.goTo(root.previousRow)
            onWebPlayerRequested: root.useWebPlayer = true

            // The last minute: load the next lecture, so "Up next" starts it at once
            onPositionChanged: {
                if (duration > 0 && duration - position < 60 * 1000 && root.nextRow >= 0) {
                    loader.prefetchLecture(root.session.item(root.nextRow).id ?? 0);
                }
            }
        }
    }

    Component {
        id: webPlayerView
        WebPlayer {
            session: root.session
            row: root.row
            url: root.session.webUrl(root.row)
            hasNext: root.nextRow >= 0
            hasPrevious: root.previousRow >= 0
            onNextRequested: root.goTo(root.nextRow)
            onPreviousRequested: root.goTo(root.previousRow)
        }
    }

    Component {
        id: articleView
        ArticleView {
            session: root.session
            row: root.row
            lecture: root.lecture
            hasNext: root.nextRow >= 0
            onNextRequested: root.goTo(root.nextRow)
        }
    }

    Component {
        id: errorView
        MessageView {
            iconName: "network-disconnect"
            text: i18n("This lecture could not be loaded")
            explanation: loader.error
            primaryText: i18n("Try again")
            onPrimaryClicked: loader.reload()
            secondaryText: root.nextRow >= 0 ? i18n("Next lecture") : ""
            onSecondaryClicked: root.goTo(root.nextRow)
        }
    }

    Component {
        id: drmView
        MessageView {
            iconName: "object-locked"
            text: i18n("This lecture is copy protected")
            explanation: i18n("It can only play in Udemy's own player, which needs the Widevine "
                + "module. Install Chromium or Google Chrome and play any protected video there "
                + "once so it downloads Widevine, then restart Udemy TV.")
            primaryText: i18n("Try Udemy's player anyway")
            onPrimaryClicked: root.useWebPlayer = true
            secondaryText: root.nextRow >= 0 ? i18n("Next lecture") : ""
            onSecondaryClicked: root.goTo(root.nextRow)
        }
    }

    Component {
        id: unsupportedView
        MessageView {
            iconName: root.kind === "processing" ? "chronometer" : "internet-services"
            text: root.kind === "processing" ? i18n("This lecture is still being processed")
                : root.kind === "file" ? i18n("This lecture is a download")
                : root.kind === "external" ? i18n("This lecture links to another website")
                : i18n("This kind of lecture is not supported yet")
            explanation: root.kind === "external" && (root.lecture.externalUrl ?? "").length > 0
                ? root.lecture.externalUrl
                : i18n("You can open it in Udemy's web player.")
            primaryText: i18n("Open in Udemy's web player")
            onPrimaryClicked: root.useWebPlayer = true
            secondaryText: root.nextRow >= 0 ? i18n("Next lecture") : ""
            onSecondaryClicked: root.goTo(root.nextRow)
        }
    }
}
