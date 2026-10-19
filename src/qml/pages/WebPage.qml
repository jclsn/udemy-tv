// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtWebEngine

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// A Udemy web page, for what the app does not do itself: signing in, checkout, quizzes.
// Chromium's spatial navigation lets the arrow keys move between links and fields.
BigscreenUI.Page {
    id: root

    property url url
    property string hint: i18n("Move with the arrow keys, select with OK, press Back to return.")

    signal closeRequested()

    background: Rectangle {
        color: Style.background
    }

    // Back goes back in the page first, then leaves it
    BigscreenUI.BackHandler.enabled: visible
    BigscreenUI.BackHandler.onActivated: {
        if (view.canGoBack && view.url.toString() !== root.url.toString()) {
            view.goBack();
        } else {
            root.closeRequested();
        }
    }

    header: Rectangle {
        implicitHeight: headerLayout.implicitHeight + Kirigami.Units.gridUnit * 1.5
        color: Style.band

        RowLayout {
            id: headerLayout
            anchors.fill: parent
            anchors.leftMargin: root.contentMargins.left
            anchors.rightMargin: root.contentMargins.right
            spacing: Kirigami.Units.gridUnit

            Wordmark {
                color: "white"
                pixelSize: 24
            }

            BigscreenUI.Label {
                Layout.fillWidth: true
                text: root.title.length > 0 ? root.title : view.title
                color: "white"
                type: BigscreenUI.Label.Heading
                elide: Text.ElideRight
            }

            BigscreenUI.Label {
                Layout.maximumWidth: root.width * 0.45
                text: root.hint
                color: Style.purpleLight
                type: BigscreenUI.Label.Small
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignRight
            }
        }

        // How far the page has loaded
        Rectangle {
            anchors.bottom: parent.bottom
            height: 3
            width: parent.width * view.loadProgress / 100
            color: Style.purple
            visible: view.loading
        }
    }

    WebEngineView {
        id: view

        anchors.fill: parent
        focus: true
        profile: UdemyClient.profile
        url: root.url
        zoomFactor: Math.max(1, Math.min(1.5, root.width / 1400))

        settings.fullScreenSupportEnabled: true
        settings.playbackRequiresUserGesture: false

        onFullScreenRequested: request => request.accept()
        onNewWindowRequested: request => view.url = request.requestedUrl
    }
}
