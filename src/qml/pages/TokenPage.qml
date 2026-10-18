// SPDX-FileCopyrightText: 2026 Jan Claussen <jan.claussen10@web.de>
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.bigscreen.ui as BigscreenUI

import io.github.udemytv

// Asks for an access token (as Udeler does), or for the Udemy Business subdomain
BigscreenUI.Page {
    id: root

    enum Mode {
        Token,
        Business
    }

    property int mode: TokenPage.Token

    signal closeRequested()
    signal businessLoginRequested()

    function submit(): void {
        if (root.mode === TokenPage.Business) {
            UdemyClient.portal = field.text;
            root.businessLoginRequested();
        } else if (field.text.trim().length > 0) {
            UdemyClient.useAccessToken(field.text);
            root.closeRequested();
        }
    }

    background: Rectangle {
        color: "white"
    }

    BigscreenUI.BackHandler.enabled: visible
    BigscreenUI.BackHandler.onActivated: root.closeRequested()

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 8, Kirigami.Units.gridUnit * 45)
        spacing: Kirigami.Units.gridUnit * 1.5

        Text {
            Layout.fillWidth: true
            text: root.mode === TokenPage.Business ? i18n("Log in to Udemy Business")
                : i18n("Use an access token")
            color: Style.text
            wrapMode: Text.Wrap
            font.family: Style.serifFamily
            font.pixelSize: 44
            font.weight: Font.Bold
        }

        BigscreenUI.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Style.subtleText
            text: root.mode === TokenPage.Business
                ? i18n("Enter your organization's Udemy address, the part before .udemy.com. "
                    + "You then sign in the way your organization set up.")
                : i18n("Sign in to Udemy in a browser on a computer, then copy the value of the "
                    + "cookie named access_token (in the developer tools, under Application or "
                    + "Storage › Cookies). You can also start the app with --token or set "
                    + "UDEMY_TOKEN.")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            BigscreenUI.TextField {
                id: field
                Layout.fillWidth: true
                focus: true
                placeholderText: root.mode === TokenPage.Business ? i18n("your-company")
                    : i18n("Access token")
                text: root.mode === TokenPage.Business && UdemyClient.portal !== "www"
                    ? UdemyClient.portal : ""
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                    | (root.mode === TokenPage.Token ? Qt.ImhSensitiveData : 0)
                echoMode: root.mode === TokenPage.Token ? TextInput.PasswordEchoOnEdit
                    : TextInput.Normal
                onAccepted: root.submit()
                KeyNavigation.down: continueButton
            }

            BigscreenUI.Label {
                visible: root.mode === TokenPage.Business
                text: ".udemy.com"
                color: Style.subtleText
            }
        }

        RowLayout {
            spacing: Kirigami.Units.gridUnit

            PrimaryButton {
                id: continueButton
                text: root.mode === TokenPage.Business ? i18n("Continue") : i18n("Sign in")
                enabled: field.text.trim().length > 0
                onClicked: root.submit()
                KeyNavigation.right: cancelButton
                KeyNavigation.up: field
            }

            PrimaryButton {
                id: cancelButton
                secondary: true
                text: i18n("Cancel")
                onClicked: root.closeRequested()
                KeyNavigation.up: field
            }
        }
    }
}
