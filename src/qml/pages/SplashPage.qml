// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

BigscreenUI.Page {
    id: root

    background: Rectangle {
        color: "white"
    }

    BigscreenUI.BackHandler.enabled: visible
    BigscreenUI.BackHandler.onActivated: Window.window.quitDialog.open()

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.6, Kirigami.Units.gridUnit * 40)
        spacing: Kirigami.Units.gridUnit * 2

        Wordmark {
            Layout.alignment: Qt.AlignHCenter
            pixelSize: 72
        }

        BigscreenUI.BusyIndicator {
            Layout.alignment: Qt.AlignHCenter
            running: root.visible
        }

        BigscreenUI.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Style.subtleText
            text: UdemyClient.bridgeReady || UdemyClient.demoMode
                ? i18n("Checking your account…") : i18n("Connecting to Udemy…")
        }

        BigscreenUI.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: text.length > 0
            type: BigscreenUI.Label.Small
            color: Kirigami.Theme.negativeTextColor
            text: UdemyClient.lastError.length > 0
                ? i18n("Still trying: %1", UdemyClient.lastError) : ""
        }
    }
}
