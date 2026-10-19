// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// The welcome screen while signed out, laid out like Udemy's login page
BigscreenUI.Page {
    id: root

    signal webLoginRequested()
    signal tokenRequested()
    signal businessRequested()

    background: Rectangle {
        color: Style.background
    }

    BigscreenUI.BackHandler.enabled: visible
    BigscreenUI.BackHandler.onActivated: Window.window.quitDialog.open()

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Udemy's login page has a picture beside the form
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 0.45
            color: Style.band

            Image {
                anchors.fill: parent
                source: "qrc:/demo/images/coast.jpg"
                fillMode: Image.PreserveAspectCrop
                opacity: 0.55
            }

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Kirigami.Units.gridUnit * 4
                spacing: Kirigami.Units.gridUnit

                Wordmark {
                    color: "white"
                    pixelSize: 56
                }

                Text {
                    Layout.fillWidth: true
                    text: i18n("Learn on the big screen.")
                    color: "white"
                    wrapMode: Text.Wrap
                    font.family: Style.serifFamily
                    font.pixelSize: 40
                    font.weight: Font.Bold
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                id: form

                anchors.centerIn: parent
                width: Math.min(parent.width - Kirigami.Units.gridUnit * 6,
                                Kirigami.Units.gridUnit * 30)
                spacing: Kirigami.Units.gridUnit * 1.5

                Text {
                    Layout.fillWidth: true
                    text: i18n("Log in to continue your learning journey")
                    color: Style.text
                    wrapMode: Text.Wrap
                    font.family: Style.serifFamily
                    font.pixelSize: 44
                    font.weight: Font.Bold
                }

                BigscreenUI.Label {
                    Layout.fillWidth: true
                    Layout.bottomMargin: Kirigami.Units.gridUnit
                    wrapMode: Text.Wrap
                    color: Style.subtleText
                    text: i18n("You sign in on Udemy's own page. Udemy then emails you a code, "
                        + "or you use your password.")
                }

                // Such as an access token Udemy did not accept
                BigscreenUI.Label {
                    Layout.fillWidth: true
                    visible: UdemyClient.lastError.length > 0
                    wrapMode: Text.Wrap
                    color: Kirigami.Theme.negativeTextColor
                    text: UdemyClient.lastError
                }

                PrimaryButton {
                    id: emailButton
                    Layout.fillWidth: true
                    focus: true
                    icon.name: "mail-message"
                    text: i18n("Continue with email")
                    onClicked: root.webLoginRequested()
                    KeyNavigation.down: businessButton
                }

                PrimaryButton {
                    id: businessButton
                    Layout.fillWidth: true
                    secondary: true
                    icon.name: "office-building"
                    text: i18n("Log in to Udemy Business")
                    onClicked: root.businessRequested()
                    KeyNavigation.down: tokenButton
                }

                PrimaryButton {
                    id: tokenButton
                    Layout.fillWidth: true
                    secondary: true
                    icon.name: "dialog-password"
                    text: i18n("Use an access token")
                    onClicked: root.tokenRequested()
                }

                BigscreenUI.Label {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.gridUnit
                    wrapMode: Text.Wrap
                    type: BigscreenUI.Label.Small
                    color: Style.subtleText
                    text: i18n("Udemy TV is an unofficial app and is not affiliated with "
                        + "Udemy, Inc.")
                }
            }
        }
    }
}
